## @meta-authors BackAt50Ft
## @meta-version 2.3
## The Realtime Database API for Firebase.
## This class is effectively a factory class to get connections to the Firebase realtime database.
## 
@tool
class_name FirebaseDatabase
extends Node

var _base_url : String = ""

@export var should_store_data: bool = true

func check_emulating() -> void:
	## Check emulating
	if not Firebase.emulating:
		_base_url = Firebase.config.databaseURL
	else:
		var port : String = Firebase.config.emulators.ports.realtimeDatabase
		if port == "":
			Firebase._printerr("You are in 'emulated' mode, but the port for Realtime Database has not been configured.")
		else:
			_base_url = "http://localhost"

func get_database_reference(path: String, filter : Dictionary = {}) -> FirebaseDatabaseReference:
	var firebase_reference = load("res://addons/godot-firebase/database/firebase_database_reference.tscn").instantiate()
	firebase_reference.set_db_path(path, filter)
	add_child(firebase_reference)
	return firebase_reference
	
func get_once_database_reference(path: String, filter : Dictionary = {}) -> FirebaseOnceDatabaseReference:
	var firebase_reference = load("res://addons/godot-firebase/database/firebase_once_database_reference.tscn").instantiate()
	firebase_reference.set_db_path(path, filter)
	add_child(firebase_reference)
	return firebase_reference

const PUSH_MIDDLEWARE = "push"
const ALL_MIDDLEWARE = "all"
const UPDATE_MIDDLEWARE = "update"

var middleware: Dictionary[String, Array] = {
	push = [],
	all = [],
	update = [],
}

func add_middleware(on_action: String, callable: Callable) -> void:
	if middleware.has(on_action):
		middleware[on_action].push_back(callable)
