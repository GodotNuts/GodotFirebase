# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.4                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will committed #
# ---------------------------------------------------- #

extends Node

const ENVIRONMENT_VARIABLES : String = "firebase/environment_variables/"
onready var Auth : FirebaseAuth = $Auth
onready var Firestore : FirebaseFirestore = $Firestore
onready var Database : FirebaseDatabase = $Database
onready var Storage : FirebaseStorage = $Storage
onready var DynamicLinks : FirebaseDynamicLinks = $DynamicLinks

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
var config : Dictionary = {
    "apiKey": "",
    "authDomain": "",
    "databaseURL": "",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": "",
    "clientId": "",
    "clientSecret": "",
    "domainUriPrefix": "",
    }

func load_config() -> void:
    if ProjectSettings.has_setting(ENVIRONMENT_VARIABLES+"apiKey"):
        for key in config.keys():
            if ProjectSettings.get_setting(ENVIRONMENT_VARIABLES+key)!="":
                config[key] = ProjectSettings.get_setting(ENVIRONMENT_VARIABLES+key)
    else:
        printerr("No configuration settings found, add them in override.cfg file.")

func _ready() -> void:
    load_config()
    Auth.set_config(config)
    Firestore.set_config(config)
    Database.set_config(config)
    Storage.set_config(config)
    DynamicLinks.set_config(config)
    Auth.connect("login_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Database, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", Database, "_on_FirebaseAuth_logout")
    Auth.connect("clear_auth", Database, "_on_firebaseAuth_clear_auth")
    Auth.connect("login_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Firestore, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", Firestore, "_on_FirebaseAuth_logout")
    Auth.connect("clear_auth", Firestore, "_on_firebaseAuth_clear_auth")
    Auth.connect("login_succeeded", Storage, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Storage, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Storage, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", Storage, "_on_FirebaseAuth_logout")
    Auth.connect("clear_auth", Storage, "_on_firebaseAuth_clear_auth")
    Auth.connect("signup_succeeded", DynamicLinks, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", DynamicLinks, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("clear_auth", DynamicLinks, "_on_firebaseAuth_clear_auth")
	Auth.connect("logged_out", DynamicLinks, "_on_FirebaseAuth_logout")
