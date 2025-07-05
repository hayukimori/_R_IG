extends Node3D

@export_category("App configs")
@export var demo_mode: bool = false


@onready var cubes_cluster: Node3D = $CubesCluster

func _process(delta: float) -> void:
	if demo_mode:
		cubes_cluster.rotate_y(0.02 * delta)
		cubes_cluster.rotate_z(0.01 * delta)