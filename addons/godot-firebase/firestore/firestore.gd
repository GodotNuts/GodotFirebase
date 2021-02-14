## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.3
##
## Referenced by [code]Firebase.Firestore[/code]. Represents the Firestore module.
## Cloud Firestore is a flexible, scalable database for mobile, web, and server development from Firebase and Google Cloud. 
## Like Firebase Realtime Database, it keeps your data in sync across client apps through realtime listeners and offers offline support for mobile and web so you can build responsive apps that work regardless of network latency or Internet connectivity. Cloud Firestore also offers seamless integration with other Firebase and Google Cloud products, including Cloud Functions.
##
## Following Cloud Firestore's NoSQL data model, you store data in [b]documents[/b] that contain fields mapping to values. These documents are stored in [b]collections[/b], which are containers for your documents that you can use to organize your data and build queries. 
## Documents support many different data types, from simple strings and numbers, to complex, nested objects. You can also create subcollections within documents and build hierarchical data structures that scale as your database grows.
## The Cloud Firestore data model supports whatever data structure works best for your app.
##
## (source: [url=https://firebase.google.com/docs/firestore]Firestore[/url])
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore
tool
class_name FirebaseFirestore
extends Node

## Emitted when a  [code]list()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal listed_documents(documents)
## Emitted when a  [code]query()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
signal result_query(result)
## Emitted when a [code]list()[/code] or [code]query()[/code] request is [b]not[/b] successfully completed.
## @arg-types Dictionary
signal error(error)

## @enum REQUESTS
enum REQUESTS {
    NONE = -1,  ## Firestore is not processing any request.
    LIST,       ## Firestore is processing a [code]list()[/code] request on a collection.
    QUERY       ## Firestore is processing a [code]query()[/code] request on a collection.
   }

## @doc-ignore
const _authorization_header : String = "Authorization: Bearer "

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.REQUESTS] to get a full list of codes identifiers.
## @type int
var request : int = -1

var _base_url : String = "https://firestore.googleapis.com/v1/"
var _extended_url : String = "projects/[PROJECT_ID]/databases/(default)/documents/"
var _query_suffix : String = ":runQuery"


## A Dictionary containing all configuration keys loaded for your project.
## @type Dictionary
var config : Dictionary = {}

## A Dictionary containing all collections currently referenced.
## @type Dictionary
var collections : Dictionary = {}

## A Dictionary containing all authentication fields for the current logged user.
## @type Dictionary
var auth : Dictionary
var _request_list_node : HTTPRequest
var _requests_queue : Array = []
var _current_query : FirestoreQuery


func _set_config(config_json : Dictionary) -> void:
    config = config_json
    _extended_url = _extended_url.replace("[PROJECT_ID]", config.projectId)
    _request_list_node = HTTPRequest.new()
    _request_list_node.connect("request_completed", self, "_on_request_completed")
    add_child(_request_list_node)


## Returns a reference collection by its [i]id[/i].
## 
## The returned object will be of [code]FirestoreCollection[/code] type.
## If saved into a variable, it can be used to issue requests on the collection itself.
## @args collection_id
## @arg-types String
## @return FirestoreCollection
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


## Issue a query on your Firestore database.
## 
## [b]Note:[/b] a [code]FirestoreQuery[/code] object needs to be created to issue the query.
## This method will return a [code]FirestoreTask[/code] object, representing a reference to the request issued. 
## If saved into a variable, the [code]FirestoreTask[/code] object can be used to yield on the [code]result_query(result)[/code] signal, or the more generic [code]task_finished(result)[/code] signal.
## 
## ex. 
## [code]var query_task : FirestoreTask = Firebase.Firestore.query(FirestoreQuery.new())[/code]
## [code]yield(query_task, "task_finished")[/code]
## Since the emitted signal is holding an argument, it can be directly retrieved as a return variable from the [code]yield()[/code] function.
## 
## ex.
## [code]var result : Array = yield(query_task, "task_finished")[/code]
## 
## @args query
## @arg-types FirestoreQuery
## @return FirestoreTask
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
        printerr("Unauthorized")
        return null


## Request a list of contents (documents and/or collections) inside a collection, specified by its [i]id[/i].
##
## This method will return a [code]FirestoreTask[/code] object, representing a reference to the request issued. 
## If saved into a variable, the [code]FirestoreTask[/code] object can be used to yield on the [code]result_query(result)[/code] signal, or the more generic [code]task_finished(result)[/code] signal.
## 
## ex. 
## [code]var query_task : FirestoreTask = Firebase.Firestore.query(FirestoreQuery.new())[/code]
## [code]yield(query_task, "task_finished")[/code]
## Since the emitted signal is holding an argument, it can be directly retrieved as a return variable from the [code]yield()[/code] function.
## 
## ex.
## [code]var result : Array = yield(query_task, "task_finished")[/code]
## 
## @args collection_id, page_size, page_token, order_by
## @arg-types String, int, String, String
## @arg-defaults , 0, "", ""
## @return FirestoreTask
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
        printerr("Unauthorized")
        return null


# -------------

func _on_listed_documents(listed_documents : Array):
    emit_signal("listed_documents", listed_documents)


func _on_result_query(result : Dictionary):
    emit_signal("result_query", result)


func _on_error(error : Dictionary):
    printerr(JSON.print(error))

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
