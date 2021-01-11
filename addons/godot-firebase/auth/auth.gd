class_name FirebaseAuth
extends HTTPRequest

signal login_succeeded(auth_result)
signal login_failed(code, message)
signal userdata_received(userdata)

const RESPONSE_SIGNIN : String   = "identitytoolkit#VerifyPasswordResponse"
const RESPONSE_SIGNUP : String   = "identitytoolkit#SignupNewUserResponse"
const RESPONSE_USERDATA : String = "identitytoolkit#GetAccountInfoResponse"

var signup_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s" 
var signin_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s" 
var userdata_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=%s" 
var refresh_request_url : String = "https://securetoken.googleapis.com/v1/token?key=%s"
var oobcode_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=%s"
var delete_account_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=%s"
var update_account_request_url : String = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=%s"

var _config : Dictionary = {}
var auth : Dictionary = {}
var needs_refresh : bool = false
var is_busy : bool = false


var login_request_body : Dictionary = {
		"email":"",
		"password":"",
		"returnSecureToken": true,
		}


var refresh_request_body : Dictionary = {
		"grant_type":"refresh_token",
		"refresh_token":"",
		}


var password_reset_body : Dictionary = {
	"requestType":"password_reset",
	"email":"",
		}


var change_email_body : Dictionary = {
	"idToken":"",
	"email":"",
	"returnSecureToken": true,
		}


var change_password_body : Dictionary = {
	"idToken":"",
	"password":"",
	"returnSecureToken": true,
		}


var account_verification_body : Dictionary = {
	"requestType":"verify_email",
	"idToken":"",
		}


# Sets the configuration needed for the plugin to talk to Firebase
# These settings come from the Firebase.gd script automatically
func set_config(config_json) -> void:
		_config = config_json
		signup_request_url %= _config.apiKey
		signin_request_url %= _config.apiKey
		userdata_request_url %= _config.apiKey
		refresh_request_url %= _config.apiKey
		oobcode_request_url %= _config.apiKey
		delete_account_request_url %= _config.apiKey
		update_account_request_url %= _config.apiKey
		connect("request_completed", self, "_on_FirebaseAuth_request_completed")


# Function is used to check if the auth script is ready to process a request. Returns true if it is not currently processing
# If false it will print an error
func _is_ready() -> bool:
		if is_busy:
				printerr("Firebase Auth is currently busy and cannot process this request")
				return false
		else:
				return true


# Called with Firebase.Auth.login_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
# If the login fails it will return an error code through the function _on_FirebaseAuth_request_completed
func login_with_email_and_password(email : String, password : String) -> void:
		if _is_ready():
				is_busy = true
				login_request_body.email = email
				login_request_body.password = password
				request(signin_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(login_request_body))


# Called with Firebase.Auth.signup_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
func signup_with_email_and_password(email : String, password : String) -> void:
		if _is_ready():
				is_busy = true
				login_request_body.email = email
				login_request_body.password = password
				request(signup_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(login_request_body))


# This function is called whenever there is an authentication request to Firebase
# On an error, this function with emit the signal 'login_failed' and print the error to the console
func _on_FirebaseAuth_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
		var bod = body.get_string_from_utf8()
		var json_result = JSON.parse(bod)
		print(json_result.result)
		if json_result.error != OK:
				print_debug("Error while parsing body json")
				is_busy = false
				return
		
		var res = json_result.result
		if response_code == HTTPClient.RESPONSE_OK:
				if not res.has("kind"):
						auth = get_clean_keys(res)
						begin_refresh_countdown()
						is_busy = false
				else:
						match res.kind:
								RESPONSE_SIGNIN, RESPONSE_SIGNUP:
										auth = get_clean_keys(res)
										emit_signal("login_succeeded", auth)
										begin_refresh_countdown()
										is_busy = false
								RESPONSE_USERDATA:
										var userdata = FirebaseUserData.new(res.users[0])
										emit_signal("userdata_received", userdata)
										is_busy = false
		else:
				# error message would be INVALID_EMAIL, EMAIL_NOT_FOUND, INVALID_PASSWORD, USER_DISABLED or WEAK_PASSWORD
				emit_signal("login_failed", res.error.code, res.error.message)
				is_busy = false


# Function used to change the email account for the currently logged in user
func change_user_email(email : String) -> void:
		if _is_ready():
				is_busy = true
				change_email_body.email = email
				change_email_body.idToken = auth.idtoken
				request(update_account_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(change_email_body))


# Function used to change the password for the currently logged in user
func change_user_password(password : String) -> void:
		if _is_ready():
				is_busy = true
				change_password_body.email = password
				change_password_body.idToken = auth.idtoken
				request(update_account_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(change_password_body))


# Function to send a account verification email
func send_account_verification_email() -> void:
		if _is_ready():
				is_busy = true
				account_verification_body.idToken = auth.idtoken
				request(oobcode_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(account_verification_body))


# Function used to reset the password for a user who has forgotten in.
# This will send the users account an email with a password reset link
func send_password_reset_email(email : String) -> void:
		if _is_ready():
				is_busy = true
				password_reset_body.email = email
				request(oobcode_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(password_reset_body))


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
		needs_refresh = true
		yield(get_tree().create_timer(float(expires_in)), "timeout")
		refresh_request_body.refresh_token = refresh_token
		request(refresh_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(refresh_request_body))


# This function is used to make all keys lowercase
# This is only used to cut down on processing errors from Firebase
# This is due to Google have inconsistencies in the API that we are trying to fix
func get_clean_keys(auth_result : Dictionary) -> Dictionary:
		var cleaned = {}
		for key in auth_result.keys():
				cleaned[key.replace("_", "").to_lower()] = auth_result[key]
		return cleaned


# Function called to get all
func get_user_data() -> void:
		if _is_ready():
				is_busy = true
				if auth == null or auth.has("idtoken") == false:
						print_debug("Not logged in")
						is_busy = false
						return
						
				request(userdata_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print({"idToken":auth.idtoken}))


# Function used to delete the account of the currently authenticated user
func delete_user_account() -> void:
		if _is_ready():
				is_busy = true
				request(delete_account_request_url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print({"idToken":auth.idtoken}))


				