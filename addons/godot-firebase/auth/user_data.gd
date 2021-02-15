## @meta-authors TODO
## @meta-version 2.2
## Authentication user data.
## Documentation TODO.
tool
class_name FirebaseUserData
extends Reference

var local_id : String = ""            # The uid of the current user.
var email : String = ""
var email_verified := false   # Whether or not the account's email has been verified.
var password_updated_at : float = 0  # The timestamp, in milliseconds, that the account password was last changed.
var last_login_at : float = 0        # The timestamp, in milliseconds, that the account last logged in at.
var created_at : float = 0           # The timestamp, in milliseconds, that the account was created at.
var provider_user_info : Array = []

var provider_id : String = ""
var display_name : String = ""
var photo_url : String = ""

func _init(p_userdata : Dictionary) ->  void:
    local_id = p_userdata.localId
    email = p_userdata.email
    email_verified = p_userdata.emailVerified
    last_login_at = int(p_userdata.lastLoginAt)
    created_at = int(p_userdata.createdAt)
    if p_userdata.has("passwordUpdatedAt"):
        password_updated_at = int(p_userdata.passwordUpdatedAt)
    if p_userdata.has("displayName"):
        display_name = p_userdata.displayName
    provider_user_info = p_userdata.providerUserInfo
    if not provider_user_info.empty():
        provider_id = provider_user_info[0].providerId
        if provider_user_info.has("photoUrl"):
            photo_url = provider_user_info[0].photoUrl
        if provider_user_info.has("displayName"):
            display_name = provider_user_info[0].displayName

func as_text() -> String:
    return _to_string()

func _to_string() -> String:
    var txt = "local_id : %s\n" % local_id
    txt += "email : %s\n" % email
    txt += "email_verified : %s\n" % ("true" if email_verified else "false")
    txt += "password_updated_at : %d\n" % password_updated_at
    txt += "last_login_at : %d\n" % last_login_at
    txt += "created_at : %d\n" % created_at
    
    txt += "provider_id : %s\n" % provider_id
    txt += "display name : %s\n" % display_name
    txt += "photo url : %s\n" % photo_url
    return txt

