extends Node

@export_category("3D")
@export var cluster: Node3D
@export var user_cube_scene: PackedScene
@export var cubes_per_frame: int = 10
@export var gen_cubes_request_url: String = "http://localhost:8081/api/v1/cubes"

@export_category("UI")
@export var devel_ui: DevelopmentUI


var cubes_count: int = 0

func _ready() -> void:
	var content = await request_cubes()
	generate_cubes(content)


# This function will be replaced in future versions
func generate_cubes(cubes_array: Array) -> void:

	if cubes_array.is_empty():
		push_error("cubes_array is empty")
		return
	
	var total := cubes_array.size()
	var i := 0

	while i < total:
		for j in range(i, min(i + cubes_per_frame, total)):
			new_cube(cubes_array[j])
		i += cubes_per_frame

		await get_tree().process_frame
		

	# if cubes_array != []:
	# 	for cube in cubes_array:
	# 		await get_tree().process_frame
	# 		new_cube(cube)
	# else:
	# 	push_error("cubes_array is empty.")


func new_cube(cube_data: Dictionary) -> void:
	if user_cube_scene == null:
		push_error("User cube scene is null")
		return
	
	if cluster == null:
		push_error("Cluster is null")
		return

	var cid: String = cube_data.id
	var owner_id: String = cube_data.owner_id
	var cube_position: Vector3 = Vector3(
		cube_data.position_x,
		cube_data.position_y,
		cube_data.position_z
	)

	var t_cube: UserCube = user_cube_scene.instantiate()
	t_cube.cube_id = cid
	t_cube.user_id = owner_id

	cluster.add_child(t_cube)
	t_cube.position = cube_position

	cubes_count += 1
	
	# DEBUG
	devel_ui.update_cubes_count(cubes_count)
	devel_ui.update_current_json_content(cube_data)


# Request for gen_cubes_request_url (GET) to get an array from all existing cubes
# This function is temporary, and it will be replaced in future versions
func request_cubes() -> Array:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Array = []

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		print_debug(result_code)
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if typeof(json) == TYPE_ARRAY:
				result.assign(json)
			elif typeof(json) == TYPE_DICTIONARY:
				result.append(json)
		else:
			push_error("Server response code: %d" % response_code)
	)

	http_request.request(gen_cubes_request_url)

	await http_request.request_completed
	http_request.queue_free()

	return result
