extends CSGBox3D
class_name UserCube

signal profile_requested(user_id)

@export var cube_id: String
@export var user_id: String

func _ready() -> void:
	if cube_id == null or user_id == null:
		push_error("Invalid user/cube.")
		queue_free()
	else:
		if user_id == Services.user_service.user_id:
			enable_track()
		

func enable_track() -> void:
	var track_scene: PackedScene = load("res://scenes/3D/components/track_reticles.tscn")
	var tmp_scene: Node3D = track_scene.instantiate()
	add_child(tmp_scene)

func on_clicked() -> void:
	profile_requested.emit(user_id)