extends CSGBox3D
class_name UserCube

@export var cube_id: String
@export var user_id: String

func _ready() -> void:
	if cube_id == null or user_id == null:
		push_error("Invalid user/cube.")
		queue_free()