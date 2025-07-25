extends CSGBox3D
class_name UserCube

@export var cube_id: String
@export var user_id: String

var profile_scene: PackedScene = preload("res://screens/components/user_profile_prototype.tscn")

func _ready() -> void:
	if cube_id == null or user_id == null:
		push_error("Invalid user/cube.")
		queue_free()


func on_clicked() -> void:
	push_warning("Cube function on_clicked not implemented.")

	# Test Profile
	var profile_ui_raw: UserProfileUIPrototype = profile_scene.instantiate()

	profile_ui_raw.profile_id = user_id
	add_child(profile_ui_raw)