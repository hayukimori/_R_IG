extends CSGBox3D
class_name UserCube

@export var cube_id: String
@export var user_id: String

var profile_scene: PackedScene = preload("res://screens/components/user_profile_prototype.tscn")

func _ready() -> void:
	if cube_id == null or user_id == null:
		push_error("Invalid user/cube.")
		queue_free()
	else:
		if user_id == CurrentUserSession.user_id:
			enable_track()
		

func enable_track() -> void:
	var track_scene: PackedScene = load("res://scenes/3D/components/track_reticles.tscn")
	var tmp_scene: Node3D = track_scene.instantiate()
	add_child(tmp_scene)

func on_clicked() -> void:
	push_warning("Cube function on_clicked not implemented.")

	# Test Profile
	var profile_ui_raw: UserProfileUIPrototype = profile_scene.instantiate()

	profile_ui_raw.profile_id = user_id
	add_child(profile_ui_raw)