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
@export var post_has_image: bool = true;


@onready var content_label: Label = $MainContentLabel
@onready var pfp_texture_rect: TextureRectRounded = $ProfilePictureTextureRect
@onready var display_name_label: Label = $DisplayNameLabel
@onready var username_timestamp_label: Label = $UsernameTimestampLabel
@onready var postmedia_tr = $PostMediaTextureRectRounded

#@onready var likes_count_label: Label = $InteractionsContainer/LikeButton/LikeLabel
#@onready var comments_count_label: Label = $InteractionsContainer/CommentButton/CommetLabel
#@onready var like_btn: Button = $InteractionsContainer/LikeButton
#@onready var comment_btn: Button = $InteractionsContainer/CommentButton


const DEFAULT_IMAGE_SIZE = Vector2(356.0, 163.0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await get_tree().process_frame
	load_data()

	var new_size = calc_size()
	change_current_size(new_size)


func load_data() -> void:
	display_name_label.text = displayName
	content_label.text = content
	#comments_count_label.text = str(commentsCount)
	#likes_count_label.text = str(likesCount)
	
	var user_texture = await ImageLib.get_image_or_default(avatarUrl)
	pfp_texture_rect.texture = user_texture



func calc_size() -> int:
	if post_has_image:
		postmedia_tr.size = DEFAULT_IMAGE_SIZE
	else:
		postmedia_tr.size = Vector2.ZERO

	return content_label.size.y + postmedia_tr.size.y + 128

func change_current_size(new_size: float) -> void:
	custom_minimum_size.y = new_size