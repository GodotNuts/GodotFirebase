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

## @enum TASK_TYPES
enum {
    TASK_GET,       ## A GET Request Task, processing a get() request
    TASK_POST,      ## A POST Request TASK, processing add() request 
    TASK_PATCH,     ## A PATCH Request TASK, processing a update() request
    TASK_DELETE,    ## A DELETE Request TASK, processing a delete() request
    TASK_QUERY,     ## A POST Request TASK, processing a query() request
    TASK_LIST       ## A POST Request TASK, processing a list() request
}

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.REQUESTS] to get a full list of codes identifiers.
## @type int
var action : int = -1 setget _set_action

var _response_headers : PoolStringArray = PoolStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _headers : PoolStringArray = []



## A variable, temporary holding the result of the request
## @type Variant
var data

func _ready():
    connect("request_completed", self, "_on_request_completed")


func _set_action(value : int) -> void:
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
            

func _push_request(url : String, headers : String, fields : String = ""):
    _url = url
    var temp_header : Array = []
    temp_header.append(headers)
    _headers = PoolStringArray(temp_header)
    if fields == "":
        request(_url, _headers, true, _method)
    else:
        request(_url, _headers, true, _method, fields)
        

func _on_request_completed(result, response_code, headers, body):
    var bod = JSON.parse(body.get_string_from_utf8()).result
    if response_code == HTTPClient.RESPONSE_OK:
        match action:
            TASK_POST:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos)
                emit_signal("add_document", document )
                emit_signal("task_finished", document)
                data = bod
            TASK_GET:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos)
                emit_signal("get_document", document )
                emit_signal("task_finished", document)
                data = bod
            TASK_PATCH:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos)
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
        var code : int = bod.error.code
        var status : int = bod.error.status
        var message : String = bod.error.message
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




