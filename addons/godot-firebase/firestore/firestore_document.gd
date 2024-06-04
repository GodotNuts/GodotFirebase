## @meta-authors TODO
## @meta-version 2.2
## A reference to a Firestore Document.
## Documentation TODO.
@tool
class_name FirestoreDocument
extends Node

# A FirestoreDocument objects that holds all important values for a Firestore Document,
# @doc_name = name of the Firestore Document, which is the request PATH
# @doc_fields = fields held by Firestore Document, in APIs format
# created when requested from a `collection().get()` call

var document : Dictionary       # the Document itself
var doc_name : String           # only .name
var create_time : String        # createTime
var collection_name : String    # Name of the collection to which it belongs
var _transforms : FieldTransformArray     # The transforms to apply
signal changed(changes)

func _init(doc : Dictionary = {}):
	_transforms = FieldTransformArray.new()
	
	document = doc.fields
	doc_name = doc.name
	if doc_name.count("/") > 2:
		doc_name = (doc_name.split("/") as Array).back()
		
	self.create_time = doc.createTime

func replace(with : FirestoreDocument, is_listener := false) -> void:
	var current = document.duplicate()
	document = with.document
	
	var changes = {
		"added": [], "removed": [], "updated": [], "is_listener": is_listener
	}
	
	for key in current.keys():
		if not document.has(key):
			changes.removed.push_back({ "key" : key })
		else:
			var new_value = Utilities.from_firebase_type(document[key])
			var old_value = Utilities.from_firebase_type(current[key])
			if new_value != old_value:
				if old_value == null:
					changes.removed.push_back({ "key" : key }) # ??
				else:
					changes.updated.push_back({ "key" : key, "old": old_value, "new" : new_value })
	
	for key in document.keys():
		if not current.has(key):
			changes.added.push_back({ "key" : key, "new" : Utilities.from_firebase_type(document[key]) })
	
	if not (changes.added.is_empty() and changes.removed.is_empty() and changes.updated.is_empty()):
		changed.emit(changes)

func is_null_value(key) -> bool:
	return document.has(key) and Utilities.from_firebase_type(document[key]) == null

# As of right now, we do not track these with track changes; instead, they'll come back when the document updates from the server.
# Until that time, it's expected if you want to track these types of changes that you commit for the transforms and then get the document yourself.
func add_field_transform(transform : FieldTransform) -> void:
	_transforms.push_back(transform)

func remove_field_transform(transform : FieldTransform) -> void:
	_transforms.erase(transform)
	
func clear_field_transforms() -> void:
	_transforms.transforms.clear()

func remove_field(field_path : String) -> void:
	if document.has(field_path):
		document[field_path] = Utilities.to_firebase_type(null)
		
		var changes = {
			"added": [], "removed": [], "updated": [], "is_listener": false
		}
		
		changes.removed.push_back({ "key" : field_path })
		changed.emit(changes)
		
func _erase(field_path : String) -> void:
	document.erase(field_path)

func add_or_update_field(field_path : String, value : Variant) -> void:		
	var changes = {
		"added": [], "removed": [], "updated": [], "is_listener": false
	}
	
	var existing_value = get_value(field_path)
	var has_field_path = existing_value != null and not is_null_value(field_path)
	
	var converted_value = Utilities.to_firebase_type(value)
	document[field_path] = converted_value
	
	if has_field_path:
		changes.updated.push_back({ "key" : field_path, "old" : existing_value, "new" : value })
	else:
		changes.added.push_back({ "key" : field_path, "new" : value })

	changed.emit(changes)
	
func on_snapshot(when_called : Callable, poll_time : float = 1.0) -> FirestoreListener.FirestoreListenerConnection:
	if get_child_count() >= 1: # Only one listener per
		assert(false, "Multiple listeners not allowed for the same document yet")
		return
	
	changed.connect(when_called, CONNECT_REFERENCE_COUNTED)
	var listener = preload("res://addons/godot-firebase/firestore/firestore_listener.tscn").instantiate()
	add_child(listener)
	listener.initialize_listener(collection_name, doc_name, poll_time)
	listener.owner = self
	var result = listener.enable_connection()
	return result

func get_value(property : StringName) -> Variant:
	if property == "doc_name":
		return doc_name
	elif property == "collection_name":
		return collection_name
	elif property == "create_time":
		return create_time
	
	if document.has(property):
		var result = Utilities.from_firebase_type(document[property])
		
		return result
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	document[property] = Utilities.to_firebase_type(value)
	return true

func keys():
	return document.keys()

# Call print(document) to return directly this document formatted
func _to_string() -> String:
	return ("doc_name: {doc_name}, \ndata: {data}, \ncreate_time: {create_time}\n").format(
		{doc_name = self.doc_name,
		data = document,
		create_time = self.create_time})
