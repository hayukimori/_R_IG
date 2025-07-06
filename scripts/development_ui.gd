extends Control
class_name DevelopmentUI

@onready var cubes_count_label: Label = $CounUI/CubesCountLabel
@onready var user_id_label: Label = $CounUI/UserIDLabel
@onready var cube_info_label: RichTextLabel = $CubeInfo/CubeInfoLabel
@onready var cube_json_content_label: Label = $CubeJsonContentLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func update_cubes_count(new_value: int) -> void:
	cubes_count_label.text = "CUBES: %d" % new_value


func update_current_json_content(new_value: Dictionary) -> void:
	cube_json_content_label.text = str(new_value)

	update_current_cube_info(
		new_value.id,
		new_value.owner_id,
		new_value.position_x,
		new_value.position_y,
		new_value.position_z
	)

func update_current_cube_info(cube_id: String, owner_id: String, pos_x: float, pos_y: float, pos_z: float) -> void:
	var text_content = []

	var cube_id_text = "[b]id: %s[/b]\n" % cube_id
	var owner_id_text = "owner_id: %s\n" % owner_id
	var position_text = "\nPosition\n"
	var pos_x_text = "[color=red]x[/color] %f\n" % pos_x
	var pos_y_text = "[color=green]y[/color] %f\n" % pos_y
	var pos_z_text = "[color=blue]z[/color] %f\n" % pos_z

	text_content.append(cube_id_text)
	text_content.append(owner_id_text)
	text_content.append(position_text)
	text_content.append(pos_x_text)
	text_content.append(pos_y_text)
	text_content.append(pos_z_text)

	var final_text = "".join(text_content)
	cube_info_label.text = final_text
