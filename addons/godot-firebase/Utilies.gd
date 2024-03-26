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


# HTTPRequeust seems to have an issue in Web exports where the body returns empty
# This appears to be caused by the gzip compression being unsupported, so we
# disable it when web export is detected.
static func fix_http_request(http_request):
    if is_web():
        http_request.accept_gzip = false

static func is_web() -> bool:
    return OS.get_name() in ["HTML5", "Web"]
