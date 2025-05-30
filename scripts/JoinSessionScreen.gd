extends Control

@onready var back_button = $TopBar/BackButton
@onready var pin_label = $MainContainer/ContentPanel/VBoxContainer/PinSection/PinHeader/PinLabel
@onready var player_name_input = $MainContainer/ContentPanel/VBoxContainer/JoinSection/PlayerNameInput
@onready var join_button = $MainContainer/ContentPanel/VBoxContainer/JoinSection/JoinButton
@onready var players_list = $MainContainer/ContentPanel/VBoxContainer/PlayersSection/ScrollContainer/PlayersList
@onready var waiting_label = $MainContainer/ContentPanel/VBoxContainer/StatusSection/WaitingLabel
@onready var status_icon = $MainContainer/ContentPanel/VBoxContainer/StatusSection/StatusIcon

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
	status_icon.text = "⚡"
	
	# Initially disable input until we're connected
	player_name_input.editable = false
	join_button.disabled = true
	
	# Connect to network events
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.session_joined.connect(_on_session_joined)
	NetworkManager.player_list_updated.connect(_on_player_list_updated)
	NetworkManager.error_received.connect(_on_network_error)
	NetworkManager.connection_error.connect(_on_connection_error)
	
	# Add visual enhancements
	_setup_ui_enhancements()
	
	# Connect to server (PIN already validated in GameModal)
	connect_to_server()

func _setup_ui_enhancements():
	# Animate content panel entrance
	var content_panel = $MainContainer/ContentPanel
	content_panel.modulate.a = 0.0
	content_panel.position.y += 30
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(content_panel, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(content_panel, "position:y", content_panel.position.y - 30, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Add hover effects to buttons
	_setup_button_effects()
	
	# Start status icon pulsing
	_animate_status_icon()

func _setup_button_effects():
	var buttons = [back_button, join_button]
	
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	if not button.disabled:
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _animate_status_icon():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(status_icon, "scale", Vector2(1.2, 1.2), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(status_icon, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_SINE)

func connect_to_server():
	if not NetworkManager.is_connected_to_server():
		waiting_label.text = "Verbinding maken met server..."
		status_icon.text = "⚡"
		status_icon.modulate = Color.YELLOW
		NetworkManager.connect_to_server()
	else:
		_on_connected_to_server()

func _on_connected_to_server():
	# PIN was already validated in GameModal, so we can proceed
	waiting_label.text = "Verbonden met server. Voer je naam in om deel te nemen."
	status_icon.text = "✅"
	status_icon.modulate = Color.GREEN
	
	player_name_input.editable = true
	join_button.disabled = false
	
	# Focus on name input with nice animation
	var tween = create_tween()
	tween.tween_property(player_name_input, "scale", Vector2(1.05, 1.05), 0.3).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(player_name_input, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(player_name_input.grab_focus)

func _on_session_joined(pin: String, player_id: String, player_data: Dictionary):
	# Reset UI state
	is_joining_session = false
	join_button.disabled = false
	join_button.text = "🚪 Deelnemen aan Sessie"
	
	# Show success feedback
	status_icon.text = "🎉"
	status_icon.modulate = Color.GREEN
	waiting_label.text = "Welkom in de sessie!"
	
	# Show success dialog
	var dialog = CustomDialog.show_info(
		self,
		"Sessie Toegetreden!",
		"Je bent succesvol toegetreden tot de sessie!\n\nJe wordt nu doorgestuurd naar de wachtruimte."
	)
	
	dialog.confirmed.connect(_navigate_to_session)

func _navigate_to_session():
	# Brief success animation then navigate
	var tween = create_tween()
	tween.tween_property(status_icon, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(status_icon, "scale", Vector2.ONE, 0.3)
	tween.tween_delay(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/SessionScreen.tscn"))

func _on_player_list_updated(players: Array):
	# Clear existing player items with animation
	for child in players_list.get_children():
		_animate_player_leave(child)
	
	# Wait a bit then add new players
	await get_tree().create_timer(0.2).timeout
	
	# Add current players with animation
	for i in range(players.size()):
		var player = players[i]
		add_player_to_list(player.name, player.get("isHost", false))
		
		# Stagger the animations
		await get_tree().create_timer(0.1).timeout

func add_player_to_list(player_name: String, is_host: bool):
	var player_item = preload("res://components/PlayerListItem.tscn").instantiate()
	player_item.setup_player(player_name, is_host)
	players_list.add_child(player_item)
	
	# Animate player item entrance
	_animate_player_join(player_item)

func _animate_player_join(player_item: Control):
	player_item.scale = Vector2.ZERO
	player_item.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(player_item, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_item, "modulate:a", 1.0, 0.3)

func _animate_player_leave(player_item: Control):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(player_item, "scale", Vector2(1.1, 0.0), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(player_item, "modulate:a", 0.0, 0.3)
	tween.tween_callback(player_item.queue_free).set_delay(0.3)

func _on_back_button_pressed():
	if not is_joining_session:
		NetworkManager.disconnect_from_server()
		
		# Smooth transition back
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/MainScreen.tscn"))

func _on_join_button_pressed():
	if is_joining_session:
		return
	
	var player_name = player_name_input.text.strip_edges()
	
	if player_name.is_empty():
		show_error("Ongeldige Naam", "Voer een geldige naam in om deel te kunnen nemen aan de sessie.")
		return
	
	if player_name.length() < 2:
		show_error("Naam Te Kort", "Je naam moet minimaal 2 karakters lang zijn.\n\nKies een naam die andere spelers kunnen herkennen.")
		return
	
	# Show loading state
	is_joining_session = true
	join_button.text = "⏳ Deelnemen..."
	join_button.disabled = true
	waiting_label.text = "Deelnemen aan sessie..."
	status_icon.text = "🔄"
	status_icon.modulate = Color.YELLOW
	
	# Add loading animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(status_icon, "rotation", PI * 2, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# Join session via network
	GameData.join_session_with_name(current_pin, player_name)

func _on_network_error(error_message: String):
	show_error("Netwerk Fout", "Er is een probleem opgetreden met de netwerkverbinding:\n\n" + error_message + "\n\nProbeer het opnieuw.")
	reset_join_state()

func _on_connection_error(error_message: String):
	show_error("Verbindingsfout", "Kan geen verbinding maken met de server:\n\n" + error_message + "\n\nControleer je internetverbinding en probeer opnieuw.")
	reset_join_state()

func reset_join_state():
	is_joining_session = false
	join_button.disabled = false
	join_button.text = "🚪 Deelnemen aan Sessie"
	waiting_label.text = "Probeer opnieuw."
	status_icon.text = "❌"
	status_icon.modulate = Color.RED
	status_icon.rotation = 0  # Stop rotation

func show_error(title: String, message: String):
	CustomDialog.show_error(self, title, message)
	
	# Also update UI to show error state
	waiting_label.text = "Fout: " + title
	waiting_label.modulate = Color.RED
	status_icon.text = "❌"
	status_icon.modulate = Color.RED
	
	# Shake animation for error feedback
	var original_pos = waiting_label.position
	var tween = create_tween()
	tween.tween_property(waiting_label, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(waiting_label, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(waiting_label, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(waiting_label, "position:x", original_pos.x, 0.05)
	
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
