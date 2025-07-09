extends Node3D

@onready var user_cube_templ: UserCube = $UserCube

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if user_cube_templ != null:
		user_cube_templ.rotation.x += .5 * delta
		user_cube_templ.rotation.y += .3 * delta
