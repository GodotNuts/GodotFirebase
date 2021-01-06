extends VBoxContainer

func _ready():
    Firebase.Auth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
    Firebase.Auth.connect("login_failed", self, "on_login_failed")
    pass

func _on_Login_pressed():
    var email = $Email.text
    var password = $Password.text
    Firebase.Auth.login_with_email_and_password(email, password)

func _on_Signup_pressed():
    var email = $Email.text
    var password = $Password.text
    Firebase.Auth.signup_with_email_and_password(email, password)

func _on_FirebaseAuth_login_succeeded(auth):
    hide()
    
func on_login_failed(error_code, message):
    print("error code: " + str(error_code))
    print("message: " + str(message))
