tool
extends "res://addons/GDFirebase/FirebaseContainer.gd"

export (float) var Radius setget set_radius
export (float) var OffsetInRadians setget set_offset

func set_radius(value):
    if value:
        Radius = value
        layout_all_children()

func set_offset(value):
    if value:
        OffsetInRadians = value
        layout_all_children()

var tween

func _ready():
    tween = get_parent().get_node("Tween")

func add_child(node : Node, legible_unique_name := false):
    .add_child(node, legible_unique_name)
    layout_all_children()
    pass
    
func remove_child(node: Node):
    .remove_child(node)
    layout_all_children()
    
func layout_all_children():
    var child_count = get_child_count()
    if child_count > 0:
        var current_angle_amount = deg2rad(360.0 / child_count)
        for idx in child_count:
            var child = get_child(idx)
            var current_angle = (current_angle_amount * idx) + OffsetInRadians
            var cart = polar2cartesian(Radius, current_angle)
            if child.rect_global_position == rect_global_position:
                child.rect_global_position = ((rect_global_position + rect_size) / 2.0)
            var new_pos = cart + ((rect_global_position + rect_size) / 2.0)
            tween.interpolate_property(child, "rect_global_position", child.rect_global_position, new_pos, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 2.0)
            tween.start()