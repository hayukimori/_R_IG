#Copyright © 2022 Marc Nahr: https://github.com/MarcPhi/godot-free-look-camera
# Modded by hayukimori in july 2025 (reason: Camera Raycast by mouse pointer position)
extends Camera3D

@export_range(0, 10, 0.01) var sensitivity : float = 3
@export_range(0, 1000, 0.1) var default_velocity : float = 25
@export_range(0, 10, 0.01) var speed_scale : float = 1.17
@export_range(1, 100, 0.1) var boost_speed_multiplier : float = 3.0
@export var max_speed : float = 1000
@export var min_speed : float = 0.2


@export_group("Mouse Raycast")
@export var ray_length = 100

@onready var _velocity = default_velocity



func _input(event):
	if not current:
		return
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation.y -= event.relative.x / 1000 * sensitivity
			rotation.x -= event.relative.y / 1000 * sensitivity
			rotation.x = clamp(rotation.x, PI/-2, PI/2)
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: # Raycast Mod
				if event.pressed:
					var mouse_pos = get_viewport().get_mouse_position()
					var from = project_ray_origin(mouse_pos)
					var to = from + project_ray_normal(mouse_pos) * ray_length
					var space = get_world_3d().direct_space_state
					var ray_query = PhysicsRayQueryParameters3D.new()
					ray_query.from = from
					ray_query.to = to
					ray_query.collide_with_areas = true
					ray_query.collide_with_bodies = true
					var result = space.intersect_ray(ray_query)
					
					if result and result["collider"].is_in_group("cubes"):
						var cube: UserCube = result["collider"]
						cube.on_clicked()

			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # increase fly velocity
				_velocity = clamp(_velocity * speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_WHEEL_DOWN: # decrease fly velocity
				_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)

func _process(delta):
	if not current:
		return
		
	var direction = Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)), 
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	
	if Input.is_physical_key_pressed(KEY_SHIFT): # boost
		translate(direction * _velocity * delta * boost_speed_multiplier)
	else:
		translate(direction * _velocity * delta)
