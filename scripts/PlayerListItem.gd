extends Control

@onready var player_name_label = $MarginContainer/HBoxContainer/PlayerInfo/PlayerNameLabel
@onready var player_status_label = $MarginContainer/HBoxContainer/PlayerInfo/PlayerStatusLabel
@onready var player_avatar = $MarginContainer/HBoxContainer/PlayerAvatar
@onready var host_badge = $MarginContainer/HBoxContainer/BadgesContainer/HostBadge
@onready var ready_indicator = $MarginContainer/HBoxContainer/BadgesContainer/ReadyIndicator

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
	
	# Set avatar based on host status
	if is_host:
		player_avatar.text = "👑"
		player_status_label.text = "Spelleider"
	else:
		player_avatar.text = "👤"
		player_status_label.text = "Dorpsbewoner"
	
	# Show host badge
	host_badge.visible = is_host
	if is_host:
		host_badge.text = "👑 HOST"
		host_badge.modulate = Color.GOLD
	
	update_ready_status()
	
	# Add subtle hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func update_ready_status():
	if not ready_indicator:
		return
	
	if is_ready:
		ready_indicator.text = "✓"
		ready_indicator.modulate = Color.GREEN
		
		# Add pulse animation for ready state
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(ready_indicator, "scale", Vector2(1.2, 1.2), 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(ready_indicator, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_SINE)
	else:
		ready_indicator.text = "○"
		ready_indicator.modulate = Color.GRAY
		ready_indicator.scale = Vector2.ONE  # Stop pulsing

func set_ready_status(ready: bool):
	var was_ready = is_ready
	is_ready = ready
	
	# Animate the ready status change
	if ready != was_ready:
		_animate_ready_change(ready)
	
	update_ready_status()

func _animate_ready_change(ready: bool):
	# Scale animation for status change
	var tween = create_tween()
	tween.tween_property(ready_indicator, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(ready_indicator, "scale", Vector2.ONE, 0.2)
	
	if ready:
		# Green flash for becoming ready
		var flash_tween = create_tween()
		flash_tween.tween_property(self, "modulate", Color.GREEN, 0.1)
		flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)

# Add entrance animation method that can be called externally
func animate_entrance():
	scale = Vector2.ZERO
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

# Add exit animation method that can be called externally
func animate_exit():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 0.0), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Queue free after animation
	tween.tween_callback(queue_free).set_delay(0.3)
