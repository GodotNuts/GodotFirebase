class_name DecrementTransform
extends FieldTransform

func _init(doc_name : String, doc_must_exist : bool, path_to_field : String, by_this_much : Variant) -> void:
	document_name = doc_name
	document_exists = doc_must_exist
	field_path = path_to_field
	
	transform_type = FieldTransform.TransformType.Increment
	
	var value_type = typeof(by_this_much)
	if value_type == TYPE_INT:
		self.value = {
			"integerValue": -by_this_much
		}
	elif value_type == TYPE_FLOAT:
		self.value = {
			"doubleValue": -by_this_much
		}
