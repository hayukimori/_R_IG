extends Node

signal session_data_changed(data: Dictionary)

# => Memory Data
var user_id: String = ""
var username: String = ""
var email: String = ""
var created_at: String = ""
var logged_in: bool = false


# => Persistent Data
var login_token: String = ""

const TOKEN_FILE_PATH := "user://session.token"

func _ready() -> void:
	# Load token from file if exists
	load_token_from_file()

func set_session_data(data: Dictionary, token: String = "") -> void:
	user_id = data.get("id", "")
	username = data.get("name", "") if data.has("name") else data.get("username", "")
	email = data.get("email", "")
	created_at = data.get("created_at", "")

	var new_token = data.get("token", token.strip_edges())

	for key in [user_id, username, email, created_at]:
		if key.is_empty():
			push_error("Session data is missing required fields: %s" % key)
			return

	if not new_token.is_empty():
		login_token = new_token
		save_token_to_file()

	logged_in = true
	session_data_changed.emit({
		"user_id": user_id,
		"username": username,
		"email": email,
		"created_at": created_at,
		"login_token": login_token
	})

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


func get_user_by_token(token: String):
	# Rquests user data by token from the server
	var http_request := HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != HTTPRequest.RESULT_SUCCESS:
			push_error("Error connecting, result_code: %d" % result_code)
			return

		if response_code >= 400:
			push_error("Error request")
			if response_code == 401:
				push_error("Unauthorized request, token may be invalid or expired.")
				clear_session()
				return
			elif response_code == 403:
				push_error("Forbidden request, you may not have access to this resource.")
				return
			elif response_code == 404:
				push_error("Not Found, the requested resource does not exist.")
				return
			elif response_code == 429:
				push_error("Too Many Requests, you have exceeded the rate limit.")
				return
		elif response_code >= 500:
			push_error("Server Error")
			return
		
		if response_code == 200:
			print("User data received successfully.")
			
			var json = JSON.parse_string(body.get_string_from_utf8())

			if typeof(json) == TYPE_DICTIONARY:
				set_session_data(json.get("user", {}), token)
				print("Set session data from token: %s" % json.get("user", {}))

				print("Current user session data: %s" % {
					"user_id": user_id,
					"username": username,
					"email": email,
					"created_at": created_at,
					"login_token": login_token
				})

		http_request.queue_free()
	)

	var headers: Array = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % token
	]

	var url = "http://localhost:3000/api/auth/protected"

	if not token.is_empty():
		print("Requesting user data by token: %s" % url)
		http_request.request(url, headers, HTTPClient.METHOD_POST)

	else:
		push_error("No token provided for user request.")

func load_token_from_file() -> void:
	if not FileAccess.file_exists(TOKEN_FILE_PATH):
		push_warning("TOKEN NOT EXISTS: Token file does not exists.")
		return
	else:
		print("Found file: %s" % TOKEN_FILE_PATH)
		var token = FileAccess.get_file_as_string(TOKEN_FILE_PATH).strip_edges()
		get_user_by_token(token)
