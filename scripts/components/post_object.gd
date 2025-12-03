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
@onready var pfp_texture_rect: TextureRectRounded = $TextureRectRounded
@onready var display_name_label: Label = $DisplayNameLabel
@onready var likes_count_label: Label = $InteractionsContainer/LikeButton/LikeLabel
@onready var comments_count_label: Label = $InteractionsContainer/CommentButton/CommetLabel

@onready var like_btn: Button = $InteractionsContainer/LikeButton
@onready var comment_btn: Button = $InteractionsContainer/CommentButton


func change_current_size() -> void:
	custom_minimum_size.y = content_label.size.y + 48

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


func like_post() -> void:
	# to be implemented
	pass

func comment_post() -> void:
	# to be implemented
	pass


func _on_comment_button_pressed() -> void:
	pass # Replace with function body.

func _on_like_button_pressed() -> void:
	like_btn.disabled = true
	like_post()
	like_btn.disabled = false

