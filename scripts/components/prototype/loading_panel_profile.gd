extends Panel


@onready var spinning_object_tr: TextureRect = $SpinningObjectTexture


func _process(delta: float) -> void:
	spinning_object_tr.rotation += 5 * delta