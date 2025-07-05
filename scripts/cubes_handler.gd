extends Node

@export var cluster: Node3D
@export var gen_cubes_request_url: String = "http://localhost/getcubes"

func _ready() -> void:
	var content = await request_cubes()
	generate_cubes(content)


# This function will be replaced in future versions
func generate_cubes(cubes_array: Array) -> void:
	if cubes_array != []:
		push_warning("This function is not implemented yet")
	else:
		push_error("cubes_array is empty.")

# Request for gen_cubes_request_url (GET) to get an array from all existing cubes
# This function is temporary, and it will be replaced in future versions
func request_cubes() -> Array:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Array = []

	http_request.request_completed.connect(func(_result_code, response_code, _headers, body):
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if typeof(json) == TYPE_ARRAY:
				result.assign(json)
			elif typeof(json) == TYPE_DICTIONARY:
				result.append(json)
	)

	http_request.request(gen_cubes_request_url)

	await http_request.request_completed
	http_request.queue_free()

	return result