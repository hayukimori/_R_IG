extends Control
class_name UIRoleComponent

@export_group("Basic")
@export var role_name: String
@export var role_description: String

@export_group("Roles Textures")
@export var texture_admin: CompressedTexture2D
@export var texture_moderator: CompressedTexture2D
@export var texture_supporter: CompressedTexture2D
@export var texture_content_creator: CompressedTexture2D
@export var texture_unknown_role: CompressedTexture2D

@onready var role_texture_trd: TextureRectRounded = $RoleTexture
@onready var role_name_label: Label = $RoleNameLabel
@onready var role_description_label: Label = $RoleDescriptionLabel

func _ready() -> void:
	role_name_label.text = role_name
	role_description_label.text = role_description

	match role_name.to_lower():
		"admin": set_texture(texture_admin)
		"moderator": set_texture(texture_moderator)
		"supporter": set_texture(texture_supporter)
		"content_creator": set_texture(texture_content_creator)
		_: pass

func set_texture(texture: CompressedTexture2D) -> void:
	var tex := texture if texture != null else texture_unknown_role
	role_texture_trd.texture = tex