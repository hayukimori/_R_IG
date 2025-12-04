extends Control
class_name PostComponentView

signal request_refresh()

@export var post_id: String;
@export var authorId: String;
@export var content: String;
@export var createdAt: String;
@export var updatedAt: String;
@export var avatarUrl: String;
@export var displayName: String;
@export var username: String;
@export var likesCount: int;
@export var commentsCount: int;
@export var media: Array = [];
@export var liked: bool;
@export var has_media: bool = false


@onready var content_label: Label = $MainContentLabel
@onready var pfp_texture_rect: TextureRectRounded = $ProfilePictureTextureRect
@onready var display_name_label: Label = $DisplayNameLabel
@onready var username_label: Label = $UsernameLabel
@onready var postmedia_tr = $MainContentLabel/PostMediaTextureRectRounded
@onready var postmedia_vd = $PostMediaVSP

@onready var like_count_label: Label = $InteractionsContainer/LikeCountLabel
@onready var comment_count_label: Label = $InteractionsContainer/CommentCountLabel
@onready var like_btn: Button = $InteractionsContainer/LikeButton
@onready var comment_btn: Button = $InteractionsContainer/CommentButton


var like_texture = preload("res://assets/textures/icons/google_icons/favorite_24dp.png")
var liked_texture = preload("res://assets/textures/icons/google_icons/favotrite_fill_24dp.png")


const DEFAULT_IMAGE_SIZE = Vector2(356.0, 163.0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await get_tree().process_frame
	load_data()

	await get_tree().process_frame
	var new_size = calc_size()
	change_current_size(new_size)


func load_data() -> void:
	display_name_label.text = displayName
	content_label.text = content
	username_label.text = "@%s" % username

	if has_media:
		load_media()

	comment_count_label.text = str(commentsCount)
	like_count_label.text = str(likesCount)

	
	var user_texture = await ImageLib.get_image_or_default(avatarUrl)
	pfp_texture_rect.texture = user_texture

	update_like()
	

func load_media() -> void:
	var raw_url = media[0].get("url")
	var media_type = media[0].get("type")
	var media_url = Services.routes.get_media_url(raw_url)

	print("=============================")
	print("[POST] raw_url: ", raw_url)
	print("[POST] media_url: ", media_url)
	print("[POST] media_type: ", media_type)

	if media_type == "image":
		print("This media is image")
		var media_texture = await ImageLib.get_image_or_default(media_url)
		postmedia_tr.texture = media_texture

	elif media_type == "video":
		print("This media is video.")
		var stream: VideoStreamTheora = VideoStreamTheora.new()
		var file: String = await Services.videolib.get_video_or_default(media_url)

		stream.file = file
		postmedia_vd.stream = stream

		print("####################################")
		print_debug(postmedia_vd.stream.file)
		print("####################################")

		
		postmedia_vd.stream = stream
		await get_tree().process_frame
		postmedia_vd.size = DEFAULT_IMAGE_SIZE
		postmedia_vd.expand = true
		postmedia_vd.play()
	else:
		print("Not an image or video")
	


func calc_size() -> int:
	var spacer = 162

	if has_media:
		postmedia_tr.size = DEFAULT_IMAGE_SIZE
		postmedia_vd.size = DEFAULT_IMAGE_SIZE
		postmedia_vd.custom_minimum_size = DEFAULT_IMAGE_SIZE
	else:
		postmedia_tr.size = Vector2.ZERO
		spacer = 128

	return content_label.size.y + postmedia_tr.size.y + spacer
	

func change_current_size(new_size: float) -> void:
	custom_minimum_size.y = new_size

func update_like() -> void:
	like_btn.icon = liked_texture.duplicate() if liked else like_texture.duplicate()

func _on_like_button_pressed() -> void:
	if liked:
		liked = false
		update_like()

		var response = await Services.posts_service.unlike(post_id)
		if !response.ok:
			liked = true
	else:
		liked = true
		update_like()

		var response = await Services.posts_service.new_like(post_id)
		if !response.ok:
			liked = false
		
	update_like()
		
		


	await get_tree().create_timer(.5).timeout
	request_refresh.emit()
