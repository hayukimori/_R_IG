extends Node

var world_follows_endpoint = Routes.get_route(Routes.ENDPOINT_WORLD_FOLLOWS)
const FETCH_INTERVAL_SECONDS = 5
const FETCH_LIMIT = 100

var last_id: String = ""
var is_fetching := false

var pending_connections := []

func _ready():
	_start_world_follow_timer()

func _start_world_follow_timer():
	var timer := Timer.new()
	timer.name = "FollowPollTimer"
	timer.wait_time = FETCH_INTERVAL_SECONDS
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_fetch_world_follows)
	add_child(timer)

func _fetch_world_follows():
	if is_fetching:
		return
	is_fetching = true

	var payload := {"limit": FETCH_LIMIT}
	if last_id != "":
		payload["lastId"] = last_id

	var result: Dictionary = await GeneralTools.protected_request(
		world_follows_endpoint, 
		payload, 
		HTTPClient.METHOD_POST
	)

	if result.has("result_array") and result["is_json"]:
		var follows = result["result_array"][0]

		if follows is Array and follows.size() > 0:
			if AppConfig.DEBUG_MODE: print("[!!] New Connections received: %d" % follows.size())

			for follow in follows:
				_handle_follow_connection(follow)

			last_id = follows[-1].get("id", last_id)
		else:
			if AppConfig.DEBUG_MODE: print("[!!] No new connections..")
	else:
		push_warning("[X] Fail getting world follow data")

	is_fetching = false


func _handle_follow_connection(follow: Dictionary) -> void:
	var follower_id = follow.get("follower_id", "")
	var following_id = follow.get("following_id", "")
	var active = follow.get("active", true)

	var gcluster = GlobalCluster.cubes_id

	if gcluster.has(follower_id) and gcluster.has(following_id):
		_connect_cubes(follower_id, following_id, active)

	else:
		pending_connections.append({
			"follower_id": follower_id,
			"following_id": following_id,
			"active": active
		})

func process_pending_connections():
	var still_pending := []

	for conn in pending_connections:
		var fid = conn.follower_id
		var tid = conn.following_id
		var gcluster = GlobalCluster.cubes_id

		if gcluster.has(fid) and gcluster.has(tid):
			_connect_cubes(fid, tid, conn.active)
		else:
			still_pending.append(conn)

	pending_connections = still_pending


func _connect_cubes(fid, tid, active):
	GlobalCluster.create_connection(fid, tid, active)
