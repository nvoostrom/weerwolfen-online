extends RefCounted

enum DialogType {
	INFO,
	WARNING, 
	ERROR,
	INPUT,
	CONFIRMATION
}

static func show_info(parent: Node, title: String, message: String):
	var dialog_script = load("res://scripts/CustomDialog.gd")
	var dialog = dialog_script.new()
	parent.add_child(dialog)
	dialog.setup_dialog(DialogHelper.DialogType.INFO, title, message, "OK")
	dialog.show_dialog()
	return dialog

static func show_error(parent: Node, title: String, message: String):
	var dialog_script = load("res://scripts/CustomDialog.gd")
	var dialog = dialog_script.new()
	parent.add_child(dialog)
	dialog.setup_dialog(DialogHelper.DialogType.ERROR, title, message, "OK")
	dialog.show_dialog()
	return dialog

static func show_warning(parent: Node, title: String, message: String):
	var dialog_script = load("res://scripts/CustomDialog.gd")
	var dialog = dialog_script.new()
	parent.add_child(dialog)
	dialog.setup_dialog(DialogHelper.DialogType.WARNING, title, message, "OK")
	dialog.show_dialog()
	return dialog

static func show_confirmation(parent: Node, title: String, message: String, confirm_text: String = "Ja", cancel_text: String = "Nee"):
	var dialog_script = load("res://scripts/CustomDialog.gd")
	var dialog = dialog_script.new()
	parent.add_child(dialog)
	dialog.setup_dialog(DialogHelper.DialogType.CONFIRMATION, title, message, confirm_text, cancel_text)
	dialog.show_dialog()
	return dialog

static func show_input(parent: Node, title: String, message: String, placeholder: String = "", default_text: String = ""):
	var dialog_script = load("res://scripts/CustomDialog.gd")
	var dialog = dialog_script.new()
	parent.add_child(dialog)
	dialog.setup_dialog(DialogHelper.DialogType.INPUT, title, message, "Bevestigen", "Annuleren")
	if dialog.line_edit:
		dialog.line_edit.placeholder_text = placeholder
		dialog.line_edit.text = default_text
	dialog.show_dialog()
	return dialog