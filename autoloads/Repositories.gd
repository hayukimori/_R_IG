extends Node

var profile_repository: ProfileRepository
var post_repository: PostRepository

func _ready() -> void:
    profile_repository = ProfileRepository.new()
    post_repository = PostRepository.new()