extends Control


@export var post_id: String;
@export var authorId: String;
@export var content: String;
@export var createdAt: String;
@export var updatedAt: String;
@export var avatarUrl: String;
@export var displayName: String;
@export var likesCount: int;
@export var commentsCount: int;



@onready var content_label: Label = $ContentLabel
@onready var pfp_texture_rect: TextureRectRounded = $LeftContainer/TextureRectRounded
@onready var display_name_label: Label = $LeftContainer/DisplayNameLabel
@onready var likes_count_label: Label = $InteractionsContainer/LikeButton/LikeLabel
@onready var comments_count_label: Label = $InteractionsContainer/CommentButton/CommetLabel


func change_current_size() -> void:
	custom_minimum_size.y = content_label.size.y + 64

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content_label.text = content
	
	await get_tree().process_frame

	load_data()
	change_current_size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func load_data() -> void:
	display_name_label.text = displayName
	comments_count_label.text = str(commentsCount)
	likes_count_label.text = str(likesCount)
	
	var texture = await ImageLib.get_image_or_default(avatarUrl)
	pfp_texture_rect.texture = texture
