extends Resource
class_name FirebaseResource

var key : String
var data : Dictionary

func _init(key : String, data : Dictionary) -> void:
		self.key = key
		self.data = data
