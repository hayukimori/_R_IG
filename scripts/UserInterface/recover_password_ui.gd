extends Control

# UI
@export_group("UI")
@export var visibility_off_texture: CompressedTexture2D
@export var visibility_on_texture: CompressedTexture2D

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

var all_locked: bool = false
var first_locked: bool = false
var second_locked: bool = false

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
	enable_first()

func _second_step() -> void:
	recover_first_step.hide()
	recover_second_step.show()
	enable_second()


# === On-Screen errors ===
func _show_on_screen_error(error: Dictionary) -> void:
	if error.is_empty(): return
	error_message_rtl.text = str(error)

func _wipe_on_screen_errors() -> void:
	error_message_rtl.text = ""


# == Main functions ===
func validate_email_send_code() -> void:
	# Validation
	var email_validation = GlobalValidations.validate_email(recovery_email_field.text)
	if !email_validation: _show_on_screen_error({"error": "Invalid email address"}); return
	_wipe_on_screen_errors()

	# Send code over request
	disable_first()
	var result = await GeneralTools.request_server_code(recovery_email_field.text)
	var error = result.has("error")
	if error: _show_on_screen_error(result); enable_first(); return

	if result.has("success") and result.get("success", false):
		_show_on_screen_error({"INFO": "Check email for code."})

	enable_first()

func validate_code_continue() -> void:
	# Validation
	var email_validation = GlobalValidations.validate_email(recovery_email_field.text)
	if !email_validation: _show_on_screen_error({"error": "Invalid email address"}); return

	var code_validation = GlobalValidations.validate_code(six_digit_code_field.text)
	if !code_validation: _show_on_screen_error({"error": "Invalid code"}); return
	_wipe_on_screen_errors()

	disable_first()
	# Send code to verification on server
	var result = await GeneralTools.request_verify_code(recovery_email_field.text, six_digit_code_field.text)
	var error = result.has("error")
	if error: _show_on_screen_error(result); enable_first(); return
	_wipe_on_screen_errors()

	if result.has("success") and result.get("success"):
		recovery_token = result.get("token")
	else:
		_show_on_screen_error({"error": "Error receiving token"})
		enable_first()

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

	disable_second()

	var result = await GeneralTools.request_password_reset(
		recovery_token, 
		password_field.text, confirm_password_field.text
	)

	if result.has("error"): _show_on_screen_error(result); enable_second(); return
	if result.has("success") and result.get("success"):
		disable_all_fields_and_buttons()
		_show_on_screen_error({"info": "Password reseted, redirecting to login screen..."})
		print("Password reseted, redirecting to login screen...")

		# Redirect to login
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_packed(SceneRouter.get_login_scene())

	_show_on_screen_error(result)

func enable_first() -> void:
	first_locked = false
	step_2_button.disabled = false
	send_code_button.disabled = false

	recovery_email_field.editable = true
	six_digit_code_field.editable = true

func disable_first() -> void:
	first_locked = true
	step_2_button.disabled = true
	send_code_button.disabled = true

	recovery_email_field.editable = false
	six_digit_code_field.editable = false

func enable_second() -> void:
	second_locked = false

	reset_password_button.disabled = false

	password_field.editable = true
	confirm_password_field.editable = true


func disable_second() -> void:
	second_locked = true

	reset_password_button.disabled = true

	password_field.editable = false
	confirm_password_field.editable = false


func disable_all_fields_and_buttons() -> void:
	all_locked = true

	# Disable buttons
	step_2_button.disabled = true
	send_code_button.disabled = true
	reset_password_button.disabled = true


	# Disable Fields
	password_field.editable = false
	confirm_password_field.editable = false
	recovery_email_field.editable = false
	six_digit_code_field.editable = false

func enable_all_fields_and_buttons() -> void:
	all_locked = false

	# Enable buttons
	step_2_button.disabled = false
	send_code_button.disabled = false
	reset_password_button.disabled = false

	# Enable Fields
	password_field.editable = true
	confirm_password_field.editable = true
	recovery_email_field.editable = true
	six_digit_code_field.editable = true


# ====== Signals ======
func _on_send_code_button_pressed() -> void:
	validate_email_send_code()

func _on_reset_password_button_pressed() -> void:
	reset_password_to_new()

func _on_goto_step_2_button_pressed() -> void:
	await validate_code_continue()

	if recovery_token.is_empty(): _show_on_screen_error({"error": "Token is empty"}); return
	_wipe_on_screen_errors()
	_second_step()

func _manage_t1_fields() -> void:
	var email_validation = GlobalValidations.validate_email(recovery_email_field.text)
	var code_validation = GlobalValidations.validate_code(six_digit_code_field.text)

	if all_locked: return
	if first_locked: return
	step_2_button.disabled = not (email_validation and code_validation)

func _manage_t2_fields() -> void:
	var password_validation = GlobalValidations.validate_password(password_field.text)
	var confirm_password_validation = GlobalValidations.validate_password(confirm_password_field.text)

	var reset_button_sch = (
		( password_validation and confirm_password_validation ) and
		( password_field.text == confirm_password_field.text ) and
		( !recovery_token.is_empty() )
	)

	if all_locked: return
	if second_locked: return
	reset_password_button.disabled = not reset_button_sch
