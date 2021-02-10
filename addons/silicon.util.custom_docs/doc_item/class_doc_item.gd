## An object that contains documentation data about a class.
## @contribute https://placeholder_contribute.com
tool
extends DocItem
class_name ClassDocItem

## @default ""
## The base class this class extends from.
var base := ""

## @default ""
## A brief description of the class.
var brief := ""

## @default ""
## A full description of the class.
var description := ""

## @default []
## A list of method documents.
var methods := []

## @default []
## A list of property documents.
var properties := []

## @default []
## A list of signal documents.
var signals := []

## @default []
## A list of constant documents, including enumerators.
var constants := []

## @default []
## A list of tutorials that helps to understand this class.
var tutorials := []

## @default ""
## A link to where the user can contribute to the class' documentation.
var contriute_url := ""

## @default false
## Whether the class is a singleton.
var is_singleton := false

## @default ""
## A path to the class icon if any.
var icon := ""

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
