extends Node

signal new_document(doc)

var base_url
var extended_url
var config
var auth
var collection_name

var pusher


const event_tag = "event: "
const data_tag = "data: "
const put_tag = "put"
const patch_tag = "patch"
const separator = "/"
const json_list_tag = ".json"
const query_tag = "?"
const auth_tag = "auth="
const authorization_header = "Authorization: Bearer "
const auth_variable_begin = "["
const auth_variable_end = "]"
const filter_tag = "&"
const escaped_quote = "\""
const equal_tag = "="
const key_filter_tag = "$key"
const documentId_tag = "documentId="

func _ready():
    var push_node = HTTPRequest.new()
    add_child(push_node)
    pusher = push_node
    pusher.connect("request_completed", self, "on_pusher_request_complete")

func add(documentId = null, data = null):
    if auth:
        var url = _get_request_url()
        if !data:
            data = build_fake_data()
        
        if documentId:
            url += query_tag + documentId_tag + documentId
        
        
        pusher.request(url, [authorization_header + auth.idtoken], true, HTTPClient.METHOD_POST, JSON.print(data))
        pass

func build_fake_data():
    var packed_scene = PackedScene.new()
    packed_scene.pack(get_tree().current_scene)
    var scene_text = var2str(packed_scene)
    return {"fields": { "scene_text": {"stringValue": "garbage" } } }

func _get_request_url():
    return base_url + extended_url + collection_name
    pass
    
func doc(documentId = "", data = null):
    pass


func on_pusher_request_complete(result, response_code, headers, body):
    var bod = body.get_string_from_utf8()
    if response_code == HTTPClient.RESPONSE_OK:
        emit_signal("new_document", JSON.parse(bod))
        pass
    else:
        print(bod)
    pass