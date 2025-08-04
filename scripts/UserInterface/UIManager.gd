extends CanvasLayer

@export var profile_scene: PackedScene = preload("res://screens/components/user_profile_prototype.tscn")

func _on_cube_profile_requested(user_id: String) -> void:

	if profile_scene == null:
		push_error("(UI Manager) profile_scene is null.")
		return

	var profile_instance: Node = profile_scene.instantiate()
	profile_instance.profile_id = user_id
	
	add_child(profile_instance)


func _on_cubes_handler_cube_added_to_cluseter(cube: UserCube) -> void:
	cube.profile_requested.connect(_on_cube_profile_requested)
