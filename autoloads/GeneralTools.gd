extends Node

var default_profile_picture: String
var profile_getter_endpoint: String = "/api/v1/profile/uid/%s"
var profile_send_endpoint: String = "/api/v1/editprofile"

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

	func get_fields_as_dict(ignore_follow_system := true, ignore_badges := true) -> Dictionary:
		var data := {
			"id": self.id,
			"displayName": self.displayName,
			"username": self.username,
			"bio": self.bio,
			"avatarUrl": self.avatarUrl,
			"bannerColor": self.bannerColor,
			"links": self.links
		}

		if not ignore_follow_system:
			data.merge({
				"followersCount": self.followersCount,
				"followingCount": self.followingCount,
				"isFollowing": self.isFollowing
			})
		
		if not ignore_badges:
			data.merge({
				"badgeIds": self.badgeIds
			})

		return data



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



## This function returns a url based in application/config/api_host settting
func get_route(endpoint: String) -> String:
	var host = ProjectSettings.get_setting("application/config/api_host")
	var url: String

	if host != "":
		url = host + endpoint
	else:
		push_error("API host is not set in project settings. Using default endpoint.")
		url = "http://localhost:3000" + endpoint
	
	return url



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
	var _response_code = result[1]
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



	var url = get_route(profile_getter_endpoint) % profile_id
	http_request.request(url, headers, HTTPClient.METHOD_GET)

	await http_request.request_completed
	http_request.queue_free()

	return result


func sendNewProfileData(targetId: String, data: Dictionary) -> void:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var url: String = get_route(profile_send_endpoint)

	var headers := [
		"Authorization: Bearer %s" %CurrentUserSession.login_token,
		"Content-Type: application/json",
		"Accept: application/json"
	]

	var payload = {
		"targetId": targetId,
		"fields": data
	}
	
	if not Validations.new().validate_url(url):
		push_error("Invalid URL: %s" % url)
		return

	var error = http_request.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(payload))
	if error != OK:
		push_error("Failed to make request.")
		return 

	var result = await http_request.request_completed

	var result_code = result[0]
	var response_code = result[1]
	var _headers = result[2]
	var body = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		push_error("Couldn't send profile data. Result: %d" % result_code)
		return
	
	var body_text: String = body.get_string_from_utf8()
	var parsed_json := {}
	var is_json := true

	if body_text != "":
		var parse_result = JSON.parse_string(body_text)
		if parse_result != null:
			parsed_json = parse_result
		else:
			is_json = false
	
	match response_code:
		200, 201: print("Profile updated successfuly")
		400: push_warning("Bad request. %s" % JSON.stringify(parsed_json) if is_json else "")
		401: push_warning("Unauthorized. Please log in and try again")
		403: push_warning("Forbidden. You don't have permission")
		404: push_warning("User or route not found")
		409: push_warning("Conflicting data")
		422: push_warning("Validation error: %s" % JSON.stringify(parsed_json) if is_json else "")
		500, 502, 503: push_warning("Server error (%d). Try agian later." % response_code)
		_: push_warning("Unexpected response (%d): %s" % [response_code, body_text])


func compare_profile_datas(profile_d1: UserProfile, profile_d2: UserProfile) -> Dictionary:
	var d1d = profile_d1.get_fields_as_dict()
	var d2d = profile_d2.get_fields_as_dict()

	var final_dict := {}

	var comp = compare_dicts(d1d, d2d)
	if len(comp) > 0:
		for key in comp:
			final_dict.merge({key: d2d[key]})

	return final_dict

func compare_dicts(dict_a: Dictionary, dict_b: Dictionary) -> Array:
	var differing_keys: Array = []
	var all_keys: Array = []

	for key in dict_a.keys():
		if not all_keys.has(key):
			all_keys.append(key)
	for key in dict_b.keys():
		if not all_keys.has(key):
			all_keys.append(key)

	# Compare values
	for key in all_keys:
		if not dict_a.has(key) or not dict_b.has(key):
			differing_keys.append(key)
		elif dict_a[key] != dict_b[key]:
			differing_keys.append(key)

	return differing_keys
