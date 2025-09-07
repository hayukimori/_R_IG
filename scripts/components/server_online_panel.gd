extends Panel

@onready var status_label: RichTextLabel = $StatusLabel
@export var timer_interval: float = 5.0
var is_server_online: bool = false

func _ready() -> void:

	var status = await check_status()
	update_text(status)

	var update_timer := Timer.new()
	update_timer.name = "DeltaSyncTimer"
	update_timer.wait_time = timer_interval
	update_timer.autostart = true
	update_timer.one_shot = false
	update_timer.timeout.connect(_perform_check)
	add_child(update_timer)


## Checks current server status
func check_status() -> bool:
	var api: APIService = Services.api
	var route: Route = Services.routes.ROUTE_HEALTH

	var rs := await api.simple_request(route.url(), {}, route.method)
	if (!rs): return false
	if rs.get("response_code") != 200: return false

	return true

func update_text(status: bool) -> void:
	var t = "[color=green]Online[/color]" if status else "[color=red]Offline[/color]"
	var ct = "[center][b]Connection[/b]: %s" % t

	status_label.text = ct	

func _perform_check() -> void:
	var status = await check_status()
	update_text(status)
