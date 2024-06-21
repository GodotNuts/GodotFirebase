## @meta-authors TODO
## @meta-authors TODO
## @meta-version 2.3
## A reference to a Firestore Collection.
## Documentation TODO.
tool
class_name FirestoreCollection
extends Node

signal error(error_result)

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

const _separator : String = "/"
const _query_tag : String = "?"
const _documentId_tag : String = "documentId="

var auth : Dictionary
var collection_name : String

var _base_url : String
var _extended_url : String
var _config : Dictionary

var _documents := {}

# ----------------------- Requests

## @args document_id
## @return FirestoreTask
## used to GET a document from the collection, specify @document_id
func get_doc(document_id : String, from_cache : bool = false, is_listener : bool = false) -> FirestoreDocument:
	if from_cache:
		yield(get_tree(), "idle_frame")
		# for now, just return the child directly; in the future, make it smarter so there's a default, if long, polling time for this
		for child in get_children():
			if child.doc_name == document_id:
				return child

	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_GET
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _separator + document_id.replace(" ", "%20")

	_process_request(task, document_id, url)
	yield(Firebase.Firestore._handle_task_finished(task), "completed")
	var result = task.data
	if result != null:
		for child in get_children():
			if child.doc_name == document_id:
				child.replace(result, true)
				result = child
				break
	else:
		print("get_document returned null for %s %s" % [collection_name, document_id])

	return result

## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreDocument
## used to ADD a new document to the collection, specify @documentID and @data
func add(document_id : String, data : Dictionary = {}) -> FirestoreDocument:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_POST
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _query_tag + _documentId_tag + document_id

	_process_request(task, document_id, url, JSON.print(Utilities.dict2fields(data)))
	yield(Firebase.Firestore._handle_task_finished(task), "completed")
	var result = task.data
	if result != null:
		for child in get_children():
			if child.doc_name == document_id:
				child.free() # Consider throwing an error for this since it shouldn't already exist
				break

		result.collection_name = collection_name
		add_child(result, true)
	return result

## @args document
## @return FirestoreDocument
# used to UPDATE a document, specify the document
func update(document : FirestoreDocument) -> FirestoreDocument:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_PATCH
	task.data = collection_name + "/" + document.doc_name
	var url = _get_request_url() + _separator + document.doc_name.replace(" ", "%20") + "?"
	for key in document.keys():
		url+="updateMask.fieldPaths={key}&".format({key = key})

	url = url.rstrip("&")

	for key in document.keys():
		if document.get_value(key) == null:
			document._erase(key)

	var body = JSON.print({"fields": document.document})

	_process_request(task, document.doc_name, url, body)
	yield(Firebase.Firestore._handle_task_finished(task), "completed")
	var result = task.data
	if result != null:
		for child in get_children():
			if child.doc_name == result.doc_name:
				child.replace(result, true)
				break

	return result

## @args document_id
## @return FirestoreTask
# used to DELETE a document, specify the document
func delete(document : FirestoreDocument) -> bool:
	var doc_name = document.doc_name
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_DELETE
	task.data = document.collection_name + "/" + doc_name
	var url = _get_request_url() + _separator + doc_name.replace(" ", "%20")
	_process_request(task, doc_name, url)
	yield(Firebase.Firestore._handle_task_finished(task), "completed")
	var result = task.data

	# Clean up the cache
	if result:
		for node in get_children():
			if node.doc_name == doc_name:
				node.free() # Should be only one
				break

	return result

func _get_request_url() -> String:
	return _base_url + _extended_url + collection_name

func _process_request(task : FirestoreTask, document_id : String, url : String, fields := "") -> void:
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
	Firebase.Firestore._pooled_request(task)

func get_database_url(append) -> String:
	return _base_url + _extended_url.rstrip("/") + ":" + append
