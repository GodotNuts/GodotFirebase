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
	call_deferred("_process_request", meta_task)
	
	var task := StorageTask.new()
	_pending_tasks.append(task)
	yield(meta_task, "task_finished")
	
	task.ref = ref
	task.url = _get_file_url(file_path) + "?alt=media&token=" + meta_task.data.downloadTokens
	task.action = StorageTask.TASK_DOWNLOAD
	call_deferred("_process_request", task)
	
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
	
	var response_code := 0
	var response_headers := PoolStringArray()
	var rb := PoolByteArray() # Array that will hold the data.
	
	_http_client.connect_to_host(_base_url, 443, true)
	while _http_client.get_status() == HTTPClient.STATUS_CONNECTING or _http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		_http_client.poll()
		yield(get_tree(), "idle_frame")
	
	if _http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		call_deferred("_finish_request", HTTPRequest.RESULT_CANT_CONNECT, response_code, response_headers, rb, task)
		requesting = false
		return
	
	var err := _http_client.request_raw(task.method, task.url, task.headers, task.data)
	if err:
		call_deferred("_finish_request", HTTPRequest.RESULT_CONNECTION_ERROR, response_code, response_headers, rb, task)
		requesting = false
		return
	
	while _http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		_http_client.poll()
		yield(get_tree(), "idle_frame")
	
	if not (_http_client.get_status() == HTTPClient.STATUS_BODY or _http_client.get_status() == HTTPClient.STATUS_CONNECTED):
		call_deferred("_finish_request", HTTPRequest.RESULT_CONNECTION_ERROR, response_code, response_headers, rb, task)
		requesting = false
		return
	
	if _http_client.has_response():
		# If there is a response...
		response_headers = _http_client.get_response_headers() # Get response headers.
		response_code = _http_client.get_response_code()
		
		while _http_client.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			_http_client.poll()
			var chunk = _http_client.read_response_body_chunk() # Get a chunk.
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				yield(get_tree(), "idle_frame")
			else:
				rb += chunk # Append to read buffer.
		# Done!
	
	call_deferred("_finish_request", HTTPRequest.RESULT_SUCCESS, response_code, response_headers, rb, task)
	requesting = false

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

func _finish_request(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray, task : StorageTask) -> void:
	task.result = result
	task.response_code = response_code
	task.response_headers = headers
	
	if task.action == StorageTask.TASK_DOWNLOAD:
		task.data = body
	elif task.action == StorageTask.TASK_DELETE:
		task.ref.valid = false
		references.erase(task.ref.full_path)
	else:
		task.data = JSON.parse(body.get_string_from_utf8()).result
	task.finished = true
	task.emit_signal("task_finished")
	
	if not _pending_tasks.empty():
		var next_task : StorageTask = _pending_tasks.pop_front()
		_process_request(next_task)

func _on_FirebaseAuth_login_succeeded(auth_token : Dictionary) -> void:
	auth = auth_token
