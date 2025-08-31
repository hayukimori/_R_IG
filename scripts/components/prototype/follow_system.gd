extends Control

@export_group("UI Settings")
@export var follow_image: CompressedTexture2D
@export var unfollow_image: CompressedTexture2D

@onready var follow_button: Button = $FollowUnfollowButton

var profile_data: UserProfile
var active: bool = false

func _ready() -> void:
	pass

func valid_profile_id(profile_id: String) -> bool:
	if profile_id == null: return false
	if profile_id.length() != 24: return false
	if profile_id == Services.user_service.user_id: return false
	
	return true

func follow() -> void:
	if valid_profile_id(profile_data.id):
		var route := Services.routes.ROUTE_FOLLOW
		var url = route.url()
		var payload = {"targetId": profile_data.id}
		var content = await Services.api.auth_req_post(url, payload)

		if content == {}:
			return

		var code = content.get('response_code')
		if code == null:
			print("Error")
			return

		if code == 200 or code == 201:
			if AppConfig.DEBUG_MODE: print("Success")
			update_button(unfollow)


func unfollow() -> void:
	if valid_profile_id(profile_data.id):
		var route := Services.routes.ROUTE_FOLLOW
		var url := route.url()
		var payload = {"targetId": profile_data.id}
		var content = await Services.api.auth_fetch(url, route.method, payload)

		if content == {}:
			return

		var code = content.get('response_code')
		if code == null:
			print("Error")
			return

		if code == 200 or code == 201:
			if AppConfig.DEBUG_MODE: print("Success")
			update_button(follow)

func update_button(function) -> void:
	if function == follow:
		follow_button.icon = follow_image

	if function == unfollow:
		follow_button.icon = unfollow_image

	follow_button.pressed.connect(function)

func _on_user_profile_prototype_profile_loaded(received_profile_data: UserProfile) -> void:
	profile_data = received_profile_data
	active = true

	if valid_profile_id(profile_data.id):
		if profile_data.is_following:
			follow_button.icon = unfollow_image
			follow_button.pressed.connect(unfollow)
		else:
			follow_button.icon = follow_image
			follow_button.pressed.connect(follow)
		
		follow_button.show()
