extends RefCounted
class_name PostService

var loaded_posts: Array = []
var node: Node


func _init(new_node: Node) -> void:
	node = new_node
	print("[PostService] PostService started.")

func post(content: String) -> PostResult:
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

	if response_code != 200 or response_code != 201:
		req_result.get("response_code")
		main_result.reasons.append("Post error. Unexpected Response: " + str(response_code))
	

	return main_result


func generate_post_model_send(author_id: String, content: String, _has_media: bool = false):
	var temp_post = PostModel.new(
		"", 
		author_id, 
		content, 
		"", ""
	)

	return temp_post
