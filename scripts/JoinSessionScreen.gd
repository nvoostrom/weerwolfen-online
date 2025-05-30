extends Control

@onready var back_button = $TopBar/BackButton
@onready var pin_label = $VBoxContainer/PinSection/PinLabel
@onready var player_name_input = $VBoxContainer/JoinSection/PlayerNameInput
@onready var join_button = $VBoxContainer/JoinSection/JoinButton
@onready var players_list = $VBoxContainer/PlayersSection/ScrollContainer/PlayersList
@onready var waiting_label = $VBoxContainer/StatusSection/WaitingLabel

var current_pin: String = ""

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	
	current_pin = GameData.join_pin
	pin_label.text = "PIN: " + current_pin
	
	# Set placeholder text
	player_name_input.placeholder_text = "Voer je naam in..."
	
	# Simulate joining session validation
	validate_session()

func validate_session():
	# In a real implementation, this would validate the PIN with a server
	# For now, we'll simulate a successful validation
	waiting_label.text = "Verbinding maken met sessie..."
	
	# Simulate network delay
	await get_tree().create_timer(1.0).timeout
	
	if is_valid_pin(current_pin):
		waiting_label.text = "Sessie gevonden! Voer je naam in om deel te nemen."
		player_name_input.editable = true
		join_button.disabled = false
		load_existing_players()
	else:
		waiting_label.text = "Ongeldige PIN. Controleer de PIN en probeer opnieuw."
		join_button.disabled = true

func is_valid_pin(pin: String) -> bool:
	# In a real implementation, this would check with a server
	# For demo purposes, accept any 6-digit PIN
	return pin.length() == 6 and pin.is_valid_int()

func load_existing_players():
	# In a real implementation, this would load from server
	# For demo, show some sample players
	add_player_to_list("Host", true)
	add_player_to_list("Speler1", false)

func add_player_to_list(player_name: String, is_host: bool):
	var player_item = preload("res://components/PlayerListItem.tscn").instantiate()
	player_item.setup_player(player_name, is_host)
	players_list.add_child(player_item)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainScreen.tscn")

func _on_join_button_pressed():
	var player_name = player_name_input.text.strip_edges()
	
	if player_name.is_empty():
		show_error("Voer een geldige naam in!")
		return
	
	if player_name.length() < 2:
		show_error("Naam moet minimaal 2 karakters zijn!")
		return
	
	# Add player to session
	if GameData.add_player(player_name):
		# Navigate to session screen
		get_tree().change_scene_to_file("res://scenes/SessionScreen.tscn")
	else:
		show_error("Sessie is vol!")

func show_error(message: String):
	# Simple error display
	waiting_label.text = "Fout: " + message
	waiting_label.modulate = Color.RED
	
	# Reset color after 3 seconds
	await get_tree().create_timer(3.0).timeout
	waiting_label.modulate = Color.WHITE
