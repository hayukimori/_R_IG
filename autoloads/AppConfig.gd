extends Node

func _ready():
	var env_file := "res://config/env_active.cfg"
	var config := ConfigFile.new()
	var err = config.load(env_file)
	if err != OK:
		push_error("Error loading environment config: %s" % err)
		return

	var api_url = config.get_value("network", "api_base_url", "")
	if api_url != "":
		ProjectSettings.set_setting("application/config/api_host", api_url)
		print("API HOST setado para: ", api_url)
	else:
		push_error("API_BASE_URL not set in environment config. Using default endpoint.")
