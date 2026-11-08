extends "res://tests/v07_render.gd"
func run():
	folder="res://../../work/verification-v0.13";root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
	app.I18n.set_language("ru");app.set_option.select(11);app._set_changed(11);await shot("menu")
	app._show_hero_info("william_shakespeare");await shot("new-set");app._close_popup()
	app.engine.interactive=false;await start(["william_shakespeare","hamlet","titania","the_wayward_sisters"],"globe_theatre");app.engine.interactive=true
	app._refresh();await shot("game-ru");app._show_map_rules(true);await shot("map-rules");app._close_popup()
	app.I18n.set_language("en");app._refresh();await shot("game-en");app.I18n.set_language("ru")
	app.engine.players[0].line=[card("william_shakespeare","et_tu_brute"),card("william_shakespeare","et_tu_brute")]
	app._show_special_state(0);await shot("line");app._close_popup()
	app._show_special_state(2);await shot("glamours");app._close_popup()
	app.engine.players[3].cauldron=[card("the_wayward_sisters","ward"),card("the_wayward_sisters","hurly_burly"),card("the_wayward_sisters","double_double")]
	app._show_special_state(3);await shot("cauldron");app._close_popup()
	app.engine.interactive=false;await start(["hamlet","titania"],"globe_theatre");app.engine.interactive=true;app.engine._start_turn_ability()
	app._refresh();await shot("question")
	print("V13_RENDER_OK");quit()
