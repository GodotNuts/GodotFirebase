extends Node

class_name FirestoreCollection

signal add_document(doc)
signal get_document(doc)
signal update_document(doc)
signal delete_document()
signal error(code,status,message)

var base_url
var extended_url
var config
var auth
var collection_name

var pusher


const event_tag = "event: "
const data_tag = "data: "
const put_tag = "put"
const patch_tag = "patch"
const separator = "/"
const json_list_tag = ".json"
const query_tag = "?"
const auth_tag = "auth="
const authorization_header = "Authorization: Bearer "
const auth_variable_begin = "["
const auth_variable_end = "]"
const filter_tag = "&"
const escaped_quote = "\""
const equal_tag = "="
const key_filter_tag = "$key"
const documentId_tag = "documentId="

var request : int
enum REQUESTS {
    ADD,
    GET,
    UPDATE,
    DELETE
}

func _ready():
    var push_node = HTTPRequest.new()
    add_child(push_node)
    pusher = push_node
    pusher.connect("request_completed", self, "on_pusher_request_complete")

# ----------------------- REQUESTS

# used to SAVE/ADD a new document to the collection, specify @documentID and @fields
func add(documentId : String, fields : Dictionary = {}):
    if auth:
        request = REQUESTS.ADD
        var url = _get_request_url()
        url += query_tag + documentId_tag + documentId
        
        pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_POST, JSON.print(fields))
    else:
        printerr("Unauthorized")

# used to GET a document from the collection, specify @documentId
func get(documentId : String):
    if auth:
        request = REQUESTS.GET
        var url = _get_request_url() + separator + documentId
        
        pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_GET)
    else:
        printerr("Unauthorized")

# used to UPDATE a document, specify @documentID and @fields
func update(documentId : String, fields : Dictionary = {}):
    if auth:
        request = REQUESTS.UPDATE
        var url = _get_request_url() + separator + documentId
        print(fields)
        pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_PATCH, JSON.print(fields))
    else:
        printerr("Unauthorized")

# used to DELETE a document, specify @documentId
func delete(documentId : String):
    if auth:
        request = REQUESTS.DELETE
        var url = _get_request_url() + separator + documentId
        
        pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_DELETE)
    else:
        printerr("Unauthorized")

# ----------------- Functions
func _get_request_url():
    return base_url + extended_url + collection_name


# ---------------- RESPONSES
func on_pusher_request_complete(result, response_code, headers, body):
    var bod = JSON.parse(body.get_string_from_utf8()).result
    if response_code == HTTPClient.RESPONSE_OK:
        match request:
            REQUESTS.ADD:	
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos, doc_infos.name, doc_infos.fields) 
                emit_signal("add_document", document )
            REQUESTS.GET:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos, doc_infos.name, doc_infos.fields) 
                emit_signal("get_document", document )
            REQUESTS.UPDATE:
                var doc_infos : Dictionary = bod
                var document : FirestoreDocument = FirestoreDocument.new(doc_infos, doc_infos.name, doc_infos.fields) 
                emit_signal("update_document", document )
            REQUESTS.DELETE:
                emit_signal("delete_document")
    else:
        emit_signal("error",bod.error.code,bod.error.status,bod.error.message)
