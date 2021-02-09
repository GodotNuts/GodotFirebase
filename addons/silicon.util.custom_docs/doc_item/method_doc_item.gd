tool
extends DocItem
class_name MethodDocItem

var description := "" ## A description of the method.

var return_type := "" ## The return type of the method.
var return_enum := "" ## The enumerator of [member return_type].

var args := [] ## A list of arguments the method takes in.
var is_virtual := false ## Whether the method is to be overriden in an extended class, similar to [Node._ready].


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])
