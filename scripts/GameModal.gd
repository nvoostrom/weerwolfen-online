extends Control

signal join_session_requested
signal create_session_requested
signal pin_entered(pin: String)

@onready var modal_background = $ModalBackground
@onready var modal_content = $ModalBackground/ModalContent
@onready var title_label = $ModalBackground/ModalContent/VBoxContainer/TitleLabel
@onready var content_container = $ModalBackground/ModalContent/VBoxContainer/ContentContainer
@onready var close_button = $ModalBackground/ModalContent/VBoxContainer/TopBar/CloseButton

# Initial options UI
@onready var join_button = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/InitialOptions/VBoxContainer/JoinButton
@onready var create_button = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/InitialOptions/VBoxContainer/CreateButton
@onready var initial_options = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/InitialOptions

# PIN entry UI
@onready var pin_entry = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/PinEntry
@onready var pin_input = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/PinEntry/VBoxContainer/PinInput
@onready var confirm_pin_button = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/PinEntry/VBoxContainer/ConfirmButton
@onready var back_button = $ModalBackground/ModalContent/VBoxContainer/ContentContainer/PinEntry/VBoxContainer/BackButton

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

func _on_modal_background_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.position.x < modal_content.global_position.x or \
		   event.position.x > modal_content.global_position.x + modal_content.size.x or \
		   event.position.y < modal_content.global_position.y or \
		   event.position.y > modal_content.global_position.y + modal_content.size.y:
			hide_modal()

func show_initial_options():
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

func show_pin_entry():
	title_label.text = "Sessie Deelnemen"
	initial_options.visible = false
	pin_entry.visible = true
	pin_input.text = ""
	pin_input.grab_focus()
	
	# Reset validation state
	is_validating_pin = false
	confirm_pin_button.disabled = false
	confirm_pin_button.text = "Bevestigen"

func hide_modal():
	self.visible = false
	pin_input.text = ""
	is_validating_pin = false

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
	
	# Start validation
	is_validating_pin = true
	confirm_pin_button.disabled = true
	confirm_pin_button.text = "Valideren..."
	clear_pin_error()
	
	# Validate PIN with server
	NetworkManager.validate_pin(pin)

func _on_pin_validation_result(pin: String, valid: bool, info: Dictionary):
	is_validating_pin = false
	confirm_pin_button.disabled = false
	confirm_pin_button.text = "Bevestigen"
	
	if valid:
		# PIN is valid, proceed to join session
		pin_entered.emit(pin)
		hide_modal()
	else:
		# Show error in modal
		var error_message = info.get("error", "Ongeldige PIN")
		show_pin_error(error_message)

func show_pin_error(message: String):
	# Show error by changing input appearance
	pin_input.modulate = Color.RED
	var original_placeholder = pin_input.placeholder_text
	pin_input.placeholder_text = message
	
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
