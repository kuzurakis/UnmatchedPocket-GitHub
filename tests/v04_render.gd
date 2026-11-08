extends SceneTree

var app
var folder = "res://../../work/verification-v0.4"

func _initialize():
	run.call_deferred()

func settle():
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String):
	await settle()
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	app._localize()
	await shot("menu-ru")
	app.set_option.select(1)
	app._set_changed(1)
	await shot("menu-new-set")
	app._show_hero_info("robin_hood")
	await shot("hero-info")
	app._close_popup()
	app.placement_option.select(1)
	for map_id in ["sherwood_forest", "yukon"]:
		app.placement_option.select(1)
		for index in range(app.map_option.item_count):
			if str(app.map_option.get_item_metadata(index)) == map_id: app.map_option.select(index)
		app._start_match()
		await settle()
		app._select_card(0)
		await shot(map_id)
		app._show_board_zoom()
		app.enlarged_board.highlighted = app.engine.nodes.map(func(n): return int(n.id))
		await shot(map_id + "-cells")
		app._close_popup()
		app._return_menu()
		await settle()
	for code in ["en", "nb", "es"]:
		app.I18n.set_language(code)
		app.language_option.select(["ru", "en", "nb", "es"].find(code))
		app._localize()
		await shot("menu-" + code)
	app.I18n.set_language("ru")
	app.count_option.select(2)
	app._opponent_changed(2)
	app._choose_hero("king_arthur")
	app.placement_option.select(1)
	app._start_match()
	await settle()
	app._select_card(0)
	await shot("game-ru")
	app.I18n.set_language("en")
	app._localize()
	await shot("game-en")
	app._show_help()
	await shot("help-en")
	app._close_popup()
	app._show_library()
	await shot("library-en")
	app._close_popup()
	app.I18n.set_language("ru")
	app.started = false
	print("V04_RENDER_OK")
	quit()
