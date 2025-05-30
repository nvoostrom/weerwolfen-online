extends Node

# Session data
var current_session_pin: String = ""
var join_pin: String = ""
var is_host: bool = false

# Game settings
var max_players: int = 8
var selected_roles: Array[String] = ["Burger"]
var game_rules: Dictionary = {
	"discussion_time": 300,  # 5 minutes in seconds
	"voting_time": 120,      # 2 minutes in seconds
	"night_time": 60         # 1 minute in seconds
}

# Players in session
var players: Array[Dictionary] = []

func _ready():
	# Add autoload to project settings if not already there
	pass

func generate_session_pin() -> String:
	var pin = ""
	for i in range(6):
		pin += str(randi() % 10)
	current_session_pin = pin
	return pin

func create_new_session(player_count: int, roles: Array[String], rules: Dictionary):
	max_players = player_count
	selected_roles = roles
	game_rules = rules
	is_host = true
	players.clear()
	generate_session_pin()

func add_player(player_name: String) -> bool:
	if players.size() >= max_players:
		return false
	
	var new_player = {
		"name": player_name,
		"id": generate_player_id(),
		"is_ready": false,
		"role": ""
	}
	players.append(new_player)
	return true

func generate_player_id() -> String:
	return "player_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

func get_available_roles() -> Array[String]:
	# For now, only return Burger as requested
	return ["Burger"]

func reset_session():
	current_session_pin = ""
	join_pin = ""
	is_host = false
	players.clear()
	max_players = 8
	selected_roles = ["Burger"]
