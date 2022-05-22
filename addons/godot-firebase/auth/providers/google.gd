class_name GoogleProvider
extends AuthProvider

func _init(client_id: String, client_secret: String) -> void:
    set_client_id(client_id)
    set_client_secret(client_secret)
    self.should_exchange = true
    self.access_token_uri = "https://oauth2.googleapis.com/token?"
    self.endpoint = "https://accounts.google.com/o/oauth2/v2/auth?"
    self.provider_id = "google.com"
    self.params.response_type = "code"
    self.params.scope = "email openid profile"
    self.params.response_type = "code"
    self._body_token = "id_token"
