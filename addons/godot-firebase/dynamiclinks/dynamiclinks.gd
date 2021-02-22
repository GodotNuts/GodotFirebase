## @meta-authors TODO
## @meta-authors TODO
## @meta-version 1.1
## The dynamic links API for Firebase
## Documentation TODO.
tool
class_name FirebaseDynamicLinks
extends Node

signal dynamic_link_generated(link_result)

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

var request : int = -1

var _dynamic_link_request_url : String = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=%s"

var _config : Dictionary = {}

var _auth : Dictionary
var _request_list_node : HTTPRequest

var _headers : PoolStringArray = [   
    "Access-Control-Allow-Origin: *"
   ]

enum Requests {
    NONE = -1,
    GENERATE
   }

func _set_config(config_json : Dictionary) -> void:
    _config = config_json
    _dynamic_link_request_url %= _config.apiKey
    _request_list_node = HTTPRequest.new()
    _request_list_node.connect("request_completed", self, "_on_request_completed")
    add_child(_request_list_node)

var _link_request_body : Dictionary = {
    "dynamicLinkInfo": {
        "domainUriPrefix": "",
        "link": "",
        "androidInfo": {
            "androidPackageName": ""
        },
        "iosInfo": {
            "iosBundleId": ""
        }
        },
    "suffix": {
        "option": ""
    }
    }

## @args log_link, APN, IBI, is_unguessable
## This function is used to generate a dynamic link using the Firebase REST API
## It will return a JSON with the shortened link
func generate_dynamic_link(long_link : String, APN : String, IBI : String, is_unguessable : bool) -> void:
    request = Requests.GENERATE
    _link_request_body.dynamicLinkInfo.domainUriPrefix = _config.domainUriPrefix
    _link_request_body.dynamicLinkInfo.link = long_link
    _link_request_body.dynamicLinkInfo.androidInfo.androidPackageName = APN
    _link_request_body.dynamicLinkInfo.iosInfo.iosBundleId = IBI
    if is_unguessable:
        _link_request_body.suffix.option = "UNGUESSABLE"
    else:
        _link_request_body.suffix.option = "SHORT"
    _request_list_node.request(_dynamic_link_request_url, _headers, true, HTTPClient.METHOD_POST, JSON.print(_link_request_body))

func _on_request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
    var result_body : Dictionary = JSON.parse(body.get_string_from_utf8()).result
    emit_signal("dynamic_link_generated", result_body.shortLink)
    request = Requests.NONE

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
    _auth = auth_result

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
    _auth = auth_result

func _on_FirebaseAuth_logout() -> void:
    _auth = {}
