extends Node3D

@export var grid_size := Vector2i(15, 15)
@export var spacing := 1.5

@export_group("Animation")
@export var noise_strength := 2.0
@export var noise_speed := 0.2
@export var noise_scale := 0.2

@export var noise: FastNoiseLite

@export_group("Visual")
@export var cube_color := Color(0.3, 0.3, 0.3)

# -- Internal Vars --
var cubes: Array[MeshInstance3D]
var time := 0.0


func _ready() -> void:
	if not noise:
		push_warning("Noise not configured. Creating new default FastNoiseLite")
		noise = FastNoiseLite.new()

		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.seed = randi()
		noise.frequency = 0.05

		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 4
		noise.fractal_lacunarity = 2.0
		noise.fractal_gain = 0.5

	var cube_mesh = BoxMesh.new()
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = cube_color
	cube_material.metallic = 0.8
	cube_material.roughness = 0.2

	for i in range(grid_size.x):
		for j in range(grid_size.y):
			var cube_instance = MeshInstance3D.new()
			cube_instance.mesh = cube_mesh
			cube_instance.material_override = cube_material

			var pos_x = (i - grid_size.x / 2.0) * spacing
			var pos_y = (j - grid_size.y / 2.0) * spacing

			cube_instance.position = Vector3(pos_x, pos_y, 0)

			add_child(cube_instance)
			cubes.append(cube_instance)


func _process(delta: float) -> void:
	time += delta * noise_speed
	

	for cube in cubes:
		var x = cube.position.x
		var y = cube.position.y

		var noise_value = noise.get_noise_3d(x, y, time)
		cube.position.z = noise_value * noise_strength



