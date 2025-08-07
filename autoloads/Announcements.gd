extends Node

const CONNECTION_KEEPER_INTERVAL = 5.0
var URL :String

var ws: WebSocketPeer = null
var ws_connected: bool = false
var is_connecting: bool = false


func _ready() -> void:
	URL = Routes.get_ws_url()

	var conn_timer := Timer.new()
	conn_timer.wait_time = CONNECTION_KEEPER_INTERVAL
	conn_timer.autostart = true
	conn_timer.one_shot = false
	conn_timer.timeout.connect(_manage_ws_connection)
	add_child(conn_timer)

func _process(_delta: float) -> void:
	# Make a new websocket if is null
	if ws == null: return

	ws.poll()

	var state = ws.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not ws_connected:
				# Conneccted
				ws_connected = true
				is_connecting = false
				if AppConfig.DEBUG_MODE: print("[WEBSOCKET] Websocket connected")

			# Get messages
			while ws.get_available_packet_count():
				var packet = ws.get_packet()
				if AppConfig.DEBUG_MODE: print("[WEBSOCKET] Received package: ", packet.get_string_from_utf8())

		WebSocketPeer.STATE_CLOSING:
			pass

		WebSocketPeer.STATE_CLOSED:
			if ws_connected or is_connecting:
				# Connection list
				if AppConfig.DEBUG_MODE: print("[WEBSOCKET] Websocket failed to connect")
				ws_connected = false
				is_connecting = false
				# Definimos ws como nulo para que o _manage_ws_connection saiba que precisa criar um novo
				ws = null


# Try to connect
func _manage_ws_connection() -> void:
	if not ws_connected and not is_connecting:
		if AppConfig.DEBUG_MODE: print("Trying a new websocket connection")
		_connect_to_ws()

func _connect_to_ws() -> void:
	# new instance
	ws = WebSocketPeer.new()
	
	var err = ws.connect_to_url(URL)
	if err != OK:
		if AppConfig.DEBUG_MODE: print("[WEBSOCKET] Error connecting websocket: ", err)
		ws = null # Clear instance
		is_connecting = false
	else:
		is_connecting = true
