extends Node

signal full_data_update(data)
signal new_data_update(data)
signal patch_data_update(data)

signal push_successful
signal push_failed

var pusher
var listener
var store
var auth
var config

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
const UpdateGranularity = 2

var db_path

func set_db_path(path : String):
    db_path = path

func set_auth_and_config(auth_ref, config_ref):
    auth = auth_ref
    config = config_ref

func set_pusher(pusher_ref):
    if !pusher:
        pusher = pusher_ref
        add_child(pusher)
        pusher.connect("request_completed", self, "on_push_request_complete")

func set_listener(listener_ref):
    if !listener:
        listener = listener_ref
        add_child(listener)
        listener.connect("request_completed", self, "on_listener_request_complete")

func set_store(store_ref):
    if !store:
        store = store_ref
        add_child(store)
        store.set_script(preload("res://addons/FirebaseDatabase/Store.gd"))

func push(data):
    var to_push = JSON.print(data)
    # Idea being to wait until the Push request is free to send more data, consider exporting the timer on this
    while pusher.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        yield(get_tree().create_timer(0.5), "timeout")

    pusher.request(_get_list_url() + db_path + _get_remaining_path(), PoolStringArray(), true, HTTPClient.METHOD_POST, to_push)

func _get_remaining_path():
    return json_list_tag + auth_tag + auth.idtoken

func _get_list_url():
    return config.databaseURL + separator # + ListName + json_list_tag + auth_tag + auth.idtoken
#
#func _get_filter():
#    return query_tag + FilterQuery

func _process(delta):
    current_update_time += delta
    if auth and auth.idtoken  and current_update_time >= UpdateGranularity:
        listener.request(_get_list_url() + db_path + _get_remaining_path(), [accept_header], true, HTTPClient.METHOD_POST)
        current_update_time = 0

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
        store.put(path, data)
    elif command == patch_tag:
        store.patch(path, data)

func _get_data(body):
    var data_idx = body.find(data_tag)
    if not data_idx:
        return null

    body = body.right(data_idx + data_tag.length())
    var json_result = JSON.parse(body)
    var res = json_result.result
    return res

func on_listener_request_complete(result, response_code, headers, body):
    print("Listener request complete")
    if body:
        var bod = body.get_string_from_utf8()
        var command = _get_command(bod)
        if command != null:
            var data = _get_data(bod)
            _route_data(command, data.path, data.data)
            if command == put_tag:
                if data.path == separator:
                    emit_signal("full_data_update", store.data_set)
                else:
                    emit_signal("new_data_update", data.data)
            elif command == patch_tag:
                emit_signal("patch_data_update", data.data)

func on_push_request_complete(result, response_code, headers, body):
    if response_code == HTTPClient.RESPONSE_OK:
        emit_signal("push_successful")
        return

    emit_signal("push_failed")