## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.5
##
## (source: [url=https://firebase.google.com/docs/functions]Functions[/url])
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Functions
tool
class_name FirebaseFunctions
extends Node

## Emitted when a  [code]list()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal listed_documents(documents)
## Emitted when a  [code]query()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal result_query(result)
## Emitted when a  [code]query()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
## Emitted when a [code]list()[/code] or [code]query()[/code] request is [b]not[/b] successfully completed.
signal task_error(code,status,message)

enum Requests {
    NONE = -1,  ## Firestore is not processing any request.
    LIST,       ## Firestore is processing a [code]list()[/code] request on a collection.
    QUERY       ## Firestore is processing a [code]query()[/code] request on a collection.
}

# TODO: Implement cache size limit
const CACHE_SIZE_UNLIMITED = -1

const _CACHE_EXTENSION : String = ".fscache"
const _CACHE_RECORD_FILE : String = "RmlyZXN0b3JlIGNhY2hlLXJlY29yZHMu.fscache"

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

const _MAX_POOLED_REQUEST_AGE = 30

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @enum Requests
var request : int = -1

## Whether cache files can be used and generated.
## @default true
var persistence_enabled : bool = true

## Whether an internet connection can be used.
## @default true
var networking: bool = true setget set_networking

## A Dictionary containing all collections currently referenced.
## @type Dictionary
var collections : Dictionary = {}

## A Dictionary containing all authentication fields for the current logged user.
## @type Dictionary
var auth : Dictionary

var _config : Dictionary = {}
var _cache_loc: String
var _encrypt_key := _config.apiKey if OS.get_name() in ["HTML5", "UWP"] else OS.get_unique_id()

var _base_url : String =  _config.funcionsBaseUrl

var _request_list_node : HTTPRequest
var _requests_queue : Array = []
var _current_query : FirestoreQuery

var _http_request_pool := []

var _offline: bool = false setget _set_offline

func _ready() -> void:
    _request_list_node = HTTPRequest.new()
    _request_list_node.connect("request_completed", self, "_on_request_completed")
    _request_list_node.timeout = 5
    add_child(_request_list_node)

func _process(delta : float) -> void:
    for i in range(_http_request_pool.size() - 1, -1, -1):
        var request = _http_request_pool[i]
        if not request.get_meta("requesting"):
            var lifetime: float = request.get_meta("lifetime") + delta
            if lifetime > _MAX_POOLED_REQUEST_AGE:
                request.queue_free()
                _http_request_pool.remove(i)
            request.set_meta("lifetime", lifetime)


## @args 
## @return FunctionTask
func call(function: String, method: int, params: Dictionary = {}, body: Dictionary = {}) -> FunctionTask:
    var function_task : FunctionTask = FunctionTask.new()
    function_task.connect("result_query", self, "_on_result_query")
    function_task.connect("task_error", self, "_on_task_error")
    function_task.connect("task_query_error", self, "_on_task_query_error")
    function_task.action = method
    var url : String = _base_url + ("/" if not _base_url.ends_with("/") else "") + function
    function_task._url = url
    if not params.empty():
        url += "?"
        for key in params.keys():
            url += key + "=" + params[key] + "&"
    if not body.empty(): function_task._fields = JSON.print(body)
    _pooled_request(function_task)
    return function_task


func set_networking(value: bool) -> void:
    if value:
        enable_networking()
    else:
        disable_networking()


func enable_networking() -> void:
    if networking:
        return
    networking = true
    _base_url = _base_url.replace("storeoffline", "functions")
    for key in collections:
        collections[key]._base_url = _base_url


func disable_networking() -> void:
    if not networking:
        return
    networking = false
    # Pointing to an invalid url should do the trick.
    _base_url = _base_url.replace("functions", "storeoffline")
    for key in collections:
        collections[key]._base_url = _base_url


func _set_offline(value: bool) -> void:
    if value == _offline:
        return
    
    _offline = value
    if not persistence_enabled:
        return
    
    var event_record_path: String = _config["cacheLocation"].plus_file(_CACHE_RECORD_FILE)
    if not value:
        var offline_time := 2147483647 # Maximum signed 32-bit integer
        var file := File.new()
        if file.open_encrypted_with_pass(event_record_path, File.READ, _encrypt_key) == OK:
            offline_time = int(file.get_buffer(file.get_len()).get_string_from_utf8()) - 2
        file.close()
        
        var cache_dir := Directory.new()
        var cache_files := []
        if cache_dir.open(_cache_loc) == OK:
            cache_dir.list_dir_begin(true)
            var file_name = cache_dir.get_next()
            while file_name != "":
                if not cache_dir.current_is_dir() and file_name.ends_with(_CACHE_EXTENSION):
                    if file.get_modified_time(_cache_loc.plus_file(file_name)) >= offline_time:
                        cache_files.append(_cache_loc.plus_file(file_name))
#                    else:
#                        print("%s is old! It's time is %d, but the time offline was %d." % [file_name, file.get_modified_time(_cache_loc.plus_file(file_name)), offline_time])
                file_name = cache_dir.get_next()
            cache_dir.list_dir_end()
        
        cache_files.erase(event_record_path)
        cache_dir.remove(event_record_path)
        
        for cache in cache_files:
            var deleted := false
            if file.open_encrypted_with_pass(cache, File.READ, _encrypt_key) == OK:
                var name := file.get_line()
                var content := file.get_line()
                var collection_id := name.left(name.find_last("/"))
                var document_id := name.right(name.find_last("/") + 1)
                
                var collection := collection(collection_id)
                if content == "--deleted--":
                    collection.delete(document_id)
                    deleted = true
                else:
                    collection.update(document_id, FirestoreDocument.fields2dict(JSON.parse(content).result))
            else:
                Firebase._printerr("Failed to retrieve cache %s! Error code: %d" % [cache, file.get_error()])
            file.close()
            if deleted:
                cache_dir.remove(cache)
    
    else:
        var file := File.new()
        if file.open_encrypted_with_pass(event_record_path, File.WRITE, _encrypt_key) == OK:
            file.store_buffer(str(OS.get_unix_time()).to_utf8())
        file.close()


func _set_config(config_json : Dictionary) -> void:
    _config = config_json
    _cache_loc = _config["cacheLocation"]
    _extended_url = _extended_url.replace("[PROJECT_ID]", _config.projectId)
    
    var file := File.new()
    if file.file_exists(_cache_loc.plus_file(_CACHE_RECORD_FILE)):
        _offline = true
    else:
        _offline = false


func _pooled_request(task : FirestoreTask) -> void:
    if _offline:
        task._on_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 404, PoolStringArray(), PoolByteArray())
        return
    
    if not auth:
        Firebase._printerr("Unauthenticated request issued...")
        Firebase.Auth.login_anonymous()
        var result : Array = yield(Firebase.Auth, "auth_request")
        if result[0] != 1:
            _check_auth_error(result[0], result[1])
        Firebase._printerr("Client connected as Anonymous")
    
    task._headers = PoolStringArray([_AUTHORIZATION_HEADER + auth.idtoken])
    
    var http_request : HTTPRequest
    for request in _http_request_pool:
        if not request.get_meta("requesting"):
            http_request = request
            break
    
    if not http_request:
        http_request = HTTPRequest.new()
        http_request.timeout = 5
        _http_request_pool.append(http_request)
        add_child(http_request)
        http_request.connect("request_completed", self, "_on_pooled_request_completed", [http_request])
    
    http_request.set_meta("requesting", true)
    http_request.set_meta("lifetime", 0.0)
    http_request.set_meta("task", task)
    http_request.request(task._url, task._headers, true, task._method, task._fields)


# -------------


func _on_listed_documents(listed_documents : Array):
    emit_signal("listed_documents", listed_documents)


func _on_result_query(result : Array):
    emit_signal("result_query", result)

func _on_task_error(code : int, status : String, message : String):
    emit_signal("task_error", code, status, message)
    Firebase._printerr(message)

func _on_task_list_error(code : int, status : String, message : String):
    emit_signal("task_error", code, status, message)
    Firebase._printerr(message)

func _on_task_query_error(code : int, status : String, message : String):
    emit_signal("task_error", code, status, message)
    Firebase._printerr(message)

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
    for key in collections:
        collections[key].auth = auth


func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
    for key in collections:
        collections[key].auth = auth


func _on_pooled_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray, request : HTTPRequest) -> void:
    request.get_meta("task")._on_request_completed(result, response_code, headers, body)
    request.set_meta("requesting", false)
    request.queue_free()


func _on_connect_check_request_completed(result : int, _response_code, _headers, _body) -> void:
    _set_offline(result != HTTPRequest.RESULT_SUCCESS)
    #_connect_check_node.request(_base_url)


func _on_FirebaseAuth_logout() -> void:
    auth = {}

func _check_auth_error(code : int, message : String) -> void:
    var err : String
    match code:
        400: err = "Please, enable Anonymous Sign-in method or Authenticate the Client before issuing a request (best option)"
    Firebase._printerr(err)
