extends "res://tests/ui_tests.gd"
const I18n = preload("res://scripts/i18n.gd")
func find_text(node: Node, contains: String) -> String:
	if (node is Label or node is Button) and contains in node.text: return node.text
	for child in node.get_children():
		var found = find_text(child,contains)
		if found != "": return found
	return ""
func run():
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app._language_changed(0)
	app.placement_option.select(1)
	await new_match("houdini",4,"marmoreal")
	app.bot_timer.stop()
	app.engine.interactive = true
	app.engine.setup(["houdini","beowulf","little_red","genie"],1,808,"marmoreal")
	app.selected_fighter = 0
	app._refresh()
	await settle()
	var e = app.engine
	e.fighters[0].hp = 9
	var original = JSON.stringify(e.save_state())
	for code in ["ru","en","nb","es"]:
		I18n.set_language(code)
		app._refresh()
		await settle()
		for owner in range(4):
			var hud = app.hud_left if owner%2 == 0 else app.hud_right
			var panel = hud.get_child(owner/2)
			panel.pressed.emit()
			await settle()
			expect(app.popup_layer != null,"name panel opens character information " + code)
			var hero = e.heroes[e.players[owner].hero_id]
			expect(find_text(app.popup_layer,I18n.text(str(hero.ability))) != "","character popup includes complete translated ability " + code)
			expect(has_texture(app.popup_layer),"character popup shows portrait")
			expect(find_text(app.popup_layer,I18n.text("Посмотреть сброс этого игрока")) != "","character popup retains access to discard")
			if owner == 0: expect(find_text(app.popup_layer,"9 / 14") != "","character popup shows actual current hero health")
			app._close_popup()
			await settle()
			expect(JSON.stringify(e.save_state()) == original,"opening and closing information never advances match or bots")
	I18n.set_language("ru")
	app.engine.setup(["little_red","beowulf"],1,808,"heorot")
	app.engine.fighters[0].node = 17
	app.engine.fighters[1].node = 0
	app.engine.fighters[2].node = 19
	app.engine.fighters[3].node = 1
	app.selected_fighter = 0
	app._refresh()
	expect(app.doors_button.visible and app.doors_button.disabled,"door control visible, inactive outside maneuver")
	app._begin_move()
	app._show_doors()
	await settle()
	expect(find_text(app.popup_layer,"Дверь 1") != "","door popup lists numbered doors")
	app._toggle_door(0)
	await settle()
	expect(app.engine.door_states[0],"door UI closes actual engine door")
	app._toggle_door(0)
	expect(not app.engine.door_states[0] and int(app.engine.door_movement_spent[0]) == 1,"door UI opens door and pays movement")
	app._finish_move()
	app._show_player_info(1)
	await settle()
	expect(find_text(app.popup_layer,"Ярость: 1/3") != "","in-game character popup includes current rage")
	app._show_discards(1)
	await settle()
	expect(app.popup_layer != null,"discard browser still opens from information")
	app._close_popup()
	print("V8_UI checks=%d failures=%d" % [checks,failures])
	app.queue_free()
	await process_frame
	quit(1 if failures else 0)
