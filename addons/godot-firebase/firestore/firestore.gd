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


func query(query : FirestoreQuery):
    request = REQUESTS.QUERY
    var body : Dictionary = {
        structuredQuery = query.query,
       }
    var url : String = _base_url + _extended_url + _query_suffix
    _request_list_node.request(url, [_authorization_header + auth.idtoken], true, HTTPClient.METHOD_POST, JSON.print(body))
    

func list(path : String, page_size : int = 0, page_token : String = "", order_by : String = "") -> void:
    request = REQUESTS.LIST
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
    _request_list_node.request(url, [_authorization_header + auth.idtoken], true, HTTPClient.METHOD_GET)

func _on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray):
    match result:
        0:
            match response_code:
                200:
                    match request:
                        REQUESTS.LIST:
                            var result_body : Dictionary = JSON.parse(body.get_string_from_utf8()).result
                            emit_signal("listed_documents", result_body.documents)
                        REQUESTS.QUERY:
                            var result_body : Array = JSON.parse(body.get_string_from_utf8()).result
                            emit_signal("result_query", result_body)
                400:
                    match request:
                        REQUESTS.LIST:
                            var result_body : Dictionary = JSON.parse(body.get_string_from_utf8()).result
                            emit_signal("listed_documents", result_body.documents)
                        REQUESTS.QUERY:
                            var result_body : Array = JSON.parse(body.get_string_from_utf8()).result
                            emit_signal("result_query", result_body)
                    var error : Array = JSON.parse(body.get_string_from_utf8()).result
                    emit_signal("error", error[0].error.message)
                    
    request = REQUESTS.NONE


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
