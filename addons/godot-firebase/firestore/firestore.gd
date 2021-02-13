# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.1                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

class_name FirebaseFirestore
extends Node

signal listed_documents(documents)
signal result_query(result)
signal error(error)

enum REQUESTS {
    NONE = -1,
    LIST,
    QUERY
   }


const _authorization_header : String = "Authorization: Bearer "

var request : int = -1

var _base_url : String = "https://firestore.googleapis.com/v1/"
var _extended_url : String = "projects/[PROJECT_ID]/databases/(default)/documents/"
var _query_suffix : String = ":runQuery"

var config : Dictionary = {}

var collections : Dictionary = {}
var auth : Dictionary
var _request_list_node : HTTPRequest

var _requests_queue : Array = []

var _current_query : FirestoreQuery

func set_config(config_json : Dictionary) -> void:
    config = config_json
    _extended_url = _extended_url.replace("[PROJECT_ID]", config.projectId)
    _request_list_node = HTTPRequest.new()
    _request_list_node.connect("request_completed", self, "_on_request_completed")
    add_child(_request_list_node)

func collection(path : String) -> FirestoreCollection:
    if !collections.has(path):
        var coll : FirestoreCollection = FirestoreCollection.new()
        coll._extended_url = _extended_url
        coll._base_url = _base_url
        coll.config = config
        coll.auth = auth
        coll.collection_name = path
        collections[path] = coll
        add_child(coll)
        return coll
    else:
        return collections[path]


func query(query : FirestoreQuery) -> FirestoreTask:
    if auth:
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task.connect("listed_documents", self, "_on_listed_documents")
        firestore_task.connect("error", self, "_on_error")
        firestore_task._set_action(FirestoreTask.TASK_QUERY)
        var body : Dictionary = { structuredQuery = query.query }
        var url : String = _base_url + _extended_url + _query_suffix
        firestore_task._push_request(url, _authorization_header + auth.idtoken, JSON.print(body))
        return firestore_task
    else:
        print("Unauthorized")
        return null


func list(path : String, page_size : int = 0, page_token : String = "", order_by : String = "") -> FirestoreTask:
    if auth: 
        var firestore_task : FirestoreTask = FirestoreTask.new()
        add_child(firestore_task)
        firestore_task.connect("result_query", self, "_on_result_query")
        firestore_task.connect("error", self, "_on_error")
        firestore_task._set_action(FirestoreTask.TASK_LIST)
        var url : String
        if not path in [""," "]:
            url = _base_url + _extended_url + path + "/"
        else:
            url = _base_url + _extended_url
        if page_size != 0:
            url+="?pageSize="+str(page_size)
        if page_token != "":
            url+="&pageToken="+page_token
        if order_by != "":
            url+="&orderBy="+order_by
        firestore_task._push_request(url, _authorization_header + auth.idtoken)
        return firestore_task
    else:
        print("Unauthorized")
        return null


# -------------

func _on_listed_documents(listed_documents : Array):
    emit_signal("listed_documents", listed_documents)


func _on_result_query(result : Dictionary):
    emit_signal("result_query", result)


func _on_error(error : Dictionary):
    print(JSON.print(error))

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
    for collection_key in collections.keys():
        collections[collection_key].auth = auth
    pass

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
    auth = auth_result
    for collection_key in collections.keys():
        collections[collection_key].auth = auth
    pass
