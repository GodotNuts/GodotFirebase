tool
extends DocItem
class_name MethodDocItem

## @default ""
## A description of the method.
var description := ""

## @default ""
## The return type of the method.
var return_type := ""

## @default ""
## The enumerator of [member return_type].
var return_enum := ""

## @default []
## A list of arguments the method takes in.
var args := []

## @default false
## Whether the method is to be overriden in an extended class, similar to [Node._ready].
var is_virtual := false


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])


func _to_string() -> String:
	return "[Method doc: " + name + "]"
