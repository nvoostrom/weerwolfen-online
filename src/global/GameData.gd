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

# Players in session (now managed by server)
var players: Array = []  # Changed from Array[Dictionary] to Array
var current_player_name: String = ""

# Network reference
var network_manager: Node

func _ready():
	# Get reference to NetworkManager
	network_manager = get_node("/root/NetworkManager")
	
	# Connect to network events
	if network_manager:
		network_manager.session_created.connect(_on_session_created)
		network_manager.session_joined.connect(_on_session_joined)
		network_manager.player_list_updated.connect(_on_player_list_updated)
		network_manager.game_started.connect(_on_game_started)
		network_manager.error_received.connect(_on_network_error)

func _on_session_created(pin: String, _player_id: String):
	current_session_pin = pin
	is_host = true  # Person who creates session is always host
	print("GameData: Session created with PIN: ", pin, " - Player is HOST")

func _on_session_joined(pin: String, _player_id: String, player_data: Dictionary):
	current_session_pin = pin
	is_host = player_data.get("isHost", false)  # Get host status from server
	current_player_name = player_data.get("name", "")
	print("GameData: Joined session: ", pin, " - Player is host: ", is_host)

func _on_player_list_updated(new_players: Array):
	print("GameData: Player list updated with ", new_players.size(), " players")
	# Convert to ensure compatibility
	players.clear()
	for player in new_players:
		if player is Dictionary:
			players.append(player)
	print("GameData: Player list now has ", players.size(), " players")
	
	# Update host status based on current player in the list
	for player in players:
		if player.get("id") == network_manager.get_current_player_id():
			is_host = player.get("isHost", false)
			print("GameData: Updated host status from player list: ", is_host)
			break

# Helper method to get current players for UI
func get_current_players() -> Array:
	return players

func _on_game_started():
	print("Game has started!")

func _on_network_error(error_message: String):
	print("Network error: ", error_message)

func create_new_session(player_count: int, roles: Array[String], rules: Dictionary, host_name: String = ""):
	max_players = player_count
	selected_roles = roles
	game_rules = rules
	
	# Use a default name if none provided
	if host_name.is_empty():
		host_name = "Host"
	
	current_player_name = host_name
	
	# Create session via network
	if network_manager:
		var settings = {
			"maxPlayers": player_count,
			"roles": roles,
			"rules": rules
		}
		network_manager.create_session(settings, host_name)
	else:
		print("NetworkManager not available!")

func join_session_with_name(pin: String, player_name: String):
	join_pin = pin
	current_player_name = player_name
	
	if network_manager:
		network_manager.join_session(pin, player_name)
	else:
		print("NetworkManager not available!")

func set_player_ready(is_ready: bool):
	if network_manager:
		network_manager.set_player_ready(is_ready)

func start_game():
	if network_manager and is_host:
		network_manager.start_game()

func leave_session():
	if network_manager:
		network_manager.leave_session()
	
	# Reset local data
	current_session_pin = ""
	join_pin = ""
	is_host = false
	players.clear()
	current_player_name = ""

# Legacy methods for compatibility
func generate_session_pin() -> String:
	# This is now handled by the server
	return current_session_pin

func add_player(player_name: String) -> bool:
	# This is now handled by the server via join_session_with_name
	join_session_with_name(join_pin, player_name)
	return true

func generate_player_id() -> String:
	# This is now handled by the server
	return network_manager.get_current_player_id() if network_manager else ""

func get_available_roles() -> Array[String]:
	return ["Burger"]

func reset_session():
	leave_session()
