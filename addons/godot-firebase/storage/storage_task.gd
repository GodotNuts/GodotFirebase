class_name StorageTask
extends Reference

enum {
	TASK_UPLOAD,
	TASK_UPLOAD_META,
	TASK_DOWNLOAD,
	TASK_DOWNLOAD_META,
	TASK_DOWNLOAD_URL,
	TASK_LIST,
	TASK_LIST_ALL,
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
		TASK_UPLOAD_META:
			method = HTTPClient.METHOD_PATCH
		TASK_DELETE:
			method = HTTPClient.METHOD_DELETE
		_:
			method = HTTPClient.METHOD_GET
