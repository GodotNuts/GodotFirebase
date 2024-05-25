## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 1.2
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
class_name FunctionTask
extends RefCounted

## Emitted when a request is completed. The request can be successful or not successful: if not, an [code]error[/code] Dictionary will be passed as a result.
## @arg-types Variant
signal task_finished(result)

## Emitted when a cloud function is correctly executed, returning the Response Code and Result Body
## @arg-types FirestoreDocument
signal function_executed(response, result)

## Emitted when a request is [b]not[/b] successfully completed.
## @arg-types Dictionary
signal task_error(code, status, message)

## A variable, temporary holding the result of the request.
var data: Dictionary
var error: Dictionary

## Whether the data came from cache.
var from_cache : bool = false

var _response_headers : PackedStringArray = PackedStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _fields : String = ""
var _headers : PackedStringArray = []

func _on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	var bod = Utilities.get_json_data(body)
	if bod == null:
		bod = {content = body.get_string_from_utf8()} # I don't understand what this line does at all. What the hell?!

	var offline: bool = typeof(bod) == TYPE_NIL
	from_cache = offline

	data = bod
	if response_code == HTTPClient.RESPONSE_OK and data!=null:
		function_executed.emit(result, data)
	else:
		error = {result=result, response_code=response_code, data=data}
		task_error.emit(result, response_code, str(data))

	task_finished.emit(data)
