tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("HTTPSSEClient", "Node", preload("res://addons/http-sse-client/HTTPSSEClient.gd"), preload("res://addons/http-sse-client/icon.png"))

func _exit_tree():
	remove_custom_type("HTTPSSEClient")
