extends Node3D

@export_category("App configs")
@export var demo_mode: bool = false

@onready var cubes_cluster: Node3D = $CubesCluster
@onready var http := HTTPRequest.new()

func _ready() -> void:
	# Add this scene to the current scenes list for management
	SceneHandler.current_scenes.append(self)

	# Online System
	add_child(http)
	var timer := Timer.new()
	timer.wait_time = 20
	timer.one_shot = false

	timer.timeout.connect(_on_ping_timeout)
	add_child(timer)
	timer.start()


func _on_ping_timeout() -> void:
	if !CurrentUserSession.logged_in:
		return

	var user_id = CurrentUserSession.user_id
	var json = {"user_id": CurrentUserSession.user_id}
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % CurrentUserSession.login_token
	]
	var url = GeneralTools.get_route("/api/v1/ping")

	# Sends a ping to API, server will save for 60s
	http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(json))


func _process(delta: float) -> void:
	if demo_mode:
		cubes_cluster.rotate_y(0.02 * delta)
		cubes_cluster.rotate_z(0.01 * delta)