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
extends Reference

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

enum Task {
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

#func _ready() -> void:
#    connect("request_completed", self, "_on_request_completed")


#func _push_request(url := "", headers := "", fields := "") -> void:
#    _url = url
#    _fields = fields
#    var temp_header : Array = []
#    temp_header.append(headers)
#    _headers = PoolStringArray(temp_header)
#
#    if Firebase.Firestore._offline:
#        call_deferred("_on_request_completed", RESULT_CANT_CONNECT, 404, PoolStringArray(), PoolByteArray())
#    else:
#        request(_url, _headers, true, _method, _fields)


func _on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
    var bod
    if validate_json(body.get_string_from_utf8()).empty():
        bod = JSON.parse(body.get_string_from_utf8()).result
    
    var offline: bool = typeof(bod) == TYPE_NIL
    var error: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK
    from_cache = offline
    
    Firebase.Firestore._set_offline(offline)
    
    var cache_path : String = Firebase._config["cacheLocation"]
    if not cache_path.empty():
        var url_segment: String = data
        var encrypt_key: String = Firebase.Firestore._encrypt_key
        var full_path = _get_doc_file(cache_path, url_segment, encrypt_key)
        data = null
        
        var dir := Directory.new()
        dir.make_dir_recursive(cache_path)
        var file := File.new()
        match action:
            Task.TASK_POST:
                if offline or not error:
                    var save: Dictionary
                    if offline:
                        save = {
                            "name": "projects/%s/databases/(default)/documents/%s" % [Firebase._config["storageBucket"], url_segment],
                            "fields": JSON.parse(_fields).result["fields"],
                            "createTime": "from_cache_file",
                            "updateTime": "from_cache_file"
                        }
                    else:
                        save = bod.duplicate()
                    
                    if file.open_encrypted_with_pass(full_path, File.WRITE, encrypt_key) == OK:
                        file.store_line(url_segment)
                        file.store_line(JSON.print(save))
                        bod = save
                        response_code = HTTPClient.RESPONSE_OK
#                        print("file %s modified!" % full_path)
                    else:
                        printerr("Error saving cache file! Error code: %d" % file.get_error())
                    file.close()
            
            Task.TASK_PATCH:
                if offline or not error:
                    var save := {
                        "fields": {}
                    }
                    if offline:
                        var mod: Dictionary
                        mod = {
                            "name": "projects/%s/databases/(default)/documents/%s" % [Firebase._config["storageBucket"], url_segment],
                            "fields": JSON.parse(_fields).result["fields"],
                            "createTime": "from_cache_file",
                            "updateTime": "from_cache_file"
                        }
                        
                        if file.file_exists(full_path):
                            if file.open_encrypted_with_pass(full_path, File.READ, encrypt_key) == OK:
                                if file.get_len():
                                    assert(url_segment == file.get_line())
                                    var content := file.get_line()
                                    if content != "--deleted--":
                                        save = JSON.parse(content).result
                            else:
                                printerr("Error updating cache file! Error code: %d" % file.get_error())
                            file.close()
                        
                        save.fields = FirestoreDocument.dict2fields(_merge_dict(
                            FirestoreDocument.fields2dict({"fields": save.fields}),
                            FirestoreDocument.fields2dict({"fields": mod.fields}),
                            not offline
                        )).fields
                        save.name = mod.name
                        save.createTime = mod.createTime
                        save.updateTime = mod.updateTime
                    else:
                        save = bod.duplicate()
                    
                    
                    if file.open_encrypted_with_pass(full_path, File.WRITE, encrypt_key) == OK:
                        file.store_line(url_segment)
                        file.store_line(JSON.print(save))
                        bod = save
                        response_code = HTTPClient.RESPONSE_OK
#                        print("file %s modified!" % full_path)
                    else:
                        printerr("Error updating cache file! Error code: %d" % file.get_error())
                    file.close()
            
            Task.TASK_GET:
                if offline and file.file_exists(full_path):
                    if file.open_encrypted_with_pass(full_path, File.READ, encrypt_key) == OK:
                        assert(url_segment == file.get_line())
                        var content := file.get_line()
                        if content != "--deleted--":
                            bod = JSON.parse(content).result
                            response_code = HTTPClient.RESPONSE_OK
                    else:
                        printerr("Error reading cache file! Error code: %d" % file.get_error())
                    file.close()
            
            Task.TASK_DELETE:
                if offline:
                    if file.open_encrypted_with_pass(full_path, File.WRITE, encrypt_key) == OK:
                        file.store_line(url_segment)
                        file.store_line("--deleted--")
                        bod = null
#                        print("file %s modified!" % full_path)
                    else:
                        printerr("Error \"deleting\" cache file! Error code: %d" % file.get_error())
                    file.close()
                    response_code = HTTPClient.RESPONSE_OK
                else:
                    dir.remove(full_path)
    
    if response_code == HTTPClient.RESPONSE_OK:
        match action:
            Task.TASK_POST:
                var document : FirestoreDocument = FirestoreDocument.new(bod)
                data = bod
                emit_signal("add_document", document )
                emit_signal("task_finished", document)
            Task.TASK_GET:
                var document : FirestoreDocument = FirestoreDocument.new(bod)
                data = bod
                emit_signal("get_document", document )
                emit_signal("task_finished", document)
            Task.TASK_PATCH:
                var document : FirestoreDocument = FirestoreDocument.new(bod)
                data = bod
                emit_signal("update_document", document )
                emit_signal("task_finished", document)
            Task.TASK_DELETE:
                data = null
                emit_signal("delete_document")
                emit_signal("task_finished")
            Task.TASK_QUERY:
                data = null
                emit_signal("result_query", bod)
                emit_signal("task_finished", bod)
            Task.TASK_LIST:
                data = null
                emit_signal("listed_documents", bod.documents)
                emit_signal("task_finished", bod.documents)
    else:
        match action:
            Task.TASK_LIST, Task.TASK_QUERY:
                data = bod[0].error
                emit_signal("error", bod[0].error)
                emit_signal("task_finished", bod[0].error)
            _:
                data = bod.error
                emit_signal("error", bod.error)
                emit_signal("task_finished", bod.error)
#    queue_free()


func set_action(value : int) -> void:
    action = value
    match action:
        Task.TASK_GET, Task.TASK_LIST:
            _method = HTTPClient.METHOD_GET
        Task.TASK_POST, Task.TASK_QUERY:
            _method = HTTPClient.METHOD_POST
        Task.TASK_PATCH:
            _method = HTTPClient.METHOD_PATCH
        Task.TASK_DELETE:
            _method = HTTPClient.METHOD_DELETE


func _merge_dict(dic_a : Dictionary, dic_b : Dictionary, nullify := false) -> Dictionary:
    var ret := dic_a.duplicate(true)
    for key in dic_b:
        var val = dic_b[key]
        
        if val == null and nullify:
            ret.erase(key)
        elif val is Array:
            ret[key] = _merge_array(ret.get(key) if ret.get(key) else [], val)
        elif val is Dictionary:
            ret[key] = _merge_dict(ret.get(key) if ret.get(key) else {}, val)
        else:
            ret[key] = val
    return ret


func _merge_array(arr_a : Array, arr_b : Array, nullify := false) -> Array:
    var ret := arr_a.duplicate(true)
    ret.resize(len(arr_b))
    
    var deletions := 0
    for i in len(arr_b):
        var index : int = i - deletions
        var val = arr_b[index]
        if val == null and nullify:
            ret.remove(index)
            deletions += i
        elif val is Array:
            ret[index] = _merge_array(ret[index] if ret[index] else [], val)
        elif val is Dictionary:
            ret[index] = _merge_dict(ret[index] if ret[index] else {}, val)
        else:
            ret[index] = val
    return ret


static func _get_doc_file(cache_path : String, document_id : String, encrypt_key : String) -> String:
    var file := File.new()
    var path := ""
    var i = 0
    while i < 1000:
        path = cache_path.plus_file("%s-%d.fscache" % [str(document_id.hash()).pad_zeros(10), i])
        if file.file_exists(path):
            var is_file := false
            if file.open_encrypted_with_pass(path, File.READ, encrypt_key) == OK:
                is_file = file.get_line() == document_id
            file.close()
            
            if is_file:
                return path
            else:
                i += 1
        else:
            return path
    return path
