extends Node

var ROOMS_DATABASE = "rooms"

var collection
var room_code

onready var timer = $Timer

signal authenticated()
signal room_updated(info)

# Called when the node enters the scene tree for the first time.
func _ready():
    Firebase.Auth.connect("signup_succeeded", self, "_create_game")
    Firebase.Auth.connect("login_succeeded", self, "_create_game")
    Firebase.Auth.connect("login_failed", self, "_on_auth_error")
    Firebase.Auth.login_anonymous()

func _create_room_code(length):
    randomize()
    var result           = ''	
    var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    var charactersLength = characters.length()
    for _i in range(length):
        result += characters[floor(rand_range(0, charactersLength))]
    return result;

func _create_game(auth_result : Dictionary):
    emit_signal("authenticated")
    
    collection = Firebase.Firestore.collection(ROOMS_DATABASE)
    collection.connect("error", self, "_on_network_error")
    
    room_code = _create_room_code(4)
    var room_information = {
        "code": room_code,
        "players": []
    }

    collection.add(room_code, room_information)
    var document : FirestoreDocument = yield(collection, "add_document")	
    print("Created room of code: ", room_code)
    
    timer.start()

func _on_auth_error(code, msg):
    print("Authentication error encountered. Code: ", code, " MSG: ", msg)

func _on_network_error(code, status, msg):
    print("Network error encountered. Code: ", code, " Status: ", status, " MSG: ", msg)

func _on_Timer_timeout():
    collection.get(room_code)
    var document : FirestoreDocument = yield(collection, "get_document")
    var room_information = document['doc_fields']
    emit_signal("room_updated", room_information)
