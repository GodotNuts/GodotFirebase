# auth/providers/play_games_provider.gd
class_name PlayGamesProvider
extends AuthProvider

func _init() -> void:
	provider_id = "playgames.google.com"
	should_exchange = false
