## @meta-authors TODO
## @meta-version 2.3
## Authentication user data.
## Documentation TODO.
tool
class_name FirebaseUserData
extends Reference

var local_id : String = ""           # The uid of the current user.
var email : String = ""
var email_verified := false          # Whether or not the account's email has been verified.
var password_updated_at : float = 0  # The timestamp, in milliseconds, that the account password was last changed.
var last_login_at : float = 0        # The timestamp, in milliseconds, that the account last logged in at.
var created_at : float = 0           # The timestamp, in milliseconds, that the account was created at.
var provider_user_info : Array = []

var provider_id : String = ""
var display_name : String = ""
var photo_url : String = ""

func _init(p_userdata : Dictionary) ->  void:
	local_id = p_userdata.get("localId", "")
	email = p_userdata.get("email", "")
	email_verified = p_userdata.get("emailVerified", false)
	last_login_at = float(p_userdata.get("lastLoginAt", 0))
	created_at = float(p_userdata.get("createdAt", 0))
	password_updated_at = float(p_userdata.get("passwordUpdatedAt", 0))
	display_name = p_userdata.get("displayName", "")
	provider_user_info = p_userdata.get("providerUserInfo", [])
	if not provider_user_info.empty():
		provider_id = provider_user_info[0].get("providerId", "")
		photo_url = provider_user_info[0].get("photoUrl", "")
		display_name = provider_user_info[0].get("displayName", "")

func as_text() -> String:
	return _to_string()

func _to_string() -> String:
	var txt = "local_id : %s\n" % local_id
	txt += "email : %s\n" % email
	txt += "last_login_at : %d\n" % last_login_at
	txt += "provider_id : %s\n" % provider_id
	txt += "display name : %s\n" % display_name
	return txt
