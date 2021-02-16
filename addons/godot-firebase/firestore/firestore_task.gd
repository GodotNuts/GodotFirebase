## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 1.1
##
## A [code]FirestoreTask[/code] is an indipendent node inheriting [code]HTTPRequest[/code] that processes a [code]Firestore[/code] request.
## Once the Task is completed (both if successfully or not) it will emit the relative signal (or a general purpose signal [code]task_finished()[/code]) and will destroy automatically.
## 
## Being a [code]Node[/code] it can be stored in a variable to yield on it, and receive its result as a callback.
## All signals emitted by a [code]FirestoreTask[/code] represent a direct level of signal communication, which can be high ([code]get_document(document), result_query(result)[/code]) or low ([code]task_finished(result)[/code]).
## An indirect level of communication with Tasks is also provided, redirecting signals to the [class FirebaseFirestore] module.
##
## ex.
## [code]var task : FirestoreTask = Firebase.Firestore.query(query)[/code]
## [code]var result : Array = yield(task, "task_finished")[/code]
## [code]var result : Array = yield(task, "result_query")[/code]
## [code]var result : Array = yield(Firebase.Firestore, "task_finished")[/code]
## [code]var result : Array = yield(Firebase.Firestore, "result_query")[/code]
## 
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore#FirestoreTask

tool
class_name FirestoreTask
extends HTTPRequest

## Emitted when a request is completed. The request can be successful or not successful: if not, an [code]error[/code] Dictionary will be passed as a result.
## @arg-types Variant
signal task_finished(result)
## Emitted when a [code]add(document)[/code] request on a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types FirestoreDocument
signal add_document(doc)
## Emitted when a [code]get(document)[/code] request on a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types FirestoreDocument
signal get_document(doc)
## Emitted when a [code]update(document)[/code] request on a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types FirestoreDocument
signal update_document(doc)
## Emitted when a [code]delete(document)[/code] request on a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types FirestoreDocument
signal delete_document()
## Emitted when a [code]list(collection_id)[/code] request on [class FirebaseFirestore] is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal listed_documents(documents)
## Emitted when a [code]query(collection_id)[/code] request on [class FirebaseFirestore] is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal result_query(result)
## Emitted when a request is [b]not[/b] successfully completed.
## @arg-types Dictionary
signal error(error)

enum {
    TASK_GET,       ## A GET Request Task, processing a get() request
    TASK_POST,      ## A POST Request Task, processing add() request 
    TASK_PATCH,     ## A PATCH Request Task, processing a update() request
    TASK_DELETE,    ## A DELETE Request Task, processing a delete() request
    TASK_QUERY,     ## A POST Request Task, processing a query() request
    TASK_LIST       ## A POST Request Task, processing a list() request
}

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @setter set_action
var action : int = -1 setget set_action

## A variable, temporary holding the result of the request.
var data

## Whether the data came from cache.
var from_cache : bool = false

var _response_headers : PoolStringArray = PoolStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _fields : String = ""
var _headers : PoolStringArray = []

var _aes := preload("../utils/aes.gd").new()

func _ready():
    connect("request_completed", self, "_on_request_completed")


func _push_request(url : String, headers : String, fields : String = ""):
    _url = url
    _fields = fields
    var temp_header : Array = []
    temp_header.append(headers)
    _headers = PoolStringArray(temp_header)
    if _fields == "":
        request(_url, _headers, true, _method)
    else:
        request(_url, _headers, true, _method, _fields)


func _on_request_completed(result, response_code, headers, body):
    var bod = JSON.parse(body.get_string_from_utf8()).result
    var offline: bool = typeof(bod) == TYPE_NIL
    var error: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK
    from_cache = offline
    
    Firebase.Firestore._set_offline(offline)
    
    var cache_path : String = Firebase._config["cacheLocation"]
    if not cache_path.empty():
        var url_segment: String = data
        var encrypt_key: String = Firebase.Firestore._ENCRYPTION_KEY
        var full_path = cache_path.plus_file(".fscache-" + Marshalls.raw_to_base64(_aes.encrypt(url_segment, encrypt_key)))
        data = null
        
        var dir := Directory.new()
        dir.make_dir_recursive(cache_path)
        var file := File.new()
        match action:
            TASK_POST:
                if offline or not error:
                    var save: Dictionary
                    if offline or error:
                        save = {
                            "name": "projects/%s/databases/(default)/documents/%s" % [Firebase._config["storageBucket"], url_segment],
                            "fields": JSON.parse(_fields).result["fields"],
                            "createTime": "from_cache_file",
                            "updateTime": "from_cache_file"
                        }
                    else:
                        save = bod.duplicate()
                    
                    if file.open(full_path, File.WRITE) == OK:
                        file.store_buffer(_aes.encrypt(JSON.print(save), encrypt_key))
                        bod = save
                        response_code = HTTPClient.RESPONSE_OK
                    else:
                        printerr("Error saving cache file! Error code: %d" % file.get_error())
                    file.close()
            
            TASK_PATCH:
                if offline or not error:
                    var mod: Dictionary
                    if offline or error:
                        mod = {
                            "name": "projects/%s/databases/(default)/documents/%s" % [Firebase._config["storageBucket"], url_segment],
                            "fields": JSON.parse(_fields).result["fields"],
                            "createTime": "from_cache_file",
                            "updateTime": "from_cache_file"
                        }
                    else:
                        mod = bod.duplicate()
                    
                    var save := {}
                    if file.file_exists(full_path):
                        if file.open(full_path, File.READ) == OK:
                            if file.get_len():
                                var content := _aes.decrypt(file.get_buffer(file.get_len()), encrypt_key).get_string_from_utf8()
                                if content != "--deleted--":
                                    mod = JSON.parse(content).result
                        else:
                            printerr("Error updating cache file! Error code: %d" % file.get_error())
                        file.close()
                    
                    for key in mod:
                        if not offline and not mod[key] and not mod[key] is int:
                            save.erase(key)
                        else:
                            save[key] = mod[key]
                    
                    if file.open(full_path, File.WRITE) == OK:
                        file.store_buffer(_aes.encrypt(JSON.print(save), encrypt_key))
                        bod = save
                        response_code = HTTPClient.RESPONSE_OK
                    else:
                        printerr("Error updating cache file! Error code: %d" % file.get_error())
                    file.close()
            
            TASK_GET:
                if offline and file.file_exists(full_path):
                    if file.open(full_path, File.READ) == OK:
                        var content := _aes.decrypt(file.get_buffer(file.get_len()), encrypt_key).get_string_from_utf8()
                        if content != "--deleted--":
                            bod = JSON.parse(content).result
                            response_code = HTTPClient.RESPONSE_OK
                    else:
                        printerr("Error reading cache file! Error code: %d" % file.get_error())
                    file.close()
            
            TASK_DELETE:
                if offline:
                    if file.file_exists(full_path):
                        if file.open(full_path, File.WRITE) == OK:
                            file.store_buffer(_aes.encrypt("--deleted--", encrypt_key))
                            bod = null
                        else:
                            printerr("Error \"deleting\" cache file! Error code: %d" % file.get_error())
                        file.close()
                    response_code = HTTPClient.RESPONSE_OK
                else:
                    dir.remove(full_path)
    
    if response_code == HTTPClient.RESPONSE_OK:
        match action:
            TASK_POST:
                var document : FirestoreDocument = FirestoreDocument.new(bod)
                emit_signal("add_document", document )
                emit_signal("task_finished", document)
                data = bod
            TASK_GET:
                var document : FirestoreDocument = FirestoreDocument.new(bod)
                emit_signal("get_document", document )
                emit_signal("task_finished", document)
                data = bod
            TASK_PATCH:
                var document : FirestoreDocument = FirestoreDocument.new(bod)
                emit_signal("update_document", document )
                emit_signal("task_finished", document)
                data = bod
            TASK_DELETE:
                emit_signal("delete_document")
                emit_signal("task_finished")
                data = null
            TASK_QUERY:
                emit_signal("result_query", bod)
                emit_signal("task_finished", bod)
                data = null
            TASK_LIST:
                emit_signal("listed_documents", bod.documents)
                emit_signal("task_finished", bod.documents)
                data = null
    else:
        match action:
            TASK_LIST, TASK_QUERY:
                emit_signal("error", bod[0].error)
                emit_signal("task_finished", bod[0].error)
                data = bod[0].error
            _:
                emit_signal("error", bod.error)
                emit_signal("task_finished", bod.error)
                data = bod.error
    queue_free()


func set_action(value : int) -> void:
    action = value
    match action:
        TASK_GET, TASK_LIST:
            _method = HTTPClient.METHOD_GET
        TASK_POST, TASK_QUERY:
            _method = HTTPClient.METHOD_POST
        TASK_PATCH:
            _method = HTTPClient.METHOD_PATCH
        TASK_DELETE:
            _method = HTTPClient.METHOD_DELETE
