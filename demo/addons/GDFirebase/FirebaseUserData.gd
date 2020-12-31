extends Reference

class_name FirebaseUserData

var local_id := ""            # The uid of the current user.
var email := ""
var email_verified := false   # Whether or not the account's email has been verified.
var password_updated_at := 0  # The timestamp, in milliseconds, that the account password was last changed.
var last_login_at := 0        # The timestamp, in milliseconds, that the account last logged in at.
var created_at := 0           # The timestamp, in milliseconds, that the account was created at.

func _init(p_userdata):
    local_id = p_userdata.localId
    email = p_userdata.email
    email_verified = p_userdata.emailVerified
    password_updated_at = int(p_userdata.passwordUpdatedAt)
    last_login_at = int(p_userdata.lastLoginAt)
    created_at = int(p_userdata.createdAt)

func as_text()->String:
    var txt = "local_id : %s\n" % local_id
    txt += "email : %s\n" % email
    txt += "email_verified : %s\n" % ("true" if email_verified else "false")
    txt += "password_updated_at : %d\n" % password_updated_at
    txt += "last_login_at : %d\n" % last_login_at
    txt += "created_at : %d\n" % created_at
    return txt