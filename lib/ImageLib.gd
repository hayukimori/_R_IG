class_name ImageLib

## Converts an image from path to Base64
static func image_to_base64(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if not FileAccess.file_exists(path) or file == null:
		push_error("Failed opening image file: %s" % path)
		return ""
	
	var image_bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	var base64_string: String = Marshalls.raw_to_base64(image_bytes)

	return base64_string


## Get's an image from path, converts it to base64 and attach to mime type
static func encode_image_to_data_url(image_path: String) -> String:
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


## Creates an Texture2D from a file (path)
static func texture_from_file(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	if image == null:
		push_error("Error loading image: %s" % path)
		return null
	
	var texture := ImageTexture.create_from_image(image)
	return texture



## Detects image format
static func get_image_format(data: PackedByteArray) -> String:
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


## Returns a ImageTexture from PackedByteArray
static func buffer_to_texture(buffer: PackedByteArray) -> ImageTexture:
	var image = Image.new()
	var format = get_image_format(buffer)
	
	match format:
		"png": image.load_png_from_buffer(buffer)
		"jpg", "jpeg": image.load_jpg_from_buffer(buffer)
		"webp": image.load_webp_from_buffer(buffer)
	
	return ImageTexture.create_from_image(image)


static func _get_default_avatar() -> ImageTexture:
	return load("res://assets/default_profile_picture.png")


### Gets an image or default
static func get_image_or_default(url: String) -> ImageTexture:
	if not ValidationRules.validate_url(url):
		push_error("Invalid URL: %s" % url)
		return _get_default_avatar()
	
	var image_data = await Repositories.profile_repository.download_image(url)
	if image_data.is_empty():
		return _get_default_avatar()
	
	return ImageLib.buffer_to_texture(image_data)