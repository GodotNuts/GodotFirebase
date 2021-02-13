## @meta-authors SIsilicon
## @meta-version 2.4
## The Firebase Godot API.
## This singleton gives you access to your Firebase project and its capabilities. Using this requires you to fill out some Firebase configuration settings. It currently comes with four modules.
## 	- [code]Auth[/code]: Manages user authentication (logging and out, etc...)
## 	- [code]Database[/code]: A NonSQL realtime database for managing data in JSON structures.
## 	- [code]Firestore[/code]: Similar to Database, but stores data in collections and documents, among other things.
## 	- [code]Storage[/code]: Gives access to Cloud Storage; perfect for storing files like images and other assets.
## 
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki
tool
extends Node

const _ENVIRONMENT_VARIABLES : String = "firebase/environment_variables/"

## @type FirebaseAuth
## The Firebase Authentication API.
onready var Auth : FirebaseAuth = $Auth

## @type FirebaseFirestore
## The Firebase Firestore API.
onready var Firestore : FirebaseFirestore = $Firestore

## @type FirebaseDatabase
## The Firebase Realtime Database API.
onready var Database : FirebaseDatabase = $Database

## @type FirebaseStorage
## The Firebase Storage API.
onready var Storage : FirebaseStorage = $Storage

## @type FirebaseDynamicLinks
## The Firebase Dynamic Links API.
onready var DynamicLinks : FirebaseDynamicLinks = $DynamicLinks

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
var _config : Dictionary = {
    "apiKey": "",
    "authDomain": "",
    "databaseURL":"",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": "",
    "clientId": "",
    "clientSecret": "",
    "domainUriPrefix": "",
}

func _load_config() -> void:
    if ProjectSettings.has_setting(_ENVIRONMENT_VARIABLES+"apiKey"):
        for key in _config.keys():
            if ProjectSettings.get_setting(_ENVIRONMENT_VARIABLES+key)!="":
                _config[key] = ProjectSettings.get_setting(_ENVIRONMENT_VARIABLES+key)
    else:
        print("No configuration settings found, add them in override.cfg file.")

func _ready() -> void:
    _load_config()
    Auth._set_config(_config)
    Firestore._set_config(_config)
    Database._set_config(_config)
    Storage._set_config(_config)
    Auth.connect("login_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Database, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", Database, "_on_FirebaseAuth_logout")
    Auth.connect("login_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Firestore, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", Firestore, "_on_FirebaseAuth_logout")
    Auth.connect("login_succeeded", Storage, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Storage, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Storage, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", Storage, "_on_FirebaseAuth_logout")
    Auth.connect("login_succeeded", DynamicLinks, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", DynamicLinks, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", DynamicLinks, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("logged_out", DynamicLinks, "_on_FirebaseAuth_logout")
