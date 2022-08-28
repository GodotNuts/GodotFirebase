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


const _ENVIRONMENT_VARIABLES: String = "firebase/environment_variables"
const _EMULATORS_PORTS: String = "firebase/emulators/ports"
const _AUTH_PROVIDERS: String = "firebase/auth_providers"

## @type FirebaseAuth
## The Firebase Authentication API.
onready var Auth: FirebaseAuth = $Auth

## @type FirebaseFirestore
## The Firebase Firestore API.
onready var Firestore: FirebaseFirestore = $Firestore

## @type FirebaseDatabase
## The Firebase Realtime Database API.
onready var Database: FirebaseDatabase = $Database

## @type FirebaseStorage
## The Firebase Storage API.
onready var Storage: FirebaseStorage = $Storage

## @type FirebaseDynamicLinks
## The Firebase Dynamic Links API.
onready var DynamicLinks: FirebaseDynamicLinks = $DynamicLinks

## @type FirebaseFunctions
## The Firebase Cloud Functions API
onready var Functions: FirebaseFunctions = $Functions

export var emulating: bool = false

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
var _config: Dictionary = {
    "apiKey": "",
    "authDomain": "",
    "databaseURL": "",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": "",
    "measurementId": "",
    "clientId": "",
    "clientSecret": "",
    "domainUriPrefix": "",
    "functionsGeoZone": "",
    "cacheLocation": "user://.firebase_cache",
    "emulators": {
        "ports": {
            "authentication": "",
            "firestore": "",
            "realtimeDatabase": "",
            "functions": "",
            "storage": "",
            "dynamicLinks": ""
        }
    },
    "workarounds": {
        "database_connection_closed_issue": false, # fixes https://github.com/firebase/firebase-tools/issues/3329
    },
    "auth_providers": {
        "facebook_id": "",
        "facebook_secret": "",
        "github_id": "",
        "github_secret": "",
        "twitter_id": "",
        "twitter_secret": ""
    }
}


func _ready() -> void:
    _load_config()


func set_emulated(emulating: bool = true) -> void:
    self.emulating = emulating
    _check_emulating()


func _check_emulating() -> void:
    if emulating:
        print("[Firebase] You are now in 'emulated' mode: the services you are using will try to connect to your local emulators, if available.")
    for module in get_children():
        if module.has_method("_check_emulating"):
            module._check_emulating()


func _load_config() -> void:
    if _config.apiKey != "" and _config.authDomain != "":
        pass
    else:
        var env = ConfigFile.new()
        var err = env.load("res://addons/godot-firebase/.env")
        if err == OK:
            for key in _config.keys():
                if key == "emulators":
                    for port in _config[key]["ports"].keys():
                        _config[key]["ports"][port] = env.get_value(_EMULATORS_PORTS, port, "")
                if key == "auth_providers":
                    for provider in _config[key].keys():
                        _config[key][provider] = env.get_value(_AUTH_PROVIDERS, provider)
                else:
                    var value: String = env.get_value(_ENVIRONMENT_VARIABLES, key, "")
                    if value == "":
                        _print("The value for `%s` is not configured. If you are not planning to use it, ignore this message." % key)
                    else:
                        _config[key] = value
        else:
            _printerr("Unable to read .env file at path 'res://addons/godot-firebase/.env'")

    _setup_modules()


func _setup_modules() -> void:
    for module in get_children():
        module._set_config(_config)
        if not module.has_method("_on_FirebaseAuth_login_succeeded"):
            continue
        Auth.connect("login_succeeded", module, "_on_FirebaseAuth_login_succeeded")
        Auth.connect("signup_succeeded", module, "_on_FirebaseAuth_login_succeeded")
        Auth.connect("token_refresh_succeeded", module, "_on_FirebaseAuth_token_refresh_succeeded")
        Auth.connect("logged_out", module, "_on_FirebaseAuth_logout")


# -------------

func _printerr(error: String) -> void:
    printerr("[Firebase Error] >> " + error)


func _print(msg: String) -> void:
    print("[Firebase] >> " + msg)
