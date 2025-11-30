extends TextEdit

const MAX_HEIGHT := 200 

func _ready():
    scroll_fit_content_height = false
    connect("text_changed", Callable(self, "_update_height"))
    _update_height()


func _update_height():
    var needed_height := get_line_count() * get_line_height() + 10

    # Limite máximo
    if needed_height > MAX_HEIGHT:
        needed_height = MAX_HEIGHT
        scroll_vertical = true
    else:
        scroll_vertical= false

    custom_minimum_size.y = needed_height
