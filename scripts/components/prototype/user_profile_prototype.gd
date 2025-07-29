extends Control
class_name UserProfileUIPrototype

@export_group("API")
## Profile_ID should set in script
@export var profile_id: String

## `profile_getter_endpoint` is an url to get profile data (currently it's set to search by id (uid))
@export var profile_getter_endpoint: String = "/api/v1/profile/uid/%s"
@export_group("Defaults")
@export_file("*.png", "*.jpg", "*.webp", "*.svg") var default_profile_picture: String

# Basic Scene Objects
@onready var displayNameLineEdit: LineEdit = $BgPanel/DisplayNameLineEdit
@onready var usernameLineEdit: LineEdit = $BgPanel/UsernameLineEdit
@onready var bioTextEdit: TextEdit = $BgPanel/BioTextEdit
@onready var idLabel: Label = $BgPanel/IDLabel
@onready var profile_picture_texture_rect: TextureRectRounded = $BgPanel/ProfilePictureTextureRect
@onready var bgpanel: Panel = $BgPanel
@onready var editPfpButton: Button = $BgPanel/ProfilePictureTextureRect/EditPFPButton
@onready var profileDoneButton: Button = $ProfileDoneButton

var edit_mode: bool = false
var original_data: GeneralTools.UserProfile

var headers: Array = [
	"Authorization: Bearer %s" % CurrentUserSession.login_token,
	"Content-Type: application/json",
	"Accept: application/json"
]

func prepareRequirements() -> bool:
	var c_valids = GeneralTools.Validations.new()
	var uid_is_valid: bool = c_valids.validate_uid(profile_id)

	return uid_is_valid

#endregion

func loadProfile() -> void:
	var data = await GeneralTools.requestProfile(profile_id)
	if data.has("error"):
		print_debug("Got error at data", data) # TODO: Handle Errors
	
	var	profileData: GeneralTools.UserProfile = GeneralTools.UserProfile.new()
	profileData.initializeData(data)

	updateUI(profileData)


#region UI Functions
func updateUI(profile_data: GeneralTools.UserProfile) -> void:
	original_data = profile_data
	displayNameLineEdit.text = profile_data.displayName
	usernameLineEdit.text = profile_data.username
	idLabel.text = profile_data.id
	bioTextEdit.text = profile_data.bio

	changeBackground(profile_data.bannerColor)

	if profile_data.avatarUrl != "":
		var texture = await GeneralTools.getUserPfp(profile_data)
		profile_picture_texture_rect.texture = texture

	else:
		var default_image = Image.new()
		default_image.load(default_profile_picture)

		var texture = ImageTexture.create_from_image(default_image)
		profile_picture_texture_rect.texture = texture

func changeBackground(target_color: String) -> void:
	var color = Color(target_color)

	var stylebox = bgpanel.get_theme_stylebox("panel").duplicate()
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = color
		bgpanel.add_theme_stylebox_override("panel", stylebox)

#endregion

func send_profile(new_data: GeneralTools.UserProfile) -> void:
	GeneralTools.compare_profile_datas(original_data,new_data)

	# Lock content
	disable_edit_functions()

func activate_edit_functions() -> void:
	# Verify if user can edit this profile or not.
	displayNameLineEdit.editable = true
	#usernameLineEdit.editable = true # Should'nt be editable here
	bioTextEdit.editable = true
	editPfpButton.disabled = false	
	profileDoneButton.disabled = false
	profileDoneButton.visible = true

func disable_edit_functions() -> void:
	displayNameLineEdit.editable = false
	# usernameLineEdit.editable = false
	bioTextEdit.editable = false
	
	profileDoneButton.disabled = true
	editPfpButton.disabled = true

func _ready() -> void:
	await get_tree().process_frame

	if profile_id != "":
		self.edit_mode = profile_id == CurrentUserSession.user_id
	if prepareRequirements():
		loadProfile()

	if edit_mode:
		activate_edit_functions()

#region Button Signals
func _on_close_profile_button_pressed() -> void:
	print("Profile Close Button hit")
	self.queue_free()


func _on_profile_done_button_pressed() -> void:
	var raw_data = {
		"id": profile_id,
		"displayName": displayNameLineEdit.text,
		"username": usernameLineEdit.text,
		"bio": bioTextEdit.text,
		"avatarUrl": original_data.avatarUrl,
		"bannerColor": original_data.bannerColor,
		"followersCount": original_data.followersCount,
		"followingCount": original_data.followingCount,
		"badgeIds": [],
		"links": []
	}

	var new_data: GeneralTools.UserProfile = GeneralTools.UserProfile.new()
	new_data.initializeData(raw_data)
	send_profile(new_data)

#endregion
