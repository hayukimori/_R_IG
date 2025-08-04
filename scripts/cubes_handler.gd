extends Node

signal cube_added_to_cluseter(cube: UserCube)

@export_category("3D")
@export var cluster: Node3D
@export var user_cube_scene: PackedScene
@export var cubes_per_frame: int = 10

@export_category("UI")
@export var devel_ui: DevelopmentUI

@onready var main_timer: Timer = $Timer

var gen_cubes_request_url: String
var new_cubes_url: String

var cubes_count: int = 0
var cubes_history: Array = []
var last_cube_id: String = ""

func _ready() -> void:
	# Set new routes
	gen_cubes_request_url = Routes.get_route(Routes.ENDPOINT_CUBES)
	new_cubes_url = Routes.get_route(Routes.ENDPOINT_NEW_CUBES)

	if (
		CurrentUserSession.login_token != "" and 
		CurrentUserSession.user_id != ""
	):
		if devel_ui != null:
			devel_ui.update_user_id(CurrentUserSession.user_id)

	var content = await request_cubes()
	# TODO: Add an error hanlder
	
	cubes_history = content
	generate_cubes(content)

	last_cube_id = content[-1].id
	main_timer.start()

	


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

	var cid: String = cube_data["id"]
	

	var owner_id: String = cube_data.owner_id
	var cube_position: Vector3 = Vector3(
		cube_data.position.x,
		cube_data.position.y,
		cube_data.position.z
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

	t_cube.add_to_group("cubes")
	GlobalCluster.add_cube(t_cube)
	cube_added_to_cluseter.emit(t_cube)


# Request for gen_cubes_request_url (GET) to get an array from all existing cubes
# This function is temporary, and it will be replaced in future versions
func request_cubes(get_new: bool = false, last_id: String = "") -> Array:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Array = []

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != 0:
			print("error connecting, result_code: %d" % result_code)
			result.assign([
				{
				"ConnectionError": "Connection error", 
				"context": "Couldn't connect: result_code: %d"  % result_code, 
				"code": result_code
				}
			])
			
		match response_code:
			200, 201: print("Ok")
			400: push_error("400 Error")
			500: push_error("Server error")
		
		
		var json = JSON.parse_string(body.get_string_from_utf8())
		if typeof(json) == TYPE_ARRAY:
			result.assign(json)
		elif typeof(json) == TYPE_DICTIONARY:
			result.append(json)
	)

	
	var token = CurrentUserSession.login_token
	if token == "":
		push_error("CUBES HANDLER REQUEST ERROR: No Token Provided, it can result in request error.")

	var headers = [
		"Content-Type: application/json",
		"Accept: application/json",
		"Authorization: Bearer %s" % token
	]

	if get_new:
		var dict_data = { "id": last_id }
		var jsondata = JSON.stringify(dict_data)

		http_request.request(new_cubes_url, headers, HTTPClient.METHOD_POST, jsondata)

	else:
		http_request.request(gen_cubes_request_url, headers, HTTPClient.METHOD_GET)

	await http_request.request_completed
	http_request.queue_free()

	return result


func _on_timer_timeout() -> void:
	var new_cubes = await request_cubes(true, last_cube_id)

	if new_cubes.size() > 0:
		if new_cubes != cubes_history:
			cubes_history += new_cubes
			generate_cubes(new_cubes)
			print(cubes_history[-1])
			last_cube_id = cubes_history[-1].id
		else:
			print("Is equals")
