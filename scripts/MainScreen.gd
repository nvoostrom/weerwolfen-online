extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var game_modal = $GameModal

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	game_modal.join_session_requested.connect(_on_join_session_requested)
	game_modal.create_session_requested.connect(_on_create_session_requested)
	game_modal.pin_entered.connect(_on_pin_entered)

func _on_start_button_pressed():
	print("Start button pressed!")
	if game_modal:
		print("Game modal found, showing options...")
		game_modal.show_initial_options()
	else:
		print("ERROR: Game modal not found!")

func _on_join_session_requested():
	game_modal.show_pin_entry()

func _on_create_session_requested():
	get_tree().change_scene_to_file("res://scenes/CreateSessionScreen.tscn")

func _on_pin_entered(pin: String):
	# Store the PIN for the join session screen
	GameData.join_pin = pin
	get_tree().change_scene_to_file("res://scenes/JoinSessionScreen.tscn")
