extends RefCounted
class_name PostResult

var ok: bool = true
var reasons: Array[String] = []
var postId: String = ""

func _init(set_ok: bool = true, set_reasons: Array[String] = [], set_postId: String = "") -> void:
    ok = set_ok
    reasons = set_reasons
    postId = set_postId