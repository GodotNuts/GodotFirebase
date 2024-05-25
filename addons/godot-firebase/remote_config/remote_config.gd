class_name RemoteConfig
extends RefCounted

var default_config = {}

func _init(values : Dictionary) -> void:
	default_config = values
	
func get_value(key : String) -> Variant:
	if default_config.has(key):
		return default_config[key]
	
	Firebase._printerr("Remote config does not contain key: " + key)
	return null
