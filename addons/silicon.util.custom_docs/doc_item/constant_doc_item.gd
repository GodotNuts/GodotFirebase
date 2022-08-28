## An object that contains documentation data about a constant.
## @contribute https://placeholder_contribute.com
tool
class_name ConstantDocItem
extends DocItem


## @default ""
## A description of the constant.
var description := ""

## @default ""
## The value of the constant in a string form.
var value := ""

## @default ""
## The [member value]'s enumeration.
var enumeration := ""


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])


func _to_string() -> String:
	return "[Constant doc: " + name + "]"
