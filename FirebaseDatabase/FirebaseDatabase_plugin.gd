tool
extends EditorPlugin

func _enter_tree():
    add_autoload_singleton("FirebaseDatabase", "res://addons/FirebaseDatabase/FirebaseDatabase.gd")

func _exit_tree():
    remove_autoload_singleton("FirebaseDatabase")
