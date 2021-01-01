extends "res://addons/godot-firebase/FirebaseContainer.gd"

signal chat_added

func on_item_added(item, key, template):
	emit_signal("chat_added")
