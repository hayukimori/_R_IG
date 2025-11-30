extends RefCounted
class_name PostModel


var id: String;
var authorId: String;
var content: String;
var createdAt: String;
var updatedAt: String;


func _init(post_id: String, post_author_id: String, post_content: String, post_created_at: String, post_updated_at: String) -> void:
	id = post_id
	authorId = post_author_id
	content = post_content
	createdAt = post_created_at
	updatedAt = post_updated_at


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
