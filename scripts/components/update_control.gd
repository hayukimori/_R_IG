extends Control

class_name UpdateControl

@onready var version_label: Label = $bgPanel/VersionLabel
@export var current_version: String
@export var server_version: String

func _ready():
	version_label.text = "Update is required.\n%s ---> %s" % [current_version, server_version]

func _on_update_button_pressed() -> void:
	var url = Services.routes.GITHUB_RELEASE_URL
	OS.shell_open(url)
