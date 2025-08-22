class_name UserProfile

var id: String
var username: String
var display_name: String
var bio: String
var avatar_url: String
var banner_color: String
var followers_count: int
var following_count: int
var is_following: bool
var badges: Array
var links: Array

func _init(data: Dictionary = {}) -> void:
	self.id = data.get('id', '')
	self.username = data.get('username', '')
	self.display_name = data.get('displayName', '')
	self.bio = data.get('bio', '')
	self.avatar_url = data.get('avatarUrl', '')
	self.banner_color = data.get('bannerColor', '')
	self.followers_count = data.get('followersCount', 0)
	self.following_count = data.get('followingCount', 0)
	self.is_following = data.get('isFollowing', false)
	self.badges = data.get('badges', [])
	self.links = data.get('links', [])

func to_dict(ignore_follow_system := true, ignore_badges := true) -> Dictionary:
	var data := {
		"id": self.id,
		"displayName": self.display_name,
		"username": self.username,
		"bio": self.bio,
		"avatarUrl": self.avatar_url,
		"bannerColor": self.banner_color,
		"links": self.links
	}

	if not ignore_follow_system:
		data.merge({
			"followersCount": self.followers_count,
			"followingCount": self.following_count,
			"isFollowing": self.is_following
		})
	
	if not ignore_badges:
		data.merge({
			"badges": self.badges
		})

	return data
