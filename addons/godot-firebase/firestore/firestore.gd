# ---------------------------------------------------- #
#                 SCRIPT VERSION = 2.1                 #
#                 ====================                 #
# please, remember to increment the version to +0.1    #
# if you are going to make changes that will commited  #
# ---------------------------------------------------- #

class_name FirebaseFirestore
extends Node

signal listed_documents(documents)

var base_url : String = "https://firestore.googleapis.com/v1/"
var extended_url : String = "projects/[PROJECT_ID]/databases/(default)/documents/"

var config : Dictionary = {}

var collections : Dictionary = {}
var auth : Dictionary
var request_list_node : HTTPRequest

func set_config(config_json : Dictionary) -> void:
    config = config_json
    extended_url = extended_url.replace("[PROJECT_ID]", config.projectId)
    request_list_node = HTTPRequest.new()
    request_list_node.connect("request_completed", self, "on_list_request_completed")
    add_child(request_list_node)

func collection(path : String) -> FirestoreCollection:
    if !collections.has(path):
        var coll : FirestoreCollection = FirestoreCollection.new()
        coll.extended_url = extended_url
        coll.base_url = base_url
        coll.config = config
        coll.auth = auth
        coll.collection_name = path
        collections[path] = coll
        add_child(coll)
        return coll
    else:
        return collections[path]

func list(path : String = "") -> void:
    var url : String
    if not path in [""," "]:
        url = base_url + extended_url + path + "/"
    else:
        url = base_url + extended_url
    request_list_node.request(url, ["Authorization: Bearer " + auth.idtoken], true, HTTPClient.METHOD_GET)

func on_list_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray):
    print(JSON.parse(body.get_string_from_utf8()).result)

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
