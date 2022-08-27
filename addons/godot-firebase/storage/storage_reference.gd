## @meta-authors SIsilicon
## @meta-version 2.2
## A reference to a file or folder in the Firebase cloud storage.
## This object is used to interact with the cloud storage. You may get data from the server, as well as upload your own back to it.
tool
class_name StorageReference
extends Reference


## The default MIME type to use when uploading a file.
## Data sent with this type are interpreted as plain binary data. Note that firebase will generate an MIME type based on the file extenstion if none is provided.
const DEFAULT_MIME_TYPE = "application/octet-stream"

## A dictionary of common MIME types based on a file extension.
## Example: [code]MIME_TYPES.png[/code] will return [code]image/png[/code].
const MIME_TYPES = {
    "bmp": "image/bmp",
    "css": "text/css",
    "csv": "text/csv",
    "gd": "text/plain",
    "htm": "text/html",
    "html": "text/html",
    "jpeg": "image/jpeg",
    "jpg": "image/jpeg",
    "json": "application/json",
    "mp3": "audio/mpeg",
    "mpeg": "video/mpeg",
    "ogg": "audio/ogg",
    "ogv": "video/ogg",
    "png": "image/png",
    "shader": "text/plain",
    "svg": "image/svg+xml",
    "tif": "image/tiff",
    "tiff": "image/tiff",
    "tres": "text/plain",
    "tscn": "text/plain",
    "txt": "text/plain",
    "wav": "audio/wav",
    "webm": "video/webm",
    "webp": "video/webm",
    "xml": "text/xml",
}

## @default ""
## The stroage bucket this referenced file/folder is located in.
var bucket: String = ""

## @default ""
## The path to the file/folder relative to [member bucket].
var full_path: String = ""

## @default ""
## The name of the file/folder, including any file extension.
## Example: If the [member full_path] is [code]images/user/image.png[/code], then the [member name] would be [code]image.png[/code].
var name: String = ""

## The parent [StorageReference] one level up the file hierarchy.
## If the current [StorageReference] is the root (i.e. the [member full_path] is [code]""[/code]) then the [member parent] will be [code]null[/code].
var parent: StorageReference

## The root [StorageReference].
var root: StorageReference

## @type FirebaseStorage
## The Storage API that created this [StorageReference] to begin with.
var storage # FirebaseStorage (Can't static type due to cyclic reference)

## @default false
## Whether this [StorageReference] is valid. None of the functions will work when in an invalid state.
## It is set to false when [method delete] is called.
var valid: bool = false


## @args path
## @return StorageReference
## Returns a reference to another [StorageReference] relative to this one.
func child(path: String) -> StorageReference:
    if not valid:
        return null
    return storage.ref(full_path.plus_file(path))


## @args data, metadata
## @return StorageTask
## Makes an attempt to upload data to the referenced file location. Status on this task is found in the returned [StorageTask].
func put_data(data: PoolByteArray, metadata := {}) -> StorageTask:
    if not valid:
        return null
    if not "Content-Length" in metadata and OS.get_name() != "HTML5":
        metadata["Content-Length"] = data.size()

    var headers := []
    for key in metadata:
        headers.append("%s: %s" % [key, metadata[key]])

    return storage._upload(data, headers, self, false)


## @args data, metadata
## @return StorageTask
## Like [method put_data], but [code]data[/code] is a [String].
func put_string(data: String, metadata := {}) -> StorageTask:
    return put_data(data.to_utf8(), metadata)


## @args file_path, metadata
## @return StorageTask
## Like [method put_data], but the data comes from a file at [code]file_path[/code].
func put_file(file_path: String, metadata := {}) -> StorageTask:
    var file := File.new()
    file.open(file_path, File.READ)
    var data := file.get_buffer(file.get_len())
    file.close()

    if "Content-Type" in metadata:
        metadata["Content-Type"] = MIME_TYPES.get(file_path.get_extension(), DEFAULT_MIME_TYPE)

    return put_data(data, metadata)


## @return StorageTask
## Makes an attempt to download the files from the referenced file location. Status on this task is found in the returned [StorageTask].
func get_data() -> StorageTask:
    if not valid:
        return null
    storage._download(self, false, false)
    return storage._pending_tasks[-1]


## @return StorageTask
## Like [method get_data], but the data in the returned [StorageTask] comes in the form of a [String].
func get_string() -> StorageTask:
    var task := get_data()
    task.connect("task_finished", self, "_on_task_finished", [task, "stringify"])
    return task


## @return StorageTask
## Attempts to get the download url that points to the referenced file's data. Using the url directly may require an authentication header. Status on this task is found in the returned [StorageTask].
func get_download_url() -> StorageTask:
    if not valid:
        return null
    return storage._download(self, false, true)


## @return StorageTask
## Attempts to get the metadata of the referenced file. Status on this task is found in the returned [StorageTask].
func get_metadata() -> StorageTask:
    if not valid:
        return null
    return storage._download(self, true, false)


## @args metadata
## @return StorageTask
## Attempts to update the metadata of the referenced file. Any field with a value of [code]null[/code] will be deleted on the server end. Status on this task is found in the returned [StorageTask].
func update_metadata(metadata: Dictionary) -> StorageTask:
    if not valid:
        return null
    var data := JSON.print(metadata).to_utf8()
    var headers := PoolStringArray(["Accept: application/json"])
    return storage._upload(data, headers, self, true)


## @return StorageTask
## Attempts to get the list of files and/or folders under the referenced folder This function is not nested unlike [method list_all]. Status on this task is found in the returned [StorageTask].
func list() -> StorageTask:
    if not valid:
        return null
    return storage._list(self, false)


## @return StorageTask
## Attempts to get the list of files and/or folders under the referenced folder This function is nested unlike [method list]. Status on this task is found in the returned [StorageTask].
func list_all() -> StorageTask:
    if not valid:
        return null
    return storage._list(self, true)


## @return StorageTask
## Attempts to delete the referenced file/folder. If successful, the reference will become invalid And can no longer be used. If you need to reference this location again, make a new reference with [method StorageTask.ref]. Status on this task is found in the returned [StorageTask].
func delete() -> StorageTask:
    if not valid:
        return null
    return storage._delete(self)


func _to_string() -> String:
    var string := "gs://%s/%s" % [bucket, full_path]
    if not valid:
        string += " [Invalid Reference]"
    return string


func _on_task_finished(task: StorageTask, action: String) -> void:
    match action:
        "stringify":
            if typeof(task.data) == TYPE_RAW_ARRAY:
                task.data = task.data.get_string_from_utf8()
