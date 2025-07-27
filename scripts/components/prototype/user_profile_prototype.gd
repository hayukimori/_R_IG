extends Control
class_name UserProfileUIPrototype

@export_group("API")
## Profile_ID should set in script
@export var profile_id: String

## `profile_getter_endpoint` is an url to get profile data (currently it's set to search by id (uid))
@export var profile_getter_endpoint: String = "/api/v1/profile/uid/%s"

# Basic Scene Objects
@onready var displayNameLabel: Label = $BgPanel/DisplayNameLabel
@onready var usernameLabel: Label = $BgPanel/UsernameLabel
@onready var idLabel: Label = $BgPanel/IDLabel
@onready var profile_picture_texture_rect: TextureRectRounded = $BgPanel/ProfilePictureTextureRect

@export_file("*.png", "*.jpg", "*.webp", "*.svg") var default_profile_picture: String

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
	displayNameLabel.text = profile_data.displayName
	usernameLabel.text = profile_data.username
	idLabel.text = profile_data.id

	if profile_data.avatarUrl != "":
		var texture = await GeneralTools.getUserPfp(profile_data)
		profile_picture_texture_rect.texture = texture

	else:
		var default_image = Image.new()
		default_image.load(default_profile_picture)

		var texture = ImageTexture.create_from_image(default_image)
		profile_picture_texture_rect.texture = texture

#endregion


func _ready() -> void:
	await get_tree().process_frame

	if prepareRequirements():
		loadProfile()

#region Button Signals
func _on_close_profile_button_pressed() -> void:
	print("Profile Close Button hit")
	self.queue_free()
#endregion
