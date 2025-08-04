extends Node

var DEBUG_MODE: bool = false

func _ready():
	var env_file := "res://config/env_active.cfg"
	var config := ConfigFile.new()
	var err = config.load(env_file)
	if err != OK:
		push_error("Error loading environment config: %s" % err)
		return

	var api_url = config.get_value("network", "api_base_url", "")
	DEBUG_MODE = config.get_value("environment", "debug_mode", false)
	print("Current debug mode: ", DEBUG_MODE)
	if api_url != "":
		ProjectSettings.set_setting("application/config/api_host", api_url)
		if DEBUG_MODE: print("API HOST set to: ", api_url)
	else:
		push_error("API_BASE_URL not set in environment config. Using default endpoint.")
