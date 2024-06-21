extends Node
class_name Utilities

static func get_json_data(value):
	if value is PoolByteArray:
		value = value.get_string_from_utf8()
	var json_parse_result = JSON.parse(value)
	if json_parse_result.error == OK:
		return json_parse_result.result

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
			keys.invert()
			for key in keys:
				field_value = { key : field_value }

		match typeof(field_value):
			TYPE_NIL: var_type = "nullValue"
			TYPE_BOOL: var_type = "booleanValue"
			TYPE_INT: var_type = "integerValue"
			TYPE_REAL: var_type = "doubleValue"
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
		value = value.values()[0]

	return value

static func to_firebase_type(value) -> Dictionary:
	var var_type : String = ""

	match typeof(value):
		TYPE_NIL: var_type = "nullValue"
		TYPE_BOOL: var_type = "booleanValue"
		TYPE_INT: var_type = "integerValue"
		TYPE_REAL: var_type = "doubleValue"
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
			TYPE_REAL: var_type = "doubleValue"
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


class MultiSignal extends Reference:
	signal completed(sig)

	func add_signal(obj, sig : String):
		obj.connect(sig, self, "_on_object_signaled", [sig], CONNECT_ONESHOT)

	func _on_object_signaled(sig : String) -> void:
		emit_signal("completed", sig)

class SignalReducer extends Reference:
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

class SignalReducerWithResult extends Reference:
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

class ObservableDictionary extends Reference:
	signal keys_changed()

	var _internal : Dictionary
	var is_notifying := true

	func _init(copy : Dictionary = {}) -> void:
		_internal = copy

	func add(key, value) -> void:
		_internal[key] = value
		if is_notifying:
			emit_signal("keys_changed")

	func update(key, value) -> void:
		_internal[key] = value
		if is_notifying:
			emit_signal("keys_changed")

	func has(key) -> bool:
		return _internal.has(key)

	func keys():
		return _internal.keys()

	func values():
		return _internal.values()

	func erase(key) -> bool:
		var result = _internal.erase(key)
		if is_notifying:
			emit_signal("keys_changed")

		return result

	func get_value(key):
		return _internal[key]

	func _get(property: String):
		if _internal.has(property):
			return _internal[property]

		return false

	func _set(property: String, value) -> bool:
		update(property, value)
		return true

class AwaitDetachable extends Node2D:
	var awaiter : String

	func _init(freeable_node, await_signal : String) -> void:
		awaiter = await_signal
		add_child(freeable_node)
		freeable_node.connect(await_signal, self, "queue_free", [], CONNECT_ONESHOT)
