## @meta-authors Nicoló 'fenix' Santilio
## @meta-version 1.4
## A firestore query.
## Documentation TODO.
tool
extends Reference
class_name FirestoreQuery

class Order:
    var obj : Dictionary

class Cursor:
    var values : Array
    var before : bool

    func _init(v : Array, b : bool):
        values = v
        before = b

signal query_result(query_result)

const TEMPLATE_QUERY : Dictionary = {
    select = {},
    from = [],
    where = {},
    orderBy = [],
    startAt = {},
    endAt = {},
    offset = 0,
    limit = 0
   }

var query : Dictionary = {}

enum OPERATOR {
    # Standard operators
    OPERATOR_NSPECIFIED,
    LESS_THAN,
    LESS_THAN_OR_EQUAL,
    GREATER_THAN,
    GREATER_THAN_OR_EQUAL,
    EQUAL,
    NOT_EQUAL,
    ARRAY_CONTAINS,
    ARRAY_CONTAINS_ANY,
    IN,
    NOT_IN,

    # Unary operators
    IS_NAN,
    IS_NULL,
    IS_NOT_NAN,
    IS_NOT_NULL,

    # Complex operators
    AND,
    OR
   }

enum DIRECTION {
    DIRECTION_UNSPECIFIED,
    ASCENDING,
    DESCENDING
   }

func _init():
    return self


# Select which fields you want to return as a reflection from your query.
# Fields must be added inside a list. Only a field is accepted inside the list
# Leave the Array empty if you want to return the whole document
func select(fields) -> FirestoreQuery:
    match typeof(fields):
        TYPE_STRING:
            query["select"] = { fields = { fieldPath = fields } }
        TYPE_ARRAY:
            for field in fields:
                field = ({ fieldPath = field })
            query["select"] = { fields = fields }
        _:
            print("Type of 'fields' is not accepted.")
    return self



# Select the collection you want to return the query result from
# if @all_descendants also sub-collections will be returned. If false, only documents will be returned
func from(collection_id : String, all_descendants : bool = true) -> FirestoreQuery:
    query["from"] = [{collectionId = collection_id, allDescendants = all_descendants}]
    return self



# @collections_array MUST be an Array of Arrays with this structure
# [ ["collection_id", true/false] ]
func from_many(collections_array : Array) -> FirestoreQuery:
    var collections : Array = []
    for collection in collections_array:
        collections.append({collectionId = collection[0], allDescendants = collection[1]})
    query["from"] = collections.duplicate(true)
    return self


# Query the value of a field you want to match
# @field : the name of the field
# @operator : from FirestoreQuery.OPERATOR
# @value : can be any type - String, int, bool, float
# @chain : from FirestoreQuery.OPERATOR.[OR/AND], use it only if you want to chain "AND" or "OR" logic with futher where() calls
# eg. .where("name", OPERATOR.EQUAL, "Matt", OPERATOR.AND).where("age", OPERATOR.LESS_THAN, 20)
func where(field : String, operator : int, value = null, chain : int = -1):
    if operator in [OPERATOR.IS_NAN, OPERATOR.IS_NULL, OPERATOR.IS_NOT_NAN, OPERATOR.IS_NOT_NULL]:
        if (chain in [OPERATOR.AND, OPERATOR.OR]) or (query.has("where") and query.where.has("compositeFilter")):
            var filters : Array = []
            if query.has("where") and query.where.has("compositeFilter"):
                if chain == -1:
                    filters = query.where.compositeFilter.filters.duplicate(true)
                    chain = OPERATOR.get(query.where.compositeFilter.op)
                else:
                    filters.append(query.where)
            filters.append(create_unary_filter(field, operator))
            query["where"] = create_composite_filter(chain, filters)
        else:
            query["where"] = create_unary_filter(field, operator)
    else:
        if value == null:
            print("A value must be defined to match the field: {field}".format({field = field}))
        else:
            if (chain in [OPERATOR.AND, OPERATOR.OR]) or (query.has("where") and query.where.has("compositeFilter")):
                var filters : Array = []
                if query.has("where") and query.where.has("compositeFilter"):
                    if chain == -1:
                        filters = query.where.compositeFilter.filters.duplicate(true)
                        chain = OPERATOR.get(query.where.compositeFilter.op)
                    else:
                        filters.append(query.where)
                filters.append(create_field_filter(field, operator, value))
                query["where"] = create_composite_filter(chain, filters)
            else:
                query["where"] = create_field_filter(field, operator, value)
    return self


# Order by a field, defining its name and the order direction
# default directoin = Ascending
func order_by(field : String, direction : int = DIRECTION.ASCENDING) -> FirestoreQuery:
    query["orderBy"] = [_order_object(field, direction).obj]
    return self


# Order by a set of fields and directions
# @order_list is an Array of Arrays with the following structure
# [@field_name , @DIRECTION.[direction]]
# else, order_object() can be called to return an already parsed Dictionary
func order_by_fields(order_field_list : Array) -> FirestoreQuery:
    var order_list : Array = []
    for order in order_field_list:
        if order is Array:
            order_list.append(_order_object(order[0], order[1]).obj)
        elif order is Order:
            order_list.append(order.obj)
    query["orderBy"] = order_list
    return self



func start_at(value, before : bool) -> FirestoreQuery:
    var cursor : Cursor = _cursor_object(value, before)
    query["startAt"] = { values = cursor.values, before = cursor.before }
    print(query["startAt"])
    return self


func end_at(value, before : bool) -> FirestoreQuery:
    var cursor : Cursor = _cursor_object(value, before)
    query["startAt"] = { values = cursor.values, before = cursor.before }
    print(query["startAt"])
    return self


func offset(offset : int) -> FirestoreQuery:
    if offset < 0:
        print("If specified, offset must be >= 0")
    else:
        query["offset"] = offset
    return self


func limit(limit : int) -> FirestoreQuery:
    if limit < 0:
        print("If specified, offset must be >= 0")
    else:
        query["limit"] = limit
    return self



# UTILITIES ----------------------------------------

static func _cursor_object(value, before : bool) -> Cursor:
    var parse : Dictionary = FirestoreDocument.dict2fields({value = value}).fields.value
    var cursor : Cursor = Cursor.new(parse.arrayValue.values if parse.has("arrayValue") else [parse], before)
    return cursor

static func _order_object(field : String, direction : int) -> Order:
    var order : Order = Order.new()
    order.obj = { field = { fieldPath = field }, direction = DIRECTION.keys()[direction] }
    return order


func create_field_filter(field : String, operator : int, value) -> Dictionary:
    return {
        fieldFilter = {
            field = { fieldPath = field },
            op = OPERATOR.keys()[operator],
            value = FirestoreDocument.dict2fields({value = value}).fields.value
        } }

func create_unary_filter(field : String, operator : int) -> Dictionary:
    return {
        unaryFilter = {
            field = { fieldPath = field },
            op = OPERATOR.keys()[operator],
        } }

func create_composite_filter(operator : int, filters : Array) -> Dictionary:
    return {
        compositeFilter = {
            op = OPERATOR.keys()[operator],
            filters = filters
        } }

func clean() -> void:
    query = { }

func _to_string() -> String:
    var pretty : String = "QUERY:\n"
    for key in query.keys():
       pretty += "- {key} = {value}\n".format({key = key, value = query.get(key)})
    return pretty
