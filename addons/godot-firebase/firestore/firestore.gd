## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.3
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

## Emitted when a  [code]list()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal listed_documents(documents)
## Emitted when a  [code]query()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal result_query(result)
## Emitted when a [code]list()[/code] or [code]query()[/code] request is [b]not[/b] successfully completed.
## @arg-types Dictionary
signal error(error)

enum Requests {
    NONE = -1,  ## Firestore is not processing any request.
    LIST,       ## Firestore is processing a [code]list()[/code] request on a collection.
    QUERY       ## Firestore is processing a [code]query()[/code] request on a collection.
}

const CACHE_SIZE_UNLIMITED = -1

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "
const _ENCRYPTION_KEY: String = "3979244226452948404D635166546A57"
const _CACHE_PREFIX: String = ".fscache-"

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @enum Requests
var request : int = -1

## 
var persistence_enabled : bool = true

var networking: bool = true setget set_networking

## A Dictionary containing all collections currently referenced.
## @type Dictionary
var collections : Dictionary = {}

## A Dictionary containing all authentication fields for the current logged user.
## @type Dictionary
var auth : Dictionary

var _config : Dictionary = {}
var _cache_loc: String


var _base_url : String = "https://firestore.googleapis.com/v1/"
var _extended_url : String = "projects/[PROJECT_ID]/databases/(default)/documents/"
var _query_suffix : String = ":runQuery"
var _aes := preload("res://addons/godot-firebase/utils/aes.gd").new()

var _request_list_node : HTTPRequest
var _requests_queue : Array = []
var _current_query : FirestoreQuery
var _offline: bool = false setget _set_offline

func _set_config(config_json : Dictionary) -> void:
    _config = config_json
    _cache_loc = _config["cacheLocation"]
    _extended_url = _extended_url.replace("[PROJECT_ID]", _config.projectId)
    _request_list_node = HTTPRequest.new()
    _request_list_node.connect("request_completed", self, "_on_request_completed")
    add_child(_request_list_node)
    


## Returns a reference collection by its [i]path[/i].
## 
## The returned object will be of [code]FirestoreCollection[/code] type.
## If saved into a variable, it can be used to issue requests on the collection itself.
## @args path
## @return FirestoreCollection
func collection(path : String) -> FirestoreCollection:
    if !collections.has(path):
        var coll : FirestoreCollection = FirestoreCollection.new()
        coll._extended_url = _extended_url
        coll._base_url = _base_url
        coll._config = _config
        coll.auth = auth
        coll.collection_name = path
        collections[path] = coll
        add_child(coll)
        return coll
    else:
        return collections[path]


func collection_query(id : String) -> void:
    pass


func doc() -> void:
    pass


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
## @args query
## @arg-types FirestoreQuery
## @return FirestoreTask
func query(query : FirestoreQuery) -> FirestoreTask:
    if not auth:
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task.connect("listed_documents", self, "_on_listed_documents")
        firestore_task.connect("error", self, "_on_error")
        firestore_task.set_action(FirestoreTask.TASK_QUERY)
        var body : Dictionary = { structuredQuery = query.query }
        var url : String = _base_url + _extended_url + _query_suffix
        firestore_task._push_request(url, _AUTHORIZATION_HEADER + auth.idtoken, JSON.print(body))
        return firestore_task
    else:
        printerr("Unauthorized")
        return null


## Request a list of contents (documents and/or collections) inside a collection, specified by its [i]id[/i].
##
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
## @args collection_id, page_size, page_token, order_by
## @arg-types String, int, String, String
## @arg-defaults , 0, "", ""
## @return FirestoreTask
func list(path : String, page_size : int = 0, page_token : String = "", order_by : String = "") -> FirestoreTask:
    if auth: 
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task.connect("result_query", self, "_on_result_query")
        firestore_task.connect("error", self, "_on_error")
        firestore_task.set_action(FirestoreTask.TASK_LIST)
        var url : String
        if not path in [""," "]:
            url = _base_url + _extended_url + path + "/"
        else:
            url = _base_url + _extended_url
        if page_size != 0:
            url+="?pageSize="+str(page_size)
        if page_token != "":
            url+="&pageToken="+page_token
        if order_by != "":
            url+="&orderBy="+order_by
        firestore_task._push_request(url, _AUTHORIZATION_HEADER + auth.idtoken)
        return firestore_task
    else:
        printerr("Unauthorized")
        return null


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

# -------------

func _set_offline(value: bool) -> void:
    if value == _offline:
        return
    
    _offline = value
    if not persistence_enabled:
        return
    
    var unique_id := OS.get_unique_id()
    if unique_id.empty():
        unique_id = "BRY4J903BRWT89YW3N09PO3"
    var event_record_path: String = _config["cacheLocation"].plus_file(_CACHE_PREFIX + unique_id)
    
    if not value:
        var offline_time := 2147483647 # Maximum signed 32-bit integer
        var file := File.new()
        if file.open(event_record_path, File.READ) == OK:
            offline_time = int(_aes.decrypt(file.get_buffer(file.get_len()), _ENCRYPTION_KEY).get_string_from_utf8())
        file.close()
        
        var cache_dir := Directory.new()
        var cache_files := []
        if cache_dir.open(_cache_loc) == OK:
            cache_dir.list_dir_begin(true)
            var file_name = cache_dir.get_next()
            while file_name != "":
                if not cache_dir.current_is_dir() and file_name.begins_with(_CACHE_PREFIX) and file.get_modified_time(_cache_loc.plus_file(file_name)) >= offline_time:
                    cache_files.append(_cache_loc.plus_file(file_name))
                file_name = cache_dir.get_next()
            cache_dir.list_dir_end()
        
        cache_dir.remove(event_record_path)
        cache_files.erase(event_record_path)
        
        for cache in cache_files:
            var name: String = cache.right(cache.find_last(_CACHE_PREFIX) + len(_CACHE_PREFIX))
            name = _aes.decrypt(Marshalls.base64_to_raw(name), _ENCRYPTION_KEY).get_string_from_utf8()
            var deleted := false
            if file.open(cache, File.READ) == OK:
                var collection := collection(name.left(name.find_last("/")))
                var content := _aes.decrypt(file.get_buffer(file.get_len()), _ENCRYPTION_KEY).get_string_from_utf8()
                if content == "--deleted--":
                    collection.delete(name.right(name.find_last("/") + 1))
                    deleted = true
                else:
                    collection.update(name.right(name.find_last("/") + 1))
            file.close()
            if deleted:
                cache_dir.remove(cache)
    
    else:
        var file := File.new()
        if file.open(event_record_path, File.WRITE) == OK:
            file.store_buffer(_aes.encrypt(str(OS.get_unix_time()), _ENCRYPTION_KEY))
        file.close()


func _on_listed_documents(listed_documents : Array):
    emit_signal("listed_documents", listed_documents)


func _on_result_query(result : Dictionary):
    emit_signal("result_query", result)


func _on_error(error : Dictionary):
    printerr(JSON.print(error))


func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
    for key in collections:
        collections[key].auth = auth

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
    for key in collections:
        collections[key].auth = auth
