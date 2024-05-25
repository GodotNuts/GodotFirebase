class_name ServerTimestampTransform
extends FieldTransform

func _init(doc_name : String, doc_must_exist : bool, path_to_field : String) -> void:
	document_name = doc_name
	document_exists = doc_must_exist
	field_path = path_to_field
	
	transform_type = FieldTransform.TransformType.SetToServerValue
	value = "REQUEST_TIME"
