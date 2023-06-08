## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.5
##
## Referenced by [code]Firebase.Firestore[/code]. Represents the Firestore module.
## Cloud Firestore is a flexible, scalable database for mobile, web, and server development from Firebase and Google Cloud.
## Like Firebase Realtime Database, it keeps your data in sync across client apps through realtime listeners and offers offline support for mobile and web so you can build responsive apps that work regardless of network latency or Internet connectivity. Cloud Firestore also offers seamless integration with other Firebase and Google Cloud products, including Cloud Functions.
##
## Following Cloud Firestore's NoSQL data model, you store data in [b]documents[/b] that contain fields mapping to values. These documents are stored in [b]collections[/b], which are containers for your documents that you can use to organize your data and build queries.
## Documents support many different data types, from simple strings and numbers, to complex, nested objects. You can also create subcollections within documents and build hierarchical data structures that scale as your database grows.
## The Cloud Firestore data model supports whatever data structure works best for your app.
##
## (source: [url=https://firebase.google.com/docs/firestore]Firestore[/url])
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore
tool
class_name FirebaseFirestore
extends Node

const _API_VERSION : String = "v1"

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
var persistence_enabled : bool = false

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
var _encrypt_key := "5vg76n90345f7w390346" if OS.get_name() in ["HTML5", "UWP"] else OS.get_unique_id()


var _base_url : String = ""
var _extended_url : String = "projects/[PROJECT_ID]/databases/(default)/documents/"
var _query_suffix : String = ":runQuery"

#var _connect_check_node : HTTPRequest

var _request_list_node : HTTPRequest
var _requests_queue : Array = []
var _current_query : FirestoreQuery

var _http_request_pool := []

var _offline: bool = false setget _set_offline

func _ready() -> void:
    pass

func _process(delta : float) -> void:
    for i in range(_http_request_pool.size() - 1, -1, -1):
        var request = _http_request_pool[i]
        if not request.get_meta("requesting"):
            var lifetime: float = request.get_meta("lifetime") + delta
            if lifetime > _MAX_POOLED_REQUEST_AGE:
                request.queue_free()
                _http_request_pool.remove(i)
            request.set_meta("lifetime", lifetime)


## Returns a reference collection by its [i]path[/i].
##
## The returned object will be of [code]FirestoreCollection[/code] type.
## If saved into a variable, it can be used to issue requests on the collection itself.
## @args path
## @return FirestoreCollection
func collection(path : String) -> FirestoreCollection:
    if not collections.has(path):
        var coll : FirestoreCollection = FirestoreCollection.new()
        coll._extended_url = _extended_url
        coll._base_url = _base_url
        coll._config = _config
        coll.auth = auth
        coll.collection_name = path
        coll.firestore = self
        collections[path] = coll
        return coll
    else:
        return collections[path]


## Issue a query on your Firestore database.
##
## [b]Note:[/b] a [code]FirestoreQuery[/code] object needs to be created to issue the query.
## This method will return a [code]FirestoreTask[/code] object, representing a reference to the request issued.
## If saved into a variable, the [code]FirestoreTask[/code] object can be used to yield on the [code]result_query(result)[/code] signal, or the more generic [code]task_finished(result)[/code] signal.
##
## ex.
## [code]var query_task : FirestoreTask = Firebase.Firestore.query(FirestoreQuery.new())[/code]
## [code]yield(query_task, "task_finished")[/code]
## Since the emitted signal is holding an argument, it can be directly retrieved as a return variable from the [code]yield()[/code] function.
##
## ex.
## [code]var result : Array = yield(query_task, "task_finished")[/code]
##
## [b]Warning:[/b] It currently does not work offline!
##
## @args query
## @arg-types FirestoreQuery
## @return FirestoreTask
func query(query : FirestoreQuery) -> FirestoreTask:
    var firestore_task : FirestoreTask = FirestoreTask.new()
    firestore_task.connect("result_query", self, "_on_result_query")
    firestore_task.connect("task_error", self, "_on_task_error")
    firestore_task.action = FirestoreTask.Task.TASK_QUERY
    var body : Dictionary = { structuredQuery = query.query }
    var url : String = _base_url + _extended_url + _query_suffix

    firestore_task.data = query
    firestore_task._fields = JSON.print(body)
    firestore_task._url = url
    _pooled_request(firestore_task)
    return firestore_task


## Request a list of contents (documents and/or collections) inside a collection, specified by its [i]id[/i]. This method will return a [code]FirestoreTask[/code] object, representing a reference to the request issued. If saved into a variable, the [code]FirestoreTask[/code] object can be used to yield on the [code]result_query(result)[/code] signal, or the more generic [code]task_finished(result)[/code] signal.
## [b]Note:[/b] [code]order_by[/code] does not work in offline mode.
## ex.
## [code]var query_task : FirestoreTask = Firebase.Firestore.query(FirestoreQuery.new())[/code]
## [code]yield(query_task, "task_finished")[/code]
## Since the emitted signal is holding an argument, it can be directly retrieved as a return variable from the [code]yield()[/code] function.
##
## ex.
## [code]var result : Array = yield(query_task, "task_finished")[/code]
##
## @args collection_id, page_size, page_token, order_by
## @arg-types String, int, String, String
## @arg-defaults , 0, "", ""
## @return FirestoreTask
func list(path : String = "", page_size : int = 0, page_token : String = "", order_by : String = "") -> FirestoreTask:
    var firestore_task : FirestoreTask = FirestoreTask.new()
    firestore_task.connect("listed_documents", self, "_on_listed_documents")
    firestore_task.connect("task_error", self, "_on_task_error")
    firestore_task.action = FirestoreTask.Task.TASK_LIST
    var url : String = _base_url + _extended_url + path
    if page_size != 0:
        url+="?pageSize="+str(page_size)
    if page_token != "":
        url+="&pageToken="+page_token
    if order_by != "":
        url+="&orderBy="+order_by

    firestore_task.data = [path, page_size, page_token, order_by]
    firestore_task._url = url
    _pooled_request(firestore_task)
    return firestore_task


func set_networking(value: bool) -> void:
    if value:
        enable_networking()
    else:
        disable_networking()


func enable_networking() -> void:
    if networking:
        return
    networking = true
    _base_url = _base_url.replace("storeoffline", "firestore")
    for key in collections:
        collections[key]._base_url = _base_url


func disable_networking() -> void:
    if not networking:
        return
    networking = false
    # Pointing to an invalid url should do the trick.
    _base_url = _base_url.replace("firestore", "storeoffline")
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

    _check_emulating()


func _check_emulating() -> void :
    ## Check emulating
    if not Firebase.emulating:
        _base_url = "https://firestore.googleapis.com/{version}/".format({ version = _API_VERSION })
    else:
        var port : String = _config.emulators.ports.firestore
        if port == "":
            Firebase._printerr("You are in 'emulated' mode, but the port for Firestore has not been configured.")
        else:
            _base_url = "http://localhost:{port}/{version}/".format({ version = _API_VERSION, port = port })

func _pooled_request(task : FirestoreTask) -> void:
    if _offline:
        task._on_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 404, PoolStringArray(), PoolByteArray())
        return

    if not auth and not Firebase.emulating:
        Firebase._print("Unauthenticated request issued...")
        Firebase.Auth.login_anonymous()
        var result : Array = yield(Firebase.Auth, "auth_request")
        if result[0] != 1:
            _check_auth_error(result[0], result[1])
        Firebase._print("Client connected as Anonymous")

    if not Firebase.emulating:
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
    http_request.request(task._url, task._headers, !Firebase.emulating, task._method, task._fields)


# -------------


func _on_listed_documents(listed_documents : Array):
    emit_signal("listed_documents", listed_documents)


func _on_result_query(result : Array):
    emit_signal("result_query", result)

func _on_task_error(code : int, status : String, message : String, task : int):
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


func _on_connect_check_request_completed(result : int, _response_code, _headers, _body) -> void:
    _set_offline(result != HTTPRequest.RESULT_SUCCESS)
    #_connect_check_node.request(_base_url)


func _on_FirebaseAuth_logout() -> void:
    auth = {}

func _check_auth_error(code : int, message : String) -> void:
    var err : String
    match code:
        400: err = "Please enable the Anonymous Sign-in method, or Authenticate the Client before issuing a request"
    Firebase._printerr(err)
    Firebase._printerr(message)
