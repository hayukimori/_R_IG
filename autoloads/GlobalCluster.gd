extends Node

var cubes_id: Dictionary = {}
var active_connections: Dictionary = {}
var cluster_3d: Node3D

func add_cube(cube: UserCube) -> void:
	cubes_id[cube.user_id] = cube

func create_connection(fid: String, tid: String, active: bool) -> void:
	var from_cube = cubes_id[fid]
	var to_cube = cubes_id[tid]
	var key = "%s_%s" % [fid, tid]

	if active_connections.has(key):
		return
	
	var mesh := ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	mesh.surface_add_vertex(from_cube.global_transform.origin)
	mesh.surface_add_vertex(to_cube.global_transform.origin)

	mesh.surface_end()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh

	if !active:
		mesh_instance.hide()


	if cluster_3d != null:
		cluster_3d.add_child(mesh_instance)
		active_connections[key] = mesh_instance
	else:
		add_child(mesh_instance)
