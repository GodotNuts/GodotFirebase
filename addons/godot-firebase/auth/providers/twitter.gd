class_name TwitterProvider 
extends AuthProvider

func _init(client_id: String, client_secret: String) -> void:
    randomize()
    set_client_id(client_id)
    set_client_secret(client_secret)
    self.should_exchange = true
    self.endpoint = "https://twitter.com/i/oauth2/authorize?"
    self.access_token_uri = "https://api.twitter.com/2/oauth2/token"
    self.provider_id = "twitter.com"
    self.params.redirect_type = "redirect_uri"
    self.params.response_type = "code"
    self.params.scope = "users.read"
    self.params.state = str(rand_range(0, 1))
    self._body_token = "access_token"
    self.params.code_challenge = "challenge"
    self.params.code_challenge_method = "plain"
