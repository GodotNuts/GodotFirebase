extends Node2D

var allow_processing = false
var handled_keys = {}
var firebase_reference
var firestore_document
var random_color
var mouse_tapped_key


func _ready():
    randomize()
    random_color = Color8(randi() % 255, randi() % 255, randi() % 255)
    Firebase.Auth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")

func _on_FirebaseAuth_login_succeeded(auth):
    show()
    
    allow_processing = true
    
func _process(delta):
    if allow_processing:
        if Input.is_action_just_pressed("ui_tapped"):
            var mouse_pos = get_viewport().get_mouse_position()
            var color = {
                "red": random_color.r8,
                "blue": random_color.b8,
                "green": random_color.g8,
                "alpha": random_color.a8
               }
            if !firebase_reference:
                firebase_reference = Firebase.Database.get_database_reference("testlist/values", { })
                firebase_reference.connect("new_data_update", self, "_on_new_data_update")
            if mouse_tapped_key and allow_processing:
                firebase_reference.update(mouse_tapped_key, {"mouse_position": var2str(mouse_pos), "color": color})
            else:
                allow_processing = true
                firebase_reference.push({"mouse_position": var2str(mouse_pos), "color": color})

func on_data_returned(data):
    var mouse_pos = str2var(data.mouse_position)
    $Tween.interpolate_property($Sprite, "global_position", $Sprite.global_position, mouse_pos, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.interpolate_property($Sprite, "modulate", $Sprite.modulate, Color8(data.color.red, data.color.blue, data.color.green, data.color.alpha), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.start()
    yield($Tween, "tween_completed")

func _on_full_data_update(data):
    if data.data and data.data.keys():
        for key in data.data.keys():
            on_data_returned(data.data[key])

func _on_new_data_update(data):
    on_data_returned(data.data)
