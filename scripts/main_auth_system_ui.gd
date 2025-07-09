extends Control

enum AuthActions { REGISTER, LOGIN }

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

@onready var change_auth_method_btn: Button = $ChangeAuthMethod


var current_auth_method: AuthActions


var register_user_url: String = "http://localhost:3000/api/auth/register"
var login_url: String = "http://localhost:3000/api/auth/login"


func _ready() -> void:
	define_current_auth_method(default_method)


func define_current_auth_method(action: AuthActions) -> void:
	current_auth_method = action

	match action:
		AuthActions.REGISTER:
			login_control.visible = true
			register_control.visible = false

			change_auth_method_btn.text = "I don't have an account"

		AuthActions.LOGIN:
			login_control.visible = false
			register_control.visible = true

			change_auth_method_btn.text = "I already have an account"
	
	


func auth_action(action: AuthActions) -> Array:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Array = []

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		print_debug(result_code)
		match response_code:
			200:
				var json = JSON.parse_string(body.get_string_from_utf8())
				if typeof(json) == TYPE_ARRAY:
					result.assign(json)
				elif typeof(json) == TYPE_DICTIONARY:
					result.append(json)
			400:
				push_error("Server response code: %d" % response_code)
				return {}
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
				"email": register_email_line_edit.text,
				"password": register_password_line_edit.text,
			}
			

	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))

	await http_request.request_completed
	http_request.queue_free()

	return result


func _on_change_auth_method_pressed() -> void:
	match current_auth_method:
		AuthActions.REGISTER:
			define_current_auth_method(AuthActions.LOGIN)
		AuthActions.LOGIN:
			define_current_auth_method(AuthActions.REGISTER)