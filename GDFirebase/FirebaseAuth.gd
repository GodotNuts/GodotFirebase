extends HTTPRequest

signal login_succeeded(auth_result)
signal login_failed(code, message)
signal userdata_received(userdata)

var config = {}
var signup_request_url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s" 
var signin_request_url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s" 
var userdata_request_url = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=%s" 
var refresh_request_url = "https://securetoken.googleapis.com/v1/token?key=%s"

const RESPONSE_SIGNIN   = "identitytoolkit#VerifyPasswordResponse"
const RESPONSE_SIGNUP   = "identitytoolkit#SignupNewUserResponse"
const RESPONSE_USERDATA = "identitytoolkit#GetAccountInfoResponse"

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

# Sets the configuration needed for the plugin to talk to Firebase
# These settings come from the Firebase.gd script automatically
func set_config(config_json):
    config = config_json
    signup_request_url %= config.apiKey
    signin_request_url %= config.apiKey
    userdata_request_url %= config.apiKey
    refresh_request_url %= config.apiKey
    connect("request_completed", self, "_on_FirebaseAuth_request_completed")

# Called with Firebase.Auth.login_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
# If the login fails it will return an error code through the function _on_FirebaseAuth_request_completed
func login_with_email_and_password(email, password):
    login_request_body.email = email
    login_request_body.password = password
    request(signin_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(login_request_body))
    pass

# Called with Firebase.Auth.signup_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
func signup_with_email_and_password(email, password):
    login_request_body.email = email
    login_request_body.password = password
    request(signup_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(login_request_body))

# This function is called whenever there is an authentication request to Firebase
# On an error, this function with emit the signal 'login_failed' and print the error to the console
func _on_FirebaseAuth_request_completed(result, response_code, headers, body):
    var bod = body.get_string_from_utf8()
    var json_result = JSON.parse(bod)
    print(json_result.result)
    if json_result.error != OK:
        print_debug("Error while parsing body json")
        return
    
    var res = json_result.result
    if response_code == HTTPClient.RESPONSE_OK:
        if not res.has("kind"):
            auth = get_clean_keys(res)
            begin_refresh_countdown()
        else:
            match res.kind:
                RESPONSE_SIGNIN, RESPONSE_SIGNUP:
                    auth = get_clean_keys(res)
                    emit_signal("login_succeeded", auth)
                    begin_refresh_countdown()
                RESPONSE_USERDATA:
                    var userdata = FirebaseUserData.new(res.users[0])
                    emit_signal("userdata_received", userdata)
    else:
        # error message would be INVALID_EMAIL, EMAIL_NOT_FOUND, INVALID_PASSWORD, USER_DISABLED or WEAK_PASSWORD
        emit_signal("login_failed", res.error.code, res.error.message)

# Function is called when a new token is issued to a user. The function will yield until the token has expired, and then request a new one.
func begin_refresh_countdown():
    var refresh_token = null
    var expires_in = 1000
    auth = get_clean_keys(auth)
    if auth.has("refreshToken"):
        refresh_token = auth.refreshToken
        expires_in = auth.expiresIn
    elif auth.has("refresh_token"):
        refresh_token = auth.refresh_token
        expires_in = auth.expires_in
    needs_refresh = true
    yield(get_tree().create_timer(float(expires_in)), "timeout")
    refresh_request_body.refresh_token = refresh_token
    request(refresh_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(refresh_request_body))

# This function is used to make all keys lowercase
# This is only used to cut down on processing errors from Firebase
# This is due to Google have inconsistencies in the API that we are trying to fix
func get_clean_keys(auth_result):
    var cleaned = {}
    for key in auth_result.keys():
        cleaned[key.replace("_", "").to_lower()] = auth_result[key]
    return cleaned

# Function called to get all
func get_user_data():
    if auth == null or auth.has("idtoken") == false:
        print_debug("Not logged in")
        return
        
    request(userdata_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print({"idToken":auth.idtoken}))
