# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.1                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

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
var action : int = -1 setget set_action
var data = PoolByteArray() # data can be of any type.

var progress : float = 0.0
var result : int = -1
var finished : bool = false

var response_headers : PoolStringArray = PoolStringArray()
var response_code : int = 0

var _method : int = -1
var _url : String = ""
var _headers : PoolStringArray = PoolStringArray()

func set_action(value : int) -> void:
    action = value
    match action:
        TASK_UPLOAD:
            _method = HTTPClient.METHOD_POST
        TASK_UPLOAD_META:
            _method = HTTPClient.METHOD_PATCH
        TASK_DELETE:
            _method = HTTPClient.METHOD_DELETE
        _:
            _method = HTTPClient.METHOD_GET
