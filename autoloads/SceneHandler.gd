extends Node

var current_scenes: Array = []
var login_scene: PackedScene = preload("res://screens/main_auth_system_ui.tscn")


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
    get_tree().root.add_child(login_instance)

func logout() -> void:
    # Clear current session data
    CurrentUserSession.clear_session()
    CurrentUserSession.logged_in = false
    CurrentUserSession.session_data_changed.emit({
        "user_id": "",
        "username": "",
        "email": "",
        "created_at": "",
        "login_token": ""
    })
    
    GlobalCluster.cluster_3d = null
    GlobalCluster.cubes_id.clear()
    GlobalCluster.active_connections.clear()
    print_rich("[b]INFO[/b] User logged out successfully.")
    
    # Kill all current scenes
    for scene in current_scenes:
        kill_scene(scene)
    
    # Change to login scene
    change_scene_to_login()