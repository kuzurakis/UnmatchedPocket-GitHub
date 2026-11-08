extends "res://tests/v8_ui_tests.gd"
func run():
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app._language_changed(0)
	app.engine.interactive = false
	app.engine.setup(["nikola_tesla","dr_jill_trent","annie_christmas","golden_bat"],1,1010,"point_pleasant")
	app.engine.interactive = true
	app._open_match()
	app.bot_timer.stop()
	await settle()
	for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(1280,800),Vector2i(960,540),Vector2i(1024,768)]:
		root.size = dimensions
		if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(dimensions)
		await settle()
		app._show_text("Long panel", "Scrollable content\n".repeat(120))
		await settle()
		var panel = app.popup_layer
		var scroll = descendants_scroll(panel)
		scroll.scroll_vertical = 220
		await settle()
		var offset = scroll.scroll_vertical
		var state = JSON.stringify(app.engine.save_state())
		app._hide_popup()
		await settle()
		expect(app.popup_hidden and not panel.visible and app.popup_inspector != null,"hide retains original popup")
		var toolbar = app.inspector_zoom_button.get_parent()
		var bounds = Rect2(Vector2.ZERO,app.size)
		expect(bounds.encloses(toolbar.get_global_rect()),"restore toolbar fits viewport %s %s" % [dimensions,toolbar.get_global_rect()])
		app._on_node(0)
		app._bot_tick()
		expect(JSON.stringify(app.engine.save_state()) == state,"board inspection does not mutate match or advance bots")
		app._toggle_inspector_zoom()
		await settle()
		expect(app.inspector_board.visible and app.inspector_board.node_pressed.get_connections().is_empty(),"zoom board has no game input callback")
		expect(bounds.encloses(app.inspector_board.get_global_rect()),"zoom inspector fits viewport")
		app._restore_popup()
		await settle()
		expect(app.popup_layer == panel and panel.visible and scroll.scroll_vertical == offset,"restore keeps same panel and scroll")
		app._close_popup()
		await settle()
	for map in app.boards:
		app.engine.interactive = false
		app.engine.setup(["golden_bat","annie_christmas"],1,1010,str(map.id))
		app._refresh()
		await settle()
		for node in app.engine.nodes:
			expect(app.board.space_number(int(node.id)) == str(int(node.id)+1),"map labels match 1-based choices " + str(map.id))
			expect(app.board.image_rect().has_point(app.board.number_center(int(node.id))),"space number stays on map " + str(map.id))
	app.engine.interactive = false
	app.engine.setup(["nikola_tesla","dr_jill_trent"],1,1010,"point_pleasant")
	app.engine.interactive = true
	app.engine._start_ability(0,"Charge",[{"kind":"v10_end_charge"}],"end_turn")
	app._refresh()
	await settle()
	var pending = JSON.stringify(app.engine.pending_choice)
	app._hide_popup()
	app._sync_interaction()
	await settle()
	app._close_popup()
	await settle()
	expect(not app.popup_hidden and app.popup_layer != null and JSON.stringify(app.engine.pending_choice) == pending,"Back restores mandatory decision without closing or choosing")
	app._choose_effect_option(0)
	await settle()
	expect(app.engine._v10.coils(0) == 2,"restored decision still applies original choice")
	print("V10_UI checks=%d failures=%d" % [checks,failures])
	app.started = false
	app.queue_free()
	await process_frame
	quit(1 if failures else 0)

func descendants_scroll(node: Node):
	if node is ScrollContainer: return node
	for child in node.get_children():
		var result = descendants_scroll(child)
		if result != null: return result
	return null
