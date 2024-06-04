## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.5
##
## Referenced by [code]Firebase.Firestore[/code]. Represents the Firestore module.
## Cloud Firestore is a flexible, scalable database for mobile, web, and server development from Firebase and Google Cloud.
## Like Firebase Realtime Database, it keeps your data in sync across client apps through realtime listeners and offers offline support for mobile and web so you can build responsive apps that work regardless of network latency or Internet connectivity. Cloud Firestore also offers seamless integration with other Firebase and Google Cloud products, including Cloud Functions.
##
## Following Cloud Firestore's NoSQL data model, you store data in [b]documents[/b] that contain fields mapping to values. These documents are stored in [b]collections[/b], which are containers for your documents that you can use to organize your data and build queries.
## Documents support many different data types, from simple strings and numbers, to complex, nested objects. You can also create subcollections within documents and build hierarchical data structures that scale as your database grows.
## The Cloud Firestore data model supports whatever data structure works best for your app.
##
## (source: [url=https://firebase.google.com/docs/firestore]Firestore[/url])
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore
@tool
class_name FirebaseFirestore
extends Node

const _API_VERSION : String = "v1"

## Emitted when a [code]list()[/code] or [code]query()[/code] request is [b]not[/b] successfully completed.
signal error(code, status, message)

enum Requests {
	NONE = -1,  ## Firestore is not processing any request.
	LIST,       ## Firestore is processing a [code]list()[/code] request checked a collection.
	QUERY       ## Firestore is processing a [code]query()[/code] request checked a collection.
}

# TODO: Implement cache size limit
const CACHE_SIZE_UNLIMITED = -1

const _CACHE_EXTENSION : String = ".fscache"
const _CACHE_RECORD_FILE : String = "RmlyZXN0b3JlIGNhY2hlLXJlY29yZHMu.fscache"

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

const _MAX_POOLED_REQUEST_AGE = 30

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @enum Requests
var request : int = -1

## Whether cache files can be used and generated.
## @default true
var persistence_enabled : bool = false

## Whether an internet connection can be used.
## @default true
var networking: bool = true : set = set_networking

## A Dictionary containing all authentication fields for the current logged user.
## @type Dictionary
var auth : Dictionary

var _config : Dictionary = {}
var _cache_loc: String
var _encrypt_key := "5vg76n90345f7w390346" if Utilities.is_web() else OS.get_unique_id()


var _base_url : String = ""
var _extended_url : String = "projects/[PROJECT_ID]/databases/(default)/documents/"
var _query_suffix : String = ":runQuery"

#var _connect_check_node : HTTPRequest

var _request_list_node : HTTPRequest
var _requests_queue : Array = []
var _current_query : FirestoreQuery

var _offline: bool = false : set = _set_offline

func _ready() -> void:
	pass

## Returns a reference collection by its [i]path[/i].
##
## The returned object will be of [code]FirestoreCollection[/code] type.
## If saved into a variable, it can be used to issue requests checked the collection itself.
## @args path
## @return FirestoreCollection
func collection(path : String) -> FirestoreCollection:
	for coll in get_children():
		if coll is FirestoreCollection:
			if coll.collection_name == path:
				return coll
			
	var coll : FirestoreCollection = FirestoreCollection.new()
	coll._extended_url = _extended_url
	coll._base_url = _base_url
	coll._config = _config
	coll.auth = auth
	coll.collection_name = path
	add_child(coll)
	return coll


## Issue a query checked your Firestore database.
##
## [b]Note:[/b] a [code]FirestoreQuery[/code] object needs to be created to issue the query.
## This method will return a [code]FirestoreTask[/code] object, representing a reference to the request issued.
## If saved into a variable, the [code]FirestoreTask[/code] object can be used to yield checked the [code]result_query(result)[/code] signal, or the more generic [code]task_finished(result)[/code] signal.
##
## ex.
## [code]var query_task : FirestoreTask = Firebase.Firestore.query(FirestoreQuery.new())[/code]
## [code]await query_task.task_finished[/code]
## Since the emitted signal is holding an argument, it can be directly retrieved as a return variable from the [code]yield()[/code] function.
##
## ex.
## [code]var result : Array = await query_task.task_finished[/code]
##
## [b]Warning:[/b] It currently does not work offline!
##
## @args query
## @arg-types FirestoreQuery
## @return FirestoreTask
func query(query : FirestoreQuery) -> Array:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_QUERY
	var body : Dictionary = { structuredQuery = query.query }
	var url : String = _base_url + _extended_url + _query_suffix

	task.data = query
	task._fields = JSON.stringify(body)
	task._url = url
	_pooled_request(task)
	return await _handle_task_finished(task)


## Request a list of contents (documents and/or collections) inside a collection, specified by its [i]id[/i]. This method will return a [code]FirestoreTask[/code] object, representing a reference to the request issued. If saved into a variable, the [code]FirestoreTask[/code] object can be used to yield checked the [code]result_query(result)[/code] signal, or the more generic [code]task_finished(result)[/code] signal.
## [b]Note:[/b] [code]order_by[/code] does not work in offline mode.
## ex.
## [code]var query_task : FirestoreTask = Firebase.Firestore.query(FirestoreQuery.new())[/code]
## [code]await query_task.task_finished[/code]
## Since the emitted signal is holding an argument, it can be directly retrieved as a return variable from the [code]yield()[/code] function.
##
## ex.
## [code]var result : Array = await query_task.task_finished[/code]
##
## @args collection_id, page_size, page_token, order_by
## @arg-types String, int, String, String
## @arg-defaults , 0, "", ""
## @return FirestoreTask
func list(path : String = "", page_size : int = 0, page_token : String = "", order_by : String = "") -> Array:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_LIST
	var url : String = _base_url + _extended_url + path
	if page_size != 0:
		url+="?pageSize="+str(page_size)
	if page_token != "":
		url+="&pageToken="+page_token
	if order_by != "":
		url+="&orderBy="+order_by

	task.data = [path, page_size, page_token, order_by]
	task._url = url
	_pooled_request(task)
	
	return await _handle_task_finished(task)


func set_networking(value: bool) -> void:
	if value:
		enable_networking()
	else:
		disable_networking()


func enable_networking() -> void:
	if networking:
		return
	networking = true
	_base_url = _base_url.replace("storeoffline", "firestore")
	for coll in get_children():
		if coll is FirestoreCollection:
			coll._base_url = _base_url


func disable_networking() -> void:
	if not networking:
		return
	networking = false
	# Pointing to an invalid url should do the trick.
	_base_url = _base_url.replace("firestore", "storeoffline")
	for coll in get_children():
		if coll is FirestoreCollection:
			coll._base_url = _base_url


func _set_offline(value: bool) -> void:
	return # Since caching is causing a lot of issues, I'm turning it off for now. We will revisit this in the future, once we have some time to investigate why the cache is being corrupted.


func _set_config(config_json : Dictionary) -> void:
	_config = config_json
	_cache_loc = _config["cacheLocation"]
	_extended_url = _extended_url.replace("[PROJECT_ID]", _config.projectId)

	# Since caching is causing a lot of issues, I'm removing this check for now. We will revisit this in the future, once we have some time to investigate why the cache is being corrupted.

	_check_emulating()

func _check_emulating() -> void :
	## Check emulating
	if not Firebase.emulating:
		_base_url = "https://firestore.googleapis.com/{version}/".format({ version = _API_VERSION })
	else:
		var port : String = _config.emulators.ports.firestore
		if port == "":
			Firebase._printerr("You are in 'emulated' mode, but the port for Firestore has not been configured.")
		else:
			_base_url = "http://localhost:{port}/{version}/".format({ version = _API_VERSION, port = port })

func _pooled_request(task : FirestoreTask) -> void:
	if _offline:
		task._on_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 404, PackedStringArray(), PackedByteArray())
		return

	if (auth == null or auth.is_empty()) and not Firebase.emulating:
		Firebase._print("Unauthenticated request issued...")
		Firebase.Auth.login_anonymous()
		var result : Array = await Firebase.Auth.auth_request
		if result[0] != 1:
			_check_auth_error(result[0], result[1])
		Firebase._print("Client connected as Anonymous")

	if not Firebase.emulating:
		task._headers = PackedStringArray([_AUTHORIZATION_HEADER + auth.idtoken])

	var	http_request = HTTPRequest.new()
	http_request.timeout = 5
	Utilities.fix_http_request(http_request)
	add_child(http_request)
	http_request.request_completed.connect(
		func(result, response_code, headers, body): 
			task._on_request_completed(result, response_code, headers, body)
			http_request.queue_free()
	)
	
	http_request.request(task._url, task._headers, task._method, task._fields)

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
	auth = auth_result
	for coll in get_children():
		if coll is FirestoreCollection:
			coll.auth = auth

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
	auth = auth_result
	for coll in get_children():
		if coll is FirestoreCollection:
			coll.auth = auth

func _on_connect_check_request_completed(result : int, _response_code, _headers, _body) -> void:
	_set_offline(result != HTTPRequest.RESULT_SUCCESS)
	#_connect_check_node.request(_base_url)


func _on_FirebaseAuth_logout() -> void:
	auth = {}

func _check_auth_error(code : int, message : String) -> void:
	var err : String
	match code:
		400: err = "Please enable the Anonymous Sign-in method, or Authenticate the Client before issuing a request"
	Firebase._printerr(err)
	Firebase._printerr(message)

func _handle_task_finished(task : FirestoreTask):
	await task.task_finished
	
	if task.error.keys().size() > 0:
		error.emit(task.error)
		
	return task.data
