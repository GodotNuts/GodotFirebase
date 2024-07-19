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
signal task_finished()

enum Task {
	TASK_GET,       ## A GET Request Task, processing a get() request
	TASK_POST,      ## A POST Request Task, processing add() request
	TASK_PATCH,     ## A PATCH Request Task, processing a update() request
	TASK_DELETE,    ## A DELETE Request Task, processing a delete() request
	TASK_QUERY,     ## A POST Request Task, processing a query() request
	TASK_AGG_QUERY,     ## A POST Request Task, processing an aggregation_query() request
	TASK_LIST,      ## A POST Request Task, processing a list() request
	TASK_COMMIT      ## A POST Request Task that hits the write api
}

## Mapping of Task enum values to descriptions for use in printing user-friendly error codes.
const TASK_MAP = {
	Task.TASK_GET: "GET DOCUMENT",
	Task.TASK_POST: "ADD DOCUMENT",
	Task.TASK_PATCH: "UPDATE DOCUMENT",
	Task.TASK_DELETE: "DELETE DOCUMENT",
	Task.TASK_QUERY: "QUERY COLLECTION",
	Task.TASK_LIST: "LIST DOCUMENTS", 
	Task.TASK_COMMIT: "COMMIT DOCUMENT",
	Task.TASK_AGG_QUERY: "AGG QUERY COLLECTION"
}

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @setter set_action
var action : int = -1 : set = set_action

## A variable, temporary holding the result of the request.
var data
var error: Dictionary
var document: FirestoreDocument

var _response_headers: PackedStringArray = PackedStringArray()
var _response_code: int = 0

var _method: int = -1
var _url: String = ""
var _fields: String = ""
var _headers: PackedStringArray = []

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var bod = body.get_string_from_utf8()
	if bod != "":
		bod = Utilities.get_json_data(bod)
	
	var failed: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK
	# Probably going to regret this...
	if response_code == HTTPClient.RESPONSE_OK:
		match action:
			Task.TASK_POST, Task.TASK_GET, Task.TASK_PATCH:
				document = FirestoreDocument.new(bod)
				data = document
			Task.TASK_DELETE:
				data = true
			Task.TASK_QUERY:
				data = []
				for doc in bod:
					if doc.has('document'):
						data.append(FirestoreDocument.new(doc.document))
			Task.TASK_AGG_QUERY:
				var agg_results = []
				for agg_result in bod:
					var idx = 0
					var query_results = {}
					for field_value in agg_result.result.aggregateFields.keys():
						var agg = data.aggregations[idx]
						var field = agg_result.result.aggregateFields[field_value]
						query_results[agg.keys()[0]] = Utilities.from_firebase_type(field)
						idx += 1
					agg_results.push_back(query_results)
				data = agg_results
			Task.TASK_LIST:
				data = []
				if bod.has('documents'):
					for doc in bod.documents:
						data.append(FirestoreDocument.new(doc))
					if bod.has("nextPageToken"):
						data.append(bod.nextPageToken)
			Task.TASK_COMMIT:
				data = bod # Commit's response is not a full document, so don't treat it as such
	else:
		var description = ""
		if TASK_MAP.has(action):
			description = "(" + TASK_MAP[action] + ")"

		Firebase._printerr("Action in error was: " + str(action) + " " + description)
		build_error(bod, action, description)
	
	task_finished.emit()
		
func build_error(_error, action, description) -> void:
	if _error:
		if _error is Array and _error.size() > 0 and _error[0].has("error"):
			_error = _error[0].error
		elif _error is Dictionary and _error.keys().size() > 0 and _error.has("error"):
			_error = _error.error
		
		error = _error
	else:
		#error.code, error.status, error.message
		error = { "error": {
				 "code": 0,
				 "status": "Unknown Error",
				 "message": "Error: %s - %s" % [action, description]
			}
		}
	
	data = null

func set_action(value : int) -> void:
	action = value
	match action:
		Task.TASK_GET, Task.TASK_LIST:
			_method = HTTPClient.METHOD_GET
		Task.TASK_POST, Task.TASK_QUERY, Task.TASK_AGG_QUERY:
			_method = HTTPClient.METHOD_POST
		Task.TASK_PATCH:
			_method = HTTPClient.METHOD_PATCH
		Task.TASK_DELETE:
			_method = HTTPClient.METHOD_DELETE
		Task.TASK_COMMIT:
			_method = HTTPClient.METHOD_POST
		_:
			assert(false)


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
