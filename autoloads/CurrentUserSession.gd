extends Node

# => Memory Data
var user_id: String = ""
var username: String = ""
var email: String = ""
var created_at: String = ""


# => Persistent Data
var login_token: String = ""

const TOKEN_FILE_PATH := "user://session.token"

func _ready() -> void:
	load_token_from_file()

func set_session_data(data: Dictionary) -> void:
	user_id = data.get("id", "")
	username = data.get("name", "")
	email = data.get("email", "")
	created_at = data.get("created_at", "")

	var new_token = data.get("token", "")

	if not new_token.is_empty():
		login_token = new_token
		save_token_to_file()


func clear_session() -> void:
	user_id = ""
	username = ""
	email = ""
	created_at = ""
	login_token = ""

	var user_dir = DirAccess.open("user://")
	if user_dir and FileAccess.file_exists(TOKEN_FILE_PATH):
		user_dir.remove(TOKEN_FILE_PATH)


# => Save & Load functions

func save_token_to_file() -> void:
	if login_token.is_empty():
		return # No token
	
	var file = FileAccess.open(TOKEN_FILE_PATH, FileAccess.WRITE)

	# Tries to save token at TOKEN_FILE_PATH, as simple string
	if FileAccess.get_open_error() == OK:
		file.store_string(login_token)
		print("Token saved.")
	
	else:
		printerr("TOKEN SAVE ERROR: couldn't save token.")

func load_token_from_file() -> void:
	if not FileAccess.file_exists(TOKEN_FILE_PATH):
		push_warning("TOKEN NOT EXISTS: Token file does not exists.")
		return
	else:
		printerr("TOKEN READ ERROR: Couldn't read token file")
