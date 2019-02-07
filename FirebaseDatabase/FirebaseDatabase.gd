extends Node

signal full_data_update(data)
signal new_data_update(data)
signal patch_data_update(data)

signal push_successful
signal push_failed

var apiKey = ""
var authDomain = ""
var databaseURL = ""
var projectId = ""
var storageBucket = ""
var messagingSenderId = ""

var auth = null

onready var Push = HTTPRequest.new()
onready var Listen = HTTPRequest.new()
onready var Store = Node.new()

onready var ListName
onready var FilterQuery

var UpdateGranularity = 3

var current_update_time = 0
const event_tag = "event: "
const data_tag = "data: "
const put_tag = "put"
const patch_tag = "patch"
const separator = "/"
const json_list_tag = ".json"
const query_tag = "?"
const auth_tag = query_tag + "auth="
const accept_header = "accept: text/event-stream"
const auth_variable_begin = "["
const auth_variable_end = "]"

func _ready():
    add_child(Push)
    add_child(Listen)
    add_child(Store)
    Push.connect("request_completed", self, "_on_Push_request_completed")
    Listen.connect("request_completed", self, "_on_Listen_request_completed")
    Store.set_script(preload("res://addons/FirebaseDatabase/Store.gd"))
    FirebaseAuth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
    pass

func push(data):
    var to_push = JSON.print(data)
    # Idea being to wait until the Push request is free to send more data, consider exporting the timer on this
    while Push.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        yield(get_tree().create_timer(0.5), "timeout")
        
    Push.request(_get_list_url(), PoolStringArray(), true, HTTPClient.METHOD_POST, to_push)

func _get_list_url():
    if FilterQuery:
        return databaseURL + separator + ListName + json_list_tag + auth_tag + auth.idtoken + _get_filter()
        
    return databaseURL + separator + ListName + json_list_tag + auth_tag + auth.idtoken

func _get_filter():
    return query_tag + FilterQuery

func _process(delta):
    current_update_time += delta
    if auth and auth.idToken and current_update_time >= UpdateGranularity and Listen.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
        Listen.request(_get_list_url(), [accept_header], true, HTTPClient.METHOD_POST)
        current_update_time = 0

func _on_FirebaseAuth_login_succeeded(auth_result):
    auth = auth_result

func _get_command(body : String):
    # event: event name
    # data: JSON payload
    var event_idx = body.find(event_tag) + event_tag.length()
    if not event_idx:
        return null
    
    var data_idx = body.find(data_tag, event_idx)
    if not data_idx:
        return null
    
    var command_substr = body.substr(event_idx, data_idx - event_idx)
    command_substr.erase(command_substr.length() - 1, 1)
    return command_substr
    
func _route_data(command, path, data):
    if command == put_tag:
        Store.put(path, data)
    elif command == patch_tag:
        Store.patch(path, data)

func _get_data(body):
    var data_idx = body.find(data_tag)
    if not data_idx:
        return null
        
    body = body.right(data_idx + data_tag.length())
    var json_result = JSON.parse(body)
    var res = json_result.result
    return res

func _on_Listen_request_completed(result, response_code, headers, body):
    if body:
        var bod = body.get_string_from_utf8()
        var command = _get_command(bod)
        if command != null:
            var data = _get_data(bod)
            _route_data(command, data.path, data.data)
            if command == put_tag:
                if data.path == separator:
                    emit_signal("full_data_update", Store.data_set)
                else:
                    emit_signal("new_data_update", data.data)
            elif command == patch_tag:
                emit_signal("patch_data_update", data.data)
            
            

func _on_Push_request_completed(result, response_code, headers, body):
    if response_code == HTTPClient.RESPONSE_OK:
        emit_signal("push_successful")
        return
        
    emit_signal("push_failed")