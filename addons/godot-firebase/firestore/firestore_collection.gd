## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.3
##
## [b]NOTE:[/b] regarding [code]fields[/code]
## Firestore uses a specific structure for documents, both to add and retrieve them, which is in the form of:
## [code]{ "fields" : { "key" : { "stringValue" : "value" } } }[/code]
## Our module will automatically convert a GDScript Dictionary of fields in the required form.
## 
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore#FirestoreCollection

class_name FirestoreCollection
extends Node

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
## Emitted when a request is [b]not[/b] successfully completed.
## @arg-types Dictionary
signal error(error)

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

## Used to GET a document from the collection, specifying the document's [code]id[/code]
## 
## ex. 
## [code] var collection : FirestoreCollection = Firebase.Firestore.collection(COLLECTION_ID).get(DOCUMENT_ID)[/code]
## [code] var document : FirestoreDocument = yield(collection, "get_document")[/code]
## 
## Further examples and explaination at [url=https://github.com/GodotNuts/GodotFirebase/wiki/Firestore#get-a-document]Wiki/FirestoreCollection/Get[/url]
## 
## @args document_id
## @arg-types String
## @return FirestoreTask
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
        printerr("Unauthorized")
        return null

## Used to ADD a document to the collection, specifying the document's [code]id[/code] and its [code]fields[/code]. If the document already exists, it will be overwritten.
## If [code]document_id[/code] field is left to "", Firestore will automatically give to the document a random generated string as an id. This id can then be retrieved in the result of the request itself. 
## 
## ex.
## [code]var fields : Dictionary = { user = "A User", points = 500 }[/code]
## [code]var add_task : FirestoreTask = Firebase.Firestore.collection("myCollection").add("", fields)[/code]
## [code]var document : FirestoreDocument = yield(add_task, "add_document")[/code]
## [code]var document_id : String = document.doc_name # A random generated id given by Firestore, since we didn't specify the document's id in the request.[/code]
## 
## Further examples and explaination at [url=https://github.com/GodotNuts/GodotFirebase/wiki/Firestore#add-a-document]Wiki/FirestoreCollection/Add[/url]
## @args document_id, fields
## @arg-types String, Dictionary
## @arg-defaults "", {}
## @return FirestoreTask
func add(documentId : String = "", fields : Dictionary = {}) -> FirestoreTask:
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
        printerr("Unauthorized")
        return null

## Used to UPDATE a document to the collection, specifying the document's [code]id[/code] and the [code]fields[/code] we want to update.
## If [code]document_id[/code] field is left to "", Firestore will automatically generate a new document with the given fields and give to the document a random generated string as an id. This id can then be retrieved in the result of the request itself. 
## A completely new field can be specified as an argument, and it will be appended to the fields already existing inside the document.
## 
## ex.
## [code]var fields : Dictionary = { user = "A User", points = 100 }[/code]
## [code]var update_task : FirestoreTask = Firebase.Firestore.collection("myCollection").update("user-12345", fields)[/code]
## [code]var document : FirestoreDocument = yield(update_task, "update_document") # will update user's points from 500 to 100[/code]
## 
## @args document_id, fields
## @arg-types String, Dictionary
## @arg-defaults "", {}
## @return FirestoreTask
# If a field you want to update is of type [code]Array[/code] or [code]Dictionary[/code], all new values will be appended instead of being overwritten
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
        printerr("Unauthorized")
        return null


## Used to DELETE a document from the collection, specifying the document's [code]id[/code].
## 
## ex.
## [code]var delete_task : FirestoreTask = Firebase.Firestore.collection("myCollection").delete("user-12345")[/code]
## [code]yield(delete_task, "delete_document")[/code]
## 
## @args document_id
## @arg-types String
## @return FirestoreTask
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
        printerr("Unauthorized")
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
    printerr(message)



