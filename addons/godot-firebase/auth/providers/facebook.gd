class_name FacebookProvider
extends AuthProvider


func _init(client_id: String, client_secret: String) -> void:
    randomize()
    set_client_id(client_id)
    set_client_secret(client_secret)

    self.redirect_uri = "https://www.facebook.com/v13.0/dialog/oauth?"
    self.access_token_uri = "https://graph.facebook.com/v13.0/oauth/access_token"
    self.provider_id = "facebook.com"
    self.params.scope = "public_profile"
    self.params.state = str(rand_range(0, 1))
    if OS.get_name() == "HTML5":
        self.should_exchange = false
        self.params.response_type = "token"
    else:
        self.should_exchange = true
        self.params.response_type = "code"
