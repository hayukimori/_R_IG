extends Node

const ENDPOINT_LOGIN            := "/api/auth/login"
const ENDPOINT_REGISTER         := "/api/auth/register"
const ENDPOINT_PROTECTED        := "/api/auth/protected"
const ENDPOINT_FORGOT_PASSWD	:= "/api/auth/forgot-password"
const ENDPOINT_VERIFY_CODE		:= "/api/auth/verify-code"
const ENDPOINT_RESET_PASSWD		:= "/api/auth/reset-password"
const ENDPOINT_PING             := "/api/v1/ping"
const ENDPOINT_GET_PROFILE      := "/api/v1/profile/uid/%s"
const ENDPOINT_SEND_PROFILE     := "/api/v1/editprofile"
const ENDPOINT_SEND_PICTURE     := "/api/v1/update-pfp"
const ENDPOINT_CUBES            := "/api/v1/cubes"
const ENDPOINT_NEW_CUBES        := "/api/v1/checknewcubes"
const ENDPOINT_WORLD_FOLLOWS    := "/api/v1/worldfollows"
const ENDPOINT_FOLLOW           := "/api/v1/follow"
const ENDPOINT_UNFOLLOW         := "/api/v1/unfollow"
const ENDPOINT_FL_EXISTS        := "/api/v1/follow-exists"
const ENDPOINT_WORLD_UNFOLLOWS  := "/api/v1/worldunfollows"
const ENDPOINT_STIME            := "/api/v1/server-clock"
const ENDPOINT_WORLD_UPDATES    := "/api/v1/worldupdates"
const ENDPOINT_ME				:= "/api/v1/me"


func get_route(endpoint: String) -> String:
	var host = ProjectSettings.get_setting("application/config/api_host")
	var url: String
	if host != "":
		url = host + endpoint
	else:
		push_error("API host is not set in project settings. Using default endpoint.")
		url = "http://localhost:3000" + endpoint
	return url
