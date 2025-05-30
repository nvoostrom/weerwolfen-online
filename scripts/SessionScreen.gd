extends Control

@onready var back_button = $TopBar/BackButton
@onready var start_game_button = $TopBar/StartGameButton
@onready var pin_display = $VBoxContainer/SessionInfo/PinDisplay
@onready var players_count_label = $VBoxContainer/SessionInfo/PlayersCount
@onready var players_list = $VBoxContainer/PlayersSection/ScrollContainer/PlayersList
@onready var share_pin_button = $VBoxContainer/SessionInfo/SharePinButton

var update_timer: Timer

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	share_pin_button.pressed.connect(_on_share_pin_button_pressed)
	
	setup_session_display()
	setup_update_timer()
	
	# Only show start button for hosts
	start_game_button.visible = GameData.is_host

func setup_session_display():
	var pin = GameData.current_session_pin
	if pin.is_empty():
		pin = GameData.join_pin
	
	pin_display.text = "PIN: " + pin
	update_players_display()

func setup_update_timer():
	update_timer = Timer.new()
	update_timer.wait_time = 2.0  # Update every 2 seconds
	update_timer.timeout.connect(update_players_display)
	add_child(update_timer)
	update_timer.start()

func update_players_display():
	# Clear existing player items
	for child in players_list.get_children():
		child.queue_free()
	
	# Add current players
	for player in GameData.players:
		add_player_to_list(player.name, GameData.is_host and player == GameData.players[0])
	
	# Update player count
	players_count_label.text = str(GameData.players.size()) + "/" + str(GameData.max_players) + " Spelers"
	
	# Enable start button only if minimum players are present
	if GameData.is_host:
		start_game_button.disabled = GameData.players.size() < 4

func add_player_to_list(player_name: String, is_host: bool):
	var player_item = preload("res://components/PlayerListItem.tscn").instantiate()
	player_item.setup_player(player_name, is_host)
	players_list.add_child(player_item)

func _on_back_button_pressed():
	if GameData.is_host:
		show_leave_confirmation()
	else:
		leave_session()

func show_leave_confirmation():
	# Simple confirmation - could be enhanced with proper dialog
	var confirmation = AcceptDialog.new()
	confirmation.dialog_text = "Weet je zeker dat je de sessie wilt verlaten? Dit zal de sessie voor alle spelers beëindigen."
	confirmation.title = "Sessie Verlaten"
	add_child(confirmation)
	confirmation.confirmed.connect(leave_session)
	confirmation.popup_centered()

func leave_session():
	GameData.reset_session()
	get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func _on_start_game_button_pressed():
	if GameData.players.size() < 4:
		show_error("Minimaal 4 spelers nodig om te starten!")
		return
	
	# TODO: Implement game start logic
	show_info("Spel starten wordt binnenkort geïmplementeerd!")

func _on_share_pin_button_pressed():
	# Copy PIN to clipboard
	var pin = GameData.current_session_pin
	if pin.is_empty():
		pin = GameData.join_pin
	
	DisplayServer.clipboard_set(pin)
	show_info("PIN gekopieerd naar klembord!")

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
	if update_timer:
		update_timer.queue_free()
