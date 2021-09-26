## @meta-authors Kyle Szklenski
## @meta-version 2.5
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

const _ENVIRONMENT_VARIABLES : String = "firebase/environment_variables"

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

## @type FirebaseFunctions
## The Firebase Cloud Functions API
onready var Functions : FirebaseFunctions = $Functions

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
var _config : Dictionary = {
    "apiKey": "",
    "authDomain": "",
    "databaseURL": "",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": "",
    "measurementId": "",
    "clientId": "",
    "clientSecret" : "",
    "domainUriPrefix" : "",
    "functionsBaseUrl" : "",
    "cacheLocation":"user://.firebase_cache"
}

func _ready() -> void:
    _load_config()
    for module in get_children():
        module._set_config(_config)
        if not module.has_method("_on_FirebaseAuth_login_succeeded"):
            continue
        Auth.connect("login_succeeded", module, "_on_FirebaseAuth_login_succeeded")
        Auth.connect("signup_succeeded", module, "_on_FirebaseAuth_login_succeeded")
        Auth.connect("token_refresh_succeeded", module, "_on_FirebaseAuth_token_refresh_succeeded")
        Auth.connect("logged_out", module, "_on_FirebaseAuth_logout")

func _load_config() -> void:
    if _config.apiKey != "" and _config.authDomain != "":
        return
    else:    
        var env = ConfigFile.new()
        var err = env.load("res://addons/godot-firebase/.env")
        if err == OK:
            for key in _config.keys(): 
                var value : String = env.get_value(_ENVIRONMENT_VARIABLES, key, "")
                if value == "":
                    printerr("The value for %s is invalid." % key)
                else:
                    _config[key] = value
        else:
            printerr("Unable to read .env file at path 'res://addons/godot-firebase/.env'")

func _printerr(error : String) -> void:
    print("[Firebase Error] >> "+error)
