## Some brief description.
##
## A longer description. You can use most bbcode stuff in the docs.
## You can [b]bold[/b], [i]italicize[/i], [s]strikethrough[/s],
##
## [codeblock]
## var code = "block"
## [/codeblock]
##
## And so on.
##
## @tutorial https://google.com
## @tutorial https://bing.com
class_name CustomControlThing
extends Control

## @arg-types Object, int
## A custom signal that's never emitted 'cause it's just an example.
signal some_signal(param_a, param_b)

enum Enumerators {
	ENUM_A, ## An enumeration.
	ENUM_B, ## Another enumeration.
	ENUM_C ## And one more enumeration.
}

## This is a constant.
const A_CONST = 10

var foo: Spatial ## This is foo.

## @type int
## This is bar.
var bar

## @enum KeyList
## Some variable that holds an enumeration.
var key := KEY_A

## @args a, b, c
## A method.
func method_a(a, b: int, c: Spatial) -> void:
	pass

## @args d
## @arg-enums Enumerators
## @return-enum Enumerators
## Another method.
func method_b(d: int) -> int:
	return 0

## @virtual
## A virtual method to be overwriiten.
func _virtual_func() -> void:
	pass
