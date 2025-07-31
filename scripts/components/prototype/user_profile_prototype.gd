extends Control
class_name UserProfileUIPrototype

@export_group("API")
## Profile_ID should set in script
@export var profile_id: String

## `profile_getter_endpoint` is an url to get profile data (currently it's set to search by id (uid))
@export var profile_getter_endpoint: String = "/api/v1/profile/uid/%s"
@export_group("Defaults")
@export_file("*.png", "*.jpg", "*.webp", "*.svg") var default_profile_picture: String

# Basic Scene Objects
@onready var displayNameLineEdit: LineEdit = $BgPanel/DisplayNameLineEdit
@onready var usernameLineEdit: LineEdit = $BgPanel/UsernameLineEdit
@onready var bioTextEdit: TextEdit = $BgPanel/BioTextEdit
@onready var idLabel: Label = $BgPanel/IDLabel
@onready var profile_picture_texture_rect: TextureRectRounded = $BgPanel/ProfilePictureTextureRect
@onready var bgpanel: Panel = $BgPanel
@onready var editPfpButton: Button = $BgPanel/EditPFPButton
@onready var profileDoneButton: Button = $ProfileDoneButton
@onready var char_count_label: Label = $BgPanel/CharCountLabel

@onready var loading_panel: Panel = $LoadingPanel
@onready var file_dialog: FileDialog = $Files/FileDialog

var current_pfp_path: String = ""
var pfp_replaced: bool = false
var is_updating_text: bool = false

var edit_mode: bool = false
var original_data: GeneralTools.UserProfile

const BIO_MAX_CHARS = 200
var validator_regex: RegEx
var corrector_regex: RegEx

var headers: Array = [
	"Authorization: Bearer %s" % CurrentUserSession.login_token,
	"Content-Type: application/json",
	"Accept: application/json"
]

func prepareRequirements() -> bool:
	var c_valids = GeneralTools.Validations.new()
	var uid_is_valid: bool = c_valids.validate_uid(profile_id)

	return uid_is_valid

#endregion

func loadProfile() -> void:
	loading_panel.show()

	var data = await GeneralTools.requestProfile(profile_id)
	if data.has("error"):
		print_debug("Got error at data", data) # TODO: Handle Errors

	var	profileData: GeneralTools.UserProfile = GeneralTools.UserProfile.new()
	profileData.initializeData(data)

	updateUI(profileData)
	loading_panel.hide()


#region UI Functions
func updateUI(profile_data: GeneralTools.UserProfile) -> void:
	original_data = profile_data
	displayNameLineEdit.text = profile_data.displayName
	usernameLineEdit.text = profile_data.username
	idLabel.text = profile_data.id
	bioTextEdit.text = profile_data.bio

	changeBackground(profile_data.bannerColor)

	if profile_data.avatarUrl != "":
		var texture = await GeneralTools.getUserPfp(profile_data)
		profile_picture_texture_rect.texture = texture

	else:
		var default_image = Image.new()
		default_image.load(default_profile_picture)

		var texture = ImageTexture.create_from_image(default_image)
		profile_picture_texture_rect.texture = texture

func changeBackground(target_color: String) -> void:
	var color = Color(target_color)

	var stylebox = bgpanel.get_theme_stylebox("panel").duplicate()
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = color
		bgpanel.add_theme_stylebox_override("panel", stylebox)


func replaceCurrentPicture(path: String) -> void:
	if path.is_empty():
		push_warning("path is empty")
		return
	
	var texture := GeneralTools.texture_from_file(path)
	if texture:
		profile_picture_texture_rect.texture = texture


#endregion

func send_profile(new_data: GeneralTools.UserProfile) -> void:
	var diff = GeneralTools.compare_profile_datas(original_data,new_data)

	# Lock content
	disable_edit_functions()


	if pfp_replaced == true and current_pfp_path.is_empty() == false:
		await GeneralTools.send_image_to_server(profile_id, current_pfp_path)

	if diff == {}:
		activate_edit_functions(true)
		return
	
	await GeneralTools.sendNewProfileData(profile_id, diff)

	activate_edit_functions(true)


func activate_edit_functions(reenable: bool = false) -> void:
	# Verify if user can edit this profile or not.
	displayNameLineEdit.editable = true
	#usernameLineEdit.editable = true # Should'nt be editable here
	bioTextEdit.editable = true
	editPfpButton.disabled = false	
	profileDoneButton.disabled = false

	if !reenable:
		profileDoneButton.disabled = false
	profileDoneButton.visible = true

func disable_edit_functions() -> void:
	displayNameLineEdit.editable = false
	# usernameLineEdit.editable = false
	bioTextEdit.editable = false
	
	profileDoneButton.disabled = true
	editPfpButton.disabled = true

func _ready() -> void:
	await get_tree().process_frame

	if profile_id != "":
		self.edit_mode = profile_id == CurrentUserSession.user_id
	if prepareRequirements():
		loadProfile()

	if edit_mode:
		activate_edit_functions()

		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = [
			"*.jpeg ; JPEG Image",
			"*.jpg ; JPG Image",
			"*.png ; PNG Image",
			"*.webp ; WEBP Image"
		]

		file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))

		define_bio_settings()


func define_bio_settings() -> void:
	# Define Regex Patterns
	var validation_pattern = "^[\\p{L}\\p{N}\\p{M}\\p{Script=Han}\\p{Script=Hiragana}\\p{Script=Katakana}\\p{Emoji_Presentation}\\s.,?!\\-'\"()☆★♥❤️✨💡🎮🚀🔥🧠🌟]*$"
	validator_regex = RegEx.create_from_string(validation_pattern)

	var correction_pattern = "[^\\p{L}\\p{N}\\p{M}\\p{Script=Han}\\p{Script=Hiragana}\\p{Script=Katakana}\\p{Emoji_Presentation}\\s.,?!\\-'\"()☆★♥❤️✨💡🎮🚀🔥🧠🌟]"
	corrector_regex = RegEx.create_from_string(correction_pattern)
	
	bioTextEdit.text_changed.connect(_on_bio_edit_text_changed)
	update_char_count(bioTextEdit.text)


func update_char_count(text: String) -> void:
	char_count_label.text = "%d / %d" % [text.length(), BIO_MAX_CHARS]


func open_file_selector() -> void:
	file_dialog.popup_centered()


#region Signals

func _on_bio_edit_text_changed() -> void:
	var current_text: String = bioTextEdit.text
	var new_text: String = current_text

	new_text = corrector_regex.sub(new_text, "", true)

	if new_text.length() > BIO_MAX_CHARS:
		new_text = new_text.left(BIO_MAX_CHARS)
	

	if new_text != current_text:
		var caret_line = bioTextEdit.get_caret_line()
		var caret_col = bioTextEdit.get_caret_column() - 1

		bioTextEdit.text = new_text
		
		# Restaura a posição do cursor para uma experiência suave
		bioTextEdit.set_caret_line(caret_line)
		# Garante que a coluna não seja negativa
		bioTextEdit.set_caret_column(max(0, caret_col))



func _on_close_profile_button_pressed() -> void:
	print("Profile Close Button hit")
	self.queue_free()


func _on_profile_done_button_pressed() -> void:
	var raw_data = {
		"id": profile_id,
		"displayName": displayNameLineEdit.text,
		"username": usernameLineEdit.text,
		"bio": bioTextEdit.text,
		"avatarUrl": original_data.avatarUrl,
		"bannerColor": original_data.bannerColor,
		"followersCount": original_data.followersCount,
		"followingCount": original_data.followingCount,
		"badgeIds": [],
		"links": []
	}

	var new_data: GeneralTools.UserProfile = GeneralTools.UserProfile.new()
	new_data.initializeData(raw_data)
	send_profile(new_data)


func _on_edit_pfp_button_pressed() -> void:
	print("Opening file selector...")
	open_file_selector()

func _on_file_selected(path: String) -> void:
	replaceCurrentPicture(path)
	pfp_replaced = true
	current_pfp_path = path


#endregion
