extends Node

# A FirestoreDocument objects that holds all important values for a Firestore Document,
# @doc_name = name of the Firestore Document, which is the request PATH
# @doc_fields = fields held by Firestore Document, in APIs format
# created when requested from a `collection().get()` call
class_name FirestoreDocument

var document : Dictionary # the Document itself
var doc_fields : Dictionary   # only .fields
var doc_name : String         # only .name

func _init(doc : Dictionary = {}, doc_name : String = "", doc_fields : Dictionary = {}):
    self.document = doc
    self.doc_name = doc_name
    self.doc_fields = (doc_fields)

# Pass a dictionary { 'key' : 'value' } to format it in a APIs usable .fields 
func dict2fields(dict : Dictionary) -> Dictionary:
    var fields : Dictionary = dict
    var var_type : String = ""
    for field in dict.keys():
        match typeof(dict[field]):
            TYPE_NIL:
                var_type = "nullValue"
            TYPE_BOOL:
                var_type = "booleanValue"
            TYPE_INT:
                var_type = "integerValue"
            TYPE_REAL:
                var_type = "doubleValue"
            TYPE_STRING:
                var_type = "stringValue"
            TYPE_ARRAY:
                var_type = "arrayValue"
    
        fields[field] = { var_type : dict[field] }
    return {'fields' : fields}

# Pass the .fields inside a Firestore Document to print out the Dictionary { 'key' : 'value' }
func fields2dict(doc : Dictionary) -> Dictionary:
    var dict : Dictionary = doc.fields
    for field in (doc.fields).keys():
        dict[field] = (doc.fields)[field].values()[0]
    return dict
