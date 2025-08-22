class_name RouteLib
extends RefCounted


var api_host: String
var ws_host: String

func _init() -> void:
    api_host = ProjectSettings.get_setting("application/config/api_host", "http://localhost:3000")
    ws_host = ProjectSettings.get_setting("application/config/ws_host", "ws://localhost:8080")

func get_route(endpoint: String) -> String:
    return api_host + endpoint

func get_ws_url() -> String:
    return ws_host