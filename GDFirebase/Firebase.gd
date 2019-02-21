extends Node

onready var Auth = HTTPRequest.new()
onready var Database = Node.new()
onready var Firestore = Node.new()

func _ready():
    Auth.set_script(preload("res://addons/GDFirebase/FirebaseAuth.gd"))
    Database.set_script(preload("res://addons/GDFirebase/FirebaseDatabase.gd"))
    Firestore.set_script(preload("res://addons/GDFirebase/FirebaseFirestore.gd"))
    add_child(Auth)
    add_child(Database)
    add_child(Firestore)
    Auth.connect("login_succeeded", Database, "_on_FirebaseAuth_login_succeeded")
    Auth.connect("login_succeeded", Firestore, "_on_FirebaseAuth_login_succeeded")