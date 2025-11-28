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
var _cached_filter: String

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
var last_etag : String = ""

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
	last_etag = "" # Reset ETag
	var ref_pos = _get_list_url() + _db_path + _separator + reference + _get_remaining_path()
	var request_headers = _headers.duplicate()
	request_headers.append("X-Firebase-ETag: true")
	_oncer.request(ref_pos, request_headers, HTTPClient.METHOD_GET, "")

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
	
	if _cached_filter != "":
		_cached_filter = ""
		if _filter_query.has(ORDER_BY):
			_cached_filter += ORDER_BY + _equal_tag + _escaped_quote + _filter_query[ORDER_BY] + _escaped_quote
			_filter_query.erase(ORDER_BY)
		else:
			_cached_filter += ORDER_BY + _equal_tag + _escaped_quote + _key_filter_tag + _escaped_quote # Presumptuous, but to get it to work at all...
		for key in _filter_query.keys():
			_cached_filter += _filter_tag + key + _equal_tag + _filter_query[key]
	else:
		if _filter_query.has(ORDER_BY):
			_cached_filter += ORDER_BY + _equal_tag + _escaped_quote + _filter_query[ORDER_BY] + _escaped_quote
			_filter_query.erase(ORDER_BY)
		else:
			_cached_filter += ORDER_BY + _equal_tag + _escaped_quote + _key_filter_tag + _escaped_quote # Presumptuous, but to get it to work at all...
		for key in _filter_query.keys():
			_cached_filter += _filter_tag + key + _equal_tag + str(_filter_query[key])
		
	return _cached_filter

func _filter_query_empty() -> bool:
	return _filter_query == null or _filter_query.is_empty()

func on_get_request_complete(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		for header in headers:
			if header.to_lower().begins_with("etag"):
				# Split by first colon only
				var parts = header.split(":", true, 1)
				if parts.size() > 1:
					last_etag = parts[1].strip_edges()
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

func update(path : String, data : Dictionary, etag : String = "") -> void:
	path = path.strip_edges(true, true)

	if path == _separator:
		path = ""

	var to_update = JSON.stringify(data)
	var resolved_path = (_get_list_url() + _db_path + "/" + path + _get_remaining_path())
	
	var request_headers = _headers.duplicate()
	if etag != "":
		request_headers.append("If-Match: %s" % etag)
		
	_pusher.request(resolved_path, request_headers, HTTPClient.METHOD_PATCH, to_update)

func put(path : String, data : Dictionary, etag : String = "") -> void:
	path = path.strip_edges(true, true)

	if path == _separator:
		path = ""

	var to_put = JSON.stringify(data)
	var resolved_path = (_get_list_url() + _db_path + "/" + path + _get_remaining_path())
	
	var request_headers = _headers.duplicate()
	if etag != "":
		request_headers.append("If-Match: %s" % etag)
		
	_pusher.request(resolved_path, request_headers, HTTPClient.METHOD_PUT, to_put)

func delete(path : String, etag : String = "") -> void:
	path = path.strip_edges(true, true)

	if path == _separator:
		path = ""

	var resolved_path = (_get_list_url() + _db_path + "/" + path + _get_remaining_path())
	
	var request_headers = _headers.duplicate()
	if etag != "":
		request_headers.append("If-Match: %s" % etag)
		
	_pusher.request(resolved_path, request_headers, HTTPClient.METHOD_DELETE, "")
