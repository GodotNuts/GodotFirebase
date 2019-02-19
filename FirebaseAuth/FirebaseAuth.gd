extends HTTPRequest

signal login_succeeded(auth_result)
#warning-ignore:unused_signal
signal login_failed

onready var API_Key = ""
onready var signup_request_url = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key="
onready var signin_request_url = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key="
onready var refresh_request_url = "https://securetoken.googleapis.com/v1/token?key="

var needs_refresh = false
var auth = null

var login_request_body = {
    "email":"",
    "password":"",
    "returnSecureToken": true
   }

var refresh_request_body = {
    "grant_type":"refresh_token",
    "refresh_token":""
    }

func _ready():
    signup_request_url += API_Key
    signin_request_url += API_Key
    refresh_request_url += API_Key
    connect("request_completed", self, "_on_FirebaseAuth_request_completed")
    
func login_with_email_and_password(email, password):
    login_request_body.email = email
    login_request_body.password = password
#warning-ignore:return_value_discarded
    request(signin_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(login_request_body))
    pass
    
func signup_with_email_and_password(email, password):
    login_request_body.email = email
    login_request_body.password = password
#warning-ignore:return_value_discarded
    request(signup_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(login_request_body))
    
func _on_FirebaseAuth_request_completed(result, response_code, headers, body):
    if response_code == HTTPClient.RESPONSE_OK:
        var bod = body.get_string_from_ascii()
        var json_result = JSON.parse(bod)
        var res = json_result.result
        if res:
            auth = get_clean_keys(res)
            if not needs_refresh:
                emit_signal("login_succeeded", auth)
            begin_refresh_countdown()
    else:
        print(body.get_string_from_ascii())
        
func begin_refresh_countdown():
    var refresh_token = null
    var expires_in = 1000
    refresh_token = auth.refreshtoken
    expires_in = auth.expiresin
    needs_refresh = true
    yield(get_tree().create_timer(float(expires_in)), "timeout")
    refresh_request_body.refresh_token = refresh_token
    request(refresh_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(refresh_request_body))
    
func get_clean_keys(auth_result):
    var cleaned = {}
    for key in auth_result.keys():
        cleaned[key.replace("_", "").to_lower()] = auth_result[key]
    return cleaned