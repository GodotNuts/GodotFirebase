## An object that contains documentation data about an argument of a signal or method.
## @contribute https://placeholder_contribute.com
tool
extends DocItem
class_name ArgumentDocItem

var default := "" ## The default value of the argument.
var enumeration := "" ## The enumeration of [member default].

var type := "" ## The class/built-in type of [member default].


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])
