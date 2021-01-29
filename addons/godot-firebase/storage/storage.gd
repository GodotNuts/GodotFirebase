class_name FirebaseStorage
extends Node

var auth : Dictionary
var config : Dictionary
var bucket : String

var references : Dictionary = {}

var requesting : bool = false

const HTTPSSEClient = preload("res://addons/http-sse-client/HTTPSSEClient.gd")

var _base_url : String = "https://firebasestorage.googleapis.com"
var _extended_url : String = "/v0/b/[APP_ID]/o/[FILE_PATH]"
var _root_ref : StorageReference

var _http_client : HTTPClient = HTTPClient.new()
var _pending_tasks : Array = []

var _current_task : StorageTask
var _response_code : int
var _response_headers : PoolStringArray
var _response_data : PoolByteArray
var _reading_body : bool

func _notification(what : int) -> void:
	if what == NOTIFICATION_INTERNAL_PROCESS:
		_internal_process(get_process_delta_time())

func _internal_process(_delta : float) -> void:
	if not requesting:
		set_process_internal(false)
		return
	
	var task = _current_task
	
	match _http_client.get_status():
		HTTPClient.STATUS_DISCONNECTED:
			_http_client.connect_to_host(_base_url, 443, true)
		
		HTTPClient.STATUS_RESOLVING, \
		HTTPClient.STATUS_REQUESTING, \
		HTTPClient.STATUS_CONNECTING:
			_http_client.poll()
		
		HTTPClient.STATUS_CONNECTED:
			var err := _http_client.request_raw(task.method, task.url, task.headers, task.data)
			if err:
				call_deferred("_finish_request", HTTPRequest.RESULT_CONNECTION_ERROR)
		
		HTTPClient.STATUS_BODY:
			if _http_client.has_response() or _reading_body:
				_reading_body = true
				
				# If there is a response...
				_response_headers = _http_client.get_response_headers() # Get response headers.
				_response_code = _http_client.get_response_code()
				
				_http_client.poll()
				var chunk = _http_client.read_response_body_chunk() # Get a chunk.
				if chunk.size() == 0:
					# Got nothing, wait for buffers to fill a bit.
					pass
				else:
					_response_data += chunk # Append to read buffer.
				
				if _http_client.get_status() != HTTPClient.STATUS_BODY:
					call_deferred("_finish_request", HTTPRequest.RESULT_SUCCESS)
			else:
				call_deferred("_finish_request", HTTPRequest.RESULT_SUCCESS)
		
		HTTPClient.STATUS_CANT_CONNECT:
			call_deferred("_finish_request", HTTPRequest.RESULT_CANT_CONNECT)
		HTTPClient.STATUS_CANT_RESOLVE:
			call_deferred("_finish_request", HTTPRequest.RESULT_CANT_RESOLVE)
		HTTPClient.STATUS_CONNECTION_ERROR:
			call_deferred("_finish_request", HTTPRequest.RESULT_CONNECTION_ERROR)
		HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
			call_deferred("_finish_request", HTTPRequest.RESULT_SSL_HANDSHAKE_ERROR)

func set_config(config_json : Dictionary) -> void:
	config = config_json
	bucket = config.storageBucket

func ref(path := "") -> StorageReference:
	if not config:
		return null
	
	# Create a root storage reference if there's none
	# and we're not making one.
	if path != "" and not _root_ref:
		_root_ref = ref()
	
	path = _simplify_path(path)
	if not references.has(path):
		var ref := StorageReference.new()
		references[path] = ref
		ref.valid = true
		ref.bucket = bucket
		ref.full_path = path
		ref.name = path.get_file()
		ref.parent = ref(path.plus_file(".."))
		ref.root = _root_ref
		ref.storage = self
		return ref
	else:
		return references[path]

func _upload(data : PoolByteArray, file_path : String, headers : PoolStringArray, ref : StorageReference) -> StorageTask:
#	if not (config and auth):
#		return
	
	var task := StorageTask.new()
	task.ref = ref
	task.url = _get_file_url(file_path)
	task.action = StorageTask.TASK_UPLOAD
	task.headers = headers
	task.data = data
	call_deferred("_process_request", task)
	return task

func _download(file_path : String, ref : StorageReference) -> StorageTask:
#	if not (config and auth):
#		return
	
	var meta_task := StorageTask.new()
	meta_task.ref = ref
	meta_task.url = _get_file_url(file_path)
	meta_task.action = StorageTask.TASK_METADATA
	_process_request(meta_task)
	
	var task := StorageTask.new()
	_pending_tasks.append(task)
	yield(meta_task, "task_finished")
	
	task.ref = ref
	task.action = StorageTask.TASK_DOWNLOAD
	task.url = _get_file_url(file_path) + "?alt=media&token="
	
	if meta_task.data:
		task.url += meta_task.data.downloadTokens
		_process_request(task)
	else:
		task.data = PoolByteArray()
		task.response_headers = meta_task.response_headers
		task.finished = true
		task.result = meta_task.result
		task.emit_signal("task_finished")
	
	return task

func _delete(file_path : String, ref : StorageReference) -> StorageTask:
#	if not (config and auth):
#		return
	
	var task := StorageTask.new()
	task.ref = ref
	task.url = _get_file_url(file_path)
	task.action = StorageTask.TASK_DELETE
	call_deferred("_process_request", task)
	return task

func _process_request(task : StorageTask) -> void:
	if requesting:
		_pending_tasks.append(task)
		return
	requesting = true
	
	_current_task = task
	_response_code = 0
	_response_headers = PoolStringArray()
	_response_data = PoolByteArray()
	_reading_body = false
	set_process_internal(true)

func _finish_request(result : int) -> void:
	var task := _current_task
	_http_client.close()
	requesting = false
	
	task.result = result
	task.response_code = _response_code
	task.response_headers = _response_headers
	
	if task.action == StorageTask.TASK_DOWNLOAD:
		task.data = _response_data
	elif task.action == StorageTask.TASK_DELETE:
		task.ref.valid = false
		references.erase(task.ref.full_path)
	else:
		task.data = JSON.parse(_response_data.get_string_from_utf8()).result
	task.finished = true
	task.emit_signal("task_finished")
	
	if not _pending_tasks.empty():
		var next_task : StorageTask = _pending_tasks.pop_front()
		_process_request(next_task)

func _get_file_url(file_path : String) -> String:
	var url := _extended_url.replace("[APP_ID]", bucket)
	return url.replace("[FILE_PATH]", file_path.replace("/", "%2F"))

# Removes any "../" or "./" in the file path.
func _simplify_path(path : String) -> String:
	var dirs := path.split("/")
	var new_dirs := []
	for dir in dirs:
		if dir == "..":
			new_dirs.pop_back()
		elif dir == ".":
			pass
		else:
			new_dirs.push_back(dir)
	
	return PoolStringArray(new_dirs).join("/")

func _on_FirebaseAuth_login_succeeded(auth_token : Dictionary) -> void:
	auth = auth_token
