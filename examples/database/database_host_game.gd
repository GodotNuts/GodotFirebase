extends Node

var db_ref : FirebaseDatabaseReference 

signal authenticated()
signal room_updated(info)

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
    var room_code = _create_room_code(4)
        
    var rooms_ref : FirebaseDatabaseReference = Firebase.Database.get_database_reference("/rooms/", {})
    rooms_ref.connect("push_successful", self, "_connect_to_room", [room_code])
    
    rooms_ref.update(room_code, {
        "code": room_code,
    })
    
func _connect_to_room(room_code):
    db_ref = Firebase.Database.get_database_reference("/rooms/" + room_code, {})
    db_ref.connect("new_data_update", self, "_updated_data")
    db_ref.connect("patch_data_update", self, "_updated_data")

func _updated_data(data):
    var info = db_ref.get_data()
    emit_signal("room_updated", info)
    
func _on_auth_error(code, msg):
    print("Authentication errror encountered. Code: ", code, " MSG: ", msg)
