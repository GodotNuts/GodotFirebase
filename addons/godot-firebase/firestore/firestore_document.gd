## @meta-authors TODO
## @meta-version 2.2
## A reference to a Firestore Document.
## Documentation TODO.
@tool
class_name FirestoreDocument
extends RefCounted

# A FirestoreDocument objects that holds all important values for a Firestore Document,
# @doc_name = name of the Firestore Document, which is the request PATH
# @doc_fields = fields held by Firestore Document, in APIs format
# created when requested from a `collection().get()` call

var document : Dictionary       # the Document itself
var doc_fields : Dictionary     # only .fields
var doc_name : String           # only .name
var create_time : String        # createTime

func _init(doc : Dictionary = {},_doc_name : String = "",_doc_fields : Dictionary = {}):
    self.document = doc
    self.doc_name = doc.name
    if self.doc_name.count("/") > 2:
        self.doc_name = (self.doc_name.split("/") as Array).back()
    self.doc_fields = fields2dict(self.document)
    self.create_time = doc.createTime

# Pass a dictionary { 'key' : 'value' } to format it in a APIs usable .fields
# Field Path3D using the "dot" (`.`) notation are supported:
# ex. { "PATH.TO.SUBKEY" : "VALUE" } ==> { "PATH" : { "TO" : { "SUBKEY" : "VALUE" } } }
static func dict2fields(dict : Dictionary) -> Dictionary:
    var fields : Dictionary = {}
    var var_type : String = ""
    for field in dict.keys():
        var field_value = dict[field]
        if "." in field:
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

# Pass the .fields inside a Firestore Document to print out the Dictionary { 'key' : 'value' }
static func fields2dict(doc : Dictionary) -> Dictionary:
    var dict : Dictionary = {}
    if doc.has("fields"):
        for field in (doc.fields).keys():
            if (doc.fields)[field].has("mapValue"):
                dict[field] = fields2dict((doc.fields)[field].mapValue)
            elif (doc.fields)[field].has("timestampValue"):
                dict[field] = timestamp2dict((doc.fields)[field].timestampValue)
            elif (doc.fields)[field].has("arrayValue"):
                dict[field] = fields2array((doc.fields)[field].arrayValue)
            elif (doc.fields)[field].has("integerValue"):
                dict[field] = (doc.fields)[field].values()[0] as int
            elif (doc.fields)[field].has("doubleValue"):
                dict[field] = (doc.fields)[field].values()[0] as float
            elif (doc.fields)[field].has("booleanValue"):
                dict[field] = (doc.fields)[field].values()[0] as bool
            elif (doc.fields)[field].has("nullValue"):
                dict[field] = null
            else:
                dict[field] = (doc.fields)[field].values()[0]
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
    dict.erase('weekday')
    dict.erase('dst')
    var dict_values : Array = dict.values()
    return "%04d-%02d-%02dT%02d:%02d:%02d.00Z" % dict_values

# Converts a Firebase Timestamp back to a gdscript Dictionary
static func timestamp2dict(timestamp : String) -> Dictionary:
    var datetime : Dictionary = {year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0}
    var dict : PackedStringArray = timestamp.split("T")[0].split("-")
    dict.append_array(timestamp.split("T")[1].split(":"))
    for value in dict.size() :
        datetime[datetime.keys()[value]] = int(dict[value])
    return datetime

static func is_field_timestamp(field : Dictionary) -> bool:
    return field.has_all(['year','month','day','hour','minute','second'])

# Call print(document) to return directly this document formatted
func _to_string() -> String:
    return ("doc_name: {doc_name}, \ndoc_fields: {doc_fields}, \ncreate_time: {create_time}\n").format(
        {doc_name = self.doc_name,
        doc_fields = self.doc_fields,
        create_time = self.create_time})
