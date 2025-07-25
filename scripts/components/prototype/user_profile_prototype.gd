extends Control
class_name UserProfileUIPrototype

@export_group("API")
## Profile_ID should set in script
@export var profile_id: String

## `profile_getter_url` is an url to get profile data (currently it's set to search by id (uid))
@export var profile_getter_url: String = "http://localhost:3000/api/v1/profile/uid/%s"

# Basic Scene Objects
@onready var displayNameLabel: Label = $BgPanel/DisplayNameLabel
@onready var usernameLabel: Label = $BgPanel/UsernameLabel
@onready var idLabel: Label = $BgPanel/IDLabel


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
#endregion

#region underscore functions
func _ready() -> void:
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

	var url = profile_getter_url % profile_id	
	#var token = CurrentUserSession.login_token

	# if token == "":
	# 	push_error("CUBES HANDLER REQUEST ERROR: No Token Provided, it can result in request error.")
	# 	return {"error": "No token provided"}

	http_request.request(url, headers, HTTPClient.METHOD_GET)

	await http_request.request_completed
	http_request.queue_free()

	return result
#endregion

#region Button Signals
func _on_close_profile_button_pressed() -> void:
	queue_free()
