extends Node

@export var user_interface: Control
@export_node_path("AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D") var player_path: NodePath


func _ready() -> void:
	Announcements.server_event_received.connect(_manage_server_event)

# Manages server event, creates a new 'EventModel' object
# and sends it to exec_event (if is a vaid event)
func _manage_server_event(raw_content: String) -> void:
	# Try to convert to json
	var parse_result = JSON.parse_string(raw_content)

	# Validates json
	if parse_result == null: 
		push_error("Invalid JSON received from websocket")
		return

	# Unknown event (inexistent type)
	if !parse_result.has("type"):
		return

	# Ignores event if is a server_heartbeat
	if parse_result.has("type") and parse_result.get("type") == "server_heartbeat":
		return


	# Creates a new Announcement event model.
	var announcement: Announcements.EventModel
	announcement = Announcements.EventModel.new()

	announcement.type = parse_result.get("type", "")
	announcement.message = parse_result.get("message", "")
	announcement.payload = parse_result.get("payload", {})
	announcement.timestamp = parse_result.get("timestamp", "")

	# Executes announcement
	exec_event(announcement)

# Executes an Payload Action, like text banner or audio play.
func exec_action(action: PayloadAction) -> void:
	match action.current_type:
		PayloadAction.ActionType.TEXT_BANNER:
			if user_interface and user_interface.has_method("add_top_announcement"):
				user_interface.add_top_announcement(action)

		PayloadAction.ActionType.AUDIO_PLAY:			
			play_action_audio(action)


## Exects an event getting it's payload events.
func exec_event(event: Announcements.EventModel) -> void:
	var final_actions: Array[PayloadAction] = []

	# Sends a text message on screen (fallback)
	if event.payload.is_empty():
		# Creates a new event containing only message.
		var temp_action_json := {
			"type":"text",
			"message": event.get("message")
		}

		var temp_action := PayloadAction.from_dict(temp_action_json)
		exec_action(temp_action)
		return
	
	# Filter actions and executes it
	var payload_actions = event.payload.get("actions", [])
	if payload_actions.is_empty(): return

	# Filter actions to PayloadAction model
	for json_action in payload_actions:
		var act = PayloadAction.from_dict(json_action)
		final_actions.append(act)
	
	for action in final_actions:
		exec_action(action)

# Plays audio
func play_action_audio(action: PayloadAction) -> void:
	if !player_path: push_error("No player path"); return
	if !action.valid_action: push_error("Invalid action"); return
	if get_node(player_path) == null: push_error("Player not found"); return
	
	var player := get_node(player_path)

	print_debug(action.valid_action)
	print_debug(action.loaded_audio_file)
	player.stream = action.loaded_audio_file
	player.play()