extends "res://tests/v8_ui_tests.gd"
func run():
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app._language_changed(0)
	for code in ["ru","en","nb","es"]:
		I18n.set_language(code)
		app.set_option.select(8)
		app._set_changed(8)
		await settle()
		expect(app.hero_buttons.size() == 4,"BOL2 selector contains four heroes")
		app._show_map_rules(false)
		await settle()
		expect(find_text(app.popup_layer,I18n.text(str(app._selected_map().rules_text))) != "","selected board full rules are translated " + code)
		app._close_popup()
		app.engine.interactive = false
		app.engine.setup(["achilles","bloody_mary","sun_wukong","yennenga"],1,909,"hanging_gardens")
		app._open_match()
		app.bot_timer.stop()
		await settle()
		app._show_board_zoom()
		await settle()
		expect(find_text(app.popup_layer,I18n.text("Правила этого поля")) != "","board zoom offers rules during match")
		app._show_map_rules(true)
		await settle()
		expect(find_text(app.popup_layer,I18n.text(str(app.engine.board_data.rules_text))) != "","in-game board rules show real map features")
		app._close_popup()
		for owner in range(4):
			app._show_player_info(owner)
			await settle()
			var hero = app.engine.heroes[app.engine.players[owner].hero_id]
			expect(find_text(app.popup_layer,I18n.text(str(hero.ability))) != "","new hero full ability accessible " + code)
			app._close_popup()
		app._return_menu()
		await settle()
	I18n.set_language("ru")
	app.set_option.select(8)
	app._set_changed(8)
	app._choose_hero("sun_wukong")
	app.count_option.select(0)
	app._opponent_changed(0)
	app.placement_option.select(1)
	app._start_match()
	app.bot_timer.stop()
	await settle()
	expect(app.engine.pending_choice.action == "v9_clone_start" and app.engine.fighters[0].hp == 17,"first automatic-setup game offers start ability before spending health")
	app._choose_effect_option(1)
	await settle()
	if app.engine.phase == "combat_report": app._continue_combat()
	app._return_menu()
	await settle()
	app.engine.interactive = false
	app.engine.setup(["yennenga","king_arthur"],1,909,"training")
	app.engine.interactive = true
	app._open_match()
	app.bot_timer.stop()
	var e = app.engine
	var foe = nearby_enemy()
	e.fighters[0].node = 12
	e.fighters[foe].node = 13
	e.fighters[1].node = 7
	e.fighters[2].node = 17
	e.active = 1
	e.players[1].hand = [{"id":"probe","name":"Probe","fighter":"any","type":"attack","value":5,"boost":2,"effects":[]}]
	e.players[0].hand.clear()
	e.attack(foe,0,0)
	app._refresh()
	app._continue_attack()
	app._play_selected()
	await settle()
	expect(e.pending_choice.action == "v9_damage" and app.popup_kind == "choice","real defense UI opens Archer allocation")
	app._choose_effect_option(1)
	await settle()
	expect(int(e.fighters[1].hp) == 1 and app.popup_kind == "choice","damage assignment updates Archer and keeps remaining choice")
	app._choose_effect_option(0)
	await settle()
	expect(e.phase == "combat_report" and int(e.fighters[0].hp) == 11,"remaining four damage resumes real combat report")
	print("V9_UI checks=%d failures=%d" % [checks,failures])
	app.started = false
	app.queue_free()
	await process_frame
	quit(1 if failures else 0)
