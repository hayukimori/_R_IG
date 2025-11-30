extends RefCounted
class_name PostModel


var id: String;
var authorId: String;
var content: String;
var createdAt: String;
var updatedAt: String;
var avatarUrl: String;
var displayName: String;
var likesCount: int;
var commentsCount: int;

var author: UserProfile

func _init(
	post_id: String = "",
	post_author_id: String = "",
	post_content: String = "",
	post_created_at: String ="",
	post_updated_at: String = "",
	post_avatar_url: String = "",
	post_likes_count: int = 0,
	post_comments_count: int = 0
	) -> void:

	id = post_id
	authorId = post_author_id
	content = post_content
	createdAt = post_created_at
	updatedAt = post_updated_at
	avatarUrl = post_avatar_url
	likesCount = post_likes_count
	commentsCount = post_comments_count
	

func load_dict(dict: Dictionary):
	id = dict["id"]
	authorId = dict["authorId"]
	content = dict["content"]
	createdAt = dict["createdAt"]
	updatedAt = dict["updatedAt"]
	
	avatarUrl = dict["avatarUrl"]
	displayName = dict["displayName"]
	
	likesCount = dict["likesCount"]
	commentsCount = dict["commentsCount"]
	


func self_validate_post() -> ValidationResult:
	var vr = ValidationResult.new()

	var valid_content = ValidationRules.validate_post_content(self.content);
	var valid_authorId = ValidationRules.validate_object_id(self.authorId);

	if !valid_content:
		vr.error = true
		vr.reasons.append("Invalid contents")
	
	if !valid_authorId:
		vr.error = true
		vr.reasons.append("Ivalid authorId")

	return vr
