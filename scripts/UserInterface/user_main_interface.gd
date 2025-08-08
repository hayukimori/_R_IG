extends Control

# Top Bar
@onready var profile_button: Button = $TopBarControl/MainPanel/RightSide/ProfileButton
@onready var notifications_button: Button = $TopBarControl/MainPanel/RightSide/NotificationsButton
@onready var profile_picture_trd: TextureRectRounded = $TopBarControl/MainPanel/RightSide/ProfileButton/ProfilePicture
@onready var username_label: Label = $TopBarControl/MainPanel/RightSide/ProfileButton/UsernameLabel
@onready var datetime_label: Label = $TopBarControl/MainPanel/Center/DateTimeLabel
@onready var top_announcements: Control = $TopAnnouncement

# Profile preview
@onready var profile_preview: Control = $ProfilePreview
@onready var pp_picture_trd: TextureRectRounded = $ProfilePreview/ProfilePicture
@onready var pp_username_label: Label = $ProfilePreview/UsernameLabel
@onready var pp_displayname_label: Label = $ProfilePreview/DisplayNameLabel
@onready var pp_bgpanel: Panel = $ProfilePreview/BgPanel
@onready var pp_followers_count_btn: Button = $ProfilePreview/FollowersCountStaticButton
@onready var pp_following_count_btn: Button = $ProfilePreview/FollowingCountStaticButton

# User Roles Preview
@onready var roles_panel: Panel = $ProfilePreview/RolesPanel
@onready var roles_container: VBoxContainer = $ProfilePreview/RolesPanel/ScrollContainer/VBoxContainer

var announcement_rtext: PackedScene = preload("res://screens/components/announcement_richtext.tscn")
var role_component: PackedScene = preload("res://screens/components/role_component.tscn")
var preview_open: bool = false
var default_datetime_format: String = "%02d/%02d/%04d - %02d:%02d:%02d"
var current_time_string: String = "00/00/0000 - 00:00:00"
var time: Dictionary = { 
	"year": 2025, 
	"month": 7, 
	"day": 27, 
	"weekday": 0, 
	"hour": 0, 
	"minute": 5, 
	"second": 28, 
	"dst": false 
}


func _ready() -> void:
	time = Time.get_datetime_dict_from_system()

	if !CurrentUserSession.logged_in:
		push_warning("User is not logged in, profile won't be loaded")
		return
	
	updateUI()


func updateUI() -> void:
	var uid = CurrentUserSession.user_id

	# Validates uid
	if not GeneralTools.Validations.new().validate_uid(uid):
		push_warning("Invalid UID: %s" % uid)
		return
	
	# Gets profile data (as UserProfile)
	var profile_data: GeneralTools.UserProfile = await loadProfile(uid)

	# Check for profile
	if not profile_data:
		push_warning("Failed to load profile data for UID: %s" % uid)
		return

	updateTopBarElements(profile_data)
	

func updateTopBarElements(profile_data: GeneralTools.UserProfile) -> void:
	# Updates UI
	username_label.text = profile_data.username

	var default_image = Image.new()
	var texture = ImageTexture.create_from_image(default_image)

	# Checks for profile picture
	if profile_data.avatarUrl != "":
		texture = await GeneralTools.getUserPfp(profile_data)
		profile_picture_trd.texture = texture

	else:
		default_image.load(GeneralTools.default_profile_picture)
		texture = ImageTexture.create_from_image(default_image)
		profile_picture_trd.texture = texture

	changeMiniPreviewBackground(profile_data.bannerColor)
	updateProfilePreview(profile_data, texture)


func updateProfilePreview(profileData: GeneralTools.UserProfile, pfp_texture: ImageTexture) -> void:
	pp_displayname_label.text = profileData.displayName
	pp_username_label.text = profileData.username
	pp_followers_count_btn.text = GeneralTools.format_number(profileData.followersCount)
	pp_following_count_btn.text = GeneralTools.format_number(profileData.followingCount)
	pp_picture_trd.texture = pfp_texture
	changePreviewBackground(profileData.bannerColor)
	loadRoles()

func changePreviewBackground(target_color: String) -> void:
	var color = Color(target_color)

	var stylebox = pp_bgpanel.get_theme_stylebox("panel").duplicate()
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = color
		pp_bgpanel.add_theme_stylebox_override("panel", stylebox)

func changeMiniPreviewBackground(target_color: String) -> void:
	var color = Color(target_color)

	var hover_stylebox = profile_button.get_theme_stylebox("hover").duplicate()
	if hover_stylebox is StyleBoxFlat:
		hover_stylebox.bg_color = color
		profile_button.add_theme_stylebox_override("hover", hover_stylebox)


func loadProfile(profile_id) -> GeneralTools.UserProfile:
	# Request profile data using id
	var data = await GeneralTools.requestProfile(profile_id)

	# Verify errors
	if data.has("error"):
		push_error("Error at loadProfile(): ", data.error)
	
	# Gets profile as UserProfile (primitive interface using class)
	var	profileData: GeneralTools.UserProfile = GeneralTools.UserProfile.new()
	profileData.initializeData(data)

	return profileData

func loadRoles() -> void:
	roles_panel.visible = true
	var user_roles = CurrentUserSession.user_roles
	if user_roles == []:
		return
	

	var local_roles_scenes: Array = []

	for role in user_roles:
		var temp_role_scene = role_component.instantiate()
		temp_role_scene.role_name = role.get("name")
		temp_role_scene.role_description = role.get("description")

		local_roles_scenes.append(temp_role_scene)
	
	for lrs in local_roles_scenes:
		roles_container.add_child(lrs)


func add_top_announcement(action: PayloadAction) -> void:
	var ann_obj = announcement_rtext.instantiate()
	ann_obj.action = action

	top_announcements.add_child(ann_obj)

func _process(_delta: float) -> void:

	time = Time.get_datetime_dict_from_system()

	current_time_string = default_datetime_format % [
		time.day, time.month, time.year,
		time.hour, time.minute, time.second
	]

	datetime_label.text = current_time_string


func _on_logout_button_pressed() -> void:
	SceneHandler.logout()


func _on_profile_click_button_pressed() -> void:
	if preview_open:
		profile_preview.hide()
	else:
		profile_preview.show()
	
	preview_open = not preview_open
