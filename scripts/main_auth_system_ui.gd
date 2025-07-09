extends Control

enum AuthActions { REGISTER = 0, LOGIN = 1}

@export_group("Settings")
@export var default_method: AuthActions = AuthActions.LOGIN

@onready var login_control: Control = $LoginControl
@onready var register_control: Control = $RegisterControl

@onready var register_email_line_edit = $RegisterControl/BG/MainFramePanel/EmailLineEdit
@onready var register_username_line_edit = $RegisterControl/BG/MainFramePanel/UsernameLineEdit
@onready var register_password_line_edit = $RegisterControl/BG/MainFramePanel/PasswordLineEdit
@onready var register_confirm_password_line_edit = $RegisterControl/BG/MainFramePanel/PasswordLineEdit

@onready var login_email_line_edit = $LoginControl/BG/MainFramePanel/EmailLineEdit
@onready var login_password_line_edit = $LoginControl/BG/MainFramePanel/PasswordLineEdit

@onready var register_btn: Button = $RegisterControl/BG/HeadPanel2/RegisterBtn
@onready var login_btn: Button = $LoginControl/BG/HeadPanel2/LoginBtn
@onready var change_auth_method_btn: Button = $ChangeAuthMethod


var current_auth_method: AuthActions

var errors: Array = []


var register_user_url: String = "http://localhost:3000/api/auth/register"
var login_url: String = "http://localhost:3000/api/auth/login"


func _ready() -> void:
	define_current_auth_method(default_method)


func define_current_auth_method(action: AuthActions) -> void:
	current_auth_method = action

	match action:
		AuthActions.REGISTER:
			login_control.visible = false
			register_control.visible = true

			change_auth_method_btn.text = "I already have an account"

		AuthActions.LOGIN:
			login_control.visible = true
			register_control.visible = false

			change_auth_method_btn.text = "I don't have an account"
	
	


func auth_action(action: AuthActions) -> Array:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Array = []

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != 0:
			print("error connecting, result_code: %d" % result_code)
			result.assign([{"InternalError": "Connection error", "context": "Couldn't connect: result_code: %d"  % result_code}])
			
		match response_code:
			200, 201: print("Ok")
			400: push_error("400 Error")
			500: push_error("Server error")
		
		
		var json = JSON.parse_string(body.get_string_from_utf8())
		if typeof(json) == TYPE_ARRAY:
			result.assign(json)
		elif typeof(json) == TYPE_DICTIONARY:
			result.append(json)
	)


	var headers: Array = [
		"Content-Type: application/json",
	]

	var url
	var data

	match action:
		AuthActions.REGISTER: 
			url = register_user_url
			data = {
				"username": register_username_line_edit.text,
				"email": register_email_line_edit.text,
				"password": register_password_line_edit.text,
				"confirm_password": register_confirm_password_line_edit.text
			}
			
		AuthActions.LOGIN: 
			url = login_url
			data = {
				"email": login_email_line_edit.text,
				"password": login_password_line_edit.text,
			}
	
	print("Requesting: %s" % url)
			
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

	await http_request.request_completed
	http_request.queue_free()

	return result


func disable_register_fields() -> void:
	register_username_line_edit.editable = false
	register_email_line_edit.editable = false
	register_password_line_edit.editable = false
	register_confirm_password_line_edit.editable = false

	register_btn.disabled = true
	change_auth_method_btn.disabled = true
	

func disable_login_fields() -> void:
	login_email_line_edit.editable = false
	login_password_line_edit.editable = false

	login_btn.disabled = true
	change_auth_method_btn.disabled = true
	

func enable_register_fields() -> void:
	register_username_line_edit.editable = true
	register_email_line_edit.editable = true
	register_password_line_edit.editable = true
	register_confirm_password_line_edit.editable = true

	register_btn.disabled = false
	change_auth_method_btn.disabled = false
	

func enable_login_fields() -> void:
	login_email_line_edit.editable = true
	login_password_line_edit.editable = true

	login_btn.disabled = false
	change_auth_method_btn.disabled = false
	

func _on_change_auth_method_pressed() -> void:
	match current_auth_method:
		AuthActions.REGISTER:
			define_current_auth_method(AuthActions.LOGIN)
		AuthActions.LOGIN:
			define_current_auth_method(AuthActions.REGISTER)


func handleError(errorData: Dictionary) -> void:
	errors.clear()

	# Validation Errors (ZOD)
	if errorData.has("context") and errorData["context"].has("issues"):
		for issue in errorData["context"]["issues"]:
			var field = ""
			if issue.has("path") and issue["path"].size() > 0:
				field = issue["path"][0]
			var message = issue.get("message", "Unknown error")
			errors.append("[x] %s: %s" % [field.capitalize(), message])
	else:
		print(errorData.has("name"))
		# General erros (DatabaseError, no issues ValidationError )
		var errname = errorData.get("name", "Error")
		var message = errorData.get("title", "An error occurred.")

		# Action 
		var action = errorData.get("action", "")
		var error_line = "[x] %s: %s" % [errname, message]
		if action != "":
			error_line += " (%s)" % action

		errors.append(error_line)

	# Show erros on UI
	if has_node("ErrorLabel"):
		$ErrorLabel.text = "\n".join(errors)


func handleAuth(action: AuthActions, content: Array) -> void:
	if content.size() < 0: # First no data is returned from the server
		handleError({"InternalError": "No Data"})
		return

	print(content)
	
	for item in content:
		if item.has("name") and item.has("errorType"):
			handleError(item)

		


func _on_register_btn_pressed() -> void:
	disable_register_fields()
	var content = await auth_action(AuthActions.REGISTER)
	handleAuth(AuthActions.REGISTER, content)

	enable_register_fields()

func _on_login_btn_pressed() -> void:
	disable_login_fields()
	var content = await auth_action(AuthActions.LOGIN)
	handleAuth(AuthActions.LOGIN, content)

	enable_login_fields()
