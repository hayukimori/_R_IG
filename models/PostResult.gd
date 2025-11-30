extends RefCounted
class_name PostResult

var ok: bool = true
var reasons: Array[String] = []

func _init(set_ok: bool = true, set_reasons: Array[String] = []) -> void:
    ok = set_ok
    reasons = set_reasons