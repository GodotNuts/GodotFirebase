class_name TwitterProvider 
extends AuthProvider

var request_token_endpoint: String = "https://api.twitter.com/oauth/access_token?oauth_callback="

var oauth_header: Dictionary = {
    oauth_callback="",
    oauth_consumer_key="",
    oauth_nonce="",
    oauth_signature="",
    oauth_signature_method="HMAC-SHA1",
    oauth_timestamp="",
    oauth_version="1.0"
}

func _init(client_id: String,client_secret: String):
    randomize()
    set_client_id(client_id)
    set_client_secret(client_secret)
    
    self.oauth_header.oauth_consumer_key = client_id
    self.oauth_header.oauth_nonce = Time.get_ticks_usec()
    self.oauth_header.oauth_timestamp = Time.get_ticks_msec()
    
    
    self.should_exchange = true
    self.redirect_uri = "https://twitter.com/i/oauth2/authorize?"
    self.access_token_uri = "https://api.twitter.com/2/oauth2/token"
    self.provider_id = "twitter.com"
    self.params.redirect_type = "redirect_uri"
    self.params.response_type = "code"
    self.params.scope = "users.read"
    self.params.state = str(randf_range(0, 1))

func get_oauth_params() -> String:
    var params: PackedStringArray = []
    for key in self.oauth.keys():
        params.append(key+"="+self.oauth.get(key))
    return "&".join(params)
