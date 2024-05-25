class_name FirebaseOnceDatabaseReference
extends Node


## @meta-authors BackAt50Ft
## @meta-version 1.0
## A once off reference to a location in the Realtime Database.
## Documentation TODO.

signal once_successful(dataSnapshot)
signal once_failed()

signal push_successful()
signal push_failed()

const ORDER_BY : String = "orderBy"
const LIMIT_TO_FIRST : String = "limitToFirst"
const LIMIT_TO_LAST : String = "limitToLast"
const START_AT : String = "startAt"
const END_AT : String = "endAt"
const EQUAL_TO : String = "equalTo"

@onready var _oncer = $Oncer
@onready var _pusher = $Pusher

var _auth : Dictionary
var _config : Dictionary
var _filter_query : Dictionary
var _db_path : String

const _separator : String = "/"
const _json_list_tag : String = ".json"
const _query_tag : String = "?"
const _auth_tag : String = "auth="

const _auth_variable_begin : String = "["
const _auth_variable_end : String = "]"
const _filter_tag : String = "&"
const _escaped_quote : String = '"'
const _equal_tag : String = "="
const _key_filter_tag : String = "$key"

var _headers : PackedStringArray = []

func set_db_path(path : String, filter_query_dict : Dictionary) -> void:
	_db_path = path
	_filter_query = filter_query_dict

func set_auth_and_config(auth_ref : Dictionary, config_ref : Dictionary) -> void:
	_auth = auth_ref
	_config = config_ref

#
# Gets a data snapshot once at the position passed in
#
func once(reference : String) -> void:
	var ref_pos = _get_list_url() + _db_path + _separator + reference + _get_remaining_path()
	_oncer.request(ref_pos, _headers, HTTPClient.METHOD_GET, "")

func _get_remaining_path(is_push : bool = true) -> String:
	var remaining_path = ""
	if _filter_query_empty() or is_push:
		remaining_path = _json_list_tag + _query_tag + _auth_tag + Firebase.Auth.auth.idtoken
	else:
		remaining_path = _json_list_tag + _query_tag + _get_filter() + _filter_tag + _auth_tag + Firebase.Auth.auth.idtoken

	if Firebase.emulating:
		remaining_path += "&ns="+_config.projectId+"-default-rtdb"

	return remaining_path

func _get_list_url(with_port:bool = true) -> String:
	var url = Firebase.Database._base_url.trim_suffix(_separator)
	if with_port and Firebase.emulating:
		url += ":" + _config.emulators.ports.realtimeDatabase
	return url + _separator


func _get_filter():
	if _filter_query_empty():
		return ""
	
	var filter = ""
	
	if _filter_query.has(ORDER_BY):
		filter += ORDER_BY + _equal_tag + _escaped_quote + _filter_query[ORDER_BY] + _escaped_quote
		_filter_query.erase(ORDER_BY)
	else:
		filter += ORDER_BY + _equal_tag + _escaped_quote + _key_filter_tag + _escaped_quote # Presumptuous, but to get it to work at all...
		
	for key in _filter_query.keys():
		filter += _filter_tag + key + _equal_tag + _filter_query[key]

	return filter

func _filter_query_empty() -> bool:
	return _filter_query == null or _filter_query.is_empty()

func on_get_request_complete(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		var bod = Utilities.get_json_data(body)            
		once_successful.emit(bod)
	else:
		once_failed.emit()
		
func on_push_request_complete(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		push_successful.emit()
	else:
		push_failed.emit()

func push(data : Dictionary) -> void:
	var to_push = JSON.stringify(data)
	_pusher.request(_get_list_url() + _db_path + _get_remaining_path(true), _headers, HTTPClient.METHOD_POST, to_push)

func update(path : String, data : Dictionary) -> void:
	path = path.strip_edges(true, true)

	if path == _separator:
		path = ""

	var to_update = JSON.stringify(data)
	var resolved_path = (_get_list_url() + _db_path + "/" + path + _get_remaining_path())
	_pusher.request(resolved_path, _headers, HTTPClient.METHOD_PATCH, to_update)
