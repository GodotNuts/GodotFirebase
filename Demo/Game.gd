extends Node2D

var allow_processing = false
var handled_keys = {}
var firebase_reference
var firestore_document
var random_color


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
                firebase_reference = Firebase.Database.get_database_reference("testlist/values", { Firebase.Database.LimitToLast: "3" })
                firebase_reference.connect("full_data_update", self, "_on_full_data_update")
                firebase_reference.connect("new_data_update", self, "_on_new_data_update")
                #firestore_document = Firebase.Firestore.collection("AvailableMaps")
    
            firebase_reference.push({"mouse_position": {"x": mouse_pos.x, "y": mouse_pos.y}, "color": color})
            #firestore_document.add("some_random_document_2", null)
        pass

func on_data_returned(data):
    var mouse_pos = data.mouse_position
    $Tween.interpolate_property($Sprite, "global_position", $Sprite.global_position, Vector2(float(mouse_pos.x), float(mouse_pos.y)), 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.interpolate_property($Sprite, "modulate", $Sprite.modulate, Color8(data.color.red, data.color.blue, data.color.green, data.color.alpha), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.start()
    yield($Tween, "tween_completed")

func _on_full_data_update(data):
    if data and data.keys():
        for key in data.keys():
            on_data_returned(data[key])

func _on_new_data_update(data):
    on_data_returned(data)
