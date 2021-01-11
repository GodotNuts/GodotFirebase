tool
class_name FirebaseContainer
extends Control

signal item_selected(item, id, template)
signal item_deleted(item, id, template)

export (PackedScene) var item_template

var tracked_values : Dictionary = {}

export (String) var current_path : String
export (bool) var one_shot : bool = false
export (String) var specified_key : String
var db_ref : FirebaseDatabaseReference

func _ready() -> void:
	Firebase.Auth.connect("login_succeeded", self, "on_login_succeeded")
		
func on_login_succeeded(auth_token : String):
	connect_to_database()
	
func connect_to_database() -> void:
	if !specified_key:
		db_ref = Firebase.Database.get_database_reference(current_path, { })
	else:
		db_ref = Firebase.Database.get_database_reference(current_path + "/" + specified_key)
		
	db_ref.connect("new_data_update", self, "on_new_update", [], CONNECT_ONESHOT if one_shot else CONNECT_PERSIST)
	if !one_shot:
		db_ref.connect("patch_data_update", self, "on_patch_update")
		
func on_new_update(data : Dictionary) -> void:
	if data.data:
		var item = data.data
		var template = item_template.instance()
		add_child(template)
		template.set_item(item)
			
func on_item_added(item, key : String, template : PackedScene) -> void:
	pass

func on_patch_update(data : Dictionary) -> void:
	if data.data and data.path:
		if tracked_values.has(data.path):
			tracked_values[data.path].template.set_item(data.data)
	
func delete_child(key : String) -> void:
	var item = tracked_values[key]
	remove_child(item.template)
	tracked_values.erase(key)
	
func on_data_delete(data : Dictionary) -> void:
	if data:
		for key in data.keys():
			if tracked_values.has(key):
				delete_child(key)
