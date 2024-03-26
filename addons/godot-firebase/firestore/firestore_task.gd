## @meta-authors Nicolò 'fenix' Santilio, Kyle 'backat50ft' Szklenski
## @meta-version 1.4
##
## A [code]FirestoreTask[/code] is an independent node inheriting [code]HTTPRequest[/code] that processes a [code]Firestore[/code] request.
## Once the Task is completed (both if successfully or not) it will emit the relative signal (or a general purpose signal [code]task_finished()[/code]) and will destroy automatically.
##
## Being a [code]Node[/code] it can be stored in a variable to yield checked it, and receive its result as a callback.
## All signals emitted by a [code]FirestoreTask[/code] represent a direct level of signal communication, which can be high ([code]get_document(document), result_query(result)[/code]) or low ([code]task_finished(result)[/code]).
## An indirect level of communication with Tasks is also provided, redirecting signals to the [class FirebaseFirestore] module.
##
## ex.
## [code]var task : FirestoreTask = Firebase.Firestore.query(query)[/code]
## [code]var result : Array = await task.task_finished[/code]
## [code]var result : Array = await task.result_query[/code]
## [code]var result : Array = await Firebase.Firestore.task_finished[/code]
## [code]var result : Array = await Firebase.Firestore.result_query[/code]
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore#FirestoreTask

@tool
class_name FirestoreTask
extends RefCounted

## Emitted when a request is completed. The request can be successful or not successful: if not, an [code]error[/code] Dictionary will be passed as a result.
## @arg-types Variant
signal task_finished(task)
## Emitted when a [code]add(document)[/code] request checked a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise and [code]null[/code] will be passed as a result..
## @arg-types FirestoreDocument
signal add_document(doc)
## Emitted when a [code]get(document)[/code] request checked a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise and [code]null[/code] will be passed as a result.
## @arg-types FirestoreDocument
signal get_document(doc)
## Emitted when a [code]update(document)[/code] request checked a [class FirebaseCollection] is successfully completed. [code]error()[/code] signal will be emitted otherwise and [code]null[/code] will be passed as a result.
## @arg-types FirestoreDocument
signal update_document(doc)
## Emitted when a [code]delete(document)[/code] request checked a [class FirebaseCollection] is successfully completed and [code]true[/code] will be passed. [code]error()[/code] signal will be emitted otherwise and [code]false[/code] will be passed as a result.
## @arg-types bool
signal delete_document(success)
## Emitted when a [code]list(collection_id)[/code] request checked [class FirebaseFirestore] is successfully completed. [code]error()[/code] signal will be emitted otherwise and [code][][/code] will be passed as a result..
## @arg-types Array
signal listed_documents(documents)
## Emitted when a [code]query(collection_id)[/code] request checked [class FirebaseFirestore] is successfully completed. [code]error()[/code] signal will be emitted otherwise and [code][][/code] will be passed as a result.
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

## Mapping of Task enum values to descriptions for use in printing user-friendly error codes.
const TASK_MAP = {
    Task.TASK_GET: "GET DOCUMENT",
    Task.TASK_POST: "ADD DOCUMENT",
    Task.TASK_PATCH: "UPDATE DOCUMENT",
    Task.TASK_DELETE: "DELETE DOCUMENT",
    Task.TASK_QUERY: "QUERY COLLECTION",
    Task.TASK_LIST: "LIST DOCUMENTS"
}

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @setter set_action
var action : int = -1 : set = set_action

## A variable, temporary holding the result of the request.
var data
var error : Dictionary
var document : FirestoreDocument
## Whether the data came from cache.
var from_cache : bool = false

var _response_headers : PackedStringArray = PackedStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _fields : String = ""
var _headers : PackedStringArray = []

func _on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
    var bod = body.get_string_from_utf8()
    if bod != "":
        bod = Utilities.get_json_data(bod)

    var offline: bool = typeof(bod) == TYPE_NIL
    var failed: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK
    from_cache = offline

    # Probably going to regret this...
    if response_code == HTTPClient.RESPONSE_OK:
        data = bod
        match action:
            Task.TASK_POST:
                document = FirestoreDocument.new(bod)
                add_document.emit(document)
            Task.TASK_GET:
                document = FirestoreDocument.new(bod)
                get_document.emit(document)
            Task.TASK_PATCH:
                document = FirestoreDocument.new(bod)
                update_document.emit(document)
            Task.TASK_DELETE:
                delete_document.emit(true)
            Task.TASK_QUERY:
                data = []
                for doc in bod:
                    if doc.has('document'):
                        data.append(FirestoreDocument.new(doc.document))
                result_query.emit(data)
            Task.TASK_LIST:
                data = []
                if bod.has('documents'):
                    for doc in bod.documents:
                        data.append(FirestoreDocument.new(doc))
                    if bod.has("nextPageToken"):
                        data.append(bod.nextPageToken)
                listed_documents.emit(data)
    else:
        var description = ""
        if TASK_MAP.has(action):
            description = "(" + TASK_MAP[action] + ")"

        Firebase._printerr("Action in error was: " + str(action) + " " + description)
        emit_error(task_error, bod, action)
        match action:
            Task.TASK_POST:
                add_document.emit(null)
            Task.TASK_GET:
                get_document.emit(null)
            Task.TASK_PATCH:
                update_document.emit(null)
            Task.TASK_DELETE:
                delete_document.emit(false)
            Task.TASK_QUERY:
                data = []
                result_query.emit(data)
            Task.TASK_LIST:
                data = []
                listed_documents.emit(data)

    task_finished.emit(self)

func emit_error(_signal, bod, task) -> void:
    if bod:
        if bod is Array and bod.size() > 0 and bod[0].has("error"):
            error = bod[0].error
        elif bod is Dictionary and bod.keys().size() > 0 and bod.has("error"):
            error = bod.error

        _signal.emit(error.code, error.status, error.message, task)

        return

    _signal.emit(1, 0, "Unknown error", task)

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
    return body # Removing caching for now, hopefully this works without killing everyone and everything

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
            ret.remove_at(index)
            deletions += i
        elif val is Array:
            ret[index] = _merge_array(ret[index] if ret[index] else [], val)
        elif val is Dictionary:
            ret[index] = _merge_dict(ret[index] if ret[index] else {}, val)
        else:
            ret[index] = val
    return ret
