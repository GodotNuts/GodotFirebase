extends Control

var auth = null
var firebase_reference
var firebase_storage : FirebaseStorage

func _ready():
    Firebase.Auth.connect("login_succeeded", self, "login_success")
    $VBoxContainer/ScrollContainer/Chat.connect("chat_added", self, "on_chat_added")
    
    pass
    
func login_success(auth_result):
    auth = auth_result
    firebase_reference = Firebase.Database.get_database_reference("game/chat", {})
    show()

var current_file

func _on_SubmitButton_pressed():
    if Firebase.Auth.auth:
        var text = $VBoxContainer/SubmitText.text
        var user_name = Firebase.Auth.auth.email
        $VBoxContainer/SubmitText.text = ""
        firebase_reference.push({"user_name": user_name, "text": text})

func on_chat_added():
    $Tween.interpolate_property($VBoxContainer/ScrollContainer, "scroll_vertical", $VBoxContainer/ScrollContainer.scroll_vertical, $VBoxContainer/ScrollContainer.scroll_vertical + $VBoxContainer.rect_size.y, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.start()
