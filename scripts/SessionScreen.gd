extends Control

@onready var back_button = $TopBar/BackButton
@onready var start_game_button = $TopBar/StartGameButton
@onready var pin_display = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/SessionInfo/PinContainer/PinDisplay
@onready var players_count_label = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/SessionInfo/PlayersCountContainer/PlayersCount
@onready var players_list = $MarginContainer/HBoxContainer/RightPanel/PlayersSection/ScrollContainer/PlayersList
@onready var share_pin_button = $MarginContainer/HBoxContainer/LeftPanel/VBoxContainer/SessionInfo/SharePinButton

var last_player_count = 0  # Track to prevent unnecessary updates

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
	
	# FORCE LAYOUT UPDATE - This fixes the initial layout issues
	call_deferred("_force_layout_update")
	
	# Add visual enhancements after layout is fixed
	call_deferred("_setup_ui_enhancements")
	
	# Wait a moment then request player list and check fallbacks
	call_deferred("_delayed_player_request")

func _force_layout_update():
	"""Force the UI to recalculate layout properly"""
	print("Forcing layout update...")
	
	# Force container updates
	var main_container = $MarginContainer
	var hbox = $MarginContainer/HBoxContainer
	var left_panel = $MarginContainer/HBoxContainer/LeftPanel
	var right_panel = $MarginContainer/HBoxContainer/RightPanel
	
	# Ensure proper size flags and minimum sizes
	if left_panel:
		left_panel.custom_minimum_size = Vector2(300, 0)
		left_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if right_panel:
		right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Force layout recalculation
	if main_container:
		main_container.queue_redraw()
		main_container.notification(NOTIFICATION_RESIZED)
	
	if hbox:
		hbox.queue_redraw()
		hbox.notification(NOTIFICATION_RESIZED)
	
	# Wait one more frame then update layout again
	await get_tree().process_frame
	
	if main_container:
		main_container.queue_redraw()
	
	print("Layout update completed")

func _delayed_player_request():
	await get_tree().create_timer(0.2).timeout
	request_and_display_players()

func _setup_ui_enhancements():
	# Only do subtle animations to avoid layout conflicts
	var left_panel = $MarginContainer/HBoxContainer/LeftPanel
	var right_panel = $MarginContainer/HBoxContainer/RightPanel
	
	if left_panel and right_panel:
		# Simple fade-in instead of slide animation to avoid layout issues
		left_panel.modulate.a = 0.0
		right_panel.modulate.a = 0.0
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(left_panel, "modulate:a", 1.0, 0.5)
		tween.tween_property(right_panel, "modulate:a", 1.0, 0.5).set_delay(0.2)
	
	# Add hover effects to buttons
	_setup_button_effects()

func _setup_button_effects():
	var buttons = [back_button, start_game_button, share_pin_button]
	
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	if not button.disabled:
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

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
	
	# Update title bar subtitle based on host status
	var subtitle_label = $TopBar/TitleContainer/SubtitleLabel
	if NetworkManager.is_current_player_host():
		subtitle_label.text = "Je bent de spelleider van deze sessie"
		start_game_button.text = "🎮 Start Spel"
	else:
		subtitle_label.text = "Wacht tot de spelleider het spel start"

func request_and_display_players():
	# First, check if GameData already has players (fallback)
	if GameData.players.size() > 0:
		update_players_display()
	
	# Request current player list from server
	if NetworkManager.is_connected_to_server():
		NetworkManager.request_player_list()

func _on_player_list_updated(players: Array):
	print("SessionScreen: Player list updated with ", players.size(), " players")
	
	# Update GameData with new player list
	GameData.players = players
	
	# Use call_deferred to ensure proper timing
	call_deferred("update_players_display")

func update_players_display():
	if not players_list:
		print("ERROR: players_list not found")
		return
	
	print("Updating player display with ", GameData.players.size(), " players")
	
	# Clear existing player items immediately to prevent duplicates
	for child in players_list.get_children():
		child.queue_free()
	
	# Wait two frames for children to be properly freed
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Add current players
	for i in range(GameData.players.size()):
		var player = GameData.players[i]
		var player_name = player.get("name", "Unknown")
		var is_host = player.get("isHost", false)
		var is_ready = player.get("isReady", false)
		
		print("Adding player: ", player_name, " (Host: ", is_host, ", Ready: ", is_ready, ")")
		add_player_to_list(player_name, is_host, is_ready)
		
		# Small delay between adding players to ensure proper layout
		await get_tree().process_frame
	
	# Update player count
	_update_player_count()
	
	# Force layout update after adding players
	call_deferred("_force_player_list_layout")
	
	# Enable start button only if minimum players are present and user is host
	if NetworkManager.is_current_player_host():
		var was_disabled = start_game_button.disabled
		start_game_button.disabled = GameData.players.size() < 4
		
		# If button became enabled, add a highlight effect
		if was_disabled and not start_game_button.disabled:
			_highlight_start_button()

func _force_player_list_layout():
	"""Force the player list to recalculate its layout"""
	if players_list:
		players_list.queue_redraw()
		players_list.notification(NOTIFICATION_RESIZED)
		
		var scroll_container = players_list.get_parent()
		if scroll_container:
			scroll_container.queue_redraw()
			scroll_container.notification(NOTIFICATION_RESIZED)

func _update_player_count():
	var new_text = str(GameData.players.size()) + "/" + str(GameData.max_players) + " Spelers"
	players_count_label.text = new_text
	
	print("Updated player count: ", new_text)

func _highlight_start_button():
	# Pulse animation to draw attention to enabled start button
	var original_modulate = start_game_button.modulate
	var tween = create_tween()
	tween.tween_property(start_game_button, "modulate", Color.GREEN, 0.3)
	tween.tween_property(start_game_button, "modulate", original_modulate, 0.3)

func add_player_to_list(player_name: String, is_host: bool, is_ready: bool = false):
	var player_item = preload("res://components/PlayerListItem.tscn").instantiate()
	player_item.setup_player(player_name, is_host, is_ready)
	players_list.add_child(player_item)
	
	print("Added player item for: ", player_name)

func _on_back_button_pressed():
	if NetworkManager.is_current_player_host():
		show_leave_confirmation()
	else:
		leave_session()

func show_leave_confirmation():
	var dialog = CustomDialog.show_confirmation(
		self,
		"Sessie Verlaten",
		"Weet je zeker dat je de sessie wilt verlaten?\n\nAls spelleider zal dit de sessie voor alle spelers beëindigen.",
		"Ja, Verlaten",
		"Annuleren"
	)
	
	dialog.confirmed.connect(leave_session)

func leave_session():
	GameData.leave_session()
	
	# Smooth transition back to main screen
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/MainScreen.tscn"))

func _on_start_game_button_pressed():
	if GameData.players.size() < 4:
		show_error("Kan Niet Starten", "Minimaal 4 spelers nodig om het spel te starten!\n\nHuidige aantal spelers: " + str(GameData.players.size()))
		return
	
	# Show starting feedback
	start_game_button.text = "🎮 Spel wordt gestart..."
	start_game_button.disabled = true
	
	# Start game via network
	GameData.start_game()

func _on_game_started():
	var dialog = CustomDialog.show_info(
		self,
		"Spel Gestart!",
		"Het weerwolvenspel is succesvol gestart!\n\nAlle spelers kunnen nu beginnen met spelen."
	)
	
	# TODO: Navigate to game screen when implemented
	# dialog.confirmed.connect(func(): get_tree().change_scene_to_file("res://scenes/GameScreen.tscn"))

func _on_share_pin_button_pressed():
	var pin = NetworkManager.get_current_session_pin()
	if pin.is_empty():
		pin = GameData.current_session_pin
	
	DisplayServer.clipboard_set(pin)
	
	# Show copy feedback
	var original_text = share_pin_button.text
	share_pin_button.text = "✅ Gekopieerd!"
	share_pin_button.modulate = Color.GREEN
	
	var tween = create_tween()
	tween.tween_delay(2.0)
	tween.tween_callback(func():
		share_pin_button.text = original_text
		share_pin_button.modulate = Color.WHITE
	)
	
	# Show info dialog
	CustomDialog.show_info(
		self,
		"PIN Gedeeld",
		"De sessie PIN (" + pin + ") is gekopieerd naar je klembord!\n\nDeel deze PIN met vrienden zodat zij kunnen deelnemen."
	)

func _on_network_error(error_message: String):
	show_error("Netwerk Fout", "Er is een probleem opgetreden met de netwerkverbinding:\n\n" + error_message)

func _on_disconnected_from_server():
	var dialog = CustomDialog.show_error(
		self,
		"Verbinding Verbroken",
		"De verbinding met de server is verbroken.\n\nJe wordt teruggebracht naar het hoofdmenu."
	)
	
	dialog.confirmed.connect(_handle_disconnection)

func _handle_disconnection():
	await get_tree().create_timer(1.0).timeout
	leave_session()

func show_error(title: String, message: String):
	CustomDialog.show_error(self, title, message)

func show_info(title: String, message: String):
	CustomDialog.show_info(self, title, message)

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
