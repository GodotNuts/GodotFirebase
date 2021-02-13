## An object that contains documentation data about an argument of a signal or method.
## @contribute https://placeholder_contribute.com
tool
extends DocItem
class_name ArgumentDocItem

## @default ""
## The default value of the argument.
var default := ""

## @default ""
## The enumeration of [member default].
var enumeration := ""

## @default ""
## The class/built-in type of [member default].
var type := ""

func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])


func _to_string() -> String:
	return "[Argument doc: " + name + "]"
