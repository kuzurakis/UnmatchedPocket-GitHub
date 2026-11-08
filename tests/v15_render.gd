extends "res://tests/v07_render.gd"
func run():
	folder="res://../../work/verification-v0.15";root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
	app.set_option.select(13);app._set_changed(13);await shot("menu");app._show_hero_info("eredin");await shot("new-set");app._close_popup()
	app.engine.interactive=false;await start(["eredin","geralt_of_rivia","ciri","ancient_leshen"],"naglfar",{"mode":"teams"});app.engine.interactive=true;app._refresh();await shot("game-ru")
	app._show_map_rules(true);await shot("map-rules");app._close_popup();app.I18n.set_language("en");app._refresh();await shot("game-en");app.I18n.set_language("ru")
	for f in app.engine.fighters:
		if f.owner==0 and not f.hero:f.alive=false;f.hp=0
	app.engine.players[0].ongoing=card("eredin","might_of_the_aen_elle");app._show_special_state(0);await shot("eredin");app._close_popup()
	app.engine.interactive=false;await start(["eredin","ciri"],"streets_of_novigrad");app.engine.interactive=true;app._refresh();await shot("novigrad")
	print("V15_RENDER_OK");quit()
