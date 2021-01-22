class_name FirebaseDatabaseReference
extends Node

signal new_data_update(data)
signal patch_data_update(data)

signal push_successful
signal push_failed

var pusher : HTTPRequest
var listener : Node
var store : FirebaseDatabaseStore
var auth : Dictionary
var config : Dictionary
var filter_query : Dictionary
var db_path : String
var cached_filter : String
var push_queue : Array = []
var can_connect_to_host : bool = false

const put_tag : String = "put"
const patch_tag : String = "patch"
const separator : String = "/"
const json_list_tag : String = ".json"
const query_tag : String = "?"
const auth_tag : String = "auth="
const accept_header : String = "accept: text/event-stream"
const auth_variable_begin : String = "["
const auth_variable_end : String = "]"
const filter_tag : String = "&"
const escaped_quote : String = "\""
const equal_tag : String = "="
const key_filter_tag : String = "$key"

func set_db_path(path : String, filter_query_dict : Dictionary) -> void:
	db_path = path
	filter_query = filter_query_dict

func set_auth_and_config(auth_ref : Dictionary, config_ref : Dictionary) -> void:
	auth = auth_ref
	config = config_ref

func set_pusher(pusher_ref : HTTPRequest) -> void:
	if !pusher:
		pusher = pusher_ref
		add_child(pusher)
		pusher.connect("request_completed", self, "on_push_request_complete")

func set_listener(listener_ref : Node) -> void:
	if !listener:
		listener = listener_ref
		add_child(listener)
		listener.connect("new_sse_event", self, "on_new_sse_event")
		var base_url = _get_list_url().trim_suffix(separator)
		var extended_url = separator + db_path + _get_remaining_path(false)
		listener.connect_to_host(base_url, extended_url)

func on_new_sse_event(headers : Dictionary, event : String, data : Dictionary) -> void:
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

func set_store(store_ref : FirebaseDatabaseStore) -> void:
	if !store:
		store = store_ref
		add_child(store)

func update(path : String, data : Dictionary) -> void:
	path = path.strip_edges(true, true)

	if path == separator:
		path = ""
	
	var to_update = JSON.print(data)
	if pusher.get_http_client_status() != HTTPClient.STATUS_REQUESTING:
		var resolved_path = (_get_list_url() + db_path + path + _get_remaining_path())
		
		pusher.request(resolved_path, PoolStringArray(), true, HTTPClient.METHOD_PATCH, to_update)
	else:
		push_queue.append(data)

func push(data : Dictionary) -> void:
	var to_push = JSON.print(data)
	if pusher.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		pusher.request(_get_list_url() + db_path + _get_remaining_path(), PoolStringArray(), true, HTTPClient.METHOD_POST, to_push)
	else:
		push_queue.append(data)

#
# Returns a deep copy of the current local copy of the data stored at this reference in the Firebase
# Realtime Database.
#
func get_data() -> Dictionary:
	if store == null:
		return { }
	
	return store.get_data()

func _get_remaining_path(is_push : bool = true) -> String:
	if !filter_query or is_push:
		return json_list_tag + query_tag + auth_tag + Firebase.Auth.auth.idtoken
	else:
		return json_list_tag + query_tag + _get_filter() + filter_tag + auth_tag + Firebase.Auth.auth.idtoken

func _get_list_url() -> String:
	return config.databaseURL + separator # + ListName + json_list_tag + auth_tag + auth.idtoken

func _get_filter():
	if !filter_query:
		return ""
	# At the moment, this means you can't dynamically change your filter; I think it's okay to specify that in the rules.
	if !cached_filter:
		cached_filter = ""
		if filter_query.has(Firebase.Database.ORDER_BY):
			cached_filter += Firebase.Database.ORDER_BY + equal_tag + escaped_quote + filter_query[Firebase.Database.ORDER_BY] + escaped_quote
			filter_query.erase(Firebase.Database.ORDER_BY)
		else:
			cached_filter += Firebase.Database.ORDER_BY + equal_tag + escaped_quote + key_filter_tag + escaped_quote # Presumptuous, but to get it to work at all...

		for key in filter_query.keys():
			cached_filter += filter_tag + key + equal_tag + filter_query[key]

	return cached_filter

#
# Appropriately updates the current local copy of the data stored at this reference in the Firebase
# Realtime Database.
#
func _route_data(command : String, path : String, data) -> void:
	if command == put_tag:
		store.put(path, data)
	elif command == patch_tag:
		store.patch(path, data)

func on_push_request_complete(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		emit_signal("push_successful")
	else:
		emit_signal("push_failed")
	
	if push_queue.size() > 0:
		push(push_queue[0])
		push_queue.remove(0)
