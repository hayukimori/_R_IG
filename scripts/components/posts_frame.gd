extends Control

var post_object = preload("res://screens/components/post_component_model.tscn")

@onready var post_list_vbox_container = $PostsScrollContainer/PostsListVBox
@onready var teditor: TextEdit = $MainPostControl/TEditor
@onready var submit_btn: Button = $MainPostControl/TEditor/Submit
@onready var attach_file_btn: Button = $MainPostControl/TEditor/Panel/AttachFileButton
@onready var selected_file_label: Label = $MainPostControl/TEditor/Panel/SelectedFileLabel
@onready var file_dialog: FileDialog = $Files/FileDialog

var current_img_path: String
var current_file: FileAccess
var refresh_timer: Timer
var current_posts: Array[PostModel] = []
var posts_list: Array = []


func _ready() -> void:
	await get_tree().process_frame
	load_posts()
	setup_refresh_timer()


func setup_refresh_timer() -> void:
	refresh_timer = Timer.new()
	add_child(refresh_timer)
	refresh_timer.wait_time = 30.0
	refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	refresh_timer.start()


func _on_refresh_timer_timeout() -> void:
	refresh_posts()


func refresh_posts() -> void:
	var new_posts: Array[PostModel] = await Services.posts_service.load_posts()
	
	var new_post_ids = new_posts.map(func(p): return p.id)
	var current_post_ids = current_posts.map(func(p): return p.id)
	
	var posts_to_add = new_posts.filter(func(p): return p.id not in current_post_ids)
	
	for post in posts_to_add:
		var object: PostComponentView = post_object.instantiate()
		_setup_post_object(object, post)
		post_list_vbox_container.add_child(object)
		post_list_vbox_container.move_child(object, 0)

		posts_list.append(object)
	
	current_posts = new_posts


func reload_posts() -> void:
	for item in posts_list:
		post_list_vbox_container.remove_child(item)

	current_posts = []
	posts_list = []

	load_posts()

func load_posts() -> void:
	current_posts = await Services.posts_service.load_posts()
	
	for item in current_posts:
		var object: PostComponentView = post_object.instantiate()
		_setup_post_object(object, item)
		post_list_vbox_container.add_child(object)
	
		posts_list.append(object)


func _setup_post_object(object: PostComponentView, item: PostModel) -> void:
	object.post_id = item.id
	object.authorId = item.authorId
	object.content = item.content
	object.createdAt = item.createdAt
	object.updatedAt = item.updatedAt
	object.avatarUrl = item.avatarUrl
	object.displayName = item.displayName
	object.likesCount = item.likesCount
	object.commentsCount = item.commentsCount
	object.has_media = item.has_media
	object.media = item.media
	object.username = item.username


func send_post() -> void:
	teditor.editable = false
	submit_btn.disabled = true
	attach_file_btn.disabled = true

	var current_text = teditor.text
	var raw_post: PostResult = await Services.posts_service.new_post(current_text)

	if current_img_path:
		var img_post: ImgPostResult = await Services.posts_service.upload_photo(raw_post, current_img_path)
		print(img_post.ok)

	refresh_posts()

	teditor.editable = true
	attach_file_btn.disabled = false
	submit_btn.disabled = false

	


func _on_submit_pressed() -> void:
	send_post()


func _on_file_selected(path: String) -> void:
	selected_file_label.text = path
	current_img_path = path


func _on_attach_file_button_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = [
		"*.jpeg ; JPEG Image",
		"*.jpg ; JPG Image",
		"*.png ; PNG Image",
		"*.webp ; WEBP Image"
	]

	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	file_dialog.popup_centered()


func _on_reload_button_pressed() -> void:
	reload_posts()
