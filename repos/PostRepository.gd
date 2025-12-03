class_name PostRepository
extends RefCounted

func getPosts() -> Dictionary:
	
	var route = Services.routes.ROUTE_GET_POSTS;
	var url = route.url()
	
	var posts = await Services.api.auth_req_get(url)

	print("[PostRepository] Requesting: ", url)

	return posts

func newPost(post_data: PostModel) -> Dictionary:
	var route = Services.routes.ROUTE_POST;
	var url = route.url()

	var payload = {
		"authorId": Services.user_service.user_id,
		"content": post_data.content
	}
	
	var post_result = await Services.api.auth_req_post(url, payload)
	return post_result


func getComments(post_id: String) -> Dictionary:
	var route = Services.routes.ROUTE_GET_COMMENTS
	var url = route.url({"postId": post_id})
	
	var result = await Services.api.auth_req_get(url)
	return result


func getLikes(post_id: String) -> Dictionary:
	var route = Services.routes.ROUTE_GET_LIKES
	var url = route.url({"postId": post_id})
	
	var result = await Services.api.auth_req_get(url)
	return result


func sendComment(comment: CommentModel) -> Dictionary:
	var route = Services.routes.ROUTE_COMMENT_POST
	var payload = {"content": comment.content}
	var url = route.url({"postId": comment.postId})

	var rest = await Services.api.auth_req_post(url, payload)

	return rest

func sendLike(model: LikeModel) -> Dictionary:
	var route = Services.route.ROUTE_LIKE_POST
	var payload = { "userId": model.userId, "postId": model.post_id}
	var url = route.url({"postId": model.postId})

	var rest = await Services.api.auth_req_post(url, payload)

	return rest
