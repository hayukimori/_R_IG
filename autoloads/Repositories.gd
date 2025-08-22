extends Node

var profile_repository: ProfileRepository

func _ready() -> void:
    profile_repository = ProfileRepository.new()