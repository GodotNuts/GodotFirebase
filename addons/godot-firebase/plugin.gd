@tool
extends EditorPlugin

func _enable_plugin() -> void:
    add_autoload_singleton("Firebase", "res://addons/godot-firebase/firebase/firebase.tscn")

func _disable_plugin() -> void:
    remove_autoload_singleton("Firebase")
