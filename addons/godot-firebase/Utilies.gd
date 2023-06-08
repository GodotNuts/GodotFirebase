extends Node
class_name Utilities

static func get_json_data(value):
    if value is PackedByteArray:
        value = value.get_string_from_utf8()
    var json = JSON.new()
    var json_parse_result = json.parse(value)
    if json_parse_result == OK:
        return json.data
    
    return null
