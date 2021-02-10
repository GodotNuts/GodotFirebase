# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.4                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

## @meta-authors SIsilicon
## @meta-version 2.4
## The Firebase Godot API
## Description W.I.P.
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
    "clientId": "",
    "clientSecret": "",
}

func _load_config() -> void:
    if ProjectSettings.has_setting(_ENVIRONMENT_VARIABLES+"apiKey"):
        for key in _config.keys():
            if ProjectSettings.get_setting(_ENVIRONMENT_VARIABLES+key)!="":
                _config[key] = ProjectSettings.get_setting(_ENVIRONMENT_VARIABLES+key)
    else:
        printerr("No configuration settings found, add them in override.cfg file.")

func _ready() -> void:
    _load_config()
    Auth._set_config(_config)
    Firestore._set_config(_config)
    Database._set_config(_config)
    Storage._set_config(_config)
    Auth.connect("login_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Database, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("login_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Firestore, "_on_FirebaseAuth_token_refresh_succeeded")
    Auth.connect("login_succeeded", Storage, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("signup_succeeded", Storage, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("token_refresh_succeeded", Storage, "_on_FirebaseAuth_token_refresh_succeeded")
