extends Node

const CustomDialogClass = preload("res://src/global/CustomDialog.gd")
const DialogType = CustomDialogClass.DialogType

static func show_info(parent: Node, title: String, message: String, confirm_text: String = "OK"):
	return CustomDialogClass.create_dialog(parent, DialogType.INFO, title, message, confirm_text)

static func show_error(parent: Node, title: String, message: String, confirm_text: String = "OK"):
	return CustomDialogClass.create_dialog(parent, DialogType.ERROR, title, message, confirm_text)

static func show_warning(parent: Node, title: String, message: String, confirm_text: String = "OK"):
	return CustomDialogClass.create_dialog(parent, DialogType.WARNING, title, message, confirm_text)

static func show_confirmation(parent: Node, title: String, message: String, confirm_text: String = "Ja", cancel_text: String = "Nee"):
	return CustomDialogClass.create_dialog(parent, DialogType.CONFIRMATION, title, message, confirm_text, cancel_text)

static func show_input(parent: Node, title: String, message: String, placeholder: String = "", default_text: String = "", confirm_text: String = "Bevestigen", cancel_text: String = "Annuleren"):
	var dialog = CustomDialogClass.create_dialog(parent, DialogType.INPUT, title, message, confirm_text, cancel_text)
	if dialog.line_edit:
		dialog.line_edit.placeholder_text = placeholder
		dialog.line_edit.text = default_text
	return dialog
