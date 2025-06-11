extends Control

@onready var player_name_label = $MarginContainer/HBoxContainer/PlayerInfo/PlayerNameLabel
@onready var player_status_label = $MarginContainer/HBoxContainer/PlayerInfo/PlayerStatusLabel
@onready var player_avatar = $MarginContainer/HBoxContainer/PlayerAvatar
@onready var host_badge = $MarginContainer/HBoxContainer/BadgesContainer/HostBadge
@onready var ready_indicator = $MarginContainer/HBoxContainer/BadgesContainer/ReadyIndicator

var player_name: String = ""
var is_host: bool = false
var is_ready: bool = false
var player_role: String = ""
var game_started: bool = false

func setup_player(player_name_param: String, host: bool = false, ready_status: bool = false, role: String = ""):
	player_name = player_name_param
	is_host = host
	is_ready = ready_status
	player_role = role
	
	update_display()

func set_game_started(started: bool):
	game_started = started
	update_display()

func update_display():
	if not player_name_label:
		await ready
	
	player_name_label.text = player_name
	
	# Set avatar based on host status
	if is_host:
		player_avatar.text = "👑"
	else:
		player_avatar.text = "👤"
	
	# Show host badge
	host_badge.visible = is_host
	if is_host:
		host_badge.text = "👑 HOST"
		host_badge.modulate = Color.GOLD
	
	# Update status label based on game state
	if game_started and not player_role.is_empty():
		# Game has started, show the role
		player_status_label.text = player_role
	else:
		# Game hasn't started, show generic status
		if is_host:
			player_status_label.text = "Spelleider"
		else:
			player_status_label.text = "Dorpsbewoner"
	
	update_ready_status()
	
	# Add subtle hover effect that stays within container
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	# Use a smaller scale and clip the content to prevent overflow
	var inner_content = $MarginContainer
	if inner_content:
		var tween = create_tween()
		# Much smaller scale to prevent overflow
		tween.tween_property(inner_content, "scale", Vector2(1.01, 1.01), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		# Add subtle glow effect instead of scaling
		var panel_inner = get_node_or_null("PanelInner")
		if panel_inner:
			var glow_tween = create_tween()
			glow_tween.tween_property(panel_inner, "modulate", Color(1.05, 1.02, 0.95, 1), 0.2)

func _on_mouse_exited():
	var inner_content = $MarginContainer
	if inner_content:
		var tween = create_tween()
		tween.tween_property(inner_content, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		# Reset glow effect
		var panel_inner = get_node_or_null("PanelInner")
		if panel_inner:
			var glow_tween = create_tween()
			glow_tween.tween_property(panel_inner, "modulate", Color.WHITE, 0.2)

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

func set_ready_status(ready_status: bool):
	var was_ready = is_ready
	is_ready = ready_status
	
	# Animate the ready status change
	if ready_status != was_ready:
		_animate_ready_change(ready_status)
	
	update_ready_status()

func set_role(role: String):
	player_role = role
	update_display()

func _animate_ready_change(ready_status: bool):
	# Scale animation for status change
	var tween = create_tween()
	tween.tween_property(ready_indicator, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(ready_indicator, "scale", Vector2.ONE, 0.2)
	
	if ready_status:
		# Green flash for becoming ready - apply to inner panel to stay contained
		var panel_inner = get_node_or_null("PanelInner")
		if panel_inner:
			var flash_tween = create_tween()
			flash_tween.tween_property(panel_inner, "modulate", Color(0.9, 1.1, 0.9, 1), 0.1)
			flash_tween.tween_property(panel_inner, "modulate", Color.WHITE, 0.3)

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
