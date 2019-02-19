extends VBoxContainer

signal chat_added

var chatbox = load("res://ChatBox.tscn")
var handled_ids = {}

var listener

func _ready():
    Firebase.Auth.connect("login_succeeded", self, "on_login_success")
    
func on_login_success(auth_ref):
    listener = Firebase.Database.get_database_reference("game/chat", { })
    listener.connect("full_data_update", self, "on_received_chat")
    listener.connect("patch_data_update", self, "on_received_chat")
    listener.connect("new_data_update", self, "on_received_chat")
    
func add_chat(name : String, text : String):
    var new_chat = chatbox.instance()
    new_chat.user_name = name + ": "
    new_chat.text = text
    add_child(new_chat)
    emit_signal("chat_added")
    
    
func on_received_chat(data):
    if data:
        for key in data.keys():
            if handled_ids.has(key):
                continue
                
            handled_ids[key] = true
            var chat = data[key]
            add_chat(chat.user_name, chat.text)
        pass