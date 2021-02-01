# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.1                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

class_name FirebaseStorage
extends Node

signal task_successful(result, response_code, data)
signal task_failed(result, response_code, data)

var auth : Dictionary
var config : Dictionary
var bucket : String

var references : Dictionary = {}

var requesting : bool = false

var _base_url : String = "https://firebasestorage.googleapis.com"
var _extended_url : String = "/v0/b/[APP_ID]/o/[FILE_PATH]"
var _root_ref : StorageReference

var _http_client : HTTPClient = HTTPClient.new()
var _pending_tasks : Array = []

var _current_task : StorageTask
var _response_code : int
var _response_headers : PoolStringArray
var _response_data : PoolByteArray
var _content_length : int
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
            var err := _http_client.request_raw(task._method, task._url, task._headers, task.data)
            if err:
                call_deferred("_finish_request", HTTPRequest.RESULT_CONNECTION_ERROR)
        
        HTTPClient.STATUS_BODY:
            if _http_client.has_response() or _reading_body:
                _reading_body = true
                
                # If there is a response...
                if _response_headers.empty():
                    _response_headers = _http_client.get_response_headers() # Get response headers.
                    _response_code = _http_client.get_response_code()
                    
                    for header in _response_headers:
                        if "Content-Length" in header:
                            _content_length = header.trim_prefix("Content-Length: ").to_int()
                
                _http_client.poll()
                var chunk = _http_client.read_response_body_chunk() # Get a chunk.
                if chunk.size() == 0:
                    # Got nothing, wait for buffers to fill a bit.
                    pass
                else:
                    _response_data += chunk # Append to read buffer.
                    if _content_length != 0:
                        task.progress = float(_response_data.size()) / _content_length
                
                if _http_client.get_status() != HTTPClient.STATUS_BODY:
                    task.progress = 1.0
                    call_deferred("_finish_request", HTTPRequest.RESULT_SUCCESS)
            else:
                task.progress = 1.0
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
    if bucket != config.storageBucket:
        bucket = config.storageBucket
        _http_client.close()

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

func _upload(data : PoolByteArray, headers : PoolStringArray, ref : StorageReference, meta_only : bool) -> StorageTask:
    if not (config and auth):
        return null
    
    var task := StorageTask.new()
    task.ref = ref
    task._url = _get_file_url(ref)
    task.action = StorageTask.TASK_UPLOAD_META if meta_only else StorageTask.TASK_UPLOAD
    task._headers = headers
    task.data = data
    _process_request(task)
    return task

func _download(ref : StorageReference, meta_only : bool, url_only : bool) -> StorageTask:
    if not (config and auth):
        return null
    
    var info_task := StorageTask.new()
    info_task.ref = ref
    info_task._url = _get_file_url(ref)
    info_task.action = StorageTask.TASK_DOWNLOAD_URL if url_only else StorageTask.TASK_DOWNLOAD_META
    _process_request(info_task)
    
    if url_only or meta_only:
        return info_task
    
    var task := StorageTask.new()
    _pending_tasks.append(task)
    yield(info_task, "task_finished")
    
    task.ref = ref
    task._url = _get_file_url(ref) + "?alt=media&token="
    task.action = StorageTask.TASK_DOWNLOAD
    
    if info_task.data and not info_task.data.has("error"):
        task._url += info_task.data.downloadTokens
        _process_request(task)
    else:
        task.data = info_task.data
        task.response_headers = info_task.response_headers
        task.response_code = info_task.response_code
        task.finished = true
        task.result = info_task.result
        emit_signal("task_failed", task.result, task.response_code, task.data)
        task.emit_signal("task_finished")
    
    return task

func _list(ref : StorageReference, list_all : bool) -> StorageTask:
    if not (config and auth):
        return null
    
    var task := StorageTask.new()
    task.ref = ref
    task._url = _get_file_url(_root_ref).trim_suffix("/")
    task.action = StorageTask.TASK_LIST_ALL if list_all else StorageTask.TASK_LIST
    _process_request(task)
    return task

func _delete(ref : StorageReference) -> StorageTask:
    if not (config and auth):
        return null
    
    var task := StorageTask.new()
    task.ref = ref
    task._url = _get_file_url(ref)
    task.action = StorageTask.TASK_DELETE
    _process_request(task)
    return task

func _process_request(task : StorageTask) -> void:
    var headers = Array(task._headers)
    headers.append("Authorization: Bearer " + auth.idtoken)
    task._headers = PoolStringArray(headers)
    
    if requesting:
        _pending_tasks.append(task)
        return
    requesting = true
    
    _current_task = task
    _response_code = 0
    _response_headers = PoolStringArray()
    _response_data = PoolByteArray()
    _content_length = 0
    _reading_body = false
    
    if not _http_client.get_status() in [HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_DISCONNECTED]:
        _http_client.close()
    set_process_internal(true)

func _finish_request(result : int) -> void:
    var task := _current_task
    requesting = false
    
    task.result = result
    task.response_code = _response_code
    task.response_headers = _response_headers
    
    match task.action:
        StorageTask.TASK_DOWNLOAD:
            task.data = _response_data
        
        StorageTask.TASK_DELETE:
            references.erase(task.ref.full_path)
            task.ref.valid = false
            if typeof(task.data) == TYPE_RAW_ARRAY:
                task.data = null
        
        StorageTask.TASK_DOWNLOAD_URL:
            var json : Dictionary = JSON.parse(_response_data.get_string_from_utf8()).result
            if json and json.has("downloadTokens"):
                task.data = _base_url + _get_file_url(task.ref.full_path) + "?alt=media&token=" + json.downloadTokens
            else:
                task.data = ""
        
        StorageTask.TASK_LIST, StorageTask.TASK_LIST_ALL:
            var json : Dictionary = JSON.parse(_response_data.get_string_from_utf8()).result
            var items := []
            if json and json.has("items"):
                for item in json.items:
                    var item_name : String = item.name
                    if item.bucket != bucket:
                        continue
                    if not item_name.begins_with(task.ref.full_path):
                        continue
                    if task.action == StorageTask.TASK_LIST:
                        var dir_path : Array = item_name.split("/")
                        var slash_count : int = task.ref.full_path.count("/")
                        item_name = ""
                        for i in slash_count + 1:
                            item_name += dir_path[i]
                            if i != slash_count and slash_count != 0:
                                item_name += "/"
                        if item_name in items:
                            continue
                    
                    items.append(item_name)
            task.data = items
        
        _:
            task.data = JSON.parse(_response_data.get_string_from_utf8()).result
    
    task.finished = true
    task.emit_signal("task_finished")
    
    if typeof(task.data) == TYPE_DICTIONARY and task.data.has("error"):
        emit_signal("task_failed", task.result, task.response_code, task.data)
    else:
        emit_signal("task_successful", task.result, task.response_code, task.data)
    
    if not _pending_tasks.empty():
        var next_task : StorageTask = _pending_tasks.pop_front()
        _process_request(next_task)

func _get_file_url(ref : StorageReference) -> String:
    var url := _extended_url.replace("[APP_ID]", ref.bucket)
    return url.replace("[FILE_PATH]", ref.full_path.replace("/", "%2F"))

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
    
    var new_path := PoolStringArray(new_dirs).join("/")
    new_path = new_path.replace("//", "/")
    new_path = new_path.replace("\\", "/")
    return new_path

func _on_FirebaseAuth_login_succeeded(auth_token : Dictionary) -> void:
    auth = auth_token

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
