extends RefCounted
class_name SceneService

var default_cubes_scene: PackedScene = preload("res://scenes/3D/main_scene.tscn")
var main_scene := preload("res://scenes/3D/main_scene.tscn")
var login_scene := preload("res://screens/main_auth_system_ui.tscn")
var password_scene := preload("res://screens/recover_password_ui.tscn")

var current_scenes: Array = []
var profile_loaded: bool = false

var parent_node: Node

func _init(node: Node) -> void:
    parent_node = node


func get_main_scene(_first_login: bool = false) -> PackedScene:
    # First Login var saved for future case
    return default_cubes_scene

func get_login_scene() -> PackedScene:
    return login_scene

func get_password_reset_scene() -> PackedScene:
    return password_scene

func goto_scene(scene: PackedScene) -> void:
    parent_node.get_tree().change_scene_to_packed(scene)


func kill_scene(scene: Node) -> void:
    if scene and scene.is_inside_tree():
        scene.queue_free()
        current_scenes.erase(scene)
        if AppConfig.DEBUG_MODE: print("Scene %s has been killed." % scene.name)


func change_scene_to_login() -> void:
    if not login_scene:
        push_error("Login scene is not set.")
        return
    var login_instance = login_scene.instantiate()
    parent_node.get_tree().root.add_child(login_instance)


func logout() -> void:
    # Clear current session data
    Services.user_service.clear_session()
    Services.user_service.logged_in = false
    Services.user_service.session_data_changed.emit({
        "user_id": "",
        "username": "",
        "email": "",
        "created_at": "",
        "login_token": ""
    })
    
    Services.cluster_service.cluster_3d = null
    Services.cluster_service.cubes_id.clear()
    Services.cluster_service.active_connections.clear()
    print_rich("[b]INFO[/b] User logged out successfully.")
    
    # Kill all current scenes
    for scene in current_scenes:
        kill_scene(scene)
    
    # Change to login scene
    change_scene_to_login()