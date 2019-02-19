extends VBoxContainer

var tok = null

func _on_FirebaseDatabase_full_data_update(data):
    #$Label.text = str(data)
    pass

func _on_FirebaseAuth_login_succeeded(token):
    tok = token
    show()
