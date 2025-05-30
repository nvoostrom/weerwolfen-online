extends Control

@onready var back_button = $TopBar/BackButton
@onready var create_button = $TopBar/CreateButton
@onready var player_count_spinner = $ScrollContainer/VBoxContainer/PlayerSection/PlayerCountSpinner
@onready var roles_container = $ScrollContainer/VBoxContainer/RolesSection/RolesContainer
@onready var discussion_time_spinner = $ScrollContainer/VBoxContainer/RulesSection/RulesContainer/DiscussionTime/TimeSpinner
@onready var voting_time_spinner = $ScrollContainer/VBoxContainer/RulesSection/RulesContainer/VotingTime/TimeSpinner
@onready var night_time_spinner = $ScrollContainer/VBoxContainer/RulesSection/RulesContainer/NightTime/TimeSpinner

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

func setup_player_count_spinner():
	player_count_spinner.min_value = 4
	player_count_spinner.max_value = 20
	player_count_spinner.value = 8
	player_count_spinner.step = 1

func setup_roles_section():
	# For now, only show Burger role as requested
	var available_roles = GameData.get_available_roles()
	for role in available_roles:
		var checkbox = CheckBox.new()
		checkbox.text = role
		checkbox.button_pressed = true  # Burger is selected by default
		checkbox.disabled = true  # Disable for now since only Burger is implemented
		checkbox.toggled.connect(_on_role_toggled.bind(role))
		roles_container.add_child(checkbox)

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
		get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

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
		show_error("Selecteer minimaal één rol!")
		return
	
	if player_count < 4:
		show_error("Minimum 4 spelers vereist!")
		return
	
	# Ask for host name
	show_host_name_dialog(player_count, rules)

func show_host_name_dialog(player_count: int, rules: Dictionary):
	var dialog = AcceptDialog.new()
	dialog.title = "Voer je naam in"
	dialog.dialog_text = "Voer je naam in als host:"
	
	# Add line edit for name input
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Je naam..."
	line_edit.text = "Host"
	
	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = "Naam:"
	vbox.add_child(label)
	vbox.add_child(line_edit)
	
	dialog.add_child(vbox)
	add_child(dialog)
	
	dialog.confirmed.connect(_on_host_name_confirmed.bind(line_edit, player_count, rules, dialog))
	dialog.popup_centered()
	line_edit.grab_focus()

func _on_host_name_confirmed(line_edit: LineEdit, player_count: int, rules: Dictionary, dialog: AcceptDialog):
	var host_name = line_edit.text.strip_edges()
	if host_name.is_empty():
		host_name = "Host"
	
	dialog.queue_free()
	
	# Check if already creating a session
	if is_creating_session:
		return
	
	# Show loading state
	is_creating_session = true
	create_button.text = "Sessie wordt aangemaakt..."
	create_button.disabled = true
	back_button.disabled = true
	
	# Small delay to ensure UI updates
	await get_tree().process_frame
	
	# Create the session via network
	GameData.create_new_session(player_count, selected_roles, rules, host_name)

func _on_session_created(pin: String, player_id: String):
	print("Session created successfully with PIN: ", pin)
	
	# Reset UI state
	is_creating_session = false
	create_button.disabled = false
	back_button.disabled = false
	create_button.text = "Sessie Aanmaken"
	
	# Small delay to ensure everything is ready
	await get_tree().create_timer(0.1).timeout
	
	# Navigate to session screen
	get_tree().change_scene_to_file("res://scenes/SessionScreen.tscn")

func _on_network_error(error_message: String):
	print("Network error in CreateSessionScreen: ", error_message)
	show_error("Network fout: " + error_message)
	reset_create_button()

func _on_connection_error(error_message: String):
	print("Connection error in CreateSessionScreen: ", error_message)
	show_error("Verbindingsfout: " + error_message)
	reset_create_button()

func reset_create_button():
	is_creating_session = false
	create_button.disabled = false
	back_button.disabled = false
	create_button.text = "Sessie Aanmaken"

func show_error(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Fout"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _exit_tree():
	# Disconnect from network events
	if NetworkManager.session_created.is_connected(_on_session_created):
		NetworkManager.session_created.disconnect(_on_session_created)
	if NetworkManager.error_received.is_connected(_on_network_error):
		NetworkManager.error_received.disconnect(_on_network_error)
	if NetworkManager.connection_error.is_connected(_on_connection_error):
		NetworkManager.connection_error.disconnect(_on_connection_error)
