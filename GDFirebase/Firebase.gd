extends Node

onready var Auth = HTTPRequest.new()
onready var Database = Node.new()

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
onready var config = {
    "apiKey": "",
    "authDomain": "",
    "databaseURL": "",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": ""
  }

func _ready():
    Auth.set_script(preload("res://addons/GDFirebase/FirebaseAuth.gd"))
    Database.set_script(preload("res://addons/GDFirebase/FirebaseDatabase.gd"))
    Auth.set_config(config)
    Database.set_config(config)
    add_child(Auth)
    add_child(Database)
    Auth.connect("login_succeeded", Database, "_on_FirebaseAuth_login_succeeded")