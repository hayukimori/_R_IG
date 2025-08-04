extends Control

@export_group("UI Settings")
@export var follow_image: CompressedTexture2D
@export var unfollow_image: CompressedTexture2D

@onready var follow_button: Button = $FollowUnfollowButton

var profile_data: GeneralTools.UserProfile
var active: bool = false

func _ready() -> void:
	pass

func valid_profile_id(profile_id: String) -> bool:
	if profile_id == null: return false
	if profile_id.length() != 24: return false
	if profile_id == CurrentUserSession.user_id: return false
	
	return true

func follow() -> void:
	if valid_profile_id(profile_data.id):
		var url = Routes.get_route(Routes.ENDPOINT_FOLLOW)
		var content = await protected_request(
			url, 
			{"targetId": profile_data.id}, 
			HTTPClient.METHOD_POST
		)

		if content == {}:
			return

		var code = content.get('response_code')
		if code == null:
			print("Error")
			return

		if code == 200 or code == 201:
			print("Success")
			update_button(unfollow)


func unfollow() -> void:
	if valid_profile_id(profile_data.id):
		var url = Routes.get_route(Routes.ENDPOINT_UNFOLLOW)
		var content = await protected_request(
			url, 
			{"targetId": profile_data.id}, 
			HTTPClient.METHOD_POST
		)

		if content == {}:
			return

		var code = content.get('response_code')
		if code == null:
			print("Error")
			return

		if code == 200 or code == 201:
			print("Success")
			update_button(follow)

func update_button(function) -> void:
	if function == follow:
		follow_button.icon = follow_image

	if function == unfollow:
		follow_button.icon = unfollow_image

	follow_button.pressed.connect(function)

func relation_exists(target_id: String) -> bool:
	var url = Routes.get_route(Routes.ENDPOINT_FL_EXISTS)
	var content = await protected_request(url, {"targetId": target_id}, HTTPClient.METHOD_POST)

	var code = content.get('response_code')
	if code == null:
		push_error("Content is empty. returning false")
		return false

	if code != 200:
		push_error("Response != OK. (relation_exists function)")
		return false

	var json_data = content.get('parsed_json')
	print_debug(json_data)
	
	var data = json_data.get('following')
	if data == null:
		push_error("'Following' data is empty")
		return false
	
	return data


func protected_request(url: String, payload: Dictionary, method: HTTPClient.Method, custom_headers: Array = []) -> Dictionary:
	if !GeneralTools.Validations.new().validate_url(url):
		push_warning("Invalid url: ", url)
		return {}
	
	print("Requesting url: ", url)

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
	var is_json := true

	if body_text != "":
		var parse_result = JSON.parse_string(body_text)
		if parse_result != null:
			parsed_json = parse_result
		else:
			is_json = false
	
	match response_code:
		200, 201: print("Profile updated successfuly");
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
		"response_code": response_code
	}

func _on_user_profile_prototype_profile_loaded(received_profile_data:GeneralTools.UserProfile) -> void:
	profile_data = received_profile_data
	active = true

	if valid_profile_id(profile_data.id):
		if await relation_exists(profile_data.id):
			follow_button.icon = unfollow_image
			follow_button.pressed.connect(unfollow)
		else:
			follow_button.icon = follow_image
			follow_button.pressed.connect(follow)
		
		follow_button.show()
