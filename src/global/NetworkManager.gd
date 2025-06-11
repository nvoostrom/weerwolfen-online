extends Node

# WebSocket connection
var ws_client: WebSocketPeer
var connection_status: int = WebSocketPeer.STATE_CLOSED
var server_url: String = "wss://weerwolven.website-warriors.nl"  # Change this to your domain
# For development, you can use: "ws://localhost:3000"
var reconnect_timer: Timer
var ping_timer: Timer

# Connection events
signal connected_to_server
signal disconnected_from_server
signal connection_error(error: String)

# Game events
signal session_created(pin: String, player_id: String)
signal session_joined(pin: String, player_id: String, player_data: Dictionary)
signal player_list_updated(players: Array)
signal game_started(your_role: String)
signal session_closed(reason: String)
signal error_received(message: String)
signal pin_validation_result(pin: String, valid: bool, info: Dictionary)

# Current connection data
var current_player_id: String = ""
var current_session_pin: String = ""
var is_host: bool = false
var connection_attempts: int = 0
var max_connection_attempts: int = 5
var is_connecting: bool = false
var last_connection_state: int = WebSocketPeer.STATE_CLOSED

func _ready():
	# Setup timers
	setup_timers()
	
	# Initialize WebSocket
	ws_client = WebSocketPeer.new()

func setup_timers():
	# Reconnect timer
	reconnect_timer = Timer.new()
	reconnect_timer.wait_time = 3.0
	reconnect_timer.one_shot = true
	reconnect_timer.timeout.connect(_attempt_reconnect)
	add_child(reconnect_timer)
	
	# Ping timer to keep connection alive
	ping_timer = Timer.new()
	ping_timer.wait_time = 30.0
	ping_timer.timeout.connect(_send_ping)
	add_child(ping_timer)

func _process(_delta):
	if ws_client:
		ws_client.poll()
		var new_status = ws_client.get_ready_state()
		
		# Handle state changes
		if new_status != connection_status:
			_handle_connection_state_change(connection_status, new_status)
			connection_status = new_status
		
		match connection_status:
			WebSocketPeer.STATE_OPEN:
				# Connection successful
				if is_connecting:
					is_connecting = false
					connection_attempts = 0
					connected_to_server.emit()
					ping_timer.start()
				
				# Process incoming messages
				while ws_client.get_available_packet_count():
					var packet = ws_client.get_packet()
					var message_text = packet.get_string_from_utf8()
					_handle_server_message(message_text)
			
			WebSocketPeer.STATE_CONNECTING:
				# Still connecting, wait
				pass
			
			WebSocketPeer.STATE_CLOSED:
				# Connection closed
				if last_connection_state != WebSocketPeer.STATE_CLOSED:
					_handle_connection_closed()

func _handle_connection_state_change(old_state: int, _new_state: int):
	last_connection_state = old_state

func _state_to_string(state: int) -> String:
	match state:
		WebSocketPeer.STATE_CONNECTING:
			return "CONNECTING"
		WebSocketPeer.STATE_OPEN:
			return "OPEN"
		WebSocketPeer.STATE_CLOSING:
			return "CLOSING"
		WebSocketPeer.STATE_CLOSED:
			return "CLOSED"
		_:
			return "UNKNOWN"

func _handle_connection_closed():
	is_connecting = false
	
	if ping_timer and not ping_timer.is_stopped():
		ping_timer.stop()
	
	disconnected_from_server.emit()
	
	# Only attempt reconnection if we had a successful connection before
	if connection_attempts > 0 and connection_attempts < max_connection_attempts:
		reconnect_timer.start()
	elif connection_attempts >= max_connection_attempts:
		connection_error.emit("Could not connect to server after multiple attempts")

func connect_to_server() -> void:
	# Don't attempt connection if already connected or connecting
	if connection_status == WebSocketPeer.STATE_OPEN:
		connected_to_server.emit()
		return
	
	if is_connecting or connection_status == WebSocketPeer.STATE_CONNECTING:
		return
	
	connection_attempts += 1
	is_connecting = true
	
	# Reset WebSocket if it's not in a clean state
	if connection_status != WebSocketPeer.STATE_CLOSED:
		ws_client = WebSocketPeer.new()
	
	var error = ws_client.connect_to_url(server_url)
	if error != OK:
		is_connecting = false
		connection_error.emit("Failed to connect to server")
		
		# Schedule reconnection attempt
		if connection_attempts < max_connection_attempts:
			reconnect_timer.start()
		return
	
	# Wait for connection with timeout
	var timeout_timer = get_tree().create_timer(5.0)
	timeout_timer.timeout.connect(_on_connection_timeout)

func _on_connection_timeout():
	if is_connecting and connection_status != WebSocketPeer.STATE_OPEN:
		is_connecting = false
		ws_client.close()
		
		if connection_attempts < max_connection_attempts:
			reconnect_timer.start()
		else:
			connection_error.emit("Connection timeout")

func disconnect_from_server() -> void:
	is_connecting = false
	connection_attempts = 0
	
	if reconnect_timer and not reconnect_timer.is_stopped():
		reconnect_timer.stop()
	
	if ping_timer and not ping_timer.is_stopped():
		ping_timer.stop()
	
	if ws_client and connection_status != WebSocketPeer.STATE_CLOSED:
		ws_client.close()

func _attempt_reconnect():
	if connection_attempts < max_connection_attempts:
		connect_to_server()
	else:
		connection_error.emit("Could not connect to server after multiple attempts")

func _send_ping():
	send_message({"type": "ping"})

func send_message(data: Dictionary) -> void:
	if connection_status == WebSocketPeer.STATE_OPEN:
		var json_string = JSON.stringify(data)
		ws_client.send_text(json_string)

func _handle_server_message(message_text: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(message_text)
	
	if parse_result != OK:
		return
	
	var data = json.data
	
	match data.get("type", ""):
		"session_created":
			current_session_pin = data.pin
			current_player_id = data.playerId
			is_host = data.get("isHost", false)
			session_created.emit(data.pin, data.playerId)
			
		"joined_session":
			current_session_pin = data.pin
			current_player_id = data.playerId
			is_host = data.player.get("isHost", false)
			session_joined.emit(data.pin, data.playerId, data.player)
			
		"player_list_update":
			player_list_updated.emit(data.players)
			
		"game_started":
			var your_role = data.get("yourRole", "")
			game_started.emit(your_role)
			
		"session_closed":
			var reason = data.get("reason", "Session was closed")
			session_closed.emit(reason)
			
		"pin_validation_result":
			var pin = data.get("pin", "")
			var valid = data.get("valid", false)
			var info = {
				"playerCount": data.get("playerCount", 0),
				"maxPlayers": data.get("maxPlayers", 8),
				"error": data.get("error", "")
			}
			pin_validation_result.emit(pin, valid, info)
			
		"error":
			error_received.emit(data.message)
			
		"pong":
			# Server responded to ping
			pass

# API Methods for game actions
func create_session(settings: Dictionary, host_name: String = "Host") -> void:
	# Ensure we're connected before trying to create session
	if not is_connected_to_server():
		connect_to_server()
		
		# Wait for connection with timeout
		var attempts = 0
		while not is_connected_to_server() and attempts < 10:
			await get_tree().create_timer(0.5).timeout
			attempts += 1
		
		if not is_connected_to_server():
			error_received.emit("Could not connect to server")
			return
	
	send_message({
		"type": "create_session",
		"settings": settings,
		"hostName": host_name
	})

func join_session(pin: String, player_name: String) -> void:
	if not is_connected_to_server():
		connect_to_server()
		await get_tree().create_timer(0.5).timeout
	
	if is_connected_to_server():
		send_message({
			"type": "join_session",
			"pin": pin,
			"playerName": player_name
		})
	else:
		error_received.emit("Could not connect to server")

func set_player_ready(is_ready: bool) -> void:
	send_message({
		"type": "set_ready",
		"ready": is_ready
	})

func start_game() -> void:
	if is_host:
		send_message({
			"type": "start_game"
		})

func leave_session() -> void:
	disconnect_from_server()
	current_player_id = ""
	current_session_pin = ""
	is_host = false

# Helper methods
func is_connected_to_server() -> bool:
	return connection_status == WebSocketPeer.STATE_OPEN

func get_current_session_pin() -> String:
	return current_session_pin

func get_current_player_id() -> String:
	return current_player_id

func is_current_player_host() -> bool:
	return is_host

func request_player_list() -> void:
	send_message({
		"type": "request_player_list"
	})

func validate_pin(pin: String) -> void:
	if not is_connected_to_server():
		connect_to_server()
		await get_tree().create_timer(0.5).timeout
	
	if is_connected_to_server():
		send_message({
			"type": "validate_pin",
			"pin": pin
		})
	else:
		pin_validation_result.emit(pin, false, {"error": "Could not connect to server"})
