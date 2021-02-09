## An object that contains documentation data about a property.
## @contribute https://placeholder_contribute.com
tool
extends DocItem
class_name PropertyDocItem

var description := "" ## A description of the property.

var default :=  "" ## The default of the property in string form.
var enumeration := "" ## The enumeration of [member default].
var type := "" ## The class/built-in type of [member default].

var setter := "" ## The setter method of the property.
var getter := "" ## The getter method of the property.

func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])
