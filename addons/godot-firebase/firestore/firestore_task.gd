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
signal delete_document(successful)
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

var _response_headers : PoolStringArray = PoolStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _fields : String = ""
var _headers : PoolStringArray = []

func _on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
	var bod
	if validate_json(body.get_string_from_utf8()).empty():
		bod = JSON.parse(body.get_string_from_utf8()).result

	var failed: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK

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
				emit_signal("delete_document", true)
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
