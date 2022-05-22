class_name FacebookProvider 
extends AuthProvider

func _init(client_id: String) -> void:
    randomize()
    set_client_id(client_id)
    self.should_exchange = false
    self.endpoint = "https://www.facebook.com/v13.0/dialog/oauth?"
    self.provider_id = "facebook.com"
    self.params.response_type = "token"
    self.params.scope = "email public_profile"
    self.params.state = str(rand_range(0, 1))
    self.params.response_type = "access_token"
    self._body_token = "access_token"
