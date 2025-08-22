extends Node

# Routes
var world_follows_route = Services.routes.ROUTE_WORLD_FOLLOWS
var world_unfollows_route = Services.routes.ROUTE_WORLD_UNFOLLOWS
var world_updates_route = Services.routes.ROUTE_WORLD_UPDATES

# Sync definitions
const DELTA_SYNC_INTERVAL = 15.0
const BULK_FETCH_INTERVAL = 1.0
const BULK_FETCH_LIMIT = 100

# State vars
var is_bulk_loading := true       # Back-filling
var is_syncing_deltas := false
var sync_anchor_time: String      # Initial anchor timer
var last_id_for_bulk_load: String = ""

# Processing Queues
var pending_connections := []
var pending_disconnections := []


func _ready():
	world_follows_route = Services.routes.ROUTE_WORLD_FOLLOWS
	world_unfollows_route = Services.routes.ROUTE_WORLD_UNFOLLOWS
	world_updates_route = Services.routes.ROUTE_WORLD_UPDATES

	# Gets server time
	sync_anchor_time = await Services.api.get_server_time()
	if AppConfig.DEBUG_MODE: print("[SYNC] Anchor time defined to: %s" % sync_anchor_time)
	
	# 2. Inicia os timers que rodarão em paralelo
	_setup_timers()


func _setup_timers():
	# Timer 1: Back-filling Timer
	var bulk_load_timer := Timer.new()
	bulk_load_timer.name = "BulkLoadTimer"
	bulk_load_timer.wait_time = BULK_FETCH_INTERVAL
	bulk_load_timer.autostart = true
	bulk_load_timer.one_shot = false
	bulk_load_timer.timeout.connect(_fetch_bulk_follows_page)
	add_child(bulk_load_timer)

	# Timer 2: Delta sync Timer
	var delta_sync_timer := Timer.new()
	delta_sync_timer.name = "DeltaSyncTimer"
	delta_sync_timer.wait_time = DELTA_SYNC_INTERVAL
	delta_sync_timer.autostart = true
	delta_sync_timer.one_shot = false
	delta_sync_timer.timeout.connect(_perform_delta_sync)
	add_child(delta_sync_timer)

	# Queue processsing Timers
	var pending_conn_timer := Timer.new()
	pending_conn_timer.name = "PendingConnectionsProcessor"
	pending_conn_timer.wait_time = 5.0; pending_conn_timer.autostart = true; pending_conn_timer.one_shot = false
	pending_conn_timer.timeout.connect(process_pending_connections)
	add_child(pending_conn_timer)

	var pending_disconn_timer := Timer.new()
	pending_disconn_timer.name = "PendingDisconnectionsProcessor"
	pending_disconn_timer.wait_time = 5.0; pending_disconn_timer.autostart = true; pending_disconn_timer.one_shot = false
	pending_disconn_timer.timeout.connect(process_pending_disconnections)
	add_child(pending_disconn_timer)


# Gets history
func _fetch_bulk_follows_page():
	if not is_bulk_loading:
		# Stops the timer when finalized
		get_node("BulkLoadTimer").stop()
		return

	var payload := {"limit": BULK_FETCH_LIMIT}
	if last_id_for_bulk_load != "":
		payload["lastId"] = last_id_for_bulk_load

	var result: Dictionary = await Services.api.auth_fetch(
		world_follows_route.url(),
		world_follows_route.method,
		payload, 
		["Content-Type: application/json"]
	)
	if result.get("response_code") == 401:
		Services.scene_service.logout()

	if result.has("result_array") and result["is_json"]:
		var follows = result["result_array"]
		if follows is Array and not follows.is_empty():
			if AppConfig.DEBUG_MODE: print("[BULK LOAD] Got %d history follows." % follows.size())
			for follow in follows:
				_handle_follow_connection(follow)
			last_id_for_bulk_load = follows[-1].get("id", last_id_for_bulk_load)
		else:
			is_bulk_loading = false
			print("[SYNC] back-filling concluded.")
	else:
		push_warning("[X] Fail getting history")


# Longer loop
func _perform_delta_sync():
	if is_syncing_deltas: return
	is_syncing_deltas = true

	if AppConfig.DEBUG_MODE: print("[DELTA SYNC] Getting updates since %s" % sync_anchor_time)
	
	# Looks for unfollows and updates
	
	await _fetch_world_updates(sync_anchor_time)
	await _fetch_world_unfollows(sync_anchor_time)
	
	
	is_syncing_deltas = false

# World updates
func _fetch_world_updates(since_time: String):
	var payload = {"since": since_time}
	var result = await Services.api.auth_fetch(
		world_updates_route.url(),
		world_updates_route.method, 
		payload, 
		["Content-Type: application/json"]
	)

	if result.get("response_code") == 401:Services.scene_service.logout()

	if result.has("result_array") and result["is_json"]:
		var updates = result.get('result_array')
		if updates is Array and not updates.is_empty():
			if AppConfig.DEBUG_MODE: print("[DELTA SYNC] %d follows new/activated." % updates.size())
			for follow in updates:
				_handle_follow_connection(follow)

# World Unfollows
func _fetch_world_unfollows(since_time: String):
	var payload := {"since": since_time}
	var result = await Services.api.auth_fetch(
		world_unfollows_route.url(),
		world_unfollows_route.method, 
		payload, 
		["Content-Type: application/json"]
	)
	if result.get("response_code") == 401:Services.scene_service.logout()
	
	if result.has("result_array") and result["is_json"]:
		var unfollows = result.get('result_array')
		if unfollows is Array and not unfollows.is_empty():
			if AppConfig.DEBUG_MODE: print("[DELTA SYNC] %d unfollows." % unfollows.size())
			for unfollow in unfollows:
				_handle_unfollow_connection(unfollow)

# === Processors ==

func _handle_follow_connection(follow: Dictionary):
	var follower_id = follow.get("follower_id", "")
	var following_id = follow.get("following_id", "")
	var conn_id = follow.get("id", "")
	var active = follow.get("active", true)

	if Services.cluster_service.cubes_id.has(follower_id) and Services.cluster_service.cubes_id.has(following_id):
		_connect_cubes(follower_id, following_id, active, conn_id)
	else:
		if not pending_connections.any(func(c): return c.id == conn_id):
			pending_connections.append(follow)

func _handle_unfollow_connection(unfollow: Dictionary):
	var target_id = unfollow.get('id', '')
	if Services.cluster_service.active_connections.has(target_id):
		_disconnect_cubes(target_id)
	else:
		if not pending_disconnections.any(func(d): return d.id == target_id):
			pending_disconnections.append(unfollow)

func process_pending_connections():
	if pending_connections.is_empty(): return
	var still_pending := []
	for conn in pending_connections:
		if Services.cluster_service.cubes_id.has(conn.follower_id) and Services.cluster_service.cubes_id.has(conn.following_id):
			_connect_cubes(conn.follower_id, conn.following_id, conn.active, conn.id)
		else:
			still_pending.append(conn)
	pending_connections = still_pending

func process_pending_disconnections():
	if pending_disconnections.is_empty(): return
	var still_pending := []
	for conn in pending_disconnections:
		if Services.cluster_service.active_connections.has(conn.id):
			_disconnect_cubes(conn.id)
		else:
			still_pending.append(conn)
	pending_disconnections = still_pending

func _connect_cubes(fid, tid, active, conn_id):
	Services.cluster_service.create_connection(fid, tid, active, conn_id)

func _disconnect_cubes(connection_id):
	Services.cluster_service.deactivate_connection(connection_id)
