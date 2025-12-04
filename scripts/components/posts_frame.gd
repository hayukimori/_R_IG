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
	var posts_to_update = new_posts.filter(func(p): return p.id in current_post_ids)
	
	# Add new posts
	for post in posts_to_add:
		var object: PostComponentView = post_object.instantiate()
		_setup_post_object(object, post)
		post_list_vbox_container.add_child(object)
		post_list_vbox_container.move_child(object, 0)
		posts_list.append(object)
		
		object.connect("request_refresh", Callable(self, "_on_request_refresh"))

	for upd_post in posts_to_update:
		var post_obj = posts_list.filter(func(p): return p.post_id == upd_post.id)[0]

		if _has_post_changed(post_obj, upd_post):
			var x_index = posts_list.find(post_obj)
			var y_index = post_list_vbox_container.get_children().find(post_obj)
			print("[POSTS_FRAME] x_index from this updated post: ", x_index)
			posts_list.remove_at(x_index)
			post_list_vbox_container.remove_child(post_obj)
			post_obj.queue_free()

			var new_obj = post_object.instantiate()
			_setup_post_object(new_obj, upd_post)
			post_list_vbox_container.add_child(new_obj)
			post_list_vbox_container.move_child(new_obj, y_index)
			posts_list.insert(x_index, new_obj)
			new_obj.connect("request_refresh", Callable(self, "_on_request_refresh"))

	current_posts = new_posts



func _on_request_refresh() -> void:
	refresh_posts()


func _has_post_changed(object: PostComponentView, post: PostModel) -> bool:
	var content_changed = object.content != post.content
	var likes_changed = object.likesCount != post.likesCount
	var comments_changed = object.commentsCount != post.commentsCount
	var avatar_changed = object.avatarUrl != post.avatarUrl
	var display_name_changed = object.displayName != post.displayName
	var media_changed = object.media != post.media
	var updated_at_changed = object.updatedAt != post.updatedAt
	
	
	var has_changed = content_changed or \
					likes_changed or \
					comments_changed or \
					avatar_changed or \
					display_name_changed or \
					media_changed or \
					updated_at_changed
	
	return has_changed

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
		object.connect("request_refresh", Callable(self, "_on_request_refresh"))


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
	object.liked = item.liked


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
