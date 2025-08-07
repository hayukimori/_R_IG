extends Node

@export var default_cubes_scene: PackedScene = preload("res://scenes/3D/main_scene.tscn")
@export var main_scene := preload("res://scenes/3D/main_scene.tscn")
@export var login_scene := preload("res://screens/main_auth_system_ui.tscn")
@export var password_scene := preload("res://screens/recover_password_ui.tscn")

func get_main_scene(_first_login: bool = false) -> PackedScene:
    # First Login var saved for future case
    return default_cubes_scene

func get_login_scene() -> PackedScene:
    return login_scene

func get_password_reset_scene() -> PackedScene:
    return password_scene

func goto_scene(scene: PackedScene) -> void:
    get_tree().change_scene_to_packed(scene)