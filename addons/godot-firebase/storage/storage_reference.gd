class_name StorageReference
extends Reference

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

func delete() -> StorageTask:
	if not valid:
		return null
	return storage._delete(full_path, self)

# TODO: To be implemented
func get_download_url() -> void:
	pass

# TODO: To be implemented
func get_metadata() -> void:
	pass

# TODO: To be implemented
func list() -> void:
	pass

# TODO: To be implemented
func list_all() -> void:
	pass

func put(data : PoolByteArray, metadata := {}) -> StorageTask:
	if not valid:
		return null
	
	if not "Content-Length" in metadata:
		metadata["Content-Length"] = data.size()
	
	var headers := []
	for key in metadata:
		headers.append("%s: %s" % [key, metadata[key]])
	
	return storage._upload(data, full_path, headers, self)

func put_string(data : String, metadata := {}) -> StorageTask:
	return put(data.to_utf8(), metadata)

func put_file(file_path : String, metadata := {}) -> StorageTask:
	var file := File.new()
	file.open(file_path, File.READ)
	var data := file.get_buffer(file.get_len())
	file.close()
	return put(data, metadata)

func get_data() -> StorageTask:
	if not valid:
		return null
	
	storage._download(full_path, self)
	return storage._pending_tasks.pop_back()

# TODO: To be implemented
func update_metadata() -> void:
	return

func _to_string() -> String:
	var string := "gs://%s/%s" % [bucket, full_path] 
	if not valid:
		string += " [Invalid reference]"
	return string
