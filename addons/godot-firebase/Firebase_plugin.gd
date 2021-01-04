tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("Firebase", "res://addons/godot-firebase/Firebase.gd")

func _exit_tree():
	remove_autoload_singleton("Firebase")
