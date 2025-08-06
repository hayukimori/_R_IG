extends Control

# Main Steps
@onready var recover_first_step: Control = $RecoverStep1
@onready var recover_second_step: Control = $RecoverStep2


func _ready() -> void:
    pass

# === Steps ===
func _firstStep() -> void:
    pass

func _secondStep() -> void:
    pass

func _gotoStep2() -> void:
    recover_first_step.hide()
    recover_second_step.show()