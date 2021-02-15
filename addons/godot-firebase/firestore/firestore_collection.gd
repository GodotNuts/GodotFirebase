## @meta-authors TODO
## @meta-version 2.2
## A reference to a Firestore Collection.
## Documentation TODO.
tool
class_name FirestoreCollection
extends Node

signal add_document(doc)
signal get_document(doc)
signal update_document(doc)
signal delete_document()
signal error(code,status,message)

const _authorization_header : String = "Authorization: Bearer "

var _base_url : String
var _extended_url : String
var config : Dictionary
var auth : Dictionary
var collection_name : String

const _separator : String = "/"
const _query_tag : String = "?"
const _documentId_tag : String = "documentId="


func _ready() -> void:
    pass

# ----------------------- REQUESTS

# used to GET a document from the collection, specify @documentId
func get(documentId : String) -> FirestoreTask:
    if auth:
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task._set_action(FirestoreTask.TASK_GET)
        var url = _get_request_url() + _separator + documentId.replace(" ", "%20")
        firestore_task.connect("add_document", self, "_on_add_document")
        firestore_task.connect("error", self, "_on_error")
        firestore_task._push_request(url, _authorization_header + auth.idtoken)
        return firestore_task
    else:
        print("Unauthorized")
        return null

# used to SAVE/ADD a new document to the collection, specify @documentID and @fields
func add(documentId : String, fields : Dictionary = {}) -> FirestoreTask:
    if auth:
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task._set_action(FirestoreTask.TASK_POST)
        var url = _get_request_url() + _query_tag + _documentId_tag + documentId
        firestore_task._push_request(url, _authorization_header + auth.idtoken, JSON.print(FirestoreDocument.dict2fields(fields)))
        firestore_task.connect("get_document", self, "_on_get_document")
        firestore_task.connect("error", self, "_on_error")
        return firestore_task
    else:
        print("Unauthorized")
        return null

# used to UPDATE a document, specify @documentID and @fields
func update(documentId : String, fields : Dictionary = {}) -> FirestoreTask:
    if auth:
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task._set_action(FirestoreTask.TASK_PATCH)
        var url = _get_request_url() + _separator + documentId.replace(" ", "%20") + "?"
        for key in fields.keys():
            url+="updateMask.fieldPaths={key}&".format({key = key})
        url = url.rstrip("&")
        firestore_task.connect("update_document", self, "_on_update_document")
        firestore_task.connect("error", self, "_on_error")
        firestore_task._push_request(url, _authorization_header + auth.idtoken, JSON.print(FirestoreDocument.dict2fields(fields)))
        return firestore_task
    else:
        print("Unauthorized")
        return null

# used to DELETE a document, specify @documentId
func delete(documentId : String) -> FirestoreTask:
    if auth:
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task._set_action(FirestoreTask.TASK_DELETE)
        var url = _get_request_url() + _separator + documentId.replace(" ", "%20")
        firestore_task.connect("delete_document", self, "_on_delete_document")
        firestore_task.connect("error", self, "_on_error")
        firestore_task._push_request(url, _authorization_header + auth.idtoken)
        return firestore_task
    else:
        print("Unauthorized")
        return null

# ----------------- Functions
func _get_request_url() -> String:
    return _base_url + _extended_url + collection_name


# -------------------- Higher level of communication with signals
func _on_get_document(document : FirestoreDocument):
    emit_signal("get_document", document )

func _on_add_document(document : FirestoreDocument):
    emit_signal("add_document", document )

func _on_update_document(document : FirestoreDocument):
    emit_signal("update_document", document )

func _on_delete_document():
    emit_signal("delete_document")

func _on_error(code : int, status : int, message : String):
    emit_signal("error", code, status, message)
    print(message)
