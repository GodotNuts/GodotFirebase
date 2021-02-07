# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.1                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

class_name StorageReference
extends Reference

const DEFAULT_MIME_TYPE = "application/octet-stream"
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

var bucket : String = ""
var full_path : String = ""
var name : String = ""
var parent : StorageReference
var root : StorageReference
var storage # FirebaseStorage (Can't static type due to cyclic reference)
var valid : bool = false

func child(path : String) -> StorageReference:
    if not valid:
        return null
    return storage.ref(full_path.plus_file(path))

func put_data(data : PoolByteArray, metadata := {}) -> StorageTask:
    if not valid:
        return null
    if not "Content-Length" in metadata:
        metadata["Content-Length"] = data.size()
    
    var headers := []
    for key in metadata:
        headers.append("%s: %s" % [key, metadata[key]])
    
    return storage._upload(data, headers, self, false)

func put_string(data : String, metadata := {}) -> StorageTask:
    return put_data(data.to_utf8(), metadata)

func put_file(file_path : String, metadata := {}) -> StorageTask:
    var file := File.new()
    file.open(file_path, File.READ)
    var data := file.get_buffer(file.get_len())
    file.close()
    
    if "Content-Type" in metadata:
        metadata["Content-Type"] = MIME_TYPES.get(file_path.get_extension(), DEFAULT_MIME_TYPE)
    
    return put_data(data, metadata)

func get_data() -> StorageTask:
    if not valid:
        return null
    storage._download(self, false, false)
    return storage._pending_tasks.pop_back()

func get_string() -> StorageTask:
    var task := get_data()
    task.connect("task_finished", self, "_on_task_finished", [task, "stringify"])
    return task

func get_download_url() -> StorageTask:
    if not valid:
        return null
    return storage._download(self, false, true)

func get_metadata() -> StorageTask:
    if not valid:
        return null
    return storage._download(self, true, false)

func update_metadata(metadata : Dictionary) -> StorageTask:
    if not valid:
        return null
    
    var data := JSON.print(metadata).to_utf8()
    var headers := PoolStringArray(["Content-Type: application/json"])
    return storage._upload(data, headers, self, true)

func list() -> StorageTask:
    if not valid:
        return null
    return storage._list(self, false)

func list_all() -> StorageTask:
    if not valid:
        return null
    return storage._list(self, true)

func delete() -> StorageTask:
    if not valid:
        return null
    return storage._delete(self)

func _to_string() -> String:
    var string := "gs://%s/%s" % [bucket, full_path] 
    if not valid:
        string += " [Invalid Reference]"
    return string

func _on_task_finished(task : StorageTask, action : String) -> void:
    match action:
        "stringify":
            if typeof(task.data) == TYPE_RAW_ARRAY:
                task.data = task.data.get_string_from_utf8()
