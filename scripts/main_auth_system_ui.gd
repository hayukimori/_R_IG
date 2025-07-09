extends Control

@onready var register_username_line_edit: LineEdit = $RegisterTest/UsernameLineEdit
@onready var register_email_line_edit: LineEdit = $RegisterTest/EmailLineEdit
@onready var register_password_line_edit: LineEdit = $RegisterTest/PasswordLineEdit
@onready var register_password_confirm_line_edit: LineEdit = $RegisterTest/ConfirmPasswordLineEdit


enum AuthActions { REGISTER, LOGIN }

var register_user_url: String = "http://localhost:3000/api/auth/register"
var login_url: String = "http://localhost:3000/api/auth/login"

func _ready() -> void:
	pass


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
				"confirm_password": register_password_confirm_line_edit.text
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


func _on_register_btn_pressed() -> void:
	var data = await auth_action(AuthActions.REGISTER)
	print_debug(data)
