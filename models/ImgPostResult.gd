extends RefCounted
class_name ImgPostResult

var ok: bool = true
var status: String = ""
var reasons: Array = []


func _init(ipr_ok: bool = true, ipr_status: String = "", ipr_reasons: Array = []) -> void:
    ok = ipr_ok
    status = ipr_status
    reasons = ipr_reasons
