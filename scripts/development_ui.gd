extends Control
class_name DevelopmentUI

@onready var cubes_count_label: Label = $CubesCountLabel
@onready var cube_json_content_label: Label = $CubeJsonContentLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func update_cubes_count(new_value: int) -> void:
	cubes_count_label.text = "current cubes count: %d" % new_value


func update_current_json_content(new_value: Dictionary) -> void:
	cube_json_content_label.text = str(new_value)