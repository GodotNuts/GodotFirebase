## An object that contains documentation data about a class.
## @contribute https://placeholder_contribute.com
tool
class_name ClassDocItem
extends DocItem


var base := "" ## The base class this class extends from.
var path := "" ## The file location of this class' script.

var brief := "" ## A brief description of the class.
var description := "" ## A full description of the class.

var methods := [] ## A list of method documents.
var properties := [] ## A list of property documents.
var signals := [] ## A list of signal documents.
var constants := [] ## A list of constant documents, including enumerators.

var tutorials := [] ## A list of tutorials that helps to understand this class.

## @default ""
## A link to where the user can contribute to the class' documentation.
var contriute_url := ""

## @default false
## Whether the class is a singleton.
var is_singleton := false
var icon := "" ## A path to the class icon if any.


func _init(args := {}) -> void:
	for arg in args:
		set(arg, args[arg])


## @args name
## @return MethodDocItem
## Gets a method document called [code]name[/code].
func get_method_doc(name: String) -> MethodDocItem:
	for doc in methods:
		if doc.name == name:
			return doc
	return null


## @args name
## @return PropertyDocItem
## Gets a signal document called [code]name[/code].
func get_property_doc(name: String) -> PropertyDocItem:
	for doc in properties:
		if doc.name == name:
			return doc
	return null


## @args name
## @return SignalDocItem
## Gets a signal document called [code]name[/code].
func get_signal_doc(name: String) -> SignalDocItem:
	for doc in signals:
		if doc.name == name:
			return doc
	return null


## @args name
## @return ConstantlDocItem
## Gets a signal document called [code]name[/code].
func get_constant_doc(name: String) -> ConstantDocItem:
	for doc in constants:
		if doc.name == name:
			return doc
	return null


func _to_string() -> String:
	return "[Class doc: " + name + "]"
