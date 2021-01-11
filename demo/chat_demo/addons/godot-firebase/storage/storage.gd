class_name FirebaseStorage
extends HTTPRequest
# gs://asterizzle.appspot.com/
# https://firebasestorage.googleapis.com/v0/b/[APP_ID]/o/[FOLDER_NAME]%[FOLDER_NAME]%2F[FILENAME]?alt=media
# https://firebasestorage.googleapis.com/v0/b/default/asterizzle.appspot.com/o/my/path/icon.png

const DELIMITER : String = "/"
var path : String setget , get_api_path
var auth : Dictionary
var config : Dictionary

func _ready() -> void:
		connect("request_completed", self, "on_request_completed")

func set_config(config_json : Dictionary) -> void:
		config = config_json

func _on_FirebaseAuth_login_succeeded(auth_token : Dictionary) -> void:
		auth = auth_token
		
func upload(obj : String, folder_path : String, file_name : String) -> void:
		var to_push = {
				
			 }
		if config and auth:
				var replaced_project_id = self.path.replace("[PROJECT_ID]", "firebasestorage")
				var complete_path = replaced_project_id.replace("[APP_ID]", config.storageBucket.percent_encode()) + DELIMITER + folder_path.percent_encode() + DELIMITER + file_name + "?alt=media"
				print("Path: " + complete_path)
				request(complete_path, [], true, HTTPClient.METHOD_GET)
		
func download(folder_path : String, file_name : String) -> void:
		if config and auth:
				var replaced_project_id = self.path.replace("[PROJECT_ID]", config.projectId)
				var complete_path = replaced_project_id.replace("[APP_ID]", config.appID) + DELIMITER + folder_path + DELIMITER + file_name + "?key=" + auth.idtoken + "&alt=media"
				request(complete_path, ["Content-Type: image/png"], true, HTTPClient.METHOD_GET, "")

func on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray):
		var body_json = body.get_string_from_utf8()
		print("Result:")
		print(body_json)
		
func get_api_path() -> String:
		# https://www.googleapis.com/storage/v1
		return "https://www.googleapis.com/storage/v1/b/[APP_ID]/o"
