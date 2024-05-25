class_name MaxTransform
extends FieldTransform

func _init(doc_name : String, doc_must_exist : bool, path_to_field : String, value : Variant) -> void:
	document_name = doc_name
	document_exists = doc_must_exist
	field_path = path_to_field
	
	transform_type = FieldTransform.TransformType.Maximum
	
	var value_type = typeof(value)
	if value_type == TYPE_INT:
		self.value = {
			"integerValue": value
		}
	elif value_type == TYPE_FLOAT:
		self.value = {
			"doubleValue": value
		}
