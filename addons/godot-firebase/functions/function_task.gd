## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 1.2
##
## ex.
## [code]var task : FirestoreTask = Firebase.Firestore.query(query)[/code]
## [code]var result : Array = yield(task, "task_finished")[/code]
## [code]var result : Array = yield(task, "result_query")[/code]
## [code]var result : Array = yield(Firebase.Firestore, "task_finished")[/code]
## [code]var result : Array = yield(Firebase.Firestore, "result_query")[/code]
## 
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Firestore#FirestoreTask

tool
class_name FunctionTask
extends Reference

## Emitted when a request is completed. The request can be successful or not successful: if not, an [code]error[/code] Dictionary will be passed as a result.
## @arg-types Variant
signal task_finished(result)

## Emitted when a cloud function is correctly executed, returning the Response Code and Result Body
## @arg-types FirestoreDocument
signal executed_function(response, result)

## Emitted when a request is [b]not[/b] successfully completed.
## @arg-types Dictionary
signal task_error(code, status, message)

## A variable, temporary holding the result of the request.
var data

## Whether the data came from cache.
var from_cache : bool = false

var _response_headers : PoolStringArray = PoolStringArray()
var _response_code : int = 0

var _method : int = -1
var _url : String = ""
var _fields : String = ""
var _headers : PoolStringArray = []

func _on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
    var bod
    if validate_json(body.get_string_from_utf8()).empty():
        bod = JSON.parse(body.get_string_from_utf8()).result
    
    var offline: bool = typeof(bod) == TYPE_NIL
    var error: bool = bod is Dictionary and bod.has("error") and response_code != HTTPClient.RESPONSE_OK
    from_cache = offline
    
    Firebase.Firestore._set_offline(offline)
    
    var cache_path : String = Firebase._config["cacheLocation"]
    if not cache_path.empty() and not error and Firebase.Firestore.persistence_enabled:
        var encrypt_key: String = Firebase.Firestore._encrypt_key
        var url_segment : String = JSON.print(data)
        var full_path : String = _get_doc_file(cache_path, url_segment, encrypt_key)
        bod = _handle_cache(offline, data, encrypt_key, full_path, bod)
        if not bod.empty() and offline:
            response_code = HTTPClient.RESPONSE_OK
    

    if response_code == HTTPClient.RESPONSE_OK:
        data = bod
        emit_signal("function_executed", result, data)
    else:
        data = bod.error
        emit_signal("task_error", data.code, data.status, data.message)
    
    emit_signal("task_finished", data)


func _handle_cache(offline : bool, data, encrypt_key : String, cache_path : String, body) -> Dictionary:
    if offline:
        Firebase._printerr("Offline queries are currently unsupported!")
    
    if not offline:
        return body
    else:
        return body_return
