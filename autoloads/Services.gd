extends Node

var user_service: UserService
var scene_service: SceneService
var api: APIService
var announcements: AnnouncementsService
var routes: RouteService
var profile_service: ProfileService
var cluster_service: ClusterService

func _ready() -> void:
	print("[Services] Starting services")
	routes = RouteService.new(self);
	api = APIService.new(self);
	user_service = UserService.new(self);
	scene_service = SceneService.new(self);
	announcements = AnnouncementsService.new(self);
	profile_service = ProfileService.new();
	cluster_service = ClusterService.new(self);
