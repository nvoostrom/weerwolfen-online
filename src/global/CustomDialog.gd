extends Control
const UIHelper = preload("res://src/global/UIHelper.gd")

signal confirmed
signal cancelled

enum DialogType {
	INFO,
	WARNING,
	ERROR,
	INPUT,
	CONFIRMATION
}

var dialog_type: DialogType = DialogType.INFO
var input_text: String = ""
var line_edit: LineEdit

var modal_background: ColorRect
var dialog_panel: Panel
var content_container: VBoxContainer
var title_label: Label
var message_label: Label
var icon_label: Label
var button_container: HBoxContainer
var confirm_button: Button
var cancel_button: Button

func _ready():
	name = "CustomDialog"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_dialog_structure()

func _create_dialog_structure():
	# Modal background
	modal_background = ColorRect.new()
	modal_background.color = Color(0, 0, 0, 0.7)
	modal_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_background)
	
	# Center container
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_background.add_child(center_container)
	
	# Dialog panel
	dialog_panel = Panel.new()
	dialog_panel.custom_minimum_size = Vector2(420, 280)
	center_container.add_child(dialog_panel)
	
	# Panel background layers (medieval style)
	var panel_bg = ColorRect.new()
	panel_bg.color = Color(0.92, 0.87, 0.75, 1)  # Cream background
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(panel_bg)
	
	var panel_border = ColorRect.new()
	panel_border.color = Color(0.65, 0.45, 0.3, 1)  # Brown border
	panel_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_border.set_offset(SIDE_LEFT, 8)
	panel_border.set_offset(SIDE_TOP, 8)
	panel_border.set_offset(SIDE_RIGHT, -8)
	panel_border.set_offset(SIDE_BOTTOM, -8)
	panel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(panel_border)
	
	var panel_inner = ColorRect.new()
	panel_inner.color = Color(0.98, 0.95, 0.88, 1)  # Light cream inner
	panel_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_inner.set_offset(SIDE_LEFT, 16)
	panel_inner.set_offset(SIDE_TOP, 16)
	panel_inner.set_offset(SIDE_RIGHT, -16)
	panel_inner.set_offset(SIDE_BOTTOM, -16)
	panel_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(panel_inner)
	
	# Content container with proper padding
	content_container = VBoxContainer.new()
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.set_offset(SIDE_LEFT, 30)
	content_container.set_offset(SIDE_TOP, 30)
	content_container.set_offset(SIDE_RIGHT, -30)
	content_container.set_offset(SIDE_BOTTOM, -30)
	content_container.add_theme_constant_override("separation", 20)
	dialog_panel.add_child(content_container)
	
	# Header container
	var header_container = HBoxContainer.new()
	header_container.add_theme_constant_override("separation", 12)
	content_container.add_child(header_container)
	
	# Icon
	icon_label = Label.new()
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(45, 45)
	header_container.add_child(icon_label)
	
	# Title and message container
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 8)
	header_container.add_child(text_container)
	
	# Title
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05, 1))  # Dark brown
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_container.add_child(title_label)
	
	# Message
	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 13)
	message_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))  # Medium brown
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_container.add_child(message_label)
	
	# Button container with better spacing
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_container.add_child(button_container)

func _create_medieval_button(text: String, is_primary: bool = false) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 35)
	button.add_theme_font_size_override("font_size", 13)
	
	# Style the button directly with theme overrides instead of background children
	if is_primary:
		# Primary button styling
		button.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88, 1))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.9, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.8, 1.0))
		
		# Create a simple background panel for primary button
		var bg_panel = Panel.new()
		bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.z_index = -1
		button.add_child(bg_panel)
		
		# Style the background panel
		var bg_color = ColorRect.new()
		bg_color.color = Color(0.65, 0.35, 0.15, 1)
		bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.add_child(bg_color)
		
	else:
		# Secondary button styling
		button.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
		button.add_theme_color_override("font_hover_color", Color(0.4, 0.3, 0.2, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.2, 0.1, 0.05, 1))
		
		# Create a simple background panel for secondary button
		var bg_panel = Panel.new()
		bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.z_index = -1
		button.add_child(bg_panel)
		
		# Style the background panel
		var bg_color = ColorRect.new()
		bg_color.color = Color(0.85, 0.80, 0.70, 1)
		bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.add_child(bg_color)
	
        # Add hover effects
        UIHelper.add_hover_effect(button)
	
	return button


func setup_dialog(type: DialogType, title: String, message: String, confirm_text: String = "OK", cancel_text: String = "Annuleren"):
	dialog_type = type
	title_label.text = title
	message_label.text = message
	
	# Set icon based on type
	match type:
		DialogType.INFO:
			icon_label.text = "ℹ️"
			icon_label.modulate = Color(0.2, 0.6, 1.0, 1.0)  # Blue
		DialogType.WARNING:
			icon_label.text = "⚠️"
			icon_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Orange
		DialogType.ERROR:
			icon_label.text = "❌"
			icon_label.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red
		DialogType.INPUT:
			icon_label.text = "✏️"
			icon_label.modulate = Color(0.3, 0.8, 0.3, 1.0)  # Green
		DialogType.CONFIRMATION:
			icon_label.text = "❓"
			icon_label.modulate = Color(1.0, 0.6, 0.0, 1.0)  # Orange
	
	# Clear existing buttons
	for child in button_container.get_children():
		child.queue_free()
	
	# Add input field for INPUT type with proper styling
	if type == DialogType.INPUT:
		var input_container = CenterContainer.new()
		content_container.add_child(input_container)
		content_container.move_child(input_container, content_container.get_child_count() - 2)  # Before buttons
		
		line_edit = LineEdit.new()
		line_edit.placeholder_text = "Voer tekst in..."
		line_edit.custom_minimum_size = Vector2(180, 32)
		line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		line_edit.add_theme_font_size_override("font_size", 13)
		line_edit.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05, 1))
		
		input_container.add_child(line_edit)
	
	# Create buttons with medieval style
	if type == DialogType.CONFIRMATION or type == DialogType.INPUT:
		# Two buttons
		cancel_button = _create_medieval_button(cancel_text, false)
		cancel_button.pressed.connect(_on_cancel_pressed)
		button_container.add_child(cancel_button)
		
		confirm_button = _create_medieval_button(confirm_text, true)
		confirm_button.pressed.connect(_on_confirm_pressed)
		button_container.add_child(confirm_button)
	else:
		# Single OK button
		confirm_button = _create_medieval_button(confirm_text, true)
		confirm_button.pressed.connect(_on_confirm_pressed)
		button_container.add_child(confirm_button)
	
	# Focus input field or confirm button
	if type == DialogType.INPUT and line_edit:
		line_edit.grab_focus()
	else:
		confirm_button.grab_focus()

func show_dialog():
	# Animate entrance
	modulate.a = 0.0
	dialog_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(dialog_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_dialog():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(dialog_panel, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free).set_delay(0.3)

func _on_confirm_pressed():
	if dialog_type == DialogType.INPUT and line_edit:
		input_text = line_edit.text.strip_edges()
	confirmed.emit()
	hide_dialog()

func _on_cancel_pressed():
	cancelled.emit()
	hide_dialog()

func get_input_text() -> String:
	return input_text

# Helper function to create dialogs easily
static func create_dialog(parent: Node, type: DialogType, title: String, message: String, confirm_text: String = "OK", cancel_text: String = "Annuleren") -> Control:
	var dialog = preload("res://src/global/CustomDialog.gd").new()
	parent.add_child(dialog)
	dialog.setup_dialog(type, title, message, confirm_text, cancel_text)
	dialog.show_dialog()
	return dialog
