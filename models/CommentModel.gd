extends RefCounted
class_name CommentModel

var id: String
var postId: String
var authorId: String
var content: String
var createdAt: String
var updatedAt: String


var post: PostModel
var author: UserProfile

func _init(c_id: String = "", c_post_id: String = "", c_author_id: String = "", c_content: String = "", c_created_at: String = "", c_updated_at: String = "", c_author: UserProfile = null, c_post: PostModel = null) -> void:
    id = c_id
    postId = c_post_id
    authorId = c_author_id
    content = c_content
    createdAt = c_created_at
    updatedAt = c_updated_at

    # Optional
    post = c_post
    author = c_author


func self_validate_comment() -> ValidationResult:
    var vr = ValidationResult.new()

    var valid_content = ValidationRules.validate_post_content(self.content);
    var valid_authorId = ValidationRules.validate_object_id(self.authorId);
    var valid_postId = ValidationRules.validate_object_id(self.postId);


    if !valid_authorId:
        vr.error = true
        vr.reasons.append("Ivalid authorId")

    if !valid_content:
        vr.error = true
        vr.reasons.append("Invalid contents")
    
    if !valid_postId:
        vr.error = true
        vr.reasons.append("Invalid postId")
    
    return vr