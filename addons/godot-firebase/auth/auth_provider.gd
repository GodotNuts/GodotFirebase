tool
class_name AuthProvider
extends Reference

var _token_type: String = ""
var _body_token: String = ""

var endpoint: String = ""
var provider_id: String = ""
var params: Dictionary = {
    client_id = "",
    scope = "",
    response_type = "",
    state = "",
    redirect_type = "redirect_uri",
}
var client_secret: String = ""
var should_exchange: bool = false
var access_token_uri: String

func set_client_id(client_id: String) -> void:
    self.params.client_id = client_id

func set_client_secret(client_secret: String) -> void:
    self.client_secret = client_secret

func get_client_id() -> String:
    return self.params.client_id

func get_client_secret() -> String:
    return self.client_secret
