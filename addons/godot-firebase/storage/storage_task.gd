class_name StorageTask
extends Reference

enum {
	TASK_UPLOAD,
	TASK_DOWNLOAD,
	TASK_METADATA,
	TASK_DELETE,
	TASK_MAX
}

signal task_finished

var ref # Storage Reference (Can't static type due to cyclic reference)
var url : String = ""
var action : int = -1 setget set_action
var headers : PoolStringArray = PoolStringArray()
var data = PoolByteArray() # data can be of any type.

var method : int = -1
var progress : float = 0.0
var result : int = -1
var finished : bool = false

var response_headers : PoolStringArray = PoolStringArray()
var response_code : int = 0

func set_action(value : int) -> void:
	action = value
	match action:
		TASK_UPLOAD:
			method = HTTPClient.METHOD_POST
		TASK_DELETE:
			method = HTTPClient.METHOD_DELETE
		TASK_METADATA:
			method = HTTPClient.METHOD_GET
		TASK_DOWNLOAD:
			method = HTTPClient.METHOD_GET
