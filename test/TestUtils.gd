class_name TestUtils
extends Object


static func instantiate(script: Script) -> Node:
    var o = Node.new()
    o.set_script(script)
    return o
