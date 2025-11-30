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


func getComments(post_id: String) -> Array[CommentModel]:
    return []

func getLikes(post_id: String) -> Array[LikeModel]:
    return []

func sendComment(post_id: String, comment: CommentModel) -> void:
    pass
