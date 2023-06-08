class_name GitHubProvider 
extends AuthProvider

func _init(client_id: String,client_secret: String):
    randomize()
    set_client_id(client_id)
    set_client_secret(client_secret)
    self.should_exchange = true
    self.redirect_uri = "https://github.com/login/oauth/authorize?"
    self.access_token_uri = "https://github.com/login/oauth/access_token"
    self.provider_id = "github.com"
    self.params.scope = "user:read"
    self.params.state = str(randf_range(0, 1))
    self.params.response_type = "code"
