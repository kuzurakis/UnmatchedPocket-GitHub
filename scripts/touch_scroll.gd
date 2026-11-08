extends ScrollContainer
## ScrollContainer with mouse dragging as well as touch and wheel scrolling.
var dragging = false
var last_position = Vector2.ZERO

func _ready():
	scroll_deadzone = 6
	get_v_scroll_bar().custom_minimum_size.x = 20
	get_h_scroll_bar().custom_minimum_size.y = 16

func _gui_input(event):
	# Mobile touch panning is handled by ScrollContainer itself.
	if OS.has_feature("mobile"):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_position = event.position
	elif event is InputEventMouseMotion and dragging:
		var delta = event.position - last_position
		last_position = event.position
		if vertical_scroll_mode != SCROLL_MODE_DISABLED:
			scroll_vertical -= int(delta.y)
		if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
			scroll_horizontal -= int(delta.x)
		accept_event()
