# ---------------------------------------------------- #
#                 SCRIPT VERSION = 1.0                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

class_name FirestoreTask
extends HTTPRequest

signal task_finished(result)
signal add_document(doc)
signal get_document(doc)
signal update_document(doc)
signal delete_document()
signal listed_documents(documents)
signal result_query(result)
signal error(error)

enum {
    TASK_GET,
    TASK_POST,
    TASK_PATCH,
    TASK_DELETE,
    TASK_QUERY,
    TASK_LIST
}

var action : int = -1 setget set_action

var _response_headers : PoolStringArray = PoolStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _headers : PoolStringArray = PoolStringArray()

var data

func _ready():
    connect("request_completed", self, "_on_request_completed")


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
            

func push_request(url : String, headers : String, fields : String = ""):
    _url = url
    _headers = [headers] as PoolStringArray
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



