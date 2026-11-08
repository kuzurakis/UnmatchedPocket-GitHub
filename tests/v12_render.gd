extends "res://tests/v07_render.gd"
func run():
	folder="res://../../work/verification-v0.12";root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
	app.I18n.set_language("ru");app.set_option.select(10);app._set_changed(10);await shot("menu")
	app._show_hero_info("oda_nobunaga");await shot("new-set");app._close_popup()
	app.engine.interactive=false;await start(["oda_nobunaga","tomoe_gozen"],"azuchi_castle");app.engine.interactive=true
	app._refresh();await shot("game-ru");app._show_map_rules(true);await shot("map-rules");app._close_popup()
	app.I18n.set_language("en");app._refresh();await shot("game-en");app.I18n.set_language("ru")
	app.engine.interactive=false;await start(["king_arthur","sherlock_holmes"],"training");app.engine.interactive=true
	var e=app.engine;e.fighters[0].node=12;e.fighters[2].node=13;e.players[0].hand=[card("king_arthur","excalibur")];e.players[1].hand=[card("sherlock_holmes","elementary")]
	e.attack(0,2,0);e.continue_attack();app._refresh();await shot("elementary")
	app.engine.interactive=false;await start(["golden_bat","tomoe_gozen"],"azuchi_castle");app.engine.interactive=true
	for f in app.engine.fighters:f.locked_until=app.engine.turn_number
	app._refresh();await shot("roar")
	print("V12_RENDER_OK");quit()
