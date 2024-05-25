class_name FieldTransformArray
extends RefCounted

var transforms = []

var _extended_url
var _collection_name
const _separator = "/"

func set_config(config : Dictionary):
	_extended_url = config.extended_url
	_collection_name = config.collection_name

func push_back(transform : FieldTransform) -> void:
	transforms.push_back(transform)

func serialize() -> Dictionary:
	var body = {}
	var writes_array = []
	for transform in transforms:
		writes_array.push_back({
			"currentDocument": { "exists" : transform.document_exists },
			"transform" : {
				"document": _extended_url + _collection_name + _separator + transform.document_name,
				"fieldTransforms": [
					{
					  "fieldPath": transform.field_path,
					  transform.get_transform_type(): transform.value
					}]
				}
			})
			
	body = { "writes": writes_array }

	return body
