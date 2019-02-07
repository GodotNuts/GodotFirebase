tool
extends EditorPlugin

func _enter_tree():
    add_autoload_singleton("FirebaseDatabase", "res://addons/FirebaseDatabase/FirebaseDatabase.gd")
#    add_custom_type("FirebaseDatabase", "Node", preload("FirebaseDatabase.gd"), preload("AuthIcon.png"))

func _exit_tree():
    remove_autoload_singleton("FirebaseDatabase")