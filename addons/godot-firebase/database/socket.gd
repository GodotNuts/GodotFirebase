## @meta-authors TODO
## @meta-version 1.0
## Persistent WebSocket write transport for the Realtime Database.
## Speaks the v5 wire protocol the official SDKs use: one connection per
## namespace, writes acked in order, reconnect with backoff. Reads stay on SSE.
@tool
class_name FirebaseDatabaseSocket
extends Node

signal state_changed(connected : bool)

const _PROTOCOL_VERSION : String = "5"
const _MAX_FRAME_SIZE : int = 16384
const _KEEPALIVE_MSEC : int = 45000
const _BACKOFF_MIN : float = 1.0
const _BACKOFF_MAX : float = 30.0
const _OUTBOUND_BUFFER_SIZE : int = 1 << 22

## A queued or in-flight write. Resolved once by emitting `done`.
class Write extends RefCounted:
	signal done(ack : Dictionary)
	var action : String
	var body : Dictionary
	var request_id : int = 0

## True once the handshake and the auth ack are in: writes are being sent.
var connected : bool = false:
	set(value):
		if value == connected:
			return
		connected = value
		state_changed.emit(value)

var _scheme : String
var _host : String
var _namespace : String
var _token : String = ""
var _peer : WebSocketPeer = WebSocketPeer.new()
var _active : bool = false
var _handshaken : bool = false
var _session_id : String = ""
var _auth_request_id : int = 0
var _next_request_id : int = 1
var _queued : Array[Write] = []
var _in_flight : Dictionary = {}
var _backoff : float = _BACKOFF_MIN
var _retry_at_msec : int = 0
var _last_send_msec : int = 0
var _frames_expected : int = 0
var _frames_buffer : String = ""


func _init(host : String, database_namespace : String, secure : bool = true) -> void:
	_scheme = "wss" if secure else "ws"
	_host = host
	_namespace = database_namespace


func _process(_delta : float) -> void:
	if not _active:
		if Time.get_ticks_msec() >= _retry_at_msec:
			_open()
		return
	_peer.poll()
	match _peer.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while _peer.get_available_packet_count() > 0:
				_on_frame(_peer.get_packet().get_string_from_utf8())
			if Time.get_ticks_msec() - _last_send_msec >= _KEEPALIVE_MSEC:
				_send_text("0")
		WebSocketPeer.STATE_CLOSED:
			_on_closed()


func _exit_tree() -> void:
	_peer.close()
	_fail_in_flight("disconnected")
	_fail_queued("disconnected")


## Writes `data` at `path` (absolute, from the database root). `null` deletes.
func put(path : String, data : Variant) -> Dictionary:
	return await _write("p", {"p": path, "d": data})


## Updates the children of `path`, same semantics as a REST PATCH.
func merge(path : String, data : Dictionary) -> Dictionary:
	return await _write("m", {"p": path, "d": data})


## Sets the id token to authenticate with; an empty token de-authenticates.
func set_token(token : String) -> void:
	if token == _token:
		return
	_token = token
	if not _handshaken:
		return
	if token == "":
		connected = false
		_send_json({"t": "d", "d": {"r": _take_request_id(), "a": "unauth", "b": {}}})
	else:
		_send_auth()


func _write(action : String, body : Dictionary) -> Dictionary:
	var write := Write.new()
	write.action = action
	write.body = body
	_queued.push_back(write)
	_flush()
	var ack : Dictionary = await write.done
	return ack


func _flush() -> void:
	while connected and not _queued.is_empty():
		var write : Write = _queued.pop_front()
		write.request_id = _take_request_id()
		_in_flight[write.request_id] = write
		if not _send_json({"t": "d", "d": {"r": write.request_id, "a": write.action, "b": write.body}}):
			_in_flight.erase(write.request_id)
			write.done.emit(_ack(false, "send_failed", null))


func _open() -> void:
	var url := "%s://%s/.ws?v=%s&ns=%s" % [_scheme, _host, _PROTOCOL_VERSION, _namespace]
	if _session_id != "":
		url += "&ls=" + _session_id
	_peer = WebSocketPeer.new()
	_peer.outbound_buffer_size = _OUTBOUND_BUFFER_SIZE
	var err := _peer.connect_to_url(url)
	if err != OK:
		Firebase._printerr("Database socket could not connect to %s: %s" % [url, error_string(err)])
		_schedule_retry()
		return
	_active = true
	_handshaken = false
	_frames_expected = 0
	_frames_buffer = ""
	_last_send_msec = Time.get_ticks_msec()


func _on_closed() -> void:
	_active = false
	_handshaken = false
	connected = false
	_auth_request_id = 0
	Firebase._print("Database socket closed (%d %s), reconnecting in %.0fs" % [_peer.get_close_code(), _peer.get_close_reason(), _backoff])
	_fail_in_flight("disconnected")
	_schedule_retry()


func _schedule_retry() -> void:
	_retry_at_msec = Time.get_ticks_msec() + int(_backoff * 1000.0)
	_backoff = clampf(_backoff * 2.0, _BACKOFF_MIN, _BACKOFF_MAX)


## Closes the connection and reconnects to `host` without waiting.
func _redirect(host : String) -> void:
	_host = host
	_backoff = 0.0
	_peer.close()


func _on_frame(text : String) -> void:
	if _frames_expected > 0:
		_frames_buffer += text
		_frames_expected -= 1
		if _frames_expected > 0:
			return
		text = _frames_buffer
		_frames_buffer = ""
	elif text.length() <= 6 and text.is_valid_int():
		# A bare integer announces how many frames make up the next message; 0 is a keepalive.
		_frames_expected = maxi(int(text), 0)
		_frames_buffer = ""
		return
	var message : Variant = JSON.parse_string(text)
	if not message is Dictionary:
		Firebase._printerr("Database socket received an unparseable frame: %s" % text.left(200))
		return
	var body : Variant = message.get("d")
	if not body is Dictionary:
		return
	match message.get("t"):
		"c":
			_on_control(body)
		"d":
			_on_data(body)


func _on_control(body : Dictionary) -> void:
	var data : Variant = body.get("d")
	match body.get("t"):
		"h":
			_on_handshake(data)
		"r":
			_redirect(str(data))
		"s":
			Firebase._print("Database socket server shutdown: %s" % str(data))
			_peer.close()
		"e":
			Firebase._printerr("Database socket server error: %s" % str(data))


func _on_handshake(data : Dictionary) -> void:
	_session_id = str(data.get("s", ""))
	_backoff = _BACKOFF_MIN
	var host : String = str(data.get("h", ""))
	if host != "" and host != _host:
		_redirect(host)
		return
	_handshaken = true
	if _token != "":
		_send_auth()


func _on_data(body : Dictionary) -> void:
	if body.has("r"):
		var request_id : int = int(body.r)
		var response : Dictionary = body.get("b", {})
		var status : String = str(response.get("s", ""))
		var ack := _ack(status == "ok", status, response.get("d"))
		if request_id == _auth_request_id:
			_on_auth_ack(ack)
		elif _in_flight.has(request_id):
			var write : Write = _in_flight[request_id]
			_in_flight.erase(request_id)
			write.done.emit(ack)
	elif body.get("a") == "ac":
		# Auth revoked (token expired or user disabled): re-auth, the auth module refreshes the token.
		var reason : Dictionary = body.get("b", {})
		Firebase._printerr("Database socket auth revoked: %s %s" % [reason.get("s", ""), reason.get("d", "")])
		connected = false
		if _token != "":
			_send_auth()


func _on_auth_ack(ack : Dictionary) -> void:
	_auth_request_id = 0
	if ack.ok:
		if not connected:
			Firebase._print("Database socket connected to %s" % _host)
		connected = true
		_flush()
	else:
		Firebase._printerr("Database socket auth failed: %s %s" % [ack.status, str(ack.data)])
		_fail_queued(ack.status)


func _send_auth() -> void:
	_auth_request_id = _take_request_id()
	_send_json({"t": "d", "d": {"r": _auth_request_id, "a": "auth", "b": {"cred": _token}}})


func _send_json(message : Dictionary) -> bool:
	var text := JSON.stringify(message)
	if text.length() <= _MAX_FRAME_SIZE:
		return _send_text(text) == OK
	var count : int = ceili(float(text.length()) / _MAX_FRAME_SIZE)
	if _send_text(str(count)) != OK:
		return false
	for i in count:
		if _send_text(text.substr(i * _MAX_FRAME_SIZE, _MAX_FRAME_SIZE)) != OK:
			return false
	return true


func _send_text(text : String) -> Error:
	_last_send_msec = Time.get_ticks_msec()
	var err := _peer.send_text(text)
	if err != OK:
		Firebase._printerr("Database socket send failed: %s" % error_string(err))
	return err


func _take_request_id() -> int:
	_next_request_id += 1
	return _next_request_id - 1


func _fail_in_flight(status : String) -> void:
	var writes : Array = _in_flight.values()
	_in_flight.clear()
	for write : Write in writes:
		write.done.emit(_ack(false, status, null))


func _fail_queued(status : String) -> void:
	var writes : Array[Write] = _queued
	_queued = []
	for write : Write in writes:
		write.done.emit(_ack(false, status, null))


func _ack(ok : bool, status : String, data : Variant) -> Dictionary:
	return {"ok": ok, "status": status, "data": data}
