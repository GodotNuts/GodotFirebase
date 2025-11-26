class_name FirestoreListener
extends Node

signal changed(changes)

var _doc_name: String
var _collection: FirestoreCollection
var _collection_name: String
var _rtdb_ref: FirebaseDatabaseReference
var _rtdb_path: String
var _last_update_time: float
var _write_ref: FirebaseOnceDatabaseReference # Used for ETag-aware writes

func initialize_listener(collection_name: String, doc_name: String) -> void:
	_doc_name = doc_name
	_collection_name = collection_name
	_collection = Firebase.Firestore.collection(_collection_name)
	_rtdb_path = "firestore_mirrored_listener_data/%s" % _collection_name
	_rtdb_ref = Firebase.Database.get_database_reference(_rtdb_path, {})
	
	# Create a separate reference for writes to handle ETags
	_write_ref = Firebase.Database.get_once_database_reference(_rtdb_path)
	
	_last_update_time = Time.get_unix_time_from_system()
	print("[FirestoreListener] Initialized for %s/%s at RTDB path: %s" % [_collection_name, _doc_name, _rtdb_path])
	_rtdb_ref.patch_data_update.connect(_on_data_updated)
	_rtdb_ref.new_data_update.connect(_on_data_updated)
	# We might want to handle deletes differently, but for now let's see if they come through
	# _rtdb_ref.delete_data_update.connect(_on_data_updated) 

func send_change(changes) -> void:
	changes["update_time"] = Time.get_unix_time_from_system()
	print("[FirestoreListener] Attempting to send change with ETag sync: %s" % str(changes))
	
	# Start the write loop
	_attempt_write_with_retry(changes)

func _attempt_write_with_retry(changes: Dictionary, attempt: int = 1) -> void:
	if attempt > 5:
		print("[FirestoreListener] Max retry attempts reached. Write failed.")
		return
		
	# 1. Get current state and ETag
	_write_ref.once(_doc_name)
	var data = await _write_ref.once_successful
	var current_etag = _write_ref.last_etag
	
	# 2. Try to update with ETag
	_write_ref.put(_doc_name, changes, current_etag)
	
	# 3. Wait for result
	var result = await _wait_for_write_result()
	
	if not result:
		print("[FirestoreListener] Write failed (likely ETag mismatch). Retrying...")
		# Add a small random delay before retry to prevent thundering herd
		await _rtdb_ref.get_tree().create_timer(randf_range(0.1, 0.5)).timeout
		_attempt_write_with_retry(changes, attempt + 1)

func _wait_for_write_result() -> bool:
	# Wait for either success or failure signal
	# Note: update() calls use the pusher, so we listen to push_successful/failed
	var success = _write_ref.push_successful
	var failure = _write_ref.push_failed
	
	var multi_signal = Utilities.MultiSignal.new([success, failure])
	var result_signal = await multi_signal.completed
	
	# Check which signal completed the race
	return result_signal == success


func _on_data_updated(data: FirebaseResource) -> void:
	print("[FirestoreListener] Received data update. Key: %s, Data: %s" % [data.key, str(data.data)])
	# Only process updates for this specific document
	if data.key != _doc_name:
		print("[FirestoreListener] Ignoring update for different document: %s" % data.key)
		return
	
	# With ETags, we trust the server's state implicitly.
	# Any update that made it here passed the ETag check (or was a forced write).
	
	# Also check wall-clock time as a secondary ordering mechanism
	var incoming_update_time = data.data.get("update_time", 0.0) as float
	if incoming_update_time > _last_update_time:
		_last_update_time = incoming_update_time
	
	# Fetch the latest document state from Firestore
	# Since we are a child of the FirestoreDocument, we can just use it directly.
	# We cast to Node first to avoid cyclic dependency issues if not fully loaded, 
	# but ideally we trust get_parent() is the document.
	var document = get_parent()
	if not document:
		print("[FirestoreListener] Error: Listener has no parent document!")
		return
	
	# Extract change information
	var changes = data.data as Dictionary
	var updates = changes.get("updated", [])
	var deletes = changes.get("removed", [])
	var adds = changes.get("added", [])
	
	# Apply deletions
	if deletes:
		for delete in deletes:
			document._erase(delete.key)
	
	# Apply additions
	if adds:
		for add in adds:
			document[add.key] = add.new
	
	# Apply updates
	if updates:
		for update in updates:
			document[update.key] = update.new
	
	# Emit the changes to any connected listeners
	changed.emit(changes)


func enable_connection() -> FirestoreListenerConnection:
	return FirestoreListenerConnection.new(self)
	
class FirestoreListenerConnection extends RefCounted:
	var connection
	
	func _init(connection_node):
		connection = connection_node
	
	func stop():
		if connection != null and is_instance_valid(connection):
			connection.free()

	func send_change(changes):
		if connection != null and is_instance_valid(connection):
			connection.send_change(changes)
