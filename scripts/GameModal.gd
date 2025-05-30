extends Control

signal join_session_requested
signal create_session_requested
signal pin_entered(pin: String)

@onready var modal_background = $ModalBackground
@onready var modal_content = $ModalBackground/CenterContainer/ModalContent
@onready var title_label = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/TitleLabel
@onready var content_container = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer
@onready var close_button = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/TopBar/CloseButton

# Initial options UI
@onready var join_button = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/InitialOptions/CenterContainer/VBoxContainer/ButtonsContainer/JoinButton
@onready var create_button = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/InitialOptions/CenterContainer/VBoxContainer/ButtonsContainer/CreateButton
@onready var initial_options = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/InitialOptions

# PIN entry UI
@onready var pin_entry = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/PinEntry
@onready var pin_input = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/PinEntry/CenterContainer/VBoxContainer/PinSection/PinInput
@onready var confirm_pin_button = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/PinEntry/CenterContainer/VBoxContainer/ButtonsSection/ConfirmButton
@onready var back_button = $ModalBackground/CenterContainer/ModalContent/VBoxContainer/ContentContainer/PinEntry/CenterContainer/VBoxContainer/ButtonsSection/BackButton

var is_validating_pin: bool = false

func _ready():
	if modal_background:
		modal_background.visible = false
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_button_pressed)
	if create_button:
		create_button.pressed.connect(_on_create_button_pressed)
	if confirm_pin_button:
		confirm_pin_button.pressed.connect(_on_confirm_pin_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Close modal when clicking background
	if modal_background:
		modal_background.gui_input.connect(_on_modal_background_input)
	
	# Connect to PIN validation result
	NetworkManager.pin_validation_result.connect(_on_pin_validation_result)
	
	# Setup button hover effects
	_setup_button_effects()

func _setup_button_effects():
	# Add hover effects to buttons
	var buttons = [join_button, create_button, confirm_pin_button, back_button, close_button]
	
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_modal_background_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.position.x < modal_content.global_position.x or \
		   event.position.x > modal_content.global_position.x + modal_content.size.x or \
		   event.position.y < modal_content.global_position.y or \
		   event.position.y > modal_content.global_position.y + modal_content.size.y:
			hide_modal()

func show_initial_options():
	print("GameModal: show_initial_options() called")
	
	# Make the entire GameModal visible first
	self.visible = true
	
	if title_label:
		title_label.text = "Weerwolven Online"
	if initial_options:
		initial_options.visible = true
	if pin_entry:
		pin_entry.visible = false
	if modal_background:
		modal_background.visible = true
	
	# Animate modal entrance
	modal_content.scale = Vector2(0.8, 0.8)
	modal_content.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(modal_content, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal_content, "modulate:a", 1.0, 0.3)

func show_pin_entry():
	title_label.text = "Sessie Deelnemen"
	initial_options.visible = false
	pin_entry.visible = true
	pin_input.text = ""
	pin_input.grab_focus()
	
	# Reset validation state
	is_validating_pin = false
	confirm_pin_button.disabled = false
	confirm_pin_button.text = "✓ Bevestigen"
	
	# Animate transition
	var tween = create_tween()
	pin_entry.modulate.a = 0.0
	tween.tween_property(pin_entry, "modulate:a", 1.0, 0.3)

func hide_modal():
	# Animate modal exit
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(modal_content, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(modal_content, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		self.visible = false
		pin_input.text = ""
		is_validating_pin = false
	)

func _on_close_button_pressed():
	hide_modal()

func _on_join_button_pressed():
	join_session_requested.emit()

func _on_create_button_pressed():
	create_session_requested.emit()

func _on_confirm_pin_button_pressed():
	if is_validating_pin:
		return
	
	var pin = pin_input.text.strip_edges()
	if pin.length() == 0:
		show_pin_error("Voer een PIN in")
		return
	
	if pin.length() != 6 or not pin.is_valid_int():
		show_pin_error("PIN moet 6 cijfers zijn")
		return
	
	# Start validation with loading state
	is_validating_pin = true
	confirm_pin_button.disabled = true
	confirm_pin_button.text = "⏳ Valideren..."
	clear_pin_error()
	
	# Add pulsing animation while validating
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(confirm_pin_button, "modulate:a", 0.7, 0.5)
	tween.tween_property(confirm_pin_button, "modulate:a", 1.0, 0.5)
	
	# Validate PIN with server
	NetworkManager.validate_pin(pin)

func _on_pin_validation_result(pin: String, valid: bool, info: Dictionary):
	is_validating_pin = false
	confirm_pin_button.disabled = false
	confirm_pin_button.text = "✓ Bevestigen"
	confirm_pin_button.modulate.a = 1.0  # Stop pulsing
	
	if valid:
		# PIN is valid, proceed to join session
		show_success_feedback()
		await get_tree().create_timer(0.5).timeout
		pin_entered.emit(pin)
		hide_modal()
	else:
		# Show error in modal
		var error_message = info.get("error", "Ongeldige PIN")
		show_pin_error(error_message)

func show_success_feedback():
	# Brief success animation
	confirm_pin_button.text = "✅ Geldig!"
	confirm_pin_button.modulate = Color.GREEN
	
	var tween = create_tween()
	tween.tween_delay(0.5)
	tween.tween_callback(func(): confirm_pin_button.modulate = Color.WHITE)

func show_pin_error(message: String):
	# Show error by changing input appearance
	pin_input.modulate = Color.RED
	var original_placeholder = pin_input.placeholder_text
	pin_input.placeholder_text = message
	
	# Shake animation for error feedback
	var original_pos = pin_input.position
	var tween = create_tween()
	tween.tween_property(pin_input, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(pin_input, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(pin_input, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(pin_input, "position:x", original_pos.x, 0.05)
	
	# Reset after 3 seconds
	await get_tree().create_timer(3.0).timeout
	clear_pin_error()

func clear_pin_error():
	if pin_input:
		pin_input.modulate = Color.WHITE
		pin_input.placeholder_text = "123456"

func _on_back_button_pressed():
	show_initial_options()

func _exit_tree():
	if NetworkManager.pin_validation_result.is_connected(_on_pin_validation_result):
		NetworkManager.pin_validation_result.disconnect(_on_pin_validation_result)
