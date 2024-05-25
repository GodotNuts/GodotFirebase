extends FirestoreTransform
class_name FieldTransform

enum TransformType { SetToServerValue, Maximum, Minimum, Increment, AppendMissingElements, RemoveAllFromArray }

const transtype_string_map = {
	TransformType.SetToServerValue : "setToServerValue",
	TransformType.Increment : "increment",
	TransformType.Maximum : "maximum",
	TransformType.Minimum : "minimum",
	TransformType.AppendMissingElements : "appendMissingElements",
	TransformType.RemoveAllFromArray : "removeAllFromArray"
}

var document_exists : bool
var document_name : String
var field_path : String
var transform_type : TransformType
var value : Variant

func get_transform_type() -> String:
	return transtype_string_map[transform_type]
