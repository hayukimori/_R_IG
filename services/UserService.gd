extends RefCounted
class_name UserService

signal session_data_changed(data: Dictionary)
signal auto_login_status(status: String)

# => Const
const TOKEN_FILE_PATH := "user://session.token"

# => Memory Data
var user_id: String = ""
var username: String = ""
var email: String = ""
var created_at: String = ""
var logged_in: bool = false
var current_status: String = "loading"
var user_roles: Array = []
var user_permissions: Array = []

# => Persistent Data
var login_token: String = ""

var parent_node: Node

func _init(node: Node) -> void:
	# Load token from file if exists
	parent_node = node
	load_token_from_file()

## Sets new session data
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
	current_status = "success"
	auto_login_status.emit("success")
	load_user_privileges()
	session_data_changed.emit({
		"user_id": user_id,
		"username": username,
		"email": email,
		"created_at": created_at,
		"login_token": login_token
	})
	

## Clear current user session and deletes it from user://
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
## Save token to TOKEN_FILE_PATH
func save_token_to_file() -> void:
	if login_token.is_empty():
		return # No token
	
	var file = FileAccess.open(TOKEN_FILE_PATH, FileAccess.WRITE)

	# Tries to save token at TOKEN_FILE_PATH, as simple string
	if FileAccess.get_open_error() == OK:
		file.store_string(login_token)
		if AppConfig.DEBUG_MODE: print("Token saved.")
	
	else:
		printerr("TOKEN SAVE ERROR: couldn't save token.")


# => Gets current user by it's token
func get_user_by_token(token: String):
	# Rquests user data by token from the server
	var http_request := HTTPRequest.new()
	parent_node.add_child(http_request)

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != HTTPRequest.RESULT_SUCCESS:
			push_error("Error connecting, result_code: %d" % result_code)
			return

		if response_code >= 400:
			push_error("Error request")
			if response_code == 401:
				current_status = "failed"
				auto_login_status.emit("failed")
				push_error("Unauthorized request, token may be invalid or expired.")
				clear_session()
				return
			elif response_code == 403:
				current_status = "failed"
				auto_login_status.emit("failed")
				push_error("Forbidden request, you may not have access to this resource.")
				return
			elif response_code == 404:
				current_status = "failed"
				auto_login_status.emit("failed")
				push_error("Not Found, the requested resource does not exist.")
				return
			elif response_code == 429:
				current_status = "failed"
				auto_login_status.emit("failed")
				push_error("Too Many Requests, you have exceeded the rate limit.")
				return
		elif response_code >= 500:
			current_status = "failed"
			auto_login_status.emit("failed")
			push_error("Server Error")
			return
		
		if response_code == 200:
			if AppConfig.DEBUG_MODE: print("User data received successfully.")
			
			var json = JSON.parse_string(body.get_string_from_utf8())

			if typeof(json) == TYPE_DICTIONARY:
				set_session_data(json.get("user", {}), token)
				if AppConfig.DEBUG_MODE: print("User data set from token")

		http_request.queue_free()
	)

	var headers: Array = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % token
	]

	var final_url: String = ""
	final_url = Services.routes.get_route(Services.routes.ENDPOINT_PROTECTED)

	if not token.is_empty():
		if AppConfig.DEBUG_MODE: print("Requesting user data by token: %s" % final_url)
		http_request.request(final_url, headers, HTTPClient.METHOD_POST)
		current_status = "loading"

	else:
		push_error("No token provided for user request.")


## Loads a token from TOKEN_FILE_PATH
func load_token_from_file() -> void:
	if not FileAccess.file_exists(TOKEN_FILE_PATH):
		push_warning("TOKEN NOT EXISTS: Token file does not exists.")
		current_status = "no_default"
		return
	else:
		if AppConfig.DEBUG_MODE: print("Found file: %s" % TOKEN_FILE_PATH)
		var token = FileAccess.get_file_as_string(TOKEN_FILE_PATH).strip_edges()
		get_user_by_token(token)
		current_status = "loading"

## Get user's gorup and permission
func load_user_privileges() -> void:
	var result = await Services.api.get_privileges()
	if result.has("roles") and result.get("roles").size() > 0:
		user_roles = result.get("roles")

	if result.has("permissions") and result["permissions"].size() > 0:
		user_permissions = result.get("permissions")
