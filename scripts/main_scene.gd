extends Node3D

@export_category("App configs")
@export var demo_mode: bool = false
@export var ray_length: float = 50.0

@onready var cubes_cluster: Node3D = $CubesCluster

var last_target: Node3D = null
var hover_material: StandardMaterial3D = preload("res://assets/materials/3D/user_cube_hover_material.tres")

func _ready() -> void:
	Services.cluster_service.cluster_3d = cubes_cluster

	# Add this scene to the current scenes list for management
	Services.scene_service.current_scenes.append(self)

	# Online System
	var timer := Timer.new()
	timer.wait_time = 10
	timer.one_shot = false

	timer.timeout.connect(_on_ping_timeout)
	add_child(timer)
	timer.start()


func _on_ping_timeout() -> void:
	if !Services.user_service.logged_in:
		return

	var json = {"user_id": Services.user_service.user_id}

	var route := Services.routes.ROUTE_STATUS
	var url := route.url()

	# Sends a ping to API, server will save for 60s
	var result = await Services.api.auth_fetch(url, route.method, json)
	if result.get("response_code") == 401: Services.scene_service.logout()


func _process(delta: float) -> void:
	if demo_mode:
		cubes_cluster.rotate_y(0.02 * delta)
		cubes_cluster.rotate_z(0.01 * delta)
	
	var camera = get_viewport().get_camera_3d()
	if !camera: return

	# Raycast to get cubes (apply hover)
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = true
	var result = space.intersect_ray(ray_query)

	if result and result.get("collider").is_in_group("cubes"):
		var cube: UserCube = result.get("collider")
		add_highlight(cube)
		last_target = cube

	else:
		if last_target != null:
			remove_highlight(last_target)			
			last_target = null


func add_highlight(obj: CSGBox3D):
	obj.material_overlay = hover_material

func remove_highlight(obj: CSGBox3D):
	obj.material_overlay = null
