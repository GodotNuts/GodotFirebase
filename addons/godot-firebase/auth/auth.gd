## @meta-authors TODO
## @meta-version 2.3
## The authentication API for Firebase.
## Documentation TODO.
tool
class_name FirebaseAuth
extends HTTPRequest

signal signup_succeeded(auth_result)
signal login_succeeded(auth_result)
signal login_failed(code, message)
signal userdata_received(userdata)
signal token_exchanged(successful)
signal token_refresh_succeeded(auth_result)
signal logged_out()

const RESPONSE_SIGNUP : String   = "identitytoolkit#SignupNewUserResponse"
const RESPONSE_SIGNIN : String   = "identitytoolkit#VerifyPasswordResponse"
const RESPONSE_ASSERTION : String  = "identitytoolkit#VerifyAssertionResponse"
const RESPONSE_USERDATA : String = "identitytoolkit#GetAccountInfoResponse"

var _signup_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s"
var _signin_with_oauth_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=%s"
var _signin_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s"
var _userdata_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=%s"
var _refresh_request_url : String = "https://securetoken.googleapis.com/v1/token?key=%s"
var _oobcode_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=%s"
var _delete_account_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=%s"
var _update_account_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=%s"
var _google_auth_request_url : String = "https://accounts.google.com/o/oauth2/v2/auth?"
var _google_token_request_url : String = "https://oauth2.googleapis.com/token?"

var _config : Dictionary = {}
var auth : Dictionary = {}
var _needs_refresh : bool = false
var is_busy : bool = false

var _headers : PoolStringArray = [
    "Content-Type: application/json",
#    "Access-Control-Allow-Origin: *"
   ]

var requesting : int = -1

enum Requests {
    NONE = -1,
    EXCHANGE_TOKEN,
    LOGIN_WITH_OAUTH,
}

var _login_request_body : Dictionary = {
    "email":"",
    "password":"",
    "returnSecureToken": true,
    }

var _post_body : String = "id_token=[GOOGLE_ID_TOKEN]&providerId=[PROVIDER_ID]"
var _request_uri : String = "[REQUEST_URI]"

var _oauth_login_request_body : Dictionary = {
    "postBody":"",
    "requestUri":"",
    "returnIdpCredential":true,
    "returnSecureToken":true
}

var _anonymous_login_request_body : Dictionary = {
    "returnSecureToken":true
}

var _refresh_request_body : Dictionary = {
    "grant_type":"refresh_token",
    "refresh_token":"",
}


var _password_reset_body : Dictionary = {
    "requestType":"password_reset",
    "email":"",
}


var _change_email_body : Dictionary = {
    "idToken":"",
    "email":"",
    "returnSecureToken": true,
}


var _change_password_body : Dictionary = {
    "idToken":"",
    "password":"",
    "returnSecureToken": true,
}


var _account_verification_body : Dictionary = {
    "requestType":"verify_email",
    "idToken":"",
}

        
var _update_profile_body : Dictionary = {
    "idToken":"",
    "displayName":"",
    "photoUrl":"",
    "deleteAttribute":"",
    "returnSecureToken":true
}

var _google_auth_body : Dictionary = {
    "scope":"email openid profile",
    "response_type":"code",
    "redirect_uri":"urn:ietf:wg:oauth:2.0:oob",
    "client_id":"[CLIENT_ID]"
}

var _google_token_body : Dictionary = {
    "code":"",
    "client_id":"",
    "client_secret":"",
    "redirect_uri":"urn:ietf:wg:oauth:2.0:oob",
    "grant_type":"authorization_code"
}


# Sets the configuration needed for the plugin to talk to Firebase
# These settings come from the Firebase.gd script automatically
func _set_config(config_json : Dictionary) -> void:
    _config = config_json
    _signup_request_url %= _config.apiKey
    _signin_request_url %= _config.apiKey
    _signin_with_oauth_request_url %= _config.apiKey
    _userdata_request_url %= _config.apiKey
    _refresh_request_url %= _config.apiKey
    _oobcode_request_url %= _config.apiKey
    _delete_account_request_url %= _config.apiKey
    _update_account_request_url %= _config.apiKey
        
    connect("request_completed", self, "_on_FirebaseAuth_request_completed")


# Function is used to check if the auth script is ready to process a request. Returns true if it is not currently processing
# If false it will print an error
func _is_ready() -> bool:
    if is_busy:
        printerr("Firebase Auth is currently busy and cannot process this request")
        return false
    else:
        return true

# Called with Firebase.Auth.signup_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
func signup_with_email_and_password(email : String, password : String) -> void:
    if _is_ready():
        is_busy = true
        _login_request_body.email = email
        _login_request_body.password = password
        request(_signup_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_login_request_body))


# Called with Firebase.Auth.anonymous_login()
# A successful request is indicated by a 200 OK HTTP status code. 
# The response contains the Firebase ID token and refresh token associated with the anonymous user.
# The 'mail' field will be empty since no email is linked to an anonymous user
func login_anonymous() -> void:
    if _is_ready():
        is_busy = true
        request(_signup_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_anonymous_login_request_body))


# Called with Firebase.Auth.login_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
# If the login fails it will return an error code through the function _on_FirebaseAuth_request_completed
func login_with_email_and_password(email : String, password : String) -> void:
    if _is_ready():
        is_busy = true
        _login_request_body.email = email
        _login_request_body.password = password
        request(_signin_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_login_request_body))

# Open a web page in browser redirecting to Google oAuth2 page for the current project
# Once given user's authorization, a token will be generated.
# NOTE** with this method, the authorization process will be copy-pasted
func get_google_auth(client_id : String = _config.clientId) -> void:
    var url_endpoint : String = _google_auth_request_url
    for key in _google_auth_body.keys():
        url_endpoint+=key+"="+_google_auth_body[key]+"&"
    url_endpoint = url_endpoint.replace("[CLIENT_ID]&", client_id)
    OS.shell_open(url_endpoint)

# Exchange the authorization oAuth2 code obtained from browser with a proper access id_token
func exchange_google_token(google_token : String) -> void:
    if _is_ready():
        is_busy = true
        _google_token_body.code = google_token
        _google_token_body.client_id = _config.clientId
        _google_token_body.client_secret = _config.clientSecret
        requesting = Requests.EXCHANGE_TOKEN
        request(_google_token_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_google_token_body))

# Login with Google oAuth2.
# A token is automatically obtained using an authorization code using @get_google_auth()
# @provider_id and @request_uri can be changed
func login_with_oauth(google_token: String, provider_id : String = "google.com", request_uri : String = "http://localhost") -> void:
    exchange_google_token(google_token)
    var is_successful : bool = yield(self, "token_exchanged")
    if is_successful and _is_ready():
        is_busy = true
        _oauth_login_request_body.postBody = _post_body.replace("[GOOGLE_ID_TOKEN]", auth.idtoken).replace("[PROVIDER_ID]", provider_id)
        _oauth_login_request_body.requestUri = _request_uri.replace("[REQUEST_URI]", request_uri)
        requesting = Requests.LOGIN_WITH_OAUTH
        request(_signin_with_oauth_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_oauth_login_request_body))

# Function used to logout of the system, this will also remove the local encrypted auth file if there is one
func logout() -> void:
    auth = {}
    remove_auth()
    emit_signal("logged_out")

# Function is called when requesting a manual token refresh
func manual_token_refresh(auth_data):
    auth = auth_data
    var refresh_token = null
    auth = get_clean_keys(auth)
    if auth.has("refreshtoken"):
        refresh_token = auth.refreshtoken
    elif auth.has("refresh_token"):
        refresh_token = auth.refresh_token
    _needs_refresh = true
    _refresh_request_body.refresh_token = refresh_token
    request(_refresh_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_refresh_request_body))

# This function is called whenever there is an authentication request to Firebase
# On an error, this function with emit the signal 'login_failed' and print the error to the console
func _on_FirebaseAuth_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
    is_busy = false
    var bod = body.get_string_from_utf8()
    var json_result = JSON.parse(bod)
    if json_result.error != OK:
        print_debug("Error while parsing body json")
        return
        
    var res = json_result.result
    if response_code == HTTPClient.RESPONSE_OK:
        if not res.has("kind"):
            auth = get_clean_keys(res)
            match requesting:
                Requests.EXCHANGE_TOKEN:
                    emit_signal("token_exchanged", true)
            begin_refresh_countdown()
        else:
            match res.kind:
                RESPONSE_SIGNUP:
                    auth = get_clean_keys(res)
                    emit_signal("signup_succeeded", auth)
                    begin_refresh_countdown()
                RESPONSE_SIGNIN, RESPONSE_ASSERTION:
                    auth = get_clean_keys(res)
                    emit_signal("login_succeeded", auth)
                    begin_refresh_countdown()
                RESPONSE_USERDATA:
                    var userdata = FirebaseUserData.new(res.users[0])
                    emit_signal("userdata_received", userdata)
    else:
                # error message would be INVALID_EMAIL, EMAIL_NOT_FOUND, INVALID_PASSWORD, USER_DISABLED or WEAK_PASSWORD
        if requesting == Requests.EXCHANGE_TOKEN:
            emit_signal("token_exchanged", false)
            emit_signal("login_failed", res.error, res.error_description)
        else:
            emit_signal("login_failed", res.error.code, res.error.message)
    requesting = Requests.NONE

# Function used to save the auth data provided by Firebase into an encrypted file
# Note this does not work in HTML5 or UWP
func save_auth(auth : Dictionary) -> void:
    if (OS.get_name() != 'HTML5' and OS.get_name() != 'UWP'):
        var encrypted_file = File.new()
        var err = encrypted_file.open_encrypted_with_pass("user://user.auth", File.WRITE, OS.get_unique_id())
        if err != OK:
            printerr("Error Opening File. Error Code: ", err)
        else:
            encrypted_file.store_line(to_json(auth))
            encrypted_file.close()
    else:
        printerr("OS Not supported for saving auth data")

# Function used to load the auth data file that has been stored locally
# Note this does not work in HTML5 or UWP
func load_auth() -> void:
    if OS.get_name() != 'HTML5' and OS.get_name() != 'UWP':
        var encrypted_file = File.new()
        var err = encrypted_file.open_encrypted_with_pass("user://user.auth", File.READ, OS.get_unique_id())
        if err != OK:
            printerr("Error Opening File. Error Code: ", err)
        else:
            var encrypted_file_data = parse_json(encrypted_file.get_line())
            manual_token_refresh(encrypted_file_data)
    else:
        printerr("OS Not supported for loading auth data")

# Function used to remove the local encrypted auth file
func remove_auth() -> void:
    var dir = Directory.new()
    if (dir.file_exists("user://user.auth")):
        dir.remove("user://user.auth")
    else:
        printerr("No encrypted auth file exists")

# Function to check if there is an encrypted auth data file
# If there is, the game will load it and refresh the token
func check_auth_file() -> void:
    var dir = Directory.new()
    if (dir.file_exists("user://user.auth")):
        load_auth()
    else:
        printerr("No encrypted auth file exists")

# Function used to change the email account for the currently logged in user
func change_user_email(email : String) -> void:
    if _is_ready():
        is_busy = true
        _change_email_body.email = email
        _change_email_body.idToken = auth.idtoken
        request(_update_account_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_change_email_body))


# Function used to change the password for the currently logged in user
func change_user_password(password : String) -> void:
    if _is_ready():
        is_busy = true
        _change_password_body.password = password
        _change_password_body.idToken = auth.idtoken
        request(_update_account_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_change_password_body))


# User Profile handlers 
func update_account(idToken : String, displayName : String, photoUrl : String, deleteAttribute : PoolStringArray, returnSecureToken : bool) -> void:
    if _is_ready():
        is_busy = true
        _update_profile_body.idToken = idToken
        _update_profile_body.displayName = displayName
        _update_profile_body.photoUrl = photoUrl
        _update_profile_body.deleteAttribute = deleteAttribute
        _update_profile_body.returnSecureToken = returnSecureToken
        request(_update_account_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_update_profile_body))



# Function to send a account verification email
func send_account_verification_email() -> void:
    if _is_ready():
        is_busy = true
        _account_verification_body.idToken = auth.idtoken
        request(_oobcode_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_account_verification_body))


# Function used to reset the password for a user who has forgotten in.
# This will send the users account an email with a password reset link
func send_password_reset_email(email : String) -> void:
    if _is_ready():
        is_busy = true
        _password_reset_body.email = email
        request(_oobcode_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_password_reset_body))


# Function called to get all
func get_user_data() -> void:
    if _is_ready():
        is_busy = true
        if auth == null or auth.has("idtoken") == false:
            print_debug("Not logged in")
            is_busy = false
            return
                        
        request(_userdata_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print({"idToken":auth.idtoken}))


# Function used to delete the account of the currently authenticated user
func delete_user_account() -> void:
    if _is_ready():
        is_busy = true
        request(_delete_account_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print({"idToken":auth.idtoken}))


# Function is called when a new token is issued to a user. The function will yield until the token has expired, and then request a new one.
func begin_refresh_countdown() -> void:
    var refresh_token = null
    var expires_in = 1000
    auth = get_clean_keys(auth)
    if auth.has("refreshtoken"):
        refresh_token = auth.refreshtoken
        expires_in = auth.expiresin
    elif auth.has("refresh_token"):
        refresh_token = auth.refresh_token
        expires_in = auth.expires_in
    if auth.has("userid"):
        auth["localid"] = auth.userid
    _needs_refresh = true
    emit_signal("token_refresh_succeeded", auth)
    yield(get_tree().create_timer(float(expires_in)), "timeout")
    _refresh_request_body.refresh_token = refresh_token
    request(_refresh_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_refresh_request_body))


# This function is used to make all keys lowercase
# This is only used to cut down on processing errors from Firebase
# This is due to Google have inconsistencies in the API that we are trying to fix
func get_clean_keys(auth_result : Dictionary) -> Dictionary:
    var cleaned = {}
    for key in auth_result.keys():
        cleaned[key.replace("_", "").to_lower()] = auth_result[key]
    return cleaned


