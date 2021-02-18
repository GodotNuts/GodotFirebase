## @meta-authors TODO
## @meta-version 2.2
## The Realtime Database API for Firebase.
## Documentation TODO.
tool
class_name FirebaseDatabase
extends Node

const ORDER_BY : String = "orderBy"
const LIMIT_TO_FIRST : String = "limitToFirst"
const LIMIT_TO_LAST : String = "limitToLast"
const START_AT : String = "startAt"
const END_AT : String = "endAt"
const EQUAL_TO : String = "equalTo"

var _config : Dictionary = {}

var _auth : Dictionary = {}

func _set_config(config_json : Dictionary) -> void:
    _config = config_json

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
    _auth = auth_result

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
    _auth = auth_result

func _on_FirebaseAuth_logout() -> void:
    _auth = {}

func get_database_reference(path : String, filter : Dictionary = {}) -> FirebaseDatabaseReference:
    var firebase_reference : FirebaseDatabaseReference = FirebaseDatabaseReference.new()
    var pusher : HTTPRequest = HTTPRequest.new()
    var listener : Node = Node.new()
    listener.set_script(load("res://addons/http-sse-client/HTTPSSEClient.gd"))
    var store : FirebaseDatabaseStore = FirebaseDatabaseStore.new()
    firebase_reference.set_db_path(path, filter)
    firebase_reference.set_auth_and_config(_auth, _config)
    firebase_reference.set_pusher(pusher)
    firebase_reference.set_listener(listener)
    firebase_reference.set_store(store)
    add_child(firebase_reference)
    return firebase_reference
