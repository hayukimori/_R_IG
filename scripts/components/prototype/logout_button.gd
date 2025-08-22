extends Button


func _ready() -> void:
	self.text = "Logout"

func _on_pressed() -> void:
	# Executes logout function
	Services.scene_service.logout()
	