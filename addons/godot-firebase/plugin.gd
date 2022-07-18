tool
extends EditorPlugin

func disable_plugin() -> void:
    remove_autoload_singleton("Firebase")

func enable_plugin() -> void:
    add_autoload_singleton("Firebase", "res://addons/godot-firebase/firebase/firebase.tscn")
