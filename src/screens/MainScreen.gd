extends Control

@onready var start_button = $CenterContainer/MainPanel/VBoxContainer/ButtonSection/StartButton
@onready var game_modal = $GameModal

func _ready():
	# Connect signals
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	
	if game_modal:
		game_modal.join_session_requested.connect(_on_join_session_requested)
		game_modal.create_session_requested.connect(_on_create_session_requested)
		# Remove the pin_entered signal since we handle everything in GameModal now
	
	# Add visual polish
	call_deferred("_setup_ui_enhancements")

func _setup_ui_enhancements():
	if not start_button:
		return
	
	# Add hover effects to the start button
	start_button.mouse_entered.connect(_on_start_button_hover)
	start_button.mouse_exited.connect(_on_start_button_unhover)
	
	# Animate the main panel entrance
	var main_panel = get_node_or_null("CenterContainer/MainPanel")
	if main_panel:
		main_panel.modulate.a = 0.0
		main_panel.scale = Vector2(0.8, 0.8)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(main_panel, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(main_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_start_button_hover():
	if start_button:
		var tween = create_tween()
		tween.tween_property(start_button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_start_button_unhover():
	if start_button:
		var tween = create_tween()
		tween.tween_property(start_button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_start_button_pressed():
	if game_modal and game_modal.has_method("show_initial_options"):
		game_modal.show_initial_options()

func _on_join_session_requested():
	if game_modal:
		game_modal.show_pin_entry()

func _on_create_session_requested():
	# Smooth transition to create session screen
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
       tween.tween_callback(func(): get_tree().change_scene_to_file("res://src/screens/CreateSessionScreen.tscn"))
