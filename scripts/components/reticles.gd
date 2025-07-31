extends Node3D

@onready var on_screen_rtc: TextureRect = $OnScreenRTC
@onready var off_screen_rtc: TextureRect = $OffscreenRTC

var camera: Camera3D
var rtc_offset: Vector2 = Vector2(12, 12)
var border_offset: Vector2 = Vector2(12, 12)
var viewport_center: Vector2
var max_rtc_position

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	viewport_center = Vector2(get_viewport().size) / 2.0
	max_rtc_position = viewport_center - border_offset

func _process(_delta: float) -> void:
	if camera.is_position_in_frustum(global_position):
		on_screen_rtc.show()
		off_screen_rtc.hide()

		var rtc_position = camera.unproject_position(global_position)
		on_screen_rtc.set_global_position(rtc_position - rtc_offset)

	else:
		on_screen_rtc.hide()
		off_screen_rtc.show()

		var local_to_camera: Vector3 = camera.to_local(global_position)
		var rtc_position: Vector2 = Vector2(local_to_camera.x, -local_to_camera.y)

		if rtc_position.abs().aspect() > viewport_center.aspect():
			rtc_position *= max_rtc_position.x / abs(rtc_position.x)
		else:
			rtc_position *= max_rtc_position.y / abs(rtc_position.y)
		
		off_screen_rtc.set_global_position(viewport_center + rtc_position - rtc_offset)
		var angle = Vector2.UP.angle_to(rtc_position)
		off_screen_rtc.rotation = angle