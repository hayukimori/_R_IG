extends RefCounted
class_name RouteService

# Constant Routes
const ENDPOINT_LOGIN            := "/api/auth/login"
const ENDPOINT_REGISTER         := "/api/auth/register"
const ENDPOINT_PROTECTED        := "/api/auth/protected"
const ENDPOINT_FORGOT_PASSWD	:= "/api/auth/forgot-password"
const ENDPOINT_VERIFY_CODE		:= "/api/auth/verify-code"
const ENDPOINT_RESET_PASSWD		:= "/api/auth/reset-password"
const ENDPOINT_PING             := "/api/v1/ping"
const ENDPOINT_GET_PROFILE      := "/api/v1/profile/uid/%s"
const ENDPOINT_SEND_PROFILE     := "/api/v1/editprofile"
const ENDPOINT_SEND_PICTURE     := "/api/v1/update-pfp"
const ENDPOINT_CUBES            := "/api/v1/cubes"
const ENDPOINT_NEW_CUBES        := "/api/v1/checknewcubes"
const ENDPOINT_WORLD_FOLLOWS    := "/api/v1/worldfollows"
const ENDPOINT_FOLLOW           := "/api/v1/follow"
const ENDPOINT_UNFOLLOW         := "/api/v1/unfollow"
const ENDPOINT_FL_EXISTS        := "/api/v1/follow-exists"
const ENDPOINT_WORLD_UNFOLLOWS  := "/api/v1/worldunfollows"
const ENDPOINT_STIME            := "/api/v1/server-clock"
const ENDPOINT_WORLD_UPDATES    := "/api/v1/worldupdates"
const ENDPOINT_ME				:= "/api/v1/me"

var ROUTE_LOGIN                 := Route.new("/api/auth/login", HTTPClient.METHOD_POST)
var ROUTE_REGISTER              := Route.new("/api/auth/register", HTTPClient.METHOD_POST)
var ROUTE_PROTECTED             := Route.new("/api/auth/protected", HTTPClient.METHOD_POST)
var ROUTE_FORGOT_PASSWORD       := Route.new("/api/auth/forgot-password", HTTPClient.METHOD_POST)
var ROUTE_VERIFY_CODE           := Route.new("/api/auth/verify-code", HTTPClient.METHOD_POST)
var ROUTE_RESET_PASSWORD        := Route.new("/api/auth/reset-password", HTTPClient.METHOD_POST)
var ROUTE_STATUS                := Route.new("/api/v1/profile/me/status", HTTPClient.METHOD_PATCH)
var ROUTE_PROFILE               := Route.new("/api/v1/profile/{identifier}", HTTPClient.METHOD_GET)
var ROUTE_SEND_PROFILE          := Route.new("/api/v1/profile/me", HTTPClient.METHOD_PATCH)
var ROUTE_SEND_PFP              := Route.new("/api/v1/profile/me/avatar", HTTPClient.METHOD_POST)
var ROUTE_CUBES                 := Route.new("/api/v1/cubes", HTTPClient.METHOD_GET)
var ROUTE_NEW_CUBES             := Route.new("/api/v1/cubes?sinceId={sinceId}", HTTPClient.METHOD_GET)
var ROUTE_WORLD_FOLLOWS         := Route.new("/api/v1/worldfollows", HTTPClient.METHOD_GET)
var ROUTE_FOLLOW                := Route.new("/api/v1/me/following", HTTPClient.METHOD_POST)
var ROUTE_UNFOLLOW              := Route.new("/api/v1/me/following/{targetId}", HTTPClient.METHOD_DELETE)
var ROUTE_FOLLOW_EXISTS         := Route.new("/api/v1/me/following/{targetId}", HTTPClient.METHOD_GET)
var ROUTE_WORLD_UNFOLLOWS       := Route.new("/api/v1/worldunfollows", HTTPClient.METHOD_POST)
var ROUTE_WORLD_UPDATES         := Route.new("/api/v1/worldupdates", HTTPClient.METHOD_POST)
var ROUTE_ME                    := Route.new("/api/v1/profiles/me", HTTPClient.METHOD_GET)


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