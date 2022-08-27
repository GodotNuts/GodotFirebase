## An object that contains documentation data about a signal.
## @contribute https://placeholder_contribute.com
tool
class_name SignalDocItem
extends DocItem


## @default ""
## A description of the signal.
var description := ""

## @default []
## A list of arguments the signal carries.
var args := []


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])
