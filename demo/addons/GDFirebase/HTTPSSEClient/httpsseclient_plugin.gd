tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("HTTPSSEClient", "Node", preload("HTTPSSEClient.gd"), preload("icon.png"))
    pass

func _exit_tree():
    remove_custom_type("HTTPSSEClient")
    pass
