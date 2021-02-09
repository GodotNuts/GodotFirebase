## An object that contains documentation data about a signal.
## @contribute https://placeholder_contribute.com
tool
extends DocItem
class_name SignalDocItem

var description := "" ## A description of the signal.

var args := [] ## A list of arguments the signal carries.


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])
