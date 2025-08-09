extends Node3D

@export_category("App configs")
@export var demo_mode: bool = false

@onready var cubes_cluster: Node3D = $CubesCluster

func _ready() -> void:
	GlobalCluster.cluster_3d = cubes_cluster

	# Add this scene to the current scenes list for management
	SceneHandler.current_scenes.append(self)

	# Online System
	var timer := Timer.new()
	timer.wait_time = 10
	timer.one_shot = false

	timer.timeout.connect(_on_ping_timeout)
	add_child(timer)
	timer.start()


func _on_ping_timeout() -> void:
	if !CurrentUserSession.logged_in:
		return

	var json = {"user_id": CurrentUserSession.user_id}
	var url = Routes.get_route(Routes.ENDPOINT_PING)

	# Sends a ping to API, server will save for 60s
	var result = await GeneralTools.protected_request(url, json, HTTPClient.METHOD_PATCH)
	if result.get("response_code") == 401: SceneHandler.logout()


func _process(delta: float) -> void:
	if demo_mode:
		cubes_cluster.rotate_y(0.02 * delta)
		cubes_cluster.rotate_z(0.01 * delta)