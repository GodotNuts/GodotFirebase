class_name FirestoreDocument
extends Node

# A FirestoreDocument objects that holds all important values for a Firestore Document,
# @doc_name = name of the Firestore Document, which is the request PATH
# @doc_fields = fields held by Firestore Document, in APIs format
# created when requested from a `collection().get()` call

var document : Dictionary # the Document itself
var doc_fields : Dictionary   # only .fields
var doc_name : String         # only .name
var create_time : String     # createTime

func _init(doc : Dictionary = {}, _doc_name : String = "", _doc_fields : Dictionary = {}) -> void:
		self.document = doc
		self.doc_name = document.name
		if self.doc_name.count("/") > 2:
			self.doc_name = self.doc_name.substr(self.doc_name.find_last("/")+1, self.doc_name.length())
		self.doc_fields = fields2dict(document)
		self.create_time = doc.createTime

# Pass a dictionary { 'key' : 'value' } to format it in a APIs usable .fields 
static func dict2fields(dict : Dictionary) -> Dictionary:
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
static func fields2dict(doc : Dictionary) -> Dictionary:
		var dict : Dictionary = doc.fields
		for field in (doc.fields).keys():
				dict[field] = (doc.fields)[field].values()[0]
		return dict

# Call print(document) to return directly this document formatted
func _to_string() -> String:
	return ("doc_name: {doc_name}, \ndoc_fields: {doc_fields}, \ncreate_time: {create_time}\n").format(
		{doc_name = self.doc_name, 
		doc_fields = self.doc_fields, 
		create_time = self.create_time})
