extends RefCounted
class_name PostService

var loaded_posts: Array = []
var node: Node


func _init(new_node: Node) -> void:
	node = new_node
	print("[PostService] PostService started.")


func load_posts() -> Array[PostModel]:
	var posts_raw: Dictionary = await Repositories.post_repository.getPosts()
	var response_code = posts_raw.get("response_code")

	if response_code not in range (200, 299): return []

	var post_list: Array[PostModel] = []

	
	#model.load_dict(posts_raw.get("parsed_json"))
	var posts =  posts_raw.get("parsed_json")
	var posts2 = posts.posts


	for item in posts2:
		print_rich(item)

		var model = PostModel.new()
		model.load_dict(item)
		post_list.append(model)

	return post_list

	


func new_post(content: String) -> PostResult:
	var main_result: PostResult = PostResult.new()
	main_result.ok = true

	var author_id = Services.user_service.user_id

	var model = generate_post_model_send(author_id, content)
	var validation = model.self_validate_post()

	if validation.error:
		for x in validation.reasons:
			main_result.ok = false
			main_result.reasons.append(x)
		return main_result # Early return if error
	
	
	var req_result = await Repositories.post_repository.newPost(model)

	var response_code: int = req_result.get("response_code")

	if response_code not in range(200, 299):
		req_result.get("response_code")
		main_result.reasons.append("Post error. Unexpected Response: " + str(response_code))
	

	return main_result



func new_comment(post_id: String, content: String) -> PostResult:
	var main_result: PostResult = PostResult.new()
	main_result.ok = true

	var author_id = Services.user_service.user_id

	var model = generate_comment_model_send(author_id, content, post_id)
	var validation = model.self_validate_comment()

	if validation.error:
		for x in validation.reasons:
			main_result.ok = false
			main_result.reasons.append(x)
		return main_result # Early return if error
	
	
	var req_result = await Repositories.post_repository.sendComment(model)
	var response_code: int = req_result.get("response_code")

	if response_code not in range(200, 299):
		req_result.get("response_code")
		main_result.reasons.append("Post error. Unexpected Response: " + str(response_code))
	

	return main_result


func new_like(post_id: String) -> PostResult:
	var main_result: PostResult = PostResult.new()
	main_result.ok = true

	var author_id = Services.user_service.user_id

	var model = generate_like_model_send(author_id, post_id)
	var validation = model.self_validate_like()

	if validation.error:
		for x in validation.reasons:
			main_result.ok = false
			main_result.reasons.append(x)
		return main_result # Early return if error
	
	
	var req_result = await Repositories.post_repository.sendLike(model)
	var response_code: int = req_result.get("response_code")

	if response_code not in range(200, 299):
		req_result.get("response_code")
		main_result.reasons.append("Post error. Unexpected Response: " + str(response_code))
	

	return main_result


func generate_post_model_send(author_id: String, content: String, _has_media: bool = false) -> PostModel:
	var temp_post = PostModel.new()

	temp_post.authorId = author_id
	temp_post.content = content

	return temp_post

func generate_comment_model_send(author_id: String, post_id: String,  content: String) -> CommentModel:
	var temp_comment = CommentModel.new()

	temp_comment.authorId = author_id
	temp_comment.content = content
	temp_comment.postId = post_id

	return temp_comment

func generate_like_model_send(author_id: String, post_id: String) -> LikeModel:
	var temp_like = LikeModel.new(post_id, author_id)
	return temp_like
