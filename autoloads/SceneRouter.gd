extends Node

@export var default_cubes_scene: PackedScene


func get_main_scene(_first_login: bool = false) -> PackedScene:
    # First Login var saved for future case
    return default_cubes_scene