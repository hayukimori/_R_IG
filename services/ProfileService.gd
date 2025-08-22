class_name ProfileService
extends RefCounted

func get_user_avatar(profile_data: UserProfile) -> ImageTexture:
	var url = _prepare_avatar_url(profile_data.avatar_url)
	
	if not ValidationRules.validate_url(url):
		push_error("Invalid URL: %s" % url)
		return _get_default_avatar()
	
	var image_data = await Repositories.profile_repository.download_image(url)
	if image_data.is_empty():
		return _get_default_avatar()
	
	return ImageLib.buffer_to_texture(image_data)

func _prepare_avatar_url(avatar_url: String) -> String:
	if "gravatar.com" in avatar_url:
		return "%s?size=512" % avatar_url
	return avatar_url

func _get_default_avatar() -> ImageTexture:
	return load("res://assets/default_profile_picture.png")

func compare_profile_datas(data1: UserProfile, data2: UserProfile) -> Dictionary:
	var d1d = data1.to_dict()
	var d2d = data2.to_dict()

	var final_dict := {}

	var comp = FormatLib.compare_dicts(d1d, d2d)
	if len(comp) > 0:
		for key in comp:
			final_dict.merge({key: d2d[key]})

	return final_dict