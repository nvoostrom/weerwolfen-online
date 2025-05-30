extends Control

@onready var back_button = $TopBar/BackButton
@onready var start_game_button = $TopBar/StartGameButton
@onready var pin_display = $MarginContainer/VBoxContainer/SessionInfo/PinDisplay
@onready var players_count_label = $MarginContainer/VBoxContainer/SessionInfo/PlayersCount
@onready var players_list = $MarginContainer/VBoxContainer/PlayersSection/ScrollContainer/PlayersList
@onready var share_pin_button = $MarginContainer/VBoxContainer/SessionInfo/SharePinButton

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	share_pin_button.pressed.connect(_on_share_pin_button_pressed)
	
	# Connect to network events
	NetworkManager.player_list_updated.connect(_on_player_list_updated)
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.error_received.connect(_on_network_error)
	NetworkManager.disconnected_from_server.connect(_on_disconnected_from_server)
	
	# Setup initial display
	setup_session_display()
	
	# Wait a moment then request player list and check fallbacks
	await get_tree().create_timer(0.1).timeout
	request_and_display_players()

func setup_session_display():
	var pin = NetworkManager.get_current_session_pin()
	if pin.is_empty():
		pin = GameData.current_session_pin
	
	pin_display.text = "PIN: " + pin
	
	# Show initial state - will be updated by server events
	players_count_label.text = "Laden..." 
	
	# Only show start button for hosts
	start_game_button.visible = NetworkManager.is_current_player_host()
	start_game_button.disabled = true

func request_and_display_players():
	# First, check if GameData already has players (fallback)
	if GameData.players.size() > 0:
		update_players_display()
	
	# Request current player list from server
	if NetworkManager.is_connected_to_server():
		NetworkManager.request_player_list()

func _on_player_list_updated(players: Array):
	# Update GameData with new player list
	GameData.players = players
	update_players_display()

func update_players_display():
	if not players_list:
		return
	
	# Clear existing player items immediately
	var children_to_remove = players_list.get_children()
	for child in children_to_remove:
		players_list.remove_child(child)
		child.queue_free()
	
	# Add current players
	for player in GameData.players:
		var player_name = player.get("name", "Unknown")
		var is_host = player.get("isHost", false)
		var is_ready = player.get("isReady", false)
		add_player_to_list(player_name, is_host, is_ready)
	
	# Update player count
	players_count_label.text = str(GameData.players.size()) + "/" + str(GameData.max_players) + " Spelers"
	
	# Enable start button only if minimum players are present and user is host
	if NetworkManager.is_current_player_host():
		start_game_button.disabled = GameData.players.size() < 4

func add_player_to_list(player_name: String, is_host: bool, is_ready: bool = false):
	var player_item = preload("res://components/PlayerListItem.tscn").instantiate()
	player_item.setup_player(player_name, is_host, is_ready)
	players_list.add_child(player_item)

func _on_back_button_pressed():
	if NetworkManager.is_current_player_host():
		show_leave_confirmation()
	else:
		leave_session()

func show_leave_confirmation():
	var confirmation = AcceptDialog.new()
	confirmation.dialog_text = "Weet je zeker dat je de sessie wilt verlaten? Dit zal de sessie voor alle spelers beëindigen."
	confirmation.title = "Sessie Verlaten"
	add_child(confirmation)
	confirmation.confirmed.connect(leave_session)
	confirmation.popup_centered()

func leave_session():
	GameData.leave_session()
	get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func _on_start_game_button_pressed():
	if GameData.players.size() < 4:
		show_error("Minimaal 4 spelers nodig om te starten!")
		return
	
	# Start game via network
	GameData.start_game()

func _on_game_started():
	show_info("Spel is gestart!")
	# TODO: Navigate to game screen when implemented
	# get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")

func _on_share_pin_button_pressed():
	var pin = NetworkManager.get_current_session_pin()
	if pin.is_empty():
		pin = GameData.current_session_pin
	
	DisplayServer.clipboard_set(pin)
	show_info("PIN gekopieerd naar klembord!")

func _on_network_error(error_message: String):
	show_error("Network fout: " + error_message)

func _on_disconnected_from_server():
	show_error("Verbinding met server verbroken. Terug naar hoofdmenu.")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func show_error(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Fout"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func show_info(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Info"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _exit_tree():
	# Disconnect from network events
	if NetworkManager.player_list_updated.is_connected(_on_player_list_updated):
		NetworkManager.player_list_updated.disconnect(_on_player_list_updated)
	if NetworkManager.game_started.is_connected(_on_game_started):
		NetworkManager.game_started.disconnect(_on_game_started)
	if NetworkManager.error_received.is_connected(_on_network_error):
		NetworkManager.error_received.disconnect(_on_network_error)
	if NetworkManager.disconnected_from_server.is_connected(_on_disconnected_from_server):
		NetworkManager.disconnected_from_server.disconnect(_on_disconnected_from_server)
