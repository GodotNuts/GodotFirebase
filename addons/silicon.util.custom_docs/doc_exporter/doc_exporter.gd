## The base class for every document exporter.
## @contribute https://placeholder_contribute.com
tool
class_name DocExporter
extends Reference


## @virtual
## @args doc
## @arg-types ClassDocItem
## This function gets called to generate a document string from a [ClassDocItem].
func _generate(doc: ClassDocItem) -> String:
	return ""
