extends LineEdit

@onready var visibility_button: Button = $PasswordVisibility
var texture_visible: CompressedTexture2D = preload("res://assets/textures/icons/google_icons/visibility_24dp.png")
var texture_invisible: CompressedTexture2D = preload("res://assets/textures/icons/google_icons/visibility_off_24dp.png")

func _ready() -> void:
	if visibility_button == null: return
	visibility_button.pressed.connect(_change_field_visibility)

func _change_field_visibility() -> void:
	var current_vs: bool = self.secret
	if current_vs == false: visibility_button.icon = texture_invisible
	if current_vs == true: visibility_button.icon = texture_visible

	self.secret = not self.secret