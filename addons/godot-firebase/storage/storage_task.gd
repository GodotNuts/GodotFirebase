## @meta-authors SIsilicon
## @meta-version 2.2
## An object that keeps track of an operation performed by [StorageReference].
@tool
class_name StorageTask
extends RefCounted

enum Task {
    TASK_UPLOAD,
    TASK_UPLOAD_META,
    TASK_DOWNLOAD,
    TASK_DOWNLOAD_META,
    TASK_DOWNLOAD_URL,
    TASK_LIST,
    TASK_LIST_ALL,
    TASK_DELETE,
    TASK_MAX ## The number of [enum Task] constants.
}

## Emitted when the task is finished. Returns data depending checked the success and action of the task.
signal task_finished(data)

## @type StorageReference
## The [StorageReference] that created this [StorageTask].
var ref # Storage RefCounted (Can't static type due to cyclic reference)

## @enum Task
## @default -1
## @setter set_action
## The kind of operation this [StorageTask] is keeping track of.
var action : int = -1 : set = set_action

## @default PackedByteArray()
## Data that the tracked task will/has returned.
var data = PackedByteArray() # data can be of any type.

## @default 0.0
## The percentage of data that has been received.
var progress : float = 0.0

## @default -1
## @enum HTTPRequest.Result
## The resulting status of the task. Anyting other than [constant HTTPRequest.RESULT_SUCCESS] means an error has occured.
var result : int = -1

## @default false
## Whether the task is finished processing.
var finished : bool = false

## @default PackedStringArray()
## The returned HTTP response headers.
var response_headers := PackedStringArray()

## @default 0
## @enum HTTPClient.ResponseCode
## The returned HTTP response code.
var response_code : int = 0

var _method : int = -1
var _url : String = ""
var _headers : PackedStringArray = PackedStringArray()

func set_action(value : int) -> void:
    action = value
    match action:
        Task.TASK_UPLOAD:
            _method = HTTPClient.METHOD_POST
        Task.TASK_UPLOAD_META:
            _method = HTTPClient.METHOD_PATCH
        Task.TASK_DELETE:
            _method = HTTPClient.METHOD_DELETE
        _:
            _method = HTTPClient.METHOD_GET
