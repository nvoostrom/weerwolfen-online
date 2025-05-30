extends Control

@onready var back_button = $TopBar/BackButton
@onready var pin_label = $VBoxContainer/PinSection/PinLabel
@onready var player_name_input = $VBoxContainer/JoinSection/PlayerNameInput
@onready var join_button = $VBoxContainer/JoinSection/JoinButton
@onready var players_list = $VBoxContainer/PlayersSection/ScrollContainer/PlayersList
@onready var waiting_label = $VBoxContainer/StatusSection/WaitingLabel

var current_pin: String = ""
var is_joining_session: bool = false

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	
	# Setup UI
	current_pin = GameData.join_pin
	pin_label.text = "PIN: " + current_pin
	player_name_input.placeholder_text = "Voer je naam in..."
	waiting_label.text = "Verbinding maken met server..."
	
	# Initially disable input until we're connected
	player_name_input.editable = false
	join_button.disabled = true
	
	# Connect to network events
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.session_joined.connect(_on_session_joined)
	NetworkManager.player_list_updated.connect(_on_player_list_updated)
	NetworkManager.error_received.connect(_on_network_error)
	NetworkManager.connection_error.connect(_on_connection_error)
	
	# Connect to server (PIN already validated in GameModal)
	connect_to_server()

func connect_to_server():
	if not NetworkManager.is_connected_to_server():
		waiting_label.text = "Verbinding maken met server..."
		NetworkManager.connect_to_server()
	else:
		_on_connected_to_server()

func _on_connected_to_server():
	# PIN was already validated in GameModal, so we can proceed
	waiting_label.text = "Verbonden met server. Voer je naam in om deel te nemen."
	player_name_input.editable = true
	join_button.disabled = false

func _on_session_joined(pin: String, player_id: String, player_data: Dictionary):
	# Reset UI state
	is_joining_session = false
	join_button.disabled = false
	join_button.text = "Deelnemen"
	
	# Navigate to session screen
	get_tree().change_scene_to_file("res://scenes/SessionScreen.tscn")

func _on_player_list_updated(players: Array):
	# Clear existing player items
	for child in players_list.get_children():
		child.queue_free()
	
	# Add current players
	for player in players:
		add_player_to_list(player.name, player.get("isHost", false))

func add_player_to_list(player_name: String, is_host: bool):
	var player_item = preload("res://components/PlayerListItem.tscn").instantiate()
	player_item.setup_player(player_name, is_host)
	players_list.add_child(player_item)

func _on_back_button_pressed():
	if not is_joining_session:
		NetworkManager.disconnect_from_server()
		get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func _on_join_button_pressed():
	if is_joining_session:
		return
	
	var player_name = player_name_input.text.strip_edges()
	
	if player_name.is_empty():
		show_error("Voer een geldige naam in!")
		return
	
	if player_name.length() < 2:
		show_error("Naam moet minimaal 2 karakters zijn!")
		return
	
	# Show loading state
	is_joining_session = true
	join_button.text = "Deelnemen..."
	join_button.disabled = true
	waiting_label.text = "Deelnemen aan sessie..."
	
	# Join session via network
	GameData.join_session_with_name(current_pin, player_name)

func _on_network_error(error_message: String):
	show_error("Network fout: " + error_message)
	reset_join_state()

func _on_connection_error(error_message: String):
	show_error("Verbindingsfout: " + error_message)
	reset_join_state()

func reset_join_state():
	is_joining_session = false
	join_button.disabled = false
	join_button.text = "Deelnemen"
	waiting_label.text = "Probeer opnieuw."

func show_error(message: String):
	waiting_label.text = "Fout: " + message
	waiting_label.modulate = Color.RED
	
	# Reset color after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if waiting_label:  # Check if still valid
		waiting_label.modulate = Color.WHITE

func _exit_tree():
	# Disconnect from network events
	if NetworkManager.connected_to_server.is_connected(_on_connected_to_server):
		NetworkManager.connected_to_server.disconnect(_on_connected_to_server)
	if NetworkManager.session_joined.is_connected(_on_session_joined):
		NetworkManager.session_joined.disconnect(_on_session_joined)
	if NetworkManager.player_list_updated.is_connected(_on_player_list_updated):
		NetworkManager.player_list_updated.disconnect(_on_player_list_updated)
	if NetworkManager.error_received.is_connected(_on_network_error):
		NetworkManager.error_received.disconnect(_on_network_error)
	if NetworkManager.connection_error.is_connected(_on_connection_error):
		NetworkManager.connection_error.disconnect(_on_connection_error)
