extends Control

# Top Bar
@onready var notifications_button: Button = $TopBarControl/MainPanel/RightSide/NotificationsButton
@onready var profile_picture_trd: TextureRectRounded = $TopBarControl/MainPanel/RightSide/ProfileButton/ProfilePicture
@onready var username_label: Label = $TopBarControl/MainPanel/RightSide/ProfileButton/UsernameLabel


func _ready() -> void:
	if !CurrentUserSession.logged_in:
		push_warning("User is not logged in, profile won't be loaded")
		return


func load_profile() -> void:
	# Get user basic info from current session
	username_label.text = CurrentUserSession.username

