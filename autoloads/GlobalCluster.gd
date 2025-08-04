extends Node

var cubes_id: Dictionary = {}
var active_connections: Dictionary = {}
var cluster_3d: Node3D

func add_cube(cube: UserCube) -> void:
	cubes_id[cube.user_id] = cube

func create_connection(fid: String, tid: String, active: bool, conn_id: String) -> void:
	# c
	if active_connections.has(conn_id):
		var existing_connection = active_connections[conn_id]
		
		if existing_connection.active != active:
			existing_connection.mesh.visible = active
			existing_connection.active = active # Updates state
			if AppConfig.DEBUG_MODE: print("[CONNECTION] Connection '%s' updated to active=%s" % [conn_id, active])
		
		return

	if not cubes_id.has(fid) or not cubes_id.has(tid):
		return

	var from_cube = cubes_id[fid]
	var to_cube = cubes_id[tid]
	
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from_cube.global_transform.origin)
	mesh.surface_add_vertex(to_cube.global_transform.origin)
	mesh.surface_end()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.visible = active # Initial
	mesh_instance.name = "Conn_%s" % conn_id

	if cluster_3d != null:
		cluster_3d.add_child(mesh_instance)
	else:
		add_child(mesh_instance)
	
	active_connections[conn_id] = {
		"mesh": mesh_instance, 
		"from": from_cube, 
		"to": to_cube, 
		"active": active
	}
	if AppConfig.DEBUG_MODE: print("[CONNECTION] Connection '%s' created. active=%s" % [conn_id, active])


func deactivate_connection(connection_id: String) -> void:
	if active_connections.has(connection_id):
		var conn = active_connections[connection_id]
		conn.mesh.hide()
		conn.active = false
