extends Node

var default_profile_picture: String
var profile_getter_endpoint: String = "/api/v1/profile/uid/%s"

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


func getUserPfp(profile_data: UserProfile) -> ImageTexture:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var url: String

	# Checks if image is from gravatar or not
	# If it is, increase size to 512px
	if "gravatar.com" in profile_data.avatarUrl:
		var temp_url = profile_data.avatarUrl
		url = "%s?size=512" % temp_url
	else:
		url = profile_data.avatarUrl

	if not GeneralTools.Validations.new().validate_url(url):
		push_error("Invalid URL: %s" % url)
		return ImageTexture.new()

	var error = http_request.request(url, [], HTTPClient.METHOD_GET)
	if error != OK:
		push_error("Failed to make request.")
		return ImageTexture.new()

	var result = await http_request.request_completed

	var result_code = result[0]
	var response_code = result[1]
	var _headers = result[2]
	var body = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Result: %d" % result_code)
		return ImageTexture.new()
	
	var image = Image.new()
	var format = GeneralTools.Validations.new().validate_image_format(body)
	var err = OK

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
		return ImageTexture.new()
	else:
		var texture = ImageTexture.create_from_image(image)
		return texture



func requestProfile(profile_id: String) -> Dictionary:

	var headers: Array = [
		"Authorization: Bearer %s" % CurrentUserSession.login_token,
		"Content-Type: application/json",
		"Accept: application/json"
	]

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


	var host = ProjectSettings.get_setting("application/config/api_host")
	var profile_getter_url: String = ""

	if host != "":
		profile_getter_url = host + profile_getter_endpoint
	else:
		push_error("API host is not set in project settings. Using default endpoint.")
		profile_getter_url = "http://localhost:3000" + profile_getter_endpoint


	var url = profile_getter_url % profile_id
	http_request.request(url, headers, HTTPClient.METHOD_GET)

	await http_request.request_completed
	http_request.queue_free()

	return result
