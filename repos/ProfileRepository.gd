class_name ProfileRepository
extends RefCounted

func download_image(url: String) -> PackedByteArray:
	var http_request := HTTPRequest.new()
	Engine.get_main_loop().current_scene.add_child(http_request)

	var error = http_request.request(url, [], HTTPClient.METHOD_GET)

	if error != OK:
		push_error("Error requesting for image: ", url, error)
		return PackedByteArray([])

	var result = await http_request.request_completed

	var _result_code = result[0]
	var _response_code = result[1]
	var _headers = result[2]
	var body = result[3]

	return body
