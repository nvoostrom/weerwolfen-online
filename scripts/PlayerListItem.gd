extends Control

@onready var player_name_label = $HBoxContainer/PlayerNameLabel
@onready var host_badge = $HBoxContainer/HostBadge
@onready var ready_indicator = $HBoxContainer/ReadyIndicator

var player_name: String = ""
var is_host: bool = false
var is_ready: bool = false

func setup_player(name: String, host: bool = false, ready: bool = false):
	player_name = name
	is_host = host
	is_ready = ready
	
	update_display()

func update_display():
	if not player_name_label:
		await ready
	
	player_name_label.text = player_name
	host_badge.visible = is_host
	
	if is_host:
		host_badge.text = "HOST"
		host_badge.modulate = Color.GOLD
	
	update_ready_status()

func update_ready_status():
	if not ready_indicator:
		return
	
	if is_ready:
		ready_indicator.text = "✓"
		ready_indicator.modulate = Color.GREEN
	else:
		ready_indicator.text = "○"
		ready_indicator.modulate = Color.GRAY

func set_ready_status(ready: bool):
	is_ready = ready
	update_ready_status()
