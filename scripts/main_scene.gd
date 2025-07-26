extends Node3D

@export_category("App configs")
@export var demo_mode: bool = false

@onready var cubes_cluster: Node3D = $CubesCluster

func _ready() -> void:
	# Add this scene to the current scenes list for management
	SceneHandler.current_scenes.append(self)


func _process(delta: float) -> void:
	if demo_mode:
		cubes_cluster.rotate_y(0.02 * delta)
		cubes_cluster.rotate_z(0.01 * delta)