## @meta-authors Nicolò 'fenix' Santilio, Kyle 'backat50ft' Szklenski
## @meta-version 1.4
##
## A [code]FirestoreTask[/code] is an independent node inheriting [code]HTTPRequest[/code] that processes a [code]Firestore[/code] request.
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
signal task_finished(task)
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
signal task_error(code, status, message, task)

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
var error : Dictionary
var document : FirestoreDocument
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
#        call_deferred("_on_request_completed", -1, 404, PoolStringArray(), PoolByteArray())
#    else:
#        request(_url, _headers, true, _method, _fields)


func _on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
    var bod
    if validate_json(body.get_string_from_utf8()).empty():
        bod = JSON.parse(body.get_string_from_utf8()).result

    var offline: bool = typeof(bod) == TYPE_NIL
    var failed: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK
    from_cache = offline

    Firebase.Firestore._set_offline(offline)

    var cache_path : String = Firebase._config["cacheLocation"]
    if not cache_path.empty() and not failed and Firebase.Firestore.persistence_enabled:
        var encrypt_key: String = Firebase.Firestore._encrypt_key
        var full_path : String
        var url_segment : String
        match action:
            Task.TASK_LIST:
                url_segment = data[0]
                full_path = cache_path
            Task.TASK_QUERY:
                url_segment = JSON.print(data.query)
                full_path = cache_path
            _:
                url_segment = to_json(data)
                full_path = _get_doc_file(cache_path, url_segment, encrypt_key)
        bod = _handle_cache(offline, data, encrypt_key, full_path, bod)
        if not bod.empty() and offline:
            response_code = HTTPClient.RESPONSE_OK

    if response_code == HTTPClient.RESPONSE_OK:
        data = bod
        match action:
            Task.TASK_POST:
                document = FirestoreDocument.new(bod)
                emit_signal("add_document", document)
            Task.TASK_GET:
                document = FirestoreDocument.new(bod)
                emit_signal("get_document", document)
            Task.TASK_PATCH:
                document = FirestoreDocument.new(bod)
                emit_signal("update_document", document)
            Task.TASK_DELETE:
                emit_signal("delete_document")
            Task.TASK_QUERY:
                data = []
                for doc in bod:
                    if doc.has('document'):
                        data.append(FirestoreDocument.new(doc.document))
                emit_signal("result_query", data)
            Task.TASK_LIST:
                data = []
                if bod.has('documents'):
                    for doc in bod.documents:
                        data.append(FirestoreDocument.new(doc))
                    if bod.has("nextPageToken"):
                        data.append(bod.nextPageToken)
                emit_signal("listed_documents", data)
    else:
        Firebase._printerr("Action in error was: " + str(action))
        emit_error("task_error", bod, action)

    emit_signal("task_finished", self)

func emit_error(signal_name : String, bod, task) -> void:
    if bod:
        if bod is Array and bod.size() > 0 and bod[0].has("error"):
            error = bod[0].error
        elif bod is Dictionary and bod.keys().size() > 0 and bod.has("error"):
            error = bod.error

        emit_signal(signal_name, error.code, error.status, error.message, task)

        return

    emit_signal(signal_name, 1, 0, "Unknown error", task)

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


func _handle_cache(offline : bool, data, encrypt_key : String, cache_path : String, body) -> Dictionary:
    var body_return := {}

    var dir := Directory.new()
    dir.make_dir_recursive(cache_path)
    var file := File.new()
    match action:
        Task.TASK_POST:
            if offline:
                var save: Dictionary
                if offline:
                    save = {
                        "name": "projects/%s/databases/(default)/documents/%s" % [Firebase._config["storageBucket"], data],
                        "fields": JSON.parse(_fields).result["fields"],
                        "createTime": "from_cache_file",
                        "updateTime": "from_cache_file"
                    }
                else:
                    save = body.duplicate()

                if file.open_encrypted_with_pass(cache_path, File.READ, encrypt_key) == OK:
                    file.store_line(data)
                    file.store_line(JSON.print(save))
                    body_return = save
                else:
                    Firebase._printerr("Error saving cache file! Error code: %d" % file.get_error())
                file.close()

        Task.TASK_PATCH:
            if offline:
                var save := {
                    "fields": {}
                }
                if offline:
                    var mod: Dictionary
                    mod = {
                        "name": "projects/%s/databases/(default)/documents/%s" % [Firebase._config["storageBucket"], data],
                        "fields": JSON.parse(_fields).result["fields"],
                        "createTime": "from_cache_file",
                        "updateTime": "from_cache_file"
                    }

                    if file.file_exists(cache_path):
                        if file.open_encrypted_with_pass(cache_path, File.READ, encrypt_key) == OK:
                            if file.get_len():
                                assert(data == file.get_line())
                                var content := file.get_line()
                                if content != "--deleted--":
                                    save = JSON.parse(content).result
                        else:
                            Firebase._printerr("Error updating cache file! Error code: %d" % file.get_error())
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
                    save = body.duplicate()


                if file.open_encrypted_with_pass(cache_path, File.WRITE, encrypt_key) == OK:
                    file.store_line(data)
                    file.store_line(JSON.print(save))
                    body_return = save
                else:
                    Firebase._printerr("Error updating cache file! Error code: %d" % file.get_error())
                file.close()

        Task.TASK_GET:
            if offline and file.file_exists(cache_path):
                if file.open_encrypted_with_pass(cache_path, File.READ, encrypt_key) == OK:
                    assert(data == file.get_line())
                    var content := file.get_line()
                    if content != "--deleted--":
                        body_return = JSON.parse(content).result
                else:
                    Firebase._printerr("Error reading cache file! Error code: %d" % file.get_error())
                file.close()

        Task.TASK_DELETE:
            if offline:
                if file.open_encrypted_with_pass(cache_path, File.WRITE, encrypt_key) == OK:
                    file.store_line(data)
                    file.store_line("--deleted--")
                    body_return = {"deleted": true}
                else:
                    Firebase._printerr("Error \"deleting\" cache file! Error code: %d" % file.get_error())
                file.close()
            else:
                dir.remove(cache_path)

        Task.TASK_LIST:
            if offline:
                var cache_dir := Directory.new()
                var cache_files := []
                if cache_dir.open(cache_path) == OK:
                    cache_dir.list_dir_begin(true)
                    var file_name = cache_dir.get_next()
                    while file_name != "":
                        if not cache_dir.current_is_dir() and file_name.ends_with(Firebase.Firestore._CACHE_EXTENSION):
                            cache_files.append(cache_path.plus_file(file_name))
                        file_name = cache_dir.get_next()
                    cache_dir.list_dir_end()
                cache_files.erase(cache_path.plus_file(Firebase.Firestore._CACHE_RECORD_FILE))
                cache_dir.remove(cache_path.plus_file(Firebase.Firestore._CACHE_RECORD_FILE))
                print(cache_files)

                body_return.documents = []
                for cache in cache_files:
                    if file.open_encrypted_with_pass(cache, File.READ, encrypt_key) == OK:
                        if file.get_line().begins_with(data[0]):
                            body_return.documents.append(JSON.parse(file.get_line()).result)
                    else:
                        Firebase._printerr("Error opening cache file for listing! Error code: %d" % file.get_error())
                    file.close()
                body_return.documents.resize(min(data[1], body_return.documents.size()))
                body_return.nextPageToken = ""

        Task.TASK_QUERY:
            if offline:
                Firebase._printerr("Offline queries are currently unsupported!")

    if not offline:
        return body
    else:
        return body_return


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
    while i < 256:
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
