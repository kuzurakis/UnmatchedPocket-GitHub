extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.bot_timer.stop()
	app.placement_option.select(1)
	app._start_match()
	app.engine.players[0].hand[0].text = "Проверяем длинный эффект карты и прокрутку. ".repeat(100)
	app._select_card(0)
	await process_frame
	await process_frame
	app.detail_scroll.scroll_vertical = 100
	var scroll_rect = app.detail_scroll.get_global_rect()
	var press = InputEventMouseButton.new()
	press.position = scroll_rect.position + Vector2(60, scroll_rect.size.y - 12)
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = press.position
	print("RECT ",scroll_rect," POSITION ",press.position, " VIEWPORT ", app.get_viewport_rect(), " ROOT ", app.size)
	root.push_input(press, true)
	print("DRAGGING ",app.detail_scroll.dragging)
	var drag = InputEventMouseMotion.new()
	drag.position = press.position - Vector2(0, 45)
	drag.relative = Vector2(0, -45)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.global_position = drag.position
	root.push_input(drag, true)
	var release = press.duplicate()
	release.position = drag.position
	release.pressed = false
	root.push_input(release, true)
	await process_frame
	print("SCROLL_GESTURE before=100 after=", app.detail_scroll.scroll_vertical)
	var good = app.detail_scroll.scroll_vertical > 100
	app.started = false
	quit(0 if good else 1)
