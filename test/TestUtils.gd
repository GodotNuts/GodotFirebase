class_name TestUtils
extends Object

static func instantiate(clazz: Script) -> Node:
	var o = Node.new()
	
	o.set_script(clazz)
	
	return o
