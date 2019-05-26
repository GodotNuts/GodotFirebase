extends HTTPRequest
class_name FirebaseStorage
# gs://asterizzle.appspot.com/
# https://firebasestorage.googleapis.com/v0/b/[APP_ID]/o/[FOLDER_NAME]%[FOLDER_NAME]%2F[FILENAME]?alt=media
# https://firebasestorage.googleapis.com/v0/b/default/asterizzle.appspot.com/o/my/path/icon.png
var path setget , get_path
var auth
var config
const delimiter = "/"

func _ready():
    connect("request_completed", self, "on_request_completed")

func set_config(config_json):
    config = config_json

func _on_FirebaseAuth_login_succeeded(auth_token):
    auth = auth_token
    
func upload(obj : String, folder_path : String, file_name : String) -> void:
    var to_push = {
        
       }
    if config and auth:
        var replaced_project_id = self.path.replace("[PROJECT_ID]", "firebasestorage")
        var complete_path = replaced_project_id.replace("[APP_ID]", config.storageBucket.percent_encode()) + delimiter + folder_path.percent_encode() + delimiter + file_name + "?alt=media"
        print("Path: " + complete_path)
        request(complete_path, [], true, HTTPClient.METHOD_GET)
    
func download(folder_path : String, file_name : String) -> void:
    if config and auth:
        var replaced_project_id = self.path.replace("[PROJECT_ID]", config.projectId)
        var complete_path = replaced_project_id.replace("[APP_ID]", config.appID) + delimiter + folder_path + delimiter + file_name + "?key=" + auth.idtoken + "&alt=media"
        request(complete_path, ["Content-Type: image/png"], true, HTTPClient.METHOD_GET, "")

func on_request_completed(result, response_code, headers, body : PoolByteArray):
    var body_json = body.get_string_from_utf8()
    print("Result:")
    print(body_json)
    
func get_path():
    # https://www.googleapis.com/storage/v1
    return "https://www.googleapis.com/storage/v1/b/[APP_ID]/o"