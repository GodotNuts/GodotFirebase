extends Reference
class_name Utilities

class MultiAwaitSignal extends Reference:
	signal completed(sig)

	func add_signal(obj, sig : String):
		obj.connect(sig, self, "_on_object_signaled", [sig], CONNECT_ONESHOT)

	func _on_object_signaled(sig : String) -> void:
		emit_signal("completed", sig)

class MultiAwaitSignalWithResults extends Reference:
	signal completed(results, sig)

	func add_signal(obj, sig : String):
		obj.connect(sig, self, "_on_object_signaled", [sig], CONNECT_ONESHOT)

	func _on_object_signaled(results, sig : String) -> void:
		emit_signal("completed", results, sig)

class SignalParamReducer extends Reference:
	signal completed()

	var _map = {
		0: "_zero",
		1: "_one",
		2: "_two",
		3: "_three",
		4: "_four",
		5: "_five"
	}

	func _init(obj, sig : String, param_count : int) -> void:
		obj.connect(sig, self, _map[param_count], [], CONNECT_ONESHOT)

	func _zero():
		emit_signal("completed")

	func _one(p1):
		emit_signal("completed")

	func _two(p1, p2):
		emit_signal("completed")

	func _three(p1, p2, p3):
		emit_signal("completed")

	func _four(p1, p2, p3, p4):
		emit_signal("completed")

	func _five(p1, p2, p3, p4, p5):
		emit_signal("completed")

class SignalParamReducerWithResults extends Reference:
	signal completed(results)

	var _map = {
		0: "_zero",
		1: "_one",
		2: "_two",
		3: "_three",
		4: "_four",
		5: "_five"
	}

	func _init(obj, sig : String, param_count : int) -> void:
		obj.connect(sig, self, _map[param_count], [], CONNECT_ONESHOT)

	func _zero():
		emit_signal("completed")

	func _one(p1):
		emit_signal("completed", { "1": p1 })

	func _two(p1, p2):
		emit_signal("completed", {"1": p1, "2": p2})

	func _three(p1, p2, p3):
		emit_signal("completed", {"1": p1, "2": p2, "3": p3})

	func _four(p1, p2, p3, p4):
		emit_signal("completed", {"1": p1, "2": p2, "3": p3, "4": p4})

	func _five(p1, p2, p3, p4, p5):
		emit_signal("completed", {"1": p1, "2": p2, "3": p3, "4": p4, "5": p5})
