tool
class_name FirestoreTransaction
extends Reference

var _transaction_id

var _document
var _fields = {}

const FieldsReplacement = "###writes###"
const TransactionReplacement = "###transaction###"

const body_format = """{writes: [
	{
	  ###writes###
	}
  ],
  transaction: ###transaction###}"""

func _init(doc, id) -> void:
	_document = doc
	_transaction_id = id

func commit(transaction_id : String) -> void:
	var body = body_format.replace(FieldsReplacement, _document.dict2fields_(_fields))
	body.replace(TransactionReplacement, transaction_id)


func add_write(key : String, value : String) -> void:
	assert(key)
	_fields[key] = value
