## An object that contains documentation data about a property.
## @contribute https://placeholder_contribute.com
tool
class_name PropertyDocItem
extends DocItem


## @default ""
## A description of the property.
var description := ""

## @default ""
## The default of the property in string form.
var default := ""

## @default ""
## The enumeration of [member default].
var enumeration := ""

## @default ""
## The class/built-in type of [member default].
var type := ""

## @default ""
## The setter method of the property.
var setter := ""

## @default ""
## The getter method of the property.
var getter := ""


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])


func _to_string() -> String:
	return "[Property doc: " + name + "]"
