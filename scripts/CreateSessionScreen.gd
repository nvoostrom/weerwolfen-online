extends Control

@onready var back_button = $TopBar/BackButton
@onready var create_button = $TopBar/CreateButton
@onready var player_count_spinner = $MainContainer/ContentPanel/ScrollContainer/VBoxContainer/PlayerSection/PlayerCountContainer/PlayerCountSpinner
@onready var roles_container = $MainContainer/ContentPanel/ScrollContainer/VBoxContainer/RolesSection/RolesContainer
@onready var discussion_time_spinner = $MainContainer/ContentPanel/ScrollContainer/VBoxContainer/RulesSection/RulesContainer/DiscussionTime/DiscussionHeader/TimeSpinner
@onready var voting_time_spinner = $MainContainer/ContentPanel/ScrollContainer/VBoxContainer/RulesSection/RulesContainer/VotingTime/VotingHeader/TimeSpinner
@onready var night_time_spinner = $MainContainer/ContentPanel/ScrollContainer/VBoxContainer/RulesSection/RulesContainer/NightTime/NightHeader/TimeSpinner

var selected_roles: Array[String] = ["Burger"]
var is_creating_session: bool = false

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	
	setup_player_count_spinner()
	setup_roles_section()
	setup_rules_spinners()
	
	# Connect to network events
	NetworkManager.session_created.connect(_on_session_created)
	NetworkManager.error_received.connect(_on_network_error)
	NetworkManager.connection_error.connect(_on_connection_error)
	
	# Add visual enhancements
	_setup_ui_enhancements()

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

func _setup_button_effects():
	var buttons = [back_button, create_button]
	
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func setup_player_count_spinner():
	player_count_spinner.min_value = 4
	player_count_spinner.max_value = 20
	player_count_spinner.value = 8
	player_count_spinner.step = 1

func setup_roles_section():
	# For now, only show Burger role as requested
	var available_roles = GameData.get_available_roles()
	for role in available_roles:
		var role_container = HBoxContainer.new()
		role_container.add_theme_constant_override("separation", 10)
		
		var checkbox = CheckBox.new()
		checkbox.text = role
		checkbox.button_pressed = true  # Burger is selected by default
		checkbox.disabled = true  # Disable for now since only Burger is implemented
		checkbox.toggled.connect(_on_role_toggled.bind(role))
		
		var role_icon = Label.new()
		role_icon.text = "👤"  # Generic villager icon
		role_icon.add_theme_font_size_override("font_size", 16)
		
		role_container.add_child(role_icon)
		role_container.add_child(checkbox)
		roles_container.add_child(role_container)

func setup_rules_spinners():
	# Discussion time (5 minutes default)
	discussion_time_spinner.min_value = 60
	discussion_time_spinner.max_value = 600
	discussion_time_spinner.value = 300
	discussion_time_spinner.step = 30
	discussion_time_spinner.suffix = "s"
	
	# Voting time (2 minutes default)
	voting_time_spinner.min_value = 30
	voting_time_spinner.max_value = 300
	voting_time_spinner.value = 120
	voting_time_spinner.step = 15
	voting_time_spinner.suffix = "s"
	
	# Night time (1 minute default)
	night_time_spinner.min_value = 30
	night_time_spinner.max_value = 180
	night_time_spinner.value = 60
	night_time_spinner.step = 15
	night_time_spinner.suffix = "s"

func _on_role_toggled(role: String, pressed: bool):
	if pressed and role not in selected_roles:
		selected_roles.append(role)
	elif not pressed and role in selected_roles:
		selected_roles.erase(role)

func _on_back_button_pressed():
	if not is_creating_session:
		# Smooth transition back
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/MainScreen.tscn"))

func _on_create_button_pressed():
	if is_creating_session:
		print("Already creating session, ignoring button press")
		return
	
	var player_count = int(player_count_spinner.value)
	var rules = {
		"discussion_time": int(discussion_time_spinner.value),
		"voting_time": int(voting_time_spinner.value),
		"night_time": int(night_time_spinner.value)
	}
	
	# Validate settings
	if selected_roles.is_empty():
		show_error("Configuratie Fout", "Selecteer minimaal één rol!")
		return
	
	if player_count < 4:
		show_error("Configuratie Fout", "Minimum 4 spelers vereist!")
		return
	
	# Ask for host name using the improved CustomDialog
	show_host_name_dialog(player_count, rules)

func show_host_name_dialog(player_count: int, rules: Dictionary):
	var dialog = CustomDialog.create_dialog(
		self, 
		CustomDialog.DialogType.INPUT, 
		"Welkom, Spelleider!", 
		"Voer je naam in als host van deze sessie.\nJe zult de sessie beheren en het spel starten.",
		"Bevestigen", 
		"Annuleren"
	)
	
	if dialog.line_edit:
		dialog.line_edit.placeholder_text = "Je naam als spelleider..."
		dialog.line_edit.text = "Host"
	
	dialog.confirmed.connect(_on_host_name_confirmed.bind(dialog, player_count, rules))

func _on_host_name_confirmed(dialog, player_count: int, rules: Dictionary):
	var host_name = dialog.get_input_text()
	if host_name.is_empty():
		host_name = "Host"
	
	# Check if already creating a session
	if is_creating_session:
		return
	
	# Show loading state with animation
	_show_creating_state()
	
	# Small delay to ensure UI updates
	await get_tree().process_frame
	
	# Create the session via network
	GameData.create_new_session(player_count, selected_roles, rules, host_name)

func _show_creating_state():
	is_creating_session = true
	create_button.text = "🔄 Sessie wordt aangemaakt..."
	create_button.disabled = true
	back_button.disabled = true
	
	# Add pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(create_button, "modulate:a", 0.7, 0.5)
	tween.tween_property(create_button, "modulate:a", 1.0, 0.5)

func _on_session_created(pin: String, player_id: String):
	print("Session created successfully with PIN: ", pin)
	
	# Reset UI state
	_reset_create_state()
	
	# Show success feedback
	create_button.text = "✅ Sessie aangemaakt!"
	create_button.modulate = Color.GREEN
	
	# Show success dialog using improved CustomDialog
	var success_dialog = CustomDialog.create_dialog(
		self,
		CustomDialog.DialogType.INFO,
		"Sessie Aangemaakt!",
		"Je sessie is succesvol aangemaakt met PIN: " + pin + "\n\nJe wordt nu doorgestuurd naar de wachtruimte.",
		"OK"
	)
	success_dialog.confirmed.connect(_navigate_to_session)

func _navigate_to_session():
	# Small delay then navigate
	await get_tree().create_timer(0.2).timeout
	
	# Smooth transition to session screen
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/SessionScreen.tscn"))

func _on_network_error(error_message: String):
	print("Network error in CreateSessionScreen: ", error_message)
	show_error("Netwerk Fout", "Er is een probleem opgetreden met de netwerkverbinding:\n\n" + error_message + "\n\nProbeer het opnieuw.")
	_reset_create_state()

func _on_connection_error(error_message: String):
	print("Connection error in CreateSessionScreen: ", error_message)
	show_error("Verbindingsfout", "Kan geen verbinding maken met de server:\n\n" + error_message + "\n\nControleer je internetverbinding en probeer opnieuw.")
	_reset_create_state()

func _reset_create_state():
	is_creating_session = false
	create_button.disabled = false
	back_button.disabled = false
	create_button.text = "🎮 Sessie Aanmaken"
	create_button.modulate = Color.WHITE

func show_error(title: String, message: String):
	CustomDialog.create_dialog(self, CustomDialog.DialogType.ERROR, title, message, "OK")

func show_info(title: String, message: String):
	CustomDialog.create_dialog(self, CustomDialog.DialogType.INFO, title, message, "OK")

func _exit_tree():
	# Disconnect from network events
	if NetworkManager.session_created.is_connected(_on_session_created):
		NetworkManager.session_created.disconnect(_on_session_created)
	if NetworkManager.error_received.is_connected(_on_network_error):
		NetworkManager.error_received.disconnect(_on_network_error)
	if NetworkManager.connection_error.is_connected(_on_connection_error):
		NetworkManager.connection_error.disconnect(_on_connection_error)
