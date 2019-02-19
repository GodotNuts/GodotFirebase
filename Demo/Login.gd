extends VBoxContainer

func _ready():
    Firebase.Auth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
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
