class_name FirebaseResource
extends Resource

var key : String
var data : Dictionary

func _init(key : String, data : Dictionary) -> void:
		self.key = key.lstrip("/")
		self.data = data

func _to_string():
	return "{ key:{key}, data:{data}".format({key = key, data = data})
