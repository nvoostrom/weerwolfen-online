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

func _ready():
	print("GameModal _ready called")
	print("modal_background: ", modal_background)
	print("initial_options: ", initial_options)
	print("pin_entry: ", pin_entry)
	
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

func _on_modal_background_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.position.x < modal_content.global_position.x or \
		   event.position.x > modal_content.global_position.x + modal_content.size.x or \
		   event.position.y < modal_content.global_position.y or \
		   event.position.y > modal_content.global_position.y + modal_content.size.y:
			hide_modal()

func show_initial_options():
	print("show_initial_options called")
	print("modal_background exists: ", modal_background != null)
	print("initial_options exists: ", initial_options != null)
	print("pin_entry exists: ", pin_entry != null)
	
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
		print("Modal background set to visible")
	else:
		print("ERROR: modal_background is null!")

func show_pin_entry():
	title_label.text = "Sessie Deelnemen"
	initial_options.visible = false
	pin_entry.visible = true
	pin_input.text = ""
	pin_input.grab_focus()

func hide_modal():
	self.visible = false
	pin_input.text = ""

func _on_close_button_pressed():
	hide_modal()

func _on_join_button_pressed():
	join_session_requested.emit()

func _on_create_button_pressed():
	create_session_requested.emit()

func _on_confirm_pin_button_pressed():
	var pin = pin_input.text.strip_edges()
	if pin.length() > 0:
		pin_entered.emit(pin)
		hide_modal()

func _on_back_button_pressed():
	show_initial_options()
