extends Node
class_name Utilities

static func get_json_data(value):
	if value is PackedByteArray:
		value = value.get_string_from_utf8()
	var json = JSON.new()
	var json_parse_result = json.parse(value)
	if json_parse_result == OK:
		return json.data
	
	return null


# HTTPRequeust seems to have an issue in Web exports where the body returns empty
# This appears to be caused by the gzip compression being unsupported, so we
# disable it when web export is detected.
static func fix_http_request(http_request):
	if is_web():
		http_request.accept_gzip = false

static func is_web() -> bool:
	return OS.get_name() in ["HTML5", "Web"]
	

class MultiSignal extends RefCounted:
	signal completed(with_signal)
	signal all_completed()

	var _has_signaled := false
	var _early_exit := false

	var signal_count := 0

	func _init(sigs : Array[Signal], early_exit := true, should_oneshot := true) -> void:
		_early_exit = early_exit
		for sig in sigs:
			add_signal(sig, should_oneshot)

	func add_signal(sig : Signal, should_oneshot) -> void:
		signal_count += 1
		sig.connect(
			func():
				if not _has_signaled and _early_exit:
					completed.emit(sig)
					_has_signaled = true
				elif not _early_exit:
					completed.emit(sig)
					signal_count -= 1
					if signal_count <= 0: # Not sure how it could be less than
						all_completed.emit()
		, CONNECT_ONE_SHOT if should_oneshot else CONNECT_REFERENCE_COUNTED
	)
	
class SignalReducer extends RefCounted: # No need for a node, as this deals strictly with signals, which can be on any object.
	signal completed

	var awaiters : Array[Signal] = []

	var reducers = {
		0 : completed.emit,
		1 : func(p): completed.emit(),
		2 : func(p1, p2): completed.emit(),
		3 : func(p1, p2, p3): completed.emit(),
		4 : func(p1, p2, p3, p4): completed.emit()
	}

	func add_signal(sig : Signal, param_count : int = 0) -> void:
		assert(param_count < 5, "Too many parameters to reduce, just add more!")
		sig.connect(reducers[param_count], CONNECT_ONE_SHOT) # May wish to not just one-shot, but instead track all of them firing
		
class SignalReducerWithResult extends RefCounted: # No need for a node, as this deals strictly with signals, which can be on any object.
	signal completed(result)

	var awaiters : Array[Signal] = []

	var reducers = {
		0 : completed.emit,
		1 : func(p): completed.emit({1 : p}),
		2 : func(p1, p2): completed.emit({ 1 : p1, 2 : p2 }),
		3 : func(p1, p2, p3): completed.emit({ 1 : p1, 2 : p2, 3 : p3 }),
		4 : func(p1, p2, p3, p4): completed.emit({ 1 : p1, 2 : p2, 3 : p3, 4 : p4 })
	}

	func add_signal(sig : Signal, param_count : int = 0) -> void:
		assert(param_count < 5, "Too many parameters to reduce, just add more!")
		sig.connect(reducers[param_count], CONNECT_ONE_SHOT) # May wish to not just one-shot, but instead track all of them firing

class ObservableDictionary extends RefCounted:
	signal keys_changed()
	
	var _internal : Dictionary
	var is_notifying := true
	
	func _init(copy : Dictionary = {}) -> void:
		_internal = copy
		
	func add(key : Variant, value : Variant) -> void:
		_internal[key] = value
		if is_notifying:
			keys_changed.emit()
	
	func update(key : Variant, value : Variant) -> void:
		_internal[key] = value
		if is_notifying:
			keys_changed.emit()	
			
	func has(key : Variant) -> bool:
		return _internal.has(key)
	
	func keys():
		return _internal.keys()
		
	func values():
		return _internal.values()
	
	func erase(key : Variant) -> bool:
		var result = _internal.erase(key)
		if is_notifying:
			keys_changed.emit()
		
		return result
	
	func get_value(key : Variant) -> Variant:
		return _internal[key]
		
	func _get(property: StringName) -> Variant:
		if _internal.has(property):
			return _internal[property]
		
		return false
		
	func _set(property: StringName, value: Variant) -> bool:
		update(property, value)
		return true
