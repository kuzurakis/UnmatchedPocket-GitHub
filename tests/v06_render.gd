extends SceneTree
var app
var folder = "res://../../work/verification-v0.6"
func _initialize(): run.call_deferred()
func settle():
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String):
	await settle()
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
func finish():
	for i in range(15):
		if app.engine.phase == "combat_report": app._continue_combat()
		elif app.engine.phase == "effect_choice": app._choose_effect_option(0)
		else: return
		await settle()
func start(ids: Array,map_id: String):
	if app.started:
		app._return_menu()
		await settle()
	app.engine.setup(ids,1,6026,map_id)
	app._open_match()
	app.bot_timer.stop()
	await settle()
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	app.language_option.select(0)
	app.set_option.select(4)
	app._set_changed(4)
	await shot("menu")
	app._show_hero_info("jekyll_hyde")
	await shot("hero-rules")
	app._close_popup()
	app.set_option.select(2)
	app._set_changed(2)
	await shot("new-set")
	await start(["sherlock_holmes","dracula","jekyll_hyde","invisible_man"],"baskerville_manor")
	app._select_card(0)
	await shot("game-ru")
	app.I18n.set_language("en")
	app._refresh()
	await shot("game-en")
	app.I18n.set_language("ru")
	for map_id in ["soho","baskerville_manor"]:
		await start(["sherlock_holmes","dracula","jekyll_hyde","invisible_man"],map_id)
		await shot("map-"+map_id)
	for map_id in ["thrilla_in_manilla","tsing_shan_monastery"]:
		await start(["muhammad_ali","bruce_lee"],map_id)
		app._select_card(0)
		await shot("map-"+map_id)
	app.engine.ali_stance[0] = "bee"
	app.selected_card = -1
	app._refresh()
	await shot("ali")
	await start(["jekyll_hyde","sherlock_holmes"],"soho")
	if app.engine.phase == "effect_choice": app._choose_effect_option(1)
	await finish()
	app._refresh()
	await shot("hyde")
	await start(["invisible_man","dracula"],"baskerville_manor")
	await shot("fog")
	app.started = false
	print("V06_RENDER_OK")
	quit()
