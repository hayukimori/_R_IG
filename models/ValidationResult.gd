extends RefCounted
class_name ValidationResult

var error: bool = false
var reasons: Array[String] = []

func _init(v_error: bool = false, v_reasons: Array[String] = []) -> void:
    error = v_error
    reasons = v_reasons
    