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


# Pass a dictionary { 'key' : 'value' } to format it in a APIs usable .fields
# Field Path3D using the "dot" (`.`) notation are supported:
# ex. { "PATH.TO.SUBKEY" : "VALUE" } ==> { "PATH" : { "TO" : { "SUBKEY" : "VALUE" } } }
static func dict2fields(dict : Dictionary) -> Dictionary:
	var fields = {}
	var var_type : String = ""
	for field in dict.keys():
		var field_value = dict[field]
		if field is String and "." in field:
			var keys: Array = field.split(".")
			field = keys.pop_front()
			keys.reverse()
			for key in keys:
				field_value = { key : field_value }
		
		match typeof(field_value):
			TYPE_NIL: var_type = "nullValue"
			TYPE_BOOL: var_type = "booleanValue"
			TYPE_INT: var_type = "integerValue"
			TYPE_FLOAT: var_type = "doubleValue"
			TYPE_STRING: var_type = "stringValue"
			TYPE_DICTIONARY:
				if is_field_timestamp(field_value):
					var_type = "timestampValue"
					field_value = dict2timestamp(field_value)
				else:
					var_type = "mapValue"
					field_value = dict2fields(field_value)
			TYPE_ARRAY:
				var_type = "arrayValue"
				field_value = {"values": array2fields(field_value)}
				
		if fields.has(field) and fields[field].has("mapValue") and field_value.has("fields"):
			for key in field_value["fields"].keys():
				fields[field]["mapValue"]["fields"][key] = field_value["fields"][key]
		else:
			fields[field] = { var_type : field_value }
		
	return {'fields' : fields}


class FirebaseTypeConverter extends RefCounted:
	var converters = {
		"nullValue": _to_null,
		"booleanValue": _to_bool,
		"integerValue": _to_int,
		"doubleValue": _to_float,
		"vector2Value": _to_vector2,
		"vector2iValue": _to_vector2i
	}

	func convert_value(type, value):
		if converters.has(type):
			return converters[type].call(value)
		return value

	func _to_null(value):
		return null

	func _to_bool(value):
		return bool(value)

	func _to_int(value):
		return int(value)

	func _to_float(value):
		return float(value)
	
	func _to_vector2(value):
		return str_to_var(value) as Vector2
	
	func _to_vector2i(value):
		return str_to_var(value) as Vector2i

static func from_firebase_type(value):
	if value == null:
		return null

	if value.has("mapValue"):
		value = fields2dict(value.values()[0])
	elif value.has("arrayValue"):
		value = fields2array(value.values()[0])
	elif value.has("timestampValue"):
		value = Time.get_datetime_dict_from_datetime_string(value.values()[0], false)
	else:
		var converter = FirebaseTypeConverter.new()
		var type: String = value.keys()[0]
		value = value.values()[0]
		if type == "stringValue":
			var split_type: String = value.split("(")[0]
			if split_type in [ "Vector2", "Vector2i" ]:
				type = "{0}Value".format([split_type.to_lower()])
		value = converter.convert_value(type, value)

	return value


static func to_firebase_type(value : Variant) -> Dictionary:
	var var_type : String = ""
	
	match typeof(value):
		TYPE_NIL: var_type = "nullValue"
		TYPE_BOOL: var_type = "booleanValue"
		TYPE_INT: var_type = "integerValue"
		TYPE_FLOAT: var_type = "doubleValue"
		TYPE_STRING: var_type = "stringValue"
		TYPE_DICTIONARY:
			if is_field_timestamp(value):
				var_type = "timestampValue"
				value = dict2timestamp(value)
			else:
				var_type = "mapValue"
				value = dict2fields(value)
		TYPE_ARRAY:
			var_type = "arrayValue"
			value = {"values": array2fields(value)}
		TYPE_VECTOR2, TYPE_VECTOR2I:
			var_type = "stringValue"
			value = var_to_str(value)
		
	return { var_type : value }
	
# Pass the .fields inside a Firestore Document to print out the Dictionary { 'key' : 'value' }
static func fields2dict(doc) -> Dictionary:
	var dict = {}
	if doc.has("fields"):
		var fields = doc["fields"]
		
		for field in fields.keys():
			if fields[field].has("mapValue"):
				dict[field] = (fields2dict(fields[field].mapValue))
			elif fields[field].has("timestampValue"):
				dict[field] = timestamp2dict(fields[field].timestampValue)
			elif fields[field].has("arrayValue"):
				dict[field] = fields2array(fields[field].arrayValue)
			elif fields[field].has("integerValue"):
				dict[field] = fields[field].values()[0] as int
			elif fields[field].has("doubleValue"):
				dict[field] = fields[field].values()[0] as float
			elif fields[field].has("booleanValue"):
				dict[field] = fields[field].values()[0] as bool
			elif fields[field].has("nullValue"):
				dict[field] = null
			else:
				dict[field] = fields[field].values()[0]
	return dict

# Pass an Array to parse it to a Firebase arrayValue
static func array2fields(array : Array) -> Array:
	var fields : Array = []
	var var_type : String = ""
	for field in array:
		match typeof(field):
			TYPE_DICTIONARY:
				if is_field_timestamp(field):
					var_type = "timestampValue"
					field = dict2timestamp(field)
				else:
					var_type = "mapValue"
					field = dict2fields(field)
			TYPE_NIL: var_type = "nullValue"
			TYPE_BOOL: var_type = "booleanValue"
			TYPE_INT: var_type = "integerValue"
			TYPE_FLOAT: var_type = "doubleValue"
			TYPE_STRING: var_type = "stringValue"
			TYPE_ARRAY: var_type = "arrayValue"
			_: var_type = "FieldTransform"
		fields.append({ var_type : field })
	return fields

# Pass a Firebase arrayValue Dictionary to convert it back to an Array
static func fields2array(array : Dictionary) -> Array:
	var fields : Array = []
	if array.has("values"):
		for field in array.values:
			var item
			match field.keys()[0]:
				"mapValue":
					item = fields2dict(field.mapValue)
				"arrayValue":
					item = fields2array(field.arrayValue)
				"integerValue":
					item = field.values()[0] as int
				"doubleValue":
					item = field.values()[0] as float
				"booleanValue":
					item = field.values()[0] as bool
				"timestampValue":
					item = timestamp2dict(field.timestampValue)
				"nullValue":
					item = null
				_:
					item = field.values()[0]
			fields.append(item)
	return fields

# Converts a gdscript Dictionary (most likely obtained with Time.get_datetime_dict_from_system()) to a Firebase Timestamp
static func dict2timestamp(dict : Dictionary) -> String:
	#dict.erase('weekday')
	#dict.erase('dst')
	#var dict_values : Array = dict.values()
	var time = Time.get_datetime_string_from_datetime_dict(dict, false)
	return time
	#return "%04d-%02d-%02dT%02d:%02d:%02d.00Z" % dict_values

# Converts a Firebase Timestamp back to a gdscript Dictionary
static func timestamp2dict(timestamp : String) -> Dictionary:
	return Time.get_datetime_dict_from_datetime_string(timestamp, false)
	#var datetime : Dictionary = {year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0}
	#var dict : PackedStringArray = timestamp.split("T")[0].split("-")
	#dict.append_array(timestamp.split("T")[1].split(":"))
	#for value in dict.size():
		#datetime[datetime.keys()[value]] = int(dict[value])
	#return datetime

static func is_field_timestamp(field : Dictionary) -> bool:
	return field.has_all(['year','month','day','hour','minute','second'])


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
		0 : func(): completed.emit(),
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
		0 : func(): completed.emit(),
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

class AwaitDetachable extends Node2D:
	var awaiter : Signal

	func _init(freeable_node, await_signal : Signal) -> void:
		awaiter = await_signal
		add_child(freeable_node)
		awaiter.connect(queue_free)