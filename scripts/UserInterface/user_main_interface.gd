extends Control

# Top Bar
@onready var notifications_button: Button = $TopBarControl/MainPanel/RightSide/NotificationsButton
@onready var profile_picture_trd: TextureRectRounded = $TopBarControl/MainPanel/RightSide/ProfileButton/ProfilePicture
@onready var username_label: Label = $TopBarControl/MainPanel/RightSide/ProfileButton/UsernameLabel
@onready var datetime_label: Label = $TopBarControl/MainPanel/Center/DateTimeLabel

var default_datetime_format: String = "%02d/%02d/%04d - %02d:%02d:%02d"
var current_time_string: String = "00/00/0000 - 00:00:00"
var time: Dictionary = { 
	"year": 2025, 
	"month": 7, 
	"day": 27, 
	"weekday": 0, 
	"hour": 0, 
	"minute": 5, 
	"second": 28, 
	"dst": false 
}


func _ready() -> void:
	time = Time.get_datetime_dict_from_system()

	if !CurrentUserSession.logged_in:
		push_warning("User is not logged in, profile won't be loaded")
		return
	
	updateUI()


func updateUI() -> void:
	var uid = CurrentUserSession.user_id

	# Validates uid
	if not GeneralTools.Validations.new().validate_uid(uid):
		push_warning("Invalid UID: %s" % uid)
		return
	
	# Gets profile data (as UserProfile)
	var profile_data: GeneralTools.UserProfile = await loadProfile(uid)

	# Check for profile
	if not profile_data:
		push_warning("Failed to load profile data for UID: %s" % uid)
		return

	# Updates UI
	username_label.text = profile_data.username

	# Checks for profile picture
	if profile_data.avatarUrl != "":
		var texture = await GeneralTools.getUserPfp(profile_data)
		profile_picture_trd.texture = texture

	else:
		var default_image = Image.new()
		default_image.load(GeneralTools.default_profile_picture)
		var texture = ImageTexture.create_from_image(default_image)
		profile_picture_trd.texture = texture



func loadProfile(profile_id) -> GeneralTools.UserProfile:
	# Request profile data using id
	var data = await GeneralTools.requestProfile(profile_id)

	# Verify errors
	if data.has("error"):
		push_error("Error at loadProfile(): ", data.error)
	
	# Gets profile as UserProfile (primitive interface using class)
	var	profileData: GeneralTools.UserProfile = GeneralTools.UserProfile.new()
	profileData.initializeData(data)

	return profileData

	
func _process(_delta: float) -> void:

	time = Time.get_datetime_dict_from_system()

	current_time_string = default_datetime_format % [
		time.day, time.month, time.year,
		time.hour, time.minute, time.second
	]

	datetime_label.text = current_time_string


func _on_logout_button_pressed() -> void:
	SceneHandler.logout()
