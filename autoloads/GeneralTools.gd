extends Node

var default_profile_picture: String

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
	var url = Routes.get_route(Routes.ENDPOINT_GET_PROFILE % profile_id)
	var base_result = await protected_request(url, {}, HTTPClient.METHOD_GET)
	return base_result.get("parsed_json", {})


func sendNewProfileData(targetId: String, data: Dictionary) -> void:
	var url: String = Routes.get_route(Routes.ENDPOINT_SEND_PROFILE)
	var payload = {"targetId": targetId, "fields": data}
	await protected_request(url, payload, HTTPClient.METHOD_PUT)


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


func texture_from_file(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	if image == null:
		push_error("Error loading image: %s" % path)
		return null
	
	var texture := ImageTexture.create_from_image(image)
	return texture

func image_to_base64(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if not FileAccess.file_exists(path) or file == null:
		push_error("Failed opening image file: %s" % path)
		return ""
	
	var image_bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	var base64_string: String = Marshalls.raw_to_base64(image_bytes)

	return base64_string


func encode_image_to_data_url(image_path: String) -> String:
	var base64_string = image_to_base64(image_path)

	if base64_string.is_empty():
		return ""
	
	var extension = image_path.get_extension().to_lower()
	var mime_type = "application/octet-stream"

	if AppConfig.DEBUG_MODE: print("Current extension: ", extension)

	match extension:
		"png": 
			mime_type = "image/png"
		"jpg", "jpeg": 
			mime_type = "image/jpeg"
		"webp": 
			mime_type = "image/webp"

	return "data:%s;base64,%s" % [mime_type, base64_string]


func send_image_to_server(target_id: String, image_path: String) -> void:
	var data_url = encode_image_to_data_url(image_path)

	if data_url.is_empty():
		push_error("Could not prepare image to send")
		return
	
	var payload = {"targetId": target_id, "imageData": data_url}

	var url = Routes.get_route(Routes.ENDPOINT_SEND_PROFILE)
	await protected_request(url, payload)


## This function calls a url with default Authorization header. Returns a complete dict containing details (and decoded json if the route returns)
func protected_request(url: String, payload: Dictionary = {}, method: HTTPClient.Method = HTTPClient.METHOD_GET, custom_headers: Array = []) -> Dictionary:
	if !GeneralTools.Validations.new().validate_url(url):
		push_warning("Invalid url: ", url)
		return {}
	
	if AppConfig.DEBUG_MODE: print("Requesting url: ", url)

	var http_request := HTTPRequest.new()
	add_child(http_request)

	var headers = []

	if custom_headers == []:
		headers = [
			"Authorization: Bearer %s" %CurrentUserSession.login_token,
			"Content-Type: application/json",
			"Accept: application/json"
		]
	else:
		headers = custom_headers


	var error = http_request.request(url, headers, method, JSON.stringify(payload))
	if error != OK:
		push_error("Failed to make request.")
		return {}

	var result = await http_request.request_completed

	var result_code = result[0]
	var response_code = result[1]
	var _headers = result[2]
	var body = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		push_error("Couldn't complete request. Result: %d" % result_code)
		return {}
	
	var body_text: String = body.get_string_from_utf8()
	var parsed_json := {}
	var result_array := []
	var is_json := true

	if body_text != "":
		var parse_result = JSON.parse_string(body_text)
		if parse_result != null:
			if typeof(parse_result) == TYPE_ARRAY:
				result_array.assign(parse_result)

			elif typeof(parse_result) == TYPE_DICTIONARY:
				parsed_json.assign(parse_result)
		else:
			is_json = false
	
	match response_code:
		200, 201: if AppConfig.DEBUG_MODE: print("Protected request, success");
		400: push_warning("Bad request. %s" % JSON.stringify(parsed_json) if is_json else "")
		401: push_warning("Unauthorized. Please log in and try again")
		403: push_warning("Forbidden. You don't have permission")
		404: push_warning("User or route not found")
		409: push_warning("Conflicting data")
		422: push_warning("Validation error: %s" % JSON.stringify(parsed_json) if is_json else "")
		500, 502, 503: push_warning("Server error (%d). Try agian later." % response_code)
		_: push_warning("Unexpected response (%d): %s" % [response_code, body_text])
	
	return {
		"body_text": body_text, 
		"is_json": is_json, 
		"parsed_json": parsed_json, 
		"result_array": result_array,
		"response_code": response_code
	}



func get_server_time() -> String:
	var datereg = await GeneralTools.protected_request(
		Routes.get_route(Routes.ENDPOINT_STIME),
		{},
		HTTPClient.METHOD_GET,
		[]
	)

	if datereg["parsed_json"].get('now', '') != "" and datereg["response_code"] == 200:
		return datereg["parsed_json"].get('now', '')

	return ""
