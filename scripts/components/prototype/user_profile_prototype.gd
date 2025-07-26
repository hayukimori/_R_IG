extends Control
class_name UserProfileUIPrototype

@export_group("API")
## Profile_ID should set in script
@export var profile_id: String

## `profile_getter_endpoint` is an url to get profile data (currently it's set to search by id (uid))

var profile_getter_endpoint: String = "/api/v1/profile/uid/%s"

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


#region Interfaces and Validations
class UserProfile:
	var id: String
	var username: String
	var displayName: String
	var bio: String
	var avatarUrl: String
	var bannerColor: String
	var followersCount: int
	var followingCount: int
	var isFollowing: bool
	var badgeIds: Array
	var links: Array

	func initializeData(data: Dictionary) -> void:
		self.id = data.get('id', '')
		self.username = data.get('username', '')
		self.displayName = data.get('displayName', '')
		self.bio = data.get('bio', '')
		self.avatarUrl = data.get('avatarUrl', '')
		self.bannerColor = data.get('bannerColor', '')
		self.followersCount = data.get('followersCount', 0)
		self.followingCount = data.get('followingCount', 0)
		self.isFollowing = data.get('isFollowing', false)
		self.badgeIds = data.get('badgeIds', [])
		self.links = data.get('links', [])

# TODO: Extract Validations to a global tools script.
class Validations:
	func validate_uid(uid: String) -> bool:
		# Early return method
		# Requirement: UID Needs to be exactly 24 characters long. (12 bytes)
		if !type_string(typeof(uid)): return false
		if uid == "": return false
		if uid.length() != 24: return false

		return true

	func validate_url(url: String) -> bool:
		# Early return method
		if !type_string(typeof(url)): return false
		if url == "": return false
		if not url.begins_with("http://") and not url.begins_with("https://"): return false

		return true

	func validate_image_format(data: PackedByteArray) -> String:
		if data.size() >= 9:
			var png_header := PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
			if data.slice(0, 8) == png_header:
				return "png"
		if data.size() >= 2:
			if data[0] == 0xFF and data[1] == 0xD8:
				return "jpg"
		if data.size() >= 12:
			var riff_str = data.slice(0, 4).get_string_from_ascii()
			var webp_str = data.slice(8, 12).get_string_from_ascii()
			if riff_str == "RIFF" and webp_str == "WEBP":
				return "webp"
		return "unknown"


func prepareRequirements() -> bool:
	var c_valids = Validations.new()
	var uid_is_valid: bool = c_valids.validate_uid(profile_id)

	return uid_is_valid

#endregion

func loadProfile() -> void:
	var data = await _request_profile()
	if data.has("error"):
		print_debug("Got error at data", data) # TODO: Handle Errors
	
	var	profileData: UserProfile = UserProfile.new()
	profileData.initializeData(data)

	updateUI(profileData)

#region UI Functions
func updateUI(profile_data: UserProfile) -> void:
	displayNameLabel.text = profile_data.displayName
	usernameLabel.text = profile_data.username
	idLabel.text = profile_data.id
	if profile_data.avatarUrl != "":
		_get_user_pfp(profile_data)
	else:
		var default_image = Image.new()
		default_image.load(default_profile_picture)
		var texture = ImageTexture.create_from_image(default_image)
		profile_picture_texture_rect.texture = texture
#endregion

#region underscore functions
func _ready() -> void:
	# Check for host setting
	var host = ProjectSettings.get_setting("application/config/api_host")
	if host != "":
		profile_getter_endpoint = host + profile_getter_endpoint
	else:
		push_error("API host is not set in project settings. Using default endpoint.")
		profile_getter_endpoint = "http://localhost:3000" + profile_getter_endpoint

	await get_tree().process_frame

	if prepareRequirements():
		loadProfile()

func _request_profile() -> Dictionary:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Dictionary = {}

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != 0:
			print("error connecting, result_code: %d" % result_code)
			result.assign({
				"ConnectionError": "Connection error", 
				"context": "Couldn't connect: result_code: %d"  % result_code, 
				"code": result_code
			})
			
		if response_code >= 400:
			push_error("Error request")
		elif response_code >= 500:
			push_error("Server Error")

		var json = JSON.parse_string(body.get_string_from_utf8())

		if typeof(json) == TYPE_DICTIONARY:
			result.assign(json)
	)

	var url = profile_getter_endpoint % profile_id	
	#var token = CurrentUserSession.login_token

	# if token == "":
	# 	push_error("CUBES HANDLER REQUEST ERROR: No Token Provided, it can result in request error.")
	# 	return {"error": "No token provided"}

	http_request.request(url, headers, HTTPClient.METHOD_GET)

	await http_request.request_completed
	http_request.queue_free()

	return result


func _get_user_pfp(profile_data: UserProfile) -> void:

	var http_request := HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != HTTPRequest.RESULT_SUCCESS:
			push_error("Image couldn't be downloaded. Result: %d" % result_code)
	
		var image = Image.new()
		var format = Validations.new().validate_image_format(body)
		var err = OK

		print_debug("Image format detected: %s" % format)
		print_debug(result_code, response_code, _headers)

		match format:
			"png":
				err = image.load_png_from_buffer(body)
			"jpg", "jpeg":
				err = image.load_jpg_from_buffer(body)
			"webp":
				err = image.load_webp_from_buffer(body)
			_:
				push_error("Unsupported image format: %s" % format)
				err = image.load(default_profile_picture)

		if err != OK:
			push_error("Couldn't load image. Error code: %d" % err)
			return
		else:
			var texture = ImageTexture.create_from_image(image)
			profile_picture_texture_rect.texture = texture
	)

	var url = profile_data.avatarUrl
	if not Validations.new().validate_url(url):
		push_error("Invalid URL: %s" % url)
		return
	http_request.request(url, headers, HTTPClient.METHOD_GET)

#endregion

#region Button Signals
func _on_close_profile_button_pressed() -> void:
	print("Profile Close Button hit")
	self.queue_free()
#endregion
