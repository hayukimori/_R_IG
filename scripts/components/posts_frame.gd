extends Control

var post_object = preload("res://screens/components/post_component_model.tscn")

@onready var post_list_vbox_container = $PostsScrollContainer/PostsListVBox
@onready var teditor: TextEdit = $MainPostControl/TEditor
@onready var submit_btn: Button = $MainPostControl/TEditor/Submit

func _ready() -> void:
	await get_tree().process_frame

	load_posts()


func load_posts() -> void:
	var posts: Array[PostModel] = await Services.posts_service.load_posts()
	
	for item in posts:
		var object = post_object.instantiate()

		object.post_id = item.id
		object.authorId = item.authorId
		object.content = item.content
		object.createdAt = item.createdAt
		object.updatedAt = item.updatedAt
		object.avatarUrl = item.avatarUrl
		object.displayName = item.displayName
		object.likesCount = item.likesCount
		object.commentsCount = item.commentsCount

		post_list_vbox_container.add_child(object)



func send_post() -> void:
	teditor.editable = false
	submit_btn.disabled = true

	var current_text = teditor.text
	await Services.posts_service.new_post(current_text)

	teditor.editable = true
	submit_btn.disabled = false

func _on_submit_pressed() -> void:
	send_post()
