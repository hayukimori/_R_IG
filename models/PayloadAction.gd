extends Node
class_name PayloadAction

enum ActionType { 
	AUDIO_PLAY,
	TEXT_BANNER,
}

var text: String
var time: float
var bg_color: Color
var current_type: ActionType
var loaded_audio_file: AudioStream
var valid_action: bool = true


static func from_dict(payload: Dictionary) -> PayloadAction:
	var action = PayloadAction.new()

	# Filter payload
	var payload_text = payload.get("text")
	var payload_type = payload.get("type")
	var payload_color = payload.get("color", "")
	var payload_file = payload.get("file")
	var expires_in = payload.get("expires_in", 10.0)

	match payload_type:
		"text": 
			action.current_type = ActionType.TEXT_BANNER
			if payload_color:
				action.bg_color = Color.from_string(payload_color, Color.BLACK)
			if !payload_text or payload_text.is_empty():
				action.valid_action = false
			action.text = payload_text
			action.time = expires_in

		"sound":
			action.current_type = ActionType.AUDIO_PLAY
			var endfile = RIGSoundLibrary.get_sound_by_name(payload_file)
			action.loaded_audio_file = endfile
			action.valid_action = action.loaded_audio_file != null

	return action
