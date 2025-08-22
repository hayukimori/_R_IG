extends Button
class_name BadgeButton

@onready var description_label: Label = $DescriptionLabel

@export var badge_name: String
@export var badge_icon_url: String
@export var badge_description: String

var icons_preloads: Dictionary = {
	"developer": preload("res://assets/textures/icons/badge_icons/developer.png"),
	"alpha_tester": preload("res://assets/textures/icons/badge_icons/developer.png")
}

func _ready() -> void:
	if (
		badge_name.is_empty() or 
		badge_description.is_empty()
		#badge_icon_url.is_empty()
	):
		push_error("Invalid badge")
		return

	if icons_preloads.has(badge_name):
		self.icon = icons_preloads.get(badge_name)
	else:
		self.icon = await Services.api.get_image_from_url(badge_icon_url)
	
	description_label.text = badge_description



func _on_mouse_exited() -> void:
	description_label.hide()

func _on_mouse_entered() -> void:
	description_label.show()
	
