class_name FirestoreListener
extends Node

const MinPollTime = 60 * 2 # seconds, so 2 minutes

var _doc_name : String
var _poll_time : float
var _collection : FirestoreCollection

var _total_time = 0.0
var _enabled := false

func initialize_listener(collection_name : String, doc_name : String, poll_time : float) -> void:
	_poll_time = max(poll_time, MinPollTime)
	_doc_name = doc_name
	_collection = Firebase.Firestore.collection(collection_name)
	
func enable_connection() -> FirestoreListenerConnection:
	_enabled = true
	set_process(true)
	return FirestoreListenerConnection.new(self)

func _process(delta: float) -> void:
	if _enabled:
		_total_time += delta
		if _total_time >= _poll_time:
			_check_for_server_updates()
			_total_time = 0.0

func _check_for_server_updates() -> void:
	var executor = func():
					var doc = await _collection.get_doc(_doc_name, false, true)
					if doc == null:
						set_process(false) # Document was deleted out from under us, so stop updating
	
	executor.call() # Hack to work around the await here, otherwise would have to call with await in _process and that's no bueno			
	
class FirestoreListenerConnection extends RefCounted:
	var connection
	
	func _init(connection_node):
		connection = connection_node
	
	func stop():
		if connection != null and is_instance_valid(connection):
			connection.set_process(false)
			connection.free()
