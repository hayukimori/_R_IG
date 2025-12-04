class_name APIService
extends RefCounted

var parent_node: Node

func _init(node: Node) -> void:
	parent_node = node

## Requests user profile data
func request_profile(profile_id: String) -> Dictionary:
	var route: Route = Services.routes.ROUTE_PROFILE
	var url = route.url({"identifier": profile_id})

	var base_result = await auth_fetch(url, route.method)
	return base_result.get("parsed_json", {})

## Requests a PUT request to update profile picture
func send_profile_data(targetId: String, data: Dictionary) -> void:
	var route: Route = Services.routes.ROUTE_SEND_PROFILE
	var url = route.url()

	var payload = {"targetId": targetId, "fields": data}
	await auth_fetch(url, route.method, payload)

## Gets server current time.
func get_server_time() -> String:
	var route = Services.routes.ROUTE_SERVER_TIME
	var url = route.url()

	var datereg = await auth_fetch(url, route.method)
	if datereg["parsed_json"].get('now', '') != "" and datereg["response_code"] == 200:
		return datereg["parsed_json"].get('now', '')

	return ""

## Get's user roles and permissions
func get_privileges() -> Dictionary:
	var route = Services.routes.ROUTE_ME
	var url = route.url()

	var content = await auth_fetch(url, route.method)
	return content.get('parsed_json', {})


#region Request Manager

## Request mehtod with Authorization
func auth_fetch(url: String, method: HTTPClient.Method, payload: Dictionary = {}, extra_headers: Array = []) -> Dictionary:
	var headers: Array = []

	# This should solve "Content-Type: application/json" issues when calling a POST, PATCH or PUT method.
	var ctype_methods = [HTTPClient.METHOD_POST, HTTPClient.METHOD_PATCH, HTTPClient.METHOD_PUT]

	var auth_header = "Authorization: Bearer %s" % Services.user_service.login_token #.login_token
	var content_type_header = "Content-Type: application/json"
	headers.append(auth_header)

	if method in ctype_methods and not extra_headers.has(content_type_header):
		headers.append(content_type_header)

	for h in extra_headers:
		if not h.begins_with("Authorization: "):
			headers.append(h)


	var result = await simple_request(url, payload, method, headers)
	return result


## GET method with included Authorization
func auth_req_get(url, custom_headers: Array = []) -> Dictionary:
	var result = await auth_fetch(url, HTTPClient.METHOD_GET, {}, custom_headers)
	return result

## PUT method with included Authorization
func auth_req_put(url: String, payload: Dictionary, custom_headers: Array = []) -> Dictionary:
	var result = await auth_fetch(url, HTTPClient.METHOD_PUT, payload, custom_headers)
	return result

## POST method with included Authorization
func auth_req_post(url: String, payload: Dictionary, custom_headers: Array = []) -> Dictionary:
	var result = await auth_fetch(url, HTTPClient.METHOD_POST, payload, custom_headers)
	return result

## PATCH method with included Authorization
func auth_req_patch(url: String, payload: Dictionary, custom_headers: Array = []) -> Dictionary:
	var result = await auth_fetch(url, HTTPClient.METHOD_PATCH, payload, custom_headers)
	return result

func auth_req_delete(url: String, custom_headers: Array = []) -> Dictionary:
	var result = await auth_fetch(url, HTTPClient.METHOD_DELETE, {}, custom_headers)
	return result

## POST method for sending image (multipart/form-data) - Godot 4.5 compat
func auth_req_img_post(url: String, file_path: String, custom_headers: Array = []) -> Dictionary:
	var method = HTTPClient.METHOD_POST

	# validates url
	var validation = ValidationRules.validate_url(url)
	if not validation:
		push_warning("Invalid url:", url)
		return {}

	var http_request : HTTPRequest = HTTPRequest.new()
	parent_node.add_child(http_request)

	# open 
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s" % file_path)
		return {}

	var file_bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	# filename by extension
	var filename := file_path.get_file()
	var ext := filename.get_extension().to_lower()
	var mime := "application/octet-stream"
	if ext in ["png","jpg","jpeg","webp","gif","bmp"]:
		if ext == "png":
			mime = "image/png"
		elif ext == "jpg" or ext == "jpeg":
			mime = "image/jpeg"
		elif ext == "webp":
			mime = "image/webp"
		elif ext == "gif":
			mime = "image/gif"
		elif ext == "bmp":
			mime = "image/bmp"

	# boundary
	var boundary := "----GodotBoundary%08x" % randi()

	
	var b_body: PackedByteArray = PackedByteArray()
	# helper inline
	b_body += ("--" + boundary + "\r\n").to_utf8_buffer()
	b_body += ('Content-Disposition: form-data; name="file"; filename="%s"\r\n' % filename).to_utf8_buffer()
	b_body += ("Content-Type: %s\r\n\r\n" % mime).to_utf8_buffer()
	b_body += file_bytes
	b_body += "\r\n".to_utf8_buffer()
	b_body += ("--" + boundary + "--\r\n").to_utf8_buffer()

	# headers
	var headers: Array = []
	if custom_headers == []:
		headers = [
			"Content-Type: multipart/form-data; boundary=%s" % boundary,
			"Accept: application/json",
			"Authorization: Bearer %s" % Services.user_service.login_token
		]
	else:
		headers = custom_headers

	# send raw
	var err = http_request.request_raw(url, headers, method, b_body)
	if err != OK:
		push_error("Failed to make request: %s" % err)
		return {}

	# wait response
	var result = await http_request.request_completed

	var result_code = result[0]
	var response_code = result[1]
	var _headers = result[2]
	var body: PackedByteArray = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		push_error("Couldn't complete request. Result: %d" % result_code)
		return {}

	# processar corpo
	var body_text: String = ""
	if body.size() > 0:
		body_text = body.get_string_from_utf8()
	var parsed_json := {}
	var result_array := []
	var is_json := true

	if body_text != "":
		var parse_result = JSON.parse_string(body_text)
		if typeof(parse_result) == TYPE_DICTIONARY or typeof(parse_result) == TYPE_ARRAY:
			if typeof(parse_result) == TYPE_ARRAY:
				result_array.assign(parse_result)
			else:
				parsed_json.assign(parse_result)
		else:
			var parse = JSON.new()

			var try_parsed = parse.parse(body_text)
			if try_parsed.error == OK:
				if typeof(try_parsed.result) == TYPE_ARRAY:
					result_array.assign(try_parsed.result)
				elif typeof(try_parsed.result) == TYPE_DICTIONARY:
					parsed_json.assign(try_parsed.result)
				else:
					is_json = false
			else:
				is_json = false

	match response_code:
		200, 201:
			if AppConfig.DEBUG_MODE:
				print("Protected request, success")
		400:
			push_warning("Bad request. %s" % (JSON.stringify(parsed_json) if is_json else ""))
		401:
			push_warning("Unauthorized. Please log in and try again")
		403:
			push_warning("Forbidden. You don't have permission")
		404:
			push_warning("User or route not found")
		409:
			push_warning("Conflicting data")
		422:
			push_warning("Validation error: %s" % (JSON.stringify(parsed_json) if is_json else ""))
		500, 502, 503:
			push_warning("Server error (%d). Try again later." % response_code)
		_:
			push_warning("Unexpected response (%d): %s" % [response_code, body_text])

	return {
		"body_text": body_text,
		"is_json": is_json,
		"parsed_json": parsed_json,
		"result_array": result_array,
		"response_code": response_code
	}



# Makes a request and returns it as json, containing body_text, is_json, parsed_json, result_array and response_code
func simple_request(
	url: String, payload: Dictionary = {}, 
	method: HTTPClient.Method = HTTPClient.METHOD_GET, 
	custom_headers: Array = []
) -> Dictionary:

	var validation = ValidationRules.validate_url(url)
	if !validation:
		push_warning("Invalid url:", url)
		return {}
	
	var http_request := HTTPRequest.new()
	parent_node.add_child(http_request)
	var headers = []

	if custom_headers == []:
		headers = [
			"Content-Type: application/json",
			"Accpet: application/json"
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


# Requests a auth code to server
func request_server_code(email: String) -> Dictionary:
	var route: Route = Services.routes.ROUTE_FORGOT_PASSWORD
	var url = route.url()

	var generic_error := {"error": "Verify email and try again later"}

	var email_validation: bool = ValidationRules.validate_email(email)
	if !email_validation: return generic_error

	var payload = {"email": email}

	# Request
	var result = await simple_request(url, payload, route.method)

	# Verifications
	if result == {}: return generic_error
	if !result.get('is_json', false) or result.get("response_code") != 200: return generic_error
	return result.get("parsed_json", generic_error)


# Confirmates the code with the server
func request_verify_code(email: String, code: String) -> Dictionary:
	var route: Route = Services.routes.ROUTE_VERIFY_CODE
	var url := route.url()
	var generic_error := {"error": "Verify email or code and try again."}

	# Validates email and six-digit code.
	var email_validation: bool = ValidationRules.validate_email(email)
	var code_validation: bool = ValidationRules.validate_code(code)

	if !email_validation or !code_validation:
		return generic_error
	
	# Makes request to server using code and email
	var payload = { "email": email, "code": code }
	var result = await simple_request(url, payload, route.method)
	
	# Retuns generic error if it has some error
	if result == {}: return generic_error
	if !result.get('is_json', false) or result.get("response_code", 0) != 200: 
		return generic_error

	return result.get("parsed_json", generic_error)


# Requests a password reset
func request_password_reset(token: String, password: String, confirm_password: String) -> Dictionary:
	var route := Services.routes.ROUTE_RESET_PASSWORD
	var url := route.url()
	var error_ret := {"error": "Could not complete request"}

	# Validates password and confirm_password
	var password_validation: bool = ValidationRules.validate_password(password)
	var c_password_validation: bool= ValidationRules.validate_password(confirm_password)
	
	# Returns error if passwords are different
	if (
		!(password_validation and c_password_validation)
		and 
		!(password == confirm_password)
	):
		return { "error": "Verify passwords and try again" }

	# Requests to change password
	var headers = [
		"Authorization: Bearer %s" % token,
		"Content-Type: application/json",
		"Accept: application/json"
	]

	var payload := {
		"password": password,
		"confirm_password": confirm_password
	}
	var result := await simple_request(url, payload, route.method, headers)

	# Verify result
	if result.is_empty(): return error_ret
	if !result.get('is_json', false): return error_ret

	# Returns error to upper handler
	if result.get("response_code", 0) != 200:
		return result.get("parsed_json")

	return result.get("parsed_json")


## Set user's profile picture using an local image
func set_user_profile_picture(target_id: String, image_path: String) -> void:
	var data_url = ImageLib.encode_image_to_data_url(image_path)

	if data_url.is_empty():
		push_error("Could not prepare image to send")
		return
	
	var payload = {"targetId": target_id, "imageData": data_url}

	var route := Services.routes.ROUTE_SEND_PFP
	var url := route.url()

	await auth_fetch(url, route.method, payload)

## Checks for updates
func update_available() -> Dictionary:
	var default := {
		"status": false, 
		"current_version": "", 
		"next_version": "", 
		"required": false
	}

	var route := Services.routes.ROUTE_CHECK_UPDATES # Method: Post
	var url := route.url()

	var current_version : String = ProjectSettings.get_setting("application/config/version")
	print_debug(current_version)

	var result = await simple_request(url, {"version": current_version}, route.method, ["Content-Type: application/json"])
	var rs = result.get("parsed_json", {})

	return rs if rs != {} else default

## Gets an image from an url
func get_image_from_url(url: String) -> ImageTexture:
	var http_request := HTTPRequest.new()
	parent_node.add_child(http_request)
	
	if not ValidationRules.validate_url(url):
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
	var format = ImageLib.get_image_format(image)
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
			err = image.load("res://icon.svg")

	if err != OK:
		push_error("Couldn't load image. Error code: %d" % err)
		return ImageTexture.new()
	else:
		var texture = ImageTexture.create_from_image(image)
		return texture

#endregion
