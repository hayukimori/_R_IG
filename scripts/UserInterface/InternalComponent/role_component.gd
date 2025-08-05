extends Control
class_name UIRoleComponent

@export_group("Basic")
@export var role_name: String
@export var role_description: String

@onready var role_texture_trd: TextureRectRounded = $RoleTexture
@onready var role_name_label: Label = $RoleNameLabel
@onready var role_description_label: Label = $RoleDescriptionLabel

func _ready() -> void:
	role_name_label.text = role_name
	role_description_label.text = role_description