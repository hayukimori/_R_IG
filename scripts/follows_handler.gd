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

	var result: Dictionary = await protected_request(world_follows_endpoint, payload, HTTPClient.METHOD_POST)

	if result.has("result_array") and result["is_json"]:
		var follows = result["result_array"][0]

		if follows is Array and follows.size() > 0:
			print("[!!] New Connections received: %d" % follows.size())

			for follow in follows:
				_handle_follow_connection(follow)

			last_id = follows[-1].get("id", last_id)
		else:
			print("[!!] No new connections..")
	else:
		push_warning("[X] Fail getting world follow data")

	is_fetching = false


func _handle_follow_connection(follow: Dictionary) -> void:
	var follower_id = follow.get("follower_id", "")
	var following_id = follow.get("following_id", "")
	var active = follow.get("active", true)

	print("Relation: %s -> %s | Active: %s" % [follower_id, following_id, str(active)])

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

func protected_request(url: String, payload: Dictionary, method: HTTPClient.Method, custom_headers: Array = []) -> Dictionary:
	if !GeneralTools.Validations.new().validate_url(url):
		push_warning("Invalid url: ", url)
		return {}
	
	print("Requesting url: ", url)

	var http_request := HTTPRequest.new()
	add_child(http_request)

	var headers = []

	if custom_headers == []:
		headers = [
			"Authorization: Bearer %s" %CurrentUserSession.login_token,
			"Content-Type: application/json",
			"Accept: application/json"
		]
	else:
		headers = custom_headers

	
	var error = http_request.request(url, headers, method, JSON.stringify(payload))
	if error != OK:
		push_error("Failed to make request.")
		return {}

	var result = await http_request.request_completed

	var result_code = result[0]
	var response_code = result[1]
	var _headers = result[2]
	var body = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		push_error("Couldn't complete request. Result: %d" % result_code)
		return {}
	
	var body_text: String = body.get_string_from_utf8()
	var parsed_json := {}
	var result_array := []
	var is_json := true

	if body_text != "":
		var parse_result = JSON.parse_string(body_text)
		if parse_result != null:
			if typeof(parsed_json) == TYPE_ARRAY:
				result_array.assign(parse_result)

			elif typeof(parsed_json) == TYPE_DICTIONARY:
				result_array.append(parse_result)
		else:
			is_json = false
	
	match response_code:
		200, 201: print("Profile updated successfuly");
		400: push_warning("Bad request. %s" % JSON.stringify(parsed_json) if is_json else "")
		401: push_warning("Unauthorized. Please log in and try again")
		403: push_warning("Forbidden. You don't have permission")
		404: push_warning("User or route not found")
		409: push_warning("Conflicting data")
		422: push_warning("Validation error: %s" % JSON.stringify(parsed_json) if is_json else "")
		500, 502, 503: push_warning("Server error (%d). Try agian later." % response_code)
		_: push_warning("Unexpected response (%d): %s" % [response_code, body_text])
	
	return {
		"body_text": body_text, 
		"is_json": is_json, 
		"parsed_json": parsed_json, 
		"result_array": result_array,
		"response_code": response_code
	}
