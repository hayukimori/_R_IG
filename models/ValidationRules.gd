extends RefCounted
class_name ValidationRules

# Validates string
static func is_valid_string(
	value: String,
	trim: bool = false,
	min_length: int = 1, 
	max_length: int = 50, 
	regex_pattern: String = ""
) -> bool:

	# Strip edges if trim is true
	value = value.strip_edges() if trim else value

	if value.length() < min_length or value.length() > max_length:
		return false
	if regex_pattern != "":
		var regex = RegEx.new()
		regex.compile(regex_pattern)
		if not regex.search(value):
			return false
	return true


# Validation for password
# Requirements:
#   - Minimum: 12 chars
#   - Includes 1 special character
#   - Includes 1 lower case character
#   - Includes 1 upper case character
#   - Includes 1 number
static func validate_password(password: String) -> bool:
	# Setup validator for email (no regex)
	var validation = is_valid_string(
		password, 
		true,
		12, 255,
		r"""^(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?`~]).{12,}$"""
	)

	return validation


# Validation for Email
static func validate_email(email: String) -> bool:
	# Setup validator for email
	var validation = is_valid_string(
		email, 
		true, 1, 255, 
		r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
	)

	return validation 


# Validation for URL
static func validate_url(url: String) -> bool:
	# Setup validation for url
	var validation = is_valid_string(
		url, 
		true, 1, 255, 
		#r"^https?:\/\/(www\.)?[a-zA-Z0-9\-._~%]+(\.[a-zA-Z]{2,})(:[0-9]{1,5})?(\/[^\s]*)?$")
		r"^https?:\/\/(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])\.)*[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9](:\d{1,5})?(\/.*)?$|^https?:\/\/localhost(:\d{1,5})?(\/.*)?$"
	)
	return validation


# Validation for MongoDB ObjectId
static func validate_object_id(object_id: String) -> bool:
	var validation: bool = is_valid_string(
		object_id,
		true, 24, 24,
		r"^[a-fA-F0-9]{24}$"
	)

	return validation

# Validation for 6-digit code (numbers only)
static func validate_code(code: String) -> bool:
	var validation: bool = is_valid_string(
		code,
		true, 6, 6,
		r"^\d{6}$"
	)
	
	return validation

# Validates images
static func validate_image_format(data: PackedByteArray) -> String:
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


static func validate_post_content(data: String) -> bool:
	var validation: bool = is_valid_string(
		data,
		true,
		1, 
		1000, 
		""
	)

	return validation;