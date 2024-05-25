@tool
class_name FirebaseRemoteConfig
extends Node

const RemoteConfigFunctionId = "getRemoteConfig"

signal remote_config_received(config)
signal remote_config_error(error)

var _project_config = {}
var _headers : PackedStringArray = [
]
var _auth : Dictionary

func _set_config(config_json : Dictionary) -> void:
	_project_config = config_json # This may get confusing, hoping the variable name makes it easier to understand

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
	_auth = auth_result

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
	_auth = auth_result

func _on_FirebaseAuth_logout() -> void:
	_auth = {}

func get_remote_config() -> void:
	var function_task = Firebase.Functions.execute("getRemoteConfig", HTTPClient.METHOD_GET, {}, {}) as FunctionTask
	var result = await function_task.task_finished
	Firebase._print("Config request result: " + str(result))
	if result.has("error"):
		remote_config_error.emit(result)
		return
		
	var config = RemoteConfig.new(result)
	remote_config_received.emit(config)
