extends Control

# Main Steps
@onready var recover_first_step: Control = $RecoverStep1
@onready var recover_second_step: Control = $RecoverStep2

# First stage fields
@onready var recovery_email_field: LineEdit = $RecoverStep1/MainFramePanel/EmailLineEdit
@onready var six_digit_code_field: LineEdit = $RecoverStep1/MainFramePanel/PCodeLineEdit
@onready var send_code_button: Button = $RecoverStep1/MainFramePanel/SendCodeButton
@onready var step_2_button: Button = $RecoverStep1/HeadPanel2/GotoStep2Button 

# Second stage fields
@onready var password_field: LineEdit = $RecoverStep2/MainFramePanel/NewPasswordLineEdit
@onready var confirm_password_field: LineEdit = $RecoverStep2/MainFramePanel/ConfirmNewPasswordLineEdit
@onready var reset_password_button: Button = $RecoverStep2/HeadPanel2/ResetPasswordButton

# On-Screen errors
@onready var error_message_rtl: RichTextLabel = $UIErrorMessageHandler

# Important vars
var recovery_token: String


func _ready() -> void:
	_start_timers()
	_first_step()

func _start_timers() -> void:
	# Timer: Fields checking timer (Step 1)
	var first_step_timer := Timer.new()
	first_step_timer.name = "FirstStepTimer"
	first_step_timer.wait_time = 1
	first_step_timer.autostart = true
	first_step_timer.one_shot = false
	first_step_timer.timeout.connect(_manage_t1_fields)
	add_child(first_step_timer)

	# Timer: Fields checking timer
	var second_step_timer := Timer.new()
	second_step_timer.name = "SecondStepTimer"
	second_step_timer.wait_time = 1
	second_step_timer.autostart = true
	second_step_timer.one_shot = false
	second_step_timer.timeout.connect(_manage_t2_fields)
	add_child(second_step_timer)

# === Steps === (load step)
func _first_step() -> void:
	recover_first_step.show()

func _second_step() -> void:
	recover_first_step.hide()
	recover_second_step.show()


# === On-Screen errors ===
func _show_on_screen_error(error: Dictionary) -> void:
	if error.is_empty(): return
	error_message_rtl.text = str(error)

func _wipe_on_screen_errors() -> void:
	error_message_rtl.text = ""


# == Main functions ===
func validate_email_send_code() -> void:
	var email_validation = GlobalValidations.validate_email(recovery_email_field.text)
	if !email_validation: _show_on_screen_error({"error": "Invalid email address"}); return
	_wipe_on_screen_errors()

	# TODO: Request code
	# TODO: When receive response, allow to go to next step

func validate_code_continue() -> void:
	var email_validation = GlobalValidations.validate_email(recovery_email_field.text)
	if !email_validation: _show_on_screen_error({"error": "Invalid email address"}); return

	var code_validation = GlobalValidations.validate_code(six_digit_code_field.text)
	if !code_validation: _show_on_screen_error({"error": "Invalid code"}); return
	_wipe_on_screen_errors()

	# TODO: Request code validation and get token
	# TODO: Add received token to recovery_token
	
	recovery_token = "loremipsum" # DEBUG: Dev Mode

func reset_password_to_new() -> void:
	var password_validation = GlobalValidations.validate_password(password_field.text)
	var c_password_validation = GlobalValidations.validate_password(confirm_password_field.text)
	
	# Validates before call
	if !password_validation or !c_password_validation:
		_show_on_screen_error({"error": "Invalid passwords. Verify and try again"})
		return
	
	if !(password_field.text == confirm_password_field.text):
		_show_on_screen_error({"error": "Passwords didn't match. Verify and try again"})
		return
	
	if recovery_token.is_empty():
		_show_on_screen_error({"error": "Invalid token."})
		return

	_wipe_on_screen_errors()

	# TODO: Request password reset using token
	# TODO: Redirect user to login page


# ====== Signals ======
func _on_send_code_button_pressed() -> void:
	validate_email_send_code()

func _on_reset_password_button_pressed() -> void:
	pass # Replace with function body.

func _on_goto_step_2_button_pressed() -> void:
	validate_code_continue()

	if recovery_token.is_empty(): _show_on_screen_error({"error": "Token is empty"}); return
	_wipe_on_screen_errors()
	_second_step()

func _manage_t1_fields() -> void:
	var email_validation = GlobalValidations.validate_email(recovery_email_field.text)
	var code_validation = GlobalValidations.validate_code(six_digit_code_field.text)
	step_2_button.disabled = not (email_validation and code_validation)

func _manage_t2_fields() -> void:
	var password_validation = GlobalValidations.validate_password(password_field.text)
	var confirm_password_validation = GlobalValidations.validate_password(confirm_password_field.text)

	var reset_button_sch = (
		( password_validation and confirm_password_validation ) and
		( password_field.text == confirm_password_field.text ) and
		( !recovery_token.is_empty() )
	)

	reset_password_button.disabled = not reset_button_sch

	
