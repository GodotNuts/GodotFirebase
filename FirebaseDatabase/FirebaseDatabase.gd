extends Node

var config = {
"apiKey": "",
"authDomain": "",
"databaseURL": "",
"projectId": "",
"storageBucket": "",
"messagingSenderId": ""
}

var auth = null

var OrderBy = "orderBy"

onready var FilterQuery

func _ready():
    FirebaseAuth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")

func _on_FirebaseAuth_login_succeeded(auth_result):
    auth = auth_result

func get_database_reference(path : String):
    var firebase_reference = Node.new()
    firebase_reference.set_script(preload("res://addons/FirebaseDatabase/FirebaseReference.gd"))
    var pusher = HTTPRequest.new()
    var listener = HTTPRequest.new()
    var store = Node.new()
    firebase_reference.set_auth_and_config(auth, config)
    firebase_reference.set_pusher(pusher)
    firebase_reference.set_listener(listener)
    firebase_reference.set_store(store)
    firebase_reference.set_db_path(path)
    add_child(firebase_reference)

    return firebase_reference
