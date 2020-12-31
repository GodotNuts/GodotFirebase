extends Node

signal new_data_update(data)
signal patch_data_update(data)

signal push_successful
signal push_failed

var pusher
var listener
var store
var auth
var config
var filter_query
var db_path
var cached_filter
var push_queue = []
var can_connect_to_host = false

const put_tag = "put"
const patch_tag = "patch"
const separator = "/"
const json_list_tag = ".json"
const query_tag = "?"
const auth_tag = "auth="
const accept_header = "accept: text/event-stream"
const auth_variable_begin = "["
const auth_variable_end = "]"
const filter_tag = "&"
const escaped_quote = "\""
const equal_tag = "="
const key_filter_tag = "$key"

func set_db_path(path : String, filter_query_dict : Dictionary):
    db_path = path
    filter_query = filter_query_dict

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
        listener.connect("new_sse_event", self, "on_new_sse_event")
        var base_url = _get_list_url().trim_suffix(separator)
        var extended_url = separator + db_path + _get_remaining_path(false)
        listener.connect_to_host(base_url, extended_url)

func on_new_sse_event(headers, event, data):
    if data:
        var command = event        
        if command and command != "keep-alive":
            _route_data(command, data.path, data.data)
            if command == put_tag:
                if data.path == separator and data.data and data.data.keys().size() > 0:
                    for key in data.data.keys():
                        emit_signal("new_data_update", FirebaseResource.new(separator + key, data.data[key]))
                elif data.path != separator:
                    emit_signal("new_data_update", FirebaseResource.new(data.path, data.data))
            elif command == patch_tag:
                emit_signal("patch_data_update", FirebaseResource.new(data.path, data.data))
    pass

func set_store(store_ref):
    if !store:
        store = store_ref
        add_child(store)
        store.set_script(preload("res://addons/GDFirebase/Store.gd"))

func update(path, data):
    var to_update = JSON.print(data)
    if pusher.get_http_client_status() != HTTPClient.STATUS_REQUESTING:    
        pusher.request(_get_list_url() + db_path + _get_remaining_path(), PoolStringArray(), true, HTTPClient.METHOD_PATCH, to_update)
    else:
        push_queue.append(data)

func push(data):
    var to_push = JSON.print(data)
    if pusher.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
        pusher.request(_get_list_url() + db_path + _get_remaining_path(), PoolStringArray(), true, HTTPClient.METHOD_POST, to_push)
    else:
        push_queue.append(data)

func _get_remaining_path(is_push = true):
    if !filter_query or is_push:
        return json_list_tag + query_tag + auth_tag + Firebase.Auth.auth.idtoken
    else:
        return json_list_tag + query_tag + _get_filter() + filter_tag + auth_tag + Firebase.Auth.auth.idtoken

func _get_list_url():
    return config.databaseURL + separator # + ListName + json_list_tag + auth_tag + auth.idtoken

func _get_filter():
    if !filter_query:
        return ""
    # At the moment, this means you can't dynamically change your filter; I think it's okay to specify that in the rules.
    if !cached_filter:
        cached_filter = ""
        if filter_query.has(Firebase.Database.OrderBy):
            cached_filter += Firebase.Database.OrderBy + equal_tag + escaped_quote + filter_query[Firebase.Database.OrderBy] + escaped_quote
            filter_query.erase(Firebase.Database.OrderBy)
        else:
            cached_filter += Firebase.Database.OrderBy + equal_tag + escaped_quote + key_filter_tag + escaped_quote # Presumptuous, but to get it to work at all...

        for key in filter_query.keys():
            cached_filter += filter_tag + key + equal_tag + filter_query[key]

    return cached_filter

func _route_data(command, path, data):
    if path == separator and data.size() > 0:
        for key in data.keys():
            if command == put_tag:
                store.put(separator + key, data)
            elif command == patch_tag:
                store.patch(separator + key, data)
        return
        
    if command == put_tag:
        store.put(path, data)
    elif command == patch_tag:
        store.patch(path, data)

func on_push_request_complete(result, response_code, headers, body):
    if response_code == HTTPClient.RESPONSE_OK:
        emit_signal("push_successful")
    else:
        emit_signal("push_failed")
    
    if push_queue.size() > 0:
        push(push_queue[0])
        push_queue.remove(0)