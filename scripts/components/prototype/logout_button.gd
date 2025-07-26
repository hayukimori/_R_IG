extends Button


func _ready() -> void:
	self.text = "Logout"

func _on_pressed() -> void:
	# Executes SceneHandler's logout function
	SceneHandler.logout()
	