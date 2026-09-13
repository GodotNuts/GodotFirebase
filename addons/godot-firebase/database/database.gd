## @meta-authors TODO
## @meta-version 2.2
## The Realtime Database API for Firebase.
## Documentation TODO.
@tool
class_name FirebaseDatabase
extends Node

var _base_url : String = ""

var _config : Dictionary = {}

var _auth : Dictionary = {}

var _socket : FirebaseDatabaseSocket = null

func _set_config(config_json : Dictionary) -> void:
	_config = config_json
	_check_emulating()

func _check_emulating() -> void :
	## Check emulating
	if not Firebase.emulating:
		_base_url = _config.databaseURL
	else:
		var port : String = _config.emulators.ports.realtimeDatabase
		if port == "":
			Firebase._printerr("You are in 'emulated' mode, but the port for Realtime Database has not been configured.")
		else:
			_base_url = "http://localhost"

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
	_auth = auth_result
	if _socket != null:
		_socket.set_token(_auth.get("idtoken", ""))

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
	_auth = auth_result
	if _socket != null:
		_socket.set_token(_auth.get("idtoken", ""))

func _on_FirebaseAuth_logout() -> void:
	_auth = {}
	if _socket != null:
		_socket.set_token("")

## The persistent write socket for this database, opened on first use.
func get_socket() -> FirebaseDatabaseSocket:
	if _socket == null:
		if Firebase.emulating:
			var port : String = _config.emulators.ports.realtimeDatabase
			_socket = FirebaseDatabaseSocket.new("127.0.0.1:" + port, _config.projectId + "-default-rtdb", false)
		else:
			var host : String = _config.databaseURL.get_slice("://", 1).get_slice("/", 0)
			_socket = FirebaseDatabaseSocket.new(host, host.get_slice(".", 0))
		_socket.set_token(_auth.get("idtoken", ""))
		add_child(_socket)
	return _socket

func get_database_reference(path : String, filter : Dictionary = {}) -> FirebaseDatabaseReference:
	var firebase_reference = load("res://addons/godot-firebase/database/firebase_database_reference.tscn").instantiate()
	firebase_reference.set_db_path(path, filter)
	firebase_reference.set_auth_and_config(_auth, _config)
	add_child(firebase_reference)
	return firebase_reference
	
func get_once_database_reference(path : String, filter : Dictionary = {}) -> FirebaseOnceDatabaseReference:
	var firebase_reference = load("res://addons/godot-firebase/database/firebase_once_database_reference.tscn").instantiate()
	firebase_reference.set_db_path(path, filter)
	firebase_reference.set_auth_and_config(_auth, _config)
	add_child(firebase_reference)
	return firebase_reference
