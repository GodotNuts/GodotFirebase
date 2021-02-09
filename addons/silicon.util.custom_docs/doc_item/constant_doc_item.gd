## An object that contains documentation data about a constant.
## @contribute https://placeholder_contribute.com
tool
extends DocItem
class_name ConstantDocItem

var description := "" ## A description of the constant.

var value := "" ## The value of the constant in a string form.
var enumeration := "" ## The [member value]'s enumeration/


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])
