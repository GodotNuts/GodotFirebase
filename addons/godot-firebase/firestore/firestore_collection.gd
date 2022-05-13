## @meta-authors TODO
## @meta-authors TODO
## @meta-version 2.3
## A reference to a Firestore Collection.
## Documentation TODO.
tool
class_name FirestoreCollection
extends Reference

signal add_document(doc)
signal get_document(doc)
signal update_document(doc)
signal delete_document()
signal error(code,status,message)

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

const _separator : String = "/"
const _query_tag : String = "?"
const _documentId_tag : String = "documentId="

var auth : Dictionary
var collection_name : String
var firestore # FirebaseFirestore (can't static type due to cyclic reference)

var _base_url : String
var _extended_url : String
var _config : Dictionary

var _documents := {}
var _request_queues := {}

# ----------------------- Requests

## @args document_id
## @return FirestoreTask
## used to GET a document from the collection, specify @document_id
func get(document_id : String) -> FirestoreTask:
    var task : FirestoreTask = FirestoreTask.new()
    task.action = FirestoreTask.Task.TASK_GET
    task.data = collection_name + "/" + document_id
    var url = _get_request_url() + _separator + document_id.replace(" ", "%20")

    task.connect("get_document", self, "_on_get_document")
    task.connect("task_finished", self, "_on_task_finished", [document_id], CONNECT_DEFERRED)
    _process_request(task, document_id, url)
    return task

## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreTask
## used to SAVE/ADD a new document to the collection, specify @documentID and @fields
func add(document_id : String, fields : Dictionary = {}) -> FirestoreTask:
    var task : FirestoreTask = FirestoreTask.new()
    task.action = FirestoreTask.Task.TASK_POST
    task.data = collection_name + "/" + document_id
    var url = _get_request_url() + _query_tag + _documentId_tag + document_id

    task.connect("add_document", self, "_on_add_document")
    task.connect("task_finished", self, "_on_task_finished", [document_id], CONNECT_DEFERRED)
    _process_request(task, document_id, url, JSON.print(FirestoreDocument.dict2fields(fields)))
    return task

## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreTask
# used to UPDATE a document, specify @documentID and @fields
func update(document_id : String, fields : Dictionary = {}) -> FirestoreTask:
    var task : FirestoreTask = FirestoreTask.new()
    task.action = FirestoreTask.Task.TASK_PATCH
    task.data = collection_name + "/" + document_id
    var url = _get_request_url() + _separator + document_id.replace(" ", "%20") + "?"
    for key in fields.keys():
        url+="updateMask.fieldPaths={key}&".format({key = key})
    url = url.rstrip("&")

    task.connect("update_document", self, "_on_update_document")
    task.connect("task_finished", self, "_on_task_finished", [document_id], CONNECT_DEFERRED)
    _process_request(task, document_id, url, JSON.print(FirestoreDocument.dict2fields(fields)))
    return task

## @args document_id
## @return FirestoreTask
# used to DELETE a document, specify @document_id
func delete(document_id : String) -> FirestoreTask:
    var task : FirestoreTask = FirestoreTask.new()
    task.action = FirestoreTask.Task.TASK_DELETE
    task.data = collection_name + "/" + document_id
    var url = _get_request_url() + _separator + document_id.replace(" ", "%20")

    task.connect("delete_document", self, "_on_delete_document")
    task.connect("task_finished", self, "_on_task_finished", [document_id], CONNECT_DEFERRED)
    _process_request(task, document_id, url)
    return task

# ----------------- Functions
func _get_request_url() -> String:
    return _base_url + _extended_url + collection_name


func _process_request(task : FirestoreTask, document_id : String, url : String, fields := "") -> void:
    task.connect("task_error", self, "_on_error")

    if not auth:
        Firebase._print("Unauthenticated request issued...")
        Firebase.Auth.login_anonymous()
        var result : Array = yield(Firebase.Auth, "auth_request")
        if result[0] != 1:
            Firebase.Firestore._check_auth_error(result[0], result[1])
            return null
        Firebase._print("Client authenticated as Anonymous User.")

    task._url = url
    task._fields = fields
    task._headers = PoolStringArray([_AUTHORIZATION_HEADER + auth.idtoken])
    if _request_queues.has(document_id) and not _request_queues[document_id].empty():
        _request_queues[document_id].append(task)
    else:
        _request_queues[document_id] = []
        firestore._pooled_request(task)
#        task._push_request(url, , fields)


func _on_task_finished(task : FirestoreTask, document_id : String) -> void:
    if not _request_queues[document_id].empty():
        task._push_request(task._url, _AUTHORIZATION_HEADER + auth.idtoken, task._fields)


# -------------------- Higher level of communication with signals
func _on_get_document(document : FirestoreDocument):
    emit_signal("get_document", document )

func _on_add_document(document : FirestoreDocument):
    emit_signal("add_document", document )

func _on_update_document(document : FirestoreDocument):
    emit_signal("update_document", document )

func _on_delete_document():
    emit_signal("delete_document")

func _on_error(code, status, message, task):
    emit_signal("error", code, status, message)
    Firebase._printerr(message)
