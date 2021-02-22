## @meta-authors TODO
## @meta-version 2.2
## A reference to a Firestore Document.
## Documentation TODO.
tool
class_name FirestoreDocument
extends Reference

# A FirestoreDocument objects that holds all important values for a Firestore Document,
# @doc_name = name of the Firestore Document, which is the request PATH
# @doc_fields = fields held by Firestore Document, in APIs format
# created when requested from a `collection().get()` call

var document : Dictionary       # the Document itself
var doc_fields : Dictionary     # only .fields
var doc_name : String           # only .name
var create_time : String        # createTime

func _init(doc : Dictionary = {}, _doc_name : String = "", _doc_fields : Dictionary = {}) -> void:
    self.document = doc
    self.doc_name = doc.name
    if self.doc_name.count("/") > 2:
        self.doc_name = (self.doc_name.split("/") as Array).back()
    self.doc_fields = fields2dict(self.document)
    self.create_time = doc.createTime

# Pass a dictionary { 'key' : 'value' } to format it in a APIs usable .fields 
static func dict2fields(dict : Dictionary) -> Dictionary:
    var fields : Dictionary = {}
    var var_type : String = ""
    for field in dict.keys():
        var field_value = dict[field]
        match typeof(dict[field]):
            TYPE_NIL: var_type = "nullValue"
            TYPE_BOOL: var_type = "booleanValue"
            TYPE_INT: var_type = "integerValue"
            TYPE_REAL: var_type = "doubleValue"
            TYPE_STRING: var_type = "stringValue"
            TYPE_DICTIONARY: 
                var_type = "mapValue"
                field_value = dict2fields(field_value)
            TYPE_ARRAY:
                var_type = "arrayValue"
                field_value = {"values": array2fields(field_value)}
        fields[field] = { var_type : field_value }
    return {'fields' : fields}

# Pass an Array to parse it to a Firebase arrayValue
static func array2fields(array : Array) -> Array:
    var fields : Array = []
    var var_type : String = ""
    for field in array:
        if typeof(field) == TYPE_DICTIONARY:
            fields.append({'mapValue': dict2fields(field) })
            continue
        match typeof(field):
            TYPE_NIL: var_type = "nullValue"
            TYPE_BOOL: var_type = "booleanValue"
            TYPE_INT: var_type = "integerValue"
            TYPE_REAL: var_type = "doubleValue"
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
                "nullValue":
                    item = null
                _:
                    item = field.values()[0]
            fields.append(item)
    return fields

# Pass the .fields inside a Firestore Document to print out the Dictionary { 'key' : 'value' }
static func fields2dict(doc : Dictionary) -> Dictionary:
    var dict : Dictionary = {}
    if doc.has("fields"):
        for field in (doc.fields).keys():
            if (doc.fields)[field].has("mapValue"):
                dict[field] = fields2dict((doc.fields)[field].mapValue)
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

# Call print(document) to return directly this document formatted
func _to_string() -> String:
    return ("doc_name: {doc_name}, \ndoc_fields: {doc_fields}, \ncreate_time: {create_time}\n").format(
        {doc_name = self.doc_name, 
        doc_fields = self.doc_fields, 
        create_time = self.create_time})
