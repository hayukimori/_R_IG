extends Control
class_name UserProfileUIPrototype

@export var profile_id: String
@export var profile_getter_url: String = "http://localhost:3000/api/v1/profile/uid/%s"

var headers: Array = [
	"Authorization: Bearer %s" % CurrentUserSession.login_token,
	"Content-Type: application/json",
	"Accept: application/json"
]

# TODO: Extract Validations to a global tools script.
class Validations:
	func validate_uid(uid: String) -> bool:
		# Early return method
		# Requirement: UID Needs to be exactly 24 characters long. (12 bytes)
		if not type_string(typeof(uid)): return false
		if uid == "": return false
		if uid.length() != 24: return false

		return true

func _ready() -> void:
	await get_tree().process_frame

	if prepareRequirements():
		loadProfile()

func prepareRequirements() -> bool:
	var c_valids = Validations.new()
	var uid_is_valid: bool = c_valids.validate_uid(profile_id)

	return uid_is_valid


func loadProfile() -> void:
	pass

func _request_profile() -> Dictionary:
	var http_request := HTTPRequest.new()
	add_child(http_request)

	var result: Dictionary = {}

	http_request.request_completed.connect(func(result_code, response_code, _headers, body):
		if result_code != 0:
			print("error connecting, result_code: %d" % result_code)
			result.assign({
				"ConnectionError": "Connection error", 
				"context": "Couldn't connect: result_code: %d"  % result_code, 
				"code": result_code
			})
			
		if response_code >= 400:
			push_error("Error request")
		elif response_code >= 500:
			push_error("Server Error")

		var json = JSON.parse_string(body.get_string_from_utf8())

		if typeof(json) == TYPE_DICTIONARY:
			result.assign(json)
	)

	var url = profile_getter_url % profile_id	
	#var token = CurrentUserSession.login_token

	# if token == "":
	# 	push_error("CUBES HANDLER REQUEST ERROR: No Token Provided, it can result in request error.")
	# 	return {"error": "No token provided"}

	http_request.request(url, headers, HTTPClient.METHOD_GET)

	await http_request.request_completed
	http_request.queue_free()

	return result
