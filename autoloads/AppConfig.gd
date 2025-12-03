extends Node

var DEBUG_MODE: bool = false

func _ready():
	# Loads env_active.cfg
	var env_file := "res://config/env_active.cfg"
	var config := ConfigFile.new()
	var err = config.load(env_file)

	DEBUG_MODE = config.get_value("environment", "debug_mode", false)
	print("Current debug mode: ", DEBUG_MODE)

	# Returns error if fail to load
	if err != OK:
		push_error("Error loading environment config: %s" % err)
		return

	# Loads [network] values
	var api_url = config.get_value("network", "api_base_url", "")
	var ws_url  = config.get_value("network", "ws_base_url", "")
	var md_url  = config.get_value("network", "media_base_url", "")

	# Set api url on project settings
	if api_url != "":
		ProjectSettings.set_setting("application/config/api_host", api_url)
		if DEBUG_MODE: print("API HOST set to: ", api_url)
	else:
		push_error("API_BASE_URL not set in environment config. Using default endpoint.")

	# Set websocket url to project settings
	if ws_url != "":
		ProjectSettings.set_setting("application/config/ws_host", ws_url)
		if DEBUG_MODE: print("Websocket Host set to: ", ws_url)
	else:
		push_error("WS_HOST not set in environment config. Using default endpoint.")

	if md_url != "":
		ProjectSettings.set_setting("application/config/md_host", md_url)
		if DEBUG_MODE: print("Media Host set to: ", md_url)