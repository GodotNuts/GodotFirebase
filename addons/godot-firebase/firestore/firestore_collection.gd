# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.1                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

class_name FirestoreCollection
extends Node


signal add_document(doc)
signal get_document(doc)
signal update_document(doc)
signal delete_document()
signal error(code,status,message)

var base_url : String
var extended_url : String
var config : Dictionary
var auth : Dictionary
var collection_name : String

var pusher : HTTPRequest


const event_tag : String = "event: "
const data_tag : String = "data: "
const put_tag : String = "put"
const patch_tag : String = "patch"
const separator : String = "/"
const json_list_tag : String = ".json"
const query_tag : String = "?"
const auth_tag : String = "auth="
const authorization_header : String = "Authorization: Bearer "
const auth_variable_begin : String = "["
const auth_variable_end : String = "]"
const filter_tag : String = "&"
const escaped_quote : String = "\""
const equal_tag : String = "="
const key_filter_tag : String = "$key"
const documentId_tag : String = "documentId="

var request : int
var _requests_queue : Array = []

enum REQUESTS {
    ADD,
    GET,
    UPDATE,
    DELETE,
    NONE
}

func _ready() -> void:
    var push_node = HTTPRequest.new()
    add_child(push_node)
    pusher = push_node
    pusher.connect("request_completed", self, "on_pusher_request_complete")
    request = REQUESTS.NONE

# ----------------------- REQUESTS

# used to SAVE/ADD a new document to the collection, specify @documentID and @fields
func add(documentId : String, fields : Dictionary = {}) -> void:
    if auth:
        if is_pusher_available([REQUESTS.ADD, documentId, fields]):
            request = REQUESTS.ADD
            var url = _get_request_url()
            url += query_tag + documentId_tag + documentId
            pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_POST, JSON.print(FirestoreDocument.dict2fields(fields)))
    else:
        printerr("Unauthorized")

# used to GET a document from the collection, specify @documentId
func get(documentId : String) -> void:
    if auth:
        if is_pusher_available([REQUESTS.GET, documentId]):
            request = REQUESTS.GET
            var url = _get_request_url() + separator + documentId.replace(" ", "%20")
            pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_GET)
    else:
        printerr("Unauthorized")

# used to UPDATE a document, specify @documentID and @fields
func update(documentId : String, fields : Dictionary = {}) -> void:
    if auth:
        if is_pusher_available([REQUESTS.UPDATE, documentId, fields]):
            request = REQUESTS.UPDATE
            var url = _get_request_url() + separator + documentId.replace(" ", "%20")
            pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_PATCH, JSON.print(FirestoreDocument.dict2fields(fields)))
    else:
        printerr("Unauthorized")

# used to DELETE a document, specify @documentId
func delete(documentId : String) -> void:
    if auth:
        if is_pusher_available([REQUESTS.DELETE, documentId]):
            request = REQUESTS.DELETE
            var url = _get_request_url() + separator + documentId.replace(" ", "%20")
            pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_DELETE)
    else:
        printerr("Unauthorized")

# ----------------- Functions
func _get_request_url() -> String:
    return base_url + extended_url + collection_name


# ---------------- RESPONSES
func on_pusher_request_complete(result, response_code, headers, body):
    var bod = JSON.parse(body.get_string_from_utf8()).result
    if response_code == HTTPClient.RESPONSE_OK:
        match request:
            REQUESTS.ADD:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos)
                request = REQUESTS.NONE
                emit_signal("add_document", document )
            REQUESTS.GET:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos)
                request = REQUESTS.NONE
                emit_signal("get_document", document )
            REQUESTS.UPDATE:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos)
                request = REQUESTS.NONE
                emit_signal("update_document", document )
            REQUESTS.DELETE:
                request = REQUESTS.NONE
                emit_signal("delete_document")
    else:
        request = REQUESTS.NONE
        emit_signal("error",bod.error.code,bod.error.status,bod.error.message)
    process_queue()

# Check whether the @pusher is available or not to issue a request. If not, append a @request_element.
# A @request_element is a touple composed by the 'request_type' (@request) and the 'request_content' (@url)
func is_pusher_available(request_element : Array = []) -> bool:
    if request == REQUESTS.NONE :
        return true
    else:
        _requests_queue.append(request_element)
        print("Firestore is busy processing another request - the current request has been added to queue.")
        return false

func process_queue() -> void:
    if _requests_queue.size() > 0:
        var next_request : Array = _requests_queue.pop_front()
        var request_code : String
        match next_request[0]:
            REQUESTS.ADD:
                add(next_request[1], next_request[2])
                request_code = "Add"
            REQUESTS.GET:
                get(next_request[1])
                request_code = "Get"
            REQUESTS.UPDATE:
                update(next_request[1], next_request[2])
                request_code = "Update"
            REQUESTS.DELETE:
                delete(next_request[1])
                request_code = "Delete"
        print("request [%s] -> [%s] processed" % [request_code, next_request[1]])
