extends RichTextLabel

class_name AnnouncementRichText

@export var action: PayloadAction

func _ready() -> void:
	if action == null: return
	if !action.valid_action: return

	self.text = action.text

	# Announcement Timer
	var announce_timer := Timer.new()
	announce_timer.wait_time = action.time
	announce_timer.start()
	announce_timer.autostart = true
	announce_timer.one_shot = false
	announce_timer.timeout.connect(_close_announcement)
	add_child(announce_timer)

	var stylebox = self.get_theme_stylebox("panel").duplicate()
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = action.bg_color
		self.add_theme_stylebox_override("panel", stylebox)

func _close_announcement() -> void:
	queue_free()