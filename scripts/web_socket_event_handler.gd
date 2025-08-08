extends Node

@export var user_interface: Control
@export_node_path("AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D") var player_path: NodePath


func exec_event(event: Announcements.EventModel) -> void:
	# Set up event type
	match event.type:
		"server_shutdown":
			_handle_server_shutdown(event)
		"server_update":
			_handle_server_update(event)
		"alert":
			_handle_alert(event)
		_: # Generic event
			_handle_generic(event)

func _ready() -> void:
	Announcements.server_event_received.connect(_manage_server_event)

func _manage_server_event(raw_content: String) -> void:
	# Try to convert to json
	var parse_result = JSON.parse_string(raw_content)

	if parse_result == null: 
		push_error("Invalid JSON received from websocket")
		return
	
	if parse_result.has("type") and parse_result.get("type") == "server_heartbeat":
		return
	
	if !parse_result.has("type"):
		return

	var announcement: Announcements.EventModel
	announcement = Announcements.EventModel.new()

	announcement.type = parse_result.get("type", "")
	announcement.message = parse_result.get("message", "")
	announcement.payload = parse_result.get("payload", {})
	announcement.timestamp = parse_result.get("timestamp", "")

	
	exec_event(announcement)



func _handle_server_shutdown(event: Announcements.EventModel) -> void:
	# Event JSON Model
	# {
	#     "type": "server_shutdown",
	#     "name": "Server Shutdown Alert",
	#     "message": "Server shutdown at XX:XX",
	#     "payload": {
	#         "eventName": "ShtudownAlert",
	#         "description": "Alert will emit sound and a red alert flag in application",
	#         "actions": [
	#             {"type":"sound", "file": "alert0"},
	#             {"type": "text", "text": "Server will shutdown in X minutes", "bg_color": "#990F02"}
	#         ]
	#     }
	# }

	var final_actions: Array[PayloadAction] = []

	if event.payload == {}:
		new_screen_flag("TODO: Change this to actual content")
		return 
	
	var payload_actions = event.payload.get("actions", [])
	if payload_actions.is_empty(): return

	# Filter actions to PayloadAction model
	for json_action in payload_actions:
		var act = PayloadAction.from_dict(json_action)
		final_actions.append(act)
	
	for action in final_actions:
		exec_action(action)


func exec_action(action: PayloadAction) -> void:
	match action.current_type:
		PayloadAction.ActionType.TEXT_BANNER:
			if user_interface and user_interface.has_method("add_top_announcement"):
				user_interface.add_top_announcement(action)

		PayloadAction.ActionType.AUDIO_PLAY:			
			play_action_audio(action)
			print("Has player")



func play_action_audio(action: PayloadAction) -> void:
	if !player_path: return
	if !action.valid_action: return
	if get_node(player_path) == null: return
	
	var player := get_node(player_path)
	if !player.has_property("stream") or !player.has_method("play"): return

	player.stream = action.loaded_audio_file
	player.play()

func _handle_server_update(_event: Announcements.EventModel) -> void:
	pass

func _handle_alert(_event: Announcements.EventModel) -> void:
	pass

func _handle_generic(_event: Announcements.EventModel) -> void:
	pass

func new_screen_flag(_content: Variant) -> void:
	pass
