tool
extends Control

signal item_selected(item, id, template)
signal item_deleted(item, id, template)

export (PackedScene) var ItemTemplate

var tracked_values = {}

export (String) var CurrentPath
export (bool) var OneShot = false
export (String) var SpecifiedKey
var db_ref

func _ready():
	Firebase.Auth.connect("login_succeeded", self, "on_login_succeeded")
		
func on_login_succeeded(auth_token):
	connect_to_database()
	
func connect_to_database():
	if !SpecifiedKey:
		db_ref = Firebase.Database.get_database_reference(CurrentPath, { })
	else:
		db_ref = Firebase.Database.get_database_reference(CurrentPath + "/" + SpecifiedKey)
		
	db_ref.connect("new_data_update", self, "on_new_update", [], CONNECT_ONESHOT if OneShot else CONNECT_PERSIST)
	if !OneShot:
		db_ref.connect("patch_data_update", self, "on_patch_update")
		
func on_new_update(data):
	if data.data:
		var item = data.data
		var template = ItemTemplate.instance()
		add_child(template)
		template.set_item(item)
	   
func on_item_added(item, key, template):
	pass

func on_patch_update(data):
	if data.data and data.path:
		if tracked_values.has(data.path):
			tracked_values[data.path].template.set_item(data.data)
	
func delete_child(key):
	var item = tracked_values[key]
	remove_child(item.template)
	tracked_values.erase(key)
	
func on_data_delete(data):
	if data:
		for key in data.keys():
			if tracked_values.has(key):
				delete_child(key)
