extends Control

@export_group("UI Settings")
@export var follow_image: CompressedTexture2D
@export var unfollow_image: CompressedTexture2D

@onready var follow_button: Button = $FollowUnfollowButton

var profile_data: GeneralTools.UserProfile
var active: bool = false

func _ready() -> void:
	pass

func valid_profile_id(profile_id: String) -> bool:
	if profile_id == null: return false
	if profile_id.length() != 24: return false
	if profile_id == CurrentUserSession.user_id: return false
	
	return true

func follow() -> void:
	if valid_profile_id(profile_data.id):
		var url = Routes.get_route(Routes.ENDPOINT_FOLLOW)
		var content = await GeneralTools.protected_request(
			url, 
			{"targetId": profile_data.id}, 
			HTTPClient.METHOD_POST
		)

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
		var url = Routes.get_route(Routes.ENDPOINT_UNFOLLOW)
		var content = await GeneralTools.protected_request(
			url, 
			{"targetId": profile_data.id}, 
			HTTPClient.METHOD_POST
		)

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

func relation_exists(target_id: String) -> bool:
	var url = Routes.get_route(Routes.ENDPOINT_FL_EXISTS)
	var content = await GeneralTools.protected_request(url, {"targetId": target_id}, HTTPClient.METHOD_POST)

	var code = content.get('response_code')
	if code == null:
		push_error("Content is empty. returning false")
		return false

	if code != 200:
		push_error("Response != OK. (relation_exists function)")
		return false

	var json_data = content.get('parsed_json')
	
	var data = json_data.get('following')
	if data == null:
		push_error("'Following' data is empty")
		return false
	
	return data


func _on_user_profile_prototype_profile_loaded(received_profile_data:GeneralTools.UserProfile) -> void:
	profile_data = received_profile_data
	active = true

	if valid_profile_id(profile_data.id):
		if await relation_exists(profile_data.id):
			follow_button.icon = unfollow_image
			follow_button.pressed.connect(unfollow)
		else:
			follow_button.icon = follow_image
			follow_button.pressed.connect(follow)
		
		follow_button.show()
