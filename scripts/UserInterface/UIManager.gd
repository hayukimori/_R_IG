extends CanvasLayer

@export var profile_scene: PackedScene = preload("res://screens/components/user_profile_prototype.tscn")

var current_profile: UserProfileUIPrototype

func _on_cube_profile_requested(user_id: String) -> void:

	if profile_scene == null:
		push_error("(UI Manager) profile_scene is null.")
		return

	var profile_instance: Node = profile_scene.instantiate()
	profile_instance.profile_id = user_id
	
	if current_profile:
		current_profile.queue_free()

	current_profile = profile_instance
	add_child(profile_instance)

func _process(_delta: float) -> void:
	SceneHandler.profile_loaded = (current_profile != null)

func _on_cubes_handler_cube_added_to_cluseter(cube: UserCube) -> void:
	cube.profile_requested.connect(_on_cube_profile_requested)
