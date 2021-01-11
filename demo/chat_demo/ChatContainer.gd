extends "res://addons/godot-firebase/containers/container.gd"

signal chat_added

func on_item_added(item, key, template):
	emit_signal("chat_added")
