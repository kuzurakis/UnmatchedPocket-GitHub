extends "res://tests/v07_render.gd"
func run():
	folder = "res://../../work/verification-v0.9"
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	app.language_option.select(0)
	app.set_option.select(8)
	app._set_changed(8)
	await shot("menu")
	app._show_map_rules(false)
	await shot("map-rules-menu")
	app._close_popup()
	app._show_hero_info("yennenga")
	await shot("new-set")
	app._close_popup()
	app.engine.interactive = false
	await start(["achilles","bloody_mary","sun_wukong","yennenga"],"hanging_gardens")
	app.engine.interactive = true
	app.engine._damage(1,6)
	app.engine.players[0].hand = []
	for id in ["test_for_weakness","brothers_in_arms","battle_hardened","skirmish","spear_throw"]:app.engine.players[0].hand.append(card("achilles",id))
	app._refresh()
	await shot("game-ru")
	app._show_map_rules(true)
	await shot("map-rules-game")
	app._close_popup()
	app._show_player_info(0)
	await shot("character")
	app._close_popup()
	app.I18n.set_language("en")
	app._refresh()
	await shot("game-en")
	app.I18n.set_language("ru")
	app.engine.interactive = false
	await start(["sun_wukong","yennenga"],"hanging_gardens")
	app.engine.interactive = true
	app._refresh()
	await shot("wukong")
	app.engine.interactive = false
	await start(["yennenga","achilles"],"hanging_gardens")
	app.engine.interactive = true
	var e = app.engine
	e.fighters[0].node = 21
	e.fighters[1].node = 20
	e.fighters[2].node = 23
	e.fighters[3].node = 22
	e.fighters[4].node = 5
	e.active = 1
	e.players[0].hand.clear()
	e.players[1].hand = [{"id":"probe","name":"Проверка атаки","type":"attack","value":5,"fighter":"any","boost":2,"effects":[]}]
	e.attack(3,0,0)
	e.continue_attack()
	e.defend(-1)
	app._refresh()
	await shot("archers")
	print("V09_RENDER_OK")
	quit()
