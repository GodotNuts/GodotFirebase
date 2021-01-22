class_name FirebaseDatabase
extends Node

const ORDER_BY : String = "orderBy"
const LIMIT_TO_FIRST : String = "limitToFirst"
const LIMIT_TO_LAST : String = "limitToLast"
const START_AT : String = "startAt"
const END_AT : String = "endAt"
const EQUAL_TO : String = "equalTo"

var config : Dictionary = {}

var auth : Dictionary = {}

func set_config(config_json : Dictionary) -> void:
		config = config_json

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
		auth = auth_result

func get_database_reference(path : String, filter : Dictionary) -> FirebaseDatabaseReference:        
		var firebase_reference : FirebaseDatabaseReference = FirebaseDatabaseReference.new()
		var pusher : HTTPRequest = HTTPRequest.new()
		var listener : Node = Node.new()
		listener.set_script(load("res://addons/http-sse-client/HTTPSSEClient.gd"))
		var store : FirebaseDatabaseStore = FirebaseDatabaseStore.new()
		firebase_reference.set_db_path(path, filter)
		firebase_reference.set_auth_and_config(auth, config)
		firebase_reference.set_pusher(pusher)
		firebase_reference.set_listener(listener)
		firebase_reference.set_store(store)
		add_child(firebase_reference)
		return firebase_reference
