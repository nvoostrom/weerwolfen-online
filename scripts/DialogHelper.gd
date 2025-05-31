extends Node

enum DialogType {
	INFO,
	WARNING, 
	ERROR,
	INPUT,
	CONFIRMATION
}

static func show_info(parent: Node, title: String, message: String):
	return load("res://scripts/CustomDialog.gd").create_dialog(parent, DialogType.INFO, title, message, "OK")

static func show_error(parent: Node, title: String, message: String):
	return load("res://scripts/CustomDialog.gd").create_dialog(parent, DialogType.ERROR, title, message, "OK")

static func show_warning(parent: Node, title: String, message: String):
	return load("res://scripts/CustomDialog.gd").create_dialog(parent, DialogType.WARNING, title, message, "OK")

static func show_confirmation(parent: Node, title: String, message: String, confirm_text: String = "Ja", cancel_text: String = "Nee"):
	return load("res://scripts/CustomDialog.gd").create_dialog(parent, DialogType.CONFIRMATION, title, message, confirm_text, cancel_text)

static func show_input(parent: Node, title: String, message: String, placeholder: String = "", default_text: String = ""):
	var dialog = load("res://scripts/CustomDialog.gd").create_dialog(parent, DialogType.INPUT, title, message, "Bevestigen", "Annuleren")
	if dialog.line_edit:
		dialog.line_edit.placeholder_text = placeholder
		dialog.line_edit.text = default_text
	return dialog