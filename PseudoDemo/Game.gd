extends Node2D

var allow_processing = false
var handled_keys = []

func _ready():
    FirebaseAuth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
    FirebaseDatabase.connect("full_data_update", self, "_on_FirebaseDatabase_full_data_update")

func _on_FirebaseAuth_login_succeeded(auth):
    show()
    allow_processing = true
    
func _process(delta):
    if allow_processing:
        if Input.is_action_just_pressed("ui_tapped"):
            var mouse_pos = get_viewport().get_mouse_position()
            FirebaseDatabase.push({"mouse_position": {"x": mouse_pos.x, "y": mouse_pos.y}})
        pass

func on_data_returned(data):
    var mouse_pos = data.mouse_position
    var particles = load("res://SplashParticles.tscn").instance()
    add_child(particles)
    particles.global_position = Vector2(float(mouse_pos.x), float(mouse_pos.y))
    particles.emitting = true

func _on_FirebaseDatabase_full_data_update(data):
    if data and data.keys():
        for key in data.keys():
            if handled_keys.find(key) == -1:
                on_data_returned(data[key])
                handled_keys.append(key)
