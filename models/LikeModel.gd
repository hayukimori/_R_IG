class_name LikeModel
extends RefCounted

var postId: String
var userId: String

func _init(l_postId: String = "", l_userId: String = "") -> void:
    postId = l_postId
    userId = l_userId


func self_validate_like() -> ValidationResult:
    var vr = ValidationResult.new()

    var valid_userId = ValidationRules.validate_object_id(self.userId);
    var valid_postId = ValidationRules.validate_object_id(self.postId);


    if !valid_userId:
        vr.error = true
        vr.reasons.append("Ivalid userId")
    
    if !valid_postId:
        vr.error = true
        vr.reasons.append("Invalid postId")
    
    return vr
