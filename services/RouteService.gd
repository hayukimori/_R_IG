extends RefCounted
class_name RouteService

# Routes
var ROUTE_LOGIN                 := Route.new("/api/auth/login", HTTPClient.METHOD_POST)
var ROUTE_REGISTER              := Route.new("/api/auth/register", HTTPClient.METHOD_POST)
var ROUTE_PROTECTED             := Route.new("/api/auth/protected", HTTPClient.METHOD_POST)
var ROUTE_FORGOT_PASSWORD       := Route.new("/api/auth/forgot-password", HTTPClient.METHOD_POST)
var ROUTE_VERIFY_CODE           := Route.new("/api/auth/verify-code", HTTPClient.METHOD_POST)
var ROUTE_RESET_PASSWORD        := Route.new("/api/auth/reset-password", HTTPClient.METHOD_POST)
var ROUTE_STATUS                := Route.new("/api/v1/profiles/me/status", HTTPClient.METHOD_PATCH)
var ROUTE_PROFILE               := Route.new("/api/v1/profiles/{identifier}", HTTPClient.METHOD_GET)
var ROUTE_SEND_PROFILE          := Route.new("/api/v1/profiles/me", HTTPClient.METHOD_PATCH)
var ROUTE_SEND_PFP              := Route.new("/api/v1/profiles/me/avatar", HTTPClient.METHOD_POST)
var ROUTE_CUBES                 := Route.new("/api/v1/cubes", HTTPClient.METHOD_GET)
var ROUTE_NEW_CUBES             := Route.new("/api/v1/cubes?sinceId={sinceId}", HTTPClient.METHOD_GET)
var ROUTE_WORLD_FOLLOWS         := Route.new("/api/v1/worldfollows", HTTPClient.METHOD_POST)
var ROUTE_FOLLOW                := Route.new("/api/v1/profiles/me/following", HTTPClient.METHOD_POST)
var ROUTE_UNFOLLOW              := Route.new("/api/v1/profiles/me/following/{targetId}", HTTPClient.METHOD_DELETE)
var ROUTE_FOLLOW_EXISTS         := Route.new("/api/v1/profiles/me/following/{targetId}", HTTPClient.METHOD_GET)
var ROUTE_WORLD_UNFOLLOWS       := Route.new("/api/v1/worldunfollows", HTTPClient.METHOD_POST)
var ROUTE_WORLD_UPDATES         := Route.new("/api/v1/worldupdates", HTTPClient.METHOD_POST)
var ROUTE_ME                    := Route.new("/api/v1/profiles/me", HTTPClient.METHOD_GET)
var ROUTE_SERVER_TIME           := Route.new("/api/v1/server-clock", HTTPClient.METHOD_GET)


var api_host: String
var ws_host: String

var parent_node: Node

func _init(node: Node) -> void:
    api_host = ProjectSettings.get_setting("application/config/api_host", "http://localhost:3000")
    ws_host = ProjectSettings.get_setting("application/config/ws_host", "ws://localhost:8080")

    parent_node = node

    print("[RouteService] RouteService started. Got api_host and ws_host")
    print("[RouteService] api_host", api_host)
    print("[RouteService] ws_host", ws_host)

func get_route(endpoint: String) -> String:
    return api_host + endpoint

func get_ws_url() -> String:
    return ws_host