extends VBoxContainer

signal chat_added

var chatbox = load("res://ChatBox.tscn")

var listener

func _ready():
    Firebase.Auth.connect("login_succeeded", self, "on_login_success")
    
func on_login_success(auth_ref):
    listener = Firebase.Database.get_database_reference("game/chat", { })
    listener.connect("full_data_update", self, "on_received_chat")
    listener.connect("patch_data_update", self, "on_received_updated_chat")
    listener.connect("new_data_update", self, "on_received_new_chat")
    
func add_chat(name : String, text : String):
    var new_chat = chatbox.instance()
    new_chat.user_name = name + ": "
    new_chat.text = text
    add_child(new_chat)
    emit_signal("chat_added")
    
func on_received_chat(data):
    if data:
        for key in data.keys():                
            var chat = data[key]
            add_chat(chat.user_name, chat.text)
    
func on_received_new_chat(data):
    if data:            
        add_chat(data.user_name, data.text)
func on_received_updated_chat(path, data):
    if data:            
        add_chat(data.user_name, data.text)