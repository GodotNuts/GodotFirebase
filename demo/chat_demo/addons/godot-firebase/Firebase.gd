extends Node

const ENVIRONMENT_VARIABLES : String = "firebase/environment_variables/"
onready var Auth = $Auth
onready var Firestore = $Firestore
onready var Database = $Database

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
var config = {  
    "apiKey": "",
    "authDomain": "",
    "databaseURL": "",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": "",
    "measurementId": "",
    }

func load_config():
    if ProjectSettings.has_setting(ENVIRONMENT_VARIABLES+"apiKey"):
        for key in config.keys():
            config[key] = ProjectSettings.get_setting(ENVIRONMENT_VARIABLES+key)
    else:
        printerr("No configuration settings found, add them in override.cfg file.")

func _ready():
    load_config()
    Auth.set_config(config)
    Firestore.set_config(config)
    Database.set_config(config)
    Auth.connect("login_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("login_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")
