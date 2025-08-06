extends Control

# Main Steps
@onready var recover_first_step: Control = $RecoverStep1
@onready var recover_second_step: Control = $RecoverStep2


func _ready() -> void:
	_firstStep()

# === Steps ===
func _firstStep() -> void:
	recover_first_step.show()
	

func _secondStep() -> void:
	pass

func _gotoStep2() -> void:
	recover_first_step.hide()
	recover_second_step.show()

func _on_send_code_button_pressed() -> void:
	pass
