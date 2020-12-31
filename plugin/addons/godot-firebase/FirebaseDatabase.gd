extends Node

var config = {}

var auth = null

const OrderBy = "orderBy"
const LimitToFirst = "limitToFirst"
const LimitToLast = "limitToLast"
const StartAt = "startAt"
const EndAt = "endAt"
const EqualTo = "equalTo"

func set_config(config_json):
    config = config_json

func _on_FirebaseAuth_login_succeeded(auth_result):
    auth = auth_result

func get_database_reference(path : String, filter : Dictionary):        
    var firebase_reference = Node.new()
    firebase_reference.set_script(load("res://addons/GDFirebase/FirebaseReference.gd"))
    var pusher = HTTPRequest.new()
    var listener = Node.new()
    listener.set_script(load("res://addons/GDFirebase/HTTPSSEClient/HTTPSSEClient.gd"))
    var store = Node.new()
    firebase_reference.set_db_path(path, filter)
    firebase_reference.set_auth_and_config(auth, config)
    firebase_reference.set_pusher(pusher)
    firebase_reference.set_listener(listener)
    firebase_reference.set_store(store)
    add_child(firebase_reference)
    return firebase_reference
