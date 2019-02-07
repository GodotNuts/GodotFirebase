tool
extends EditorPlugin

func _enter_tree():
    add_autoload_singleton("FirebaseAuth", "res://addons/FirebaseAuth/FirebaseAuth.gd")
    #add_custom_type("FirebaseAuth", "HTTPRequest", preload("FirebaseAuth.gd"), preload("AuthIcon.png"))

func _exit_tree():
    remove_autoload_singleton("FirebaseAuth")
    