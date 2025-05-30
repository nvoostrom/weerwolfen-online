extends Control

@onready var back_button = $TopBar/BackButton
@onready var create_button = $TopBar/CreateButton
@onready var player_count_spinner = $ScrollContainer/VBoxContainer/PlayerSection/PlayerCountSpinner
@onready var roles_container = $ScrollContainer/VBoxContainer/RolesSection/RolesContainer
@onready var discussion_time_spinner = $ScrollContainer/VBoxContainer/RulesSection/RulesContainer/DiscussionTime/TimeSpinner
@onready var voting_time_spinner = $ScrollContainer/VBoxContainer/RulesSection/RulesContainer/VotingTime/TimeSpinner
@onready var night_time_spinner = $ScrollContainer/VBoxContainer/RulesSection/RulesContainer/NightTime/TimeSpinner

var selected_roles: Array[String] = ["Burger"]

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	
	setup_player_count_spinner()
	setup_roles_section()
	setup_rules_spinners()

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
	get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func _on_create_button_pressed():
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
	
	# Create the session
	GameData.create_new_session(player_count, selected_roles, rules)
	
	# Navigate to session screen
	get_tree().change_scene_to_file("res://scenes/SessionScreen.tscn")

func show_error(message: String):
	# Simple error display - could be enhanced with a proper dialog
	print("Error: " + message)
	# TODO: Implement proper error dialog
