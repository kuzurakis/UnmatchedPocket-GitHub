extends "res://tests/v07_render.gd"
func run():
	folder="res://../../work/verification-v0.14";root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
	app.set_option.select(12);app._set_changed(12);await shot("menu")
	app._show_hero_info("geralt_of_rivia");await shot("new-set");app._close_popup();app._show_geralt_gear();await shot("gear");app._close_popup()
	app.engine.interactive=false;await start(["geralt_of_rivia","ciri","ancient_leshen"],"kaer_morhen",{"geralt_gear":app.geralt_gear});app.engine.interactive=true;app._refresh();await shot("game-ru")
	app._show_map_rules(true);await shot("map-rules");app._close_popup();app.I18n.set_language("en");app._refresh();await shot("game-en");app.I18n.set_language("ru")
	app.engine.players[0].ongoing=card("geralt_of_rivia","gear_tawny_owl");app._show_special_state(0);await shot("ongoing");app._close_popup()
	app.engine.players[1].discard=[]
	for id in ["lion_cub_of_cintra","pushed_to_the_brink","the_lady_of_space_and_time","zireael","child_of_the_elder_blood","lion_cub_of_cintra","zireael"]:app.engine.players[1].discard.append(card("ciri",id))
	app._show_special_state(1);await shot("source");app._close_popup()
	app.engine.interactive=false;await start(["ancient_leshen","geralt_of_rivia"],"fayrlund_forest");app.engine.interactive=true;app.engine.players[0].ongoing=card("ancient_leshen","strength_of_the_pack");app._refresh();await shot("leshen")
	print("V14_RENDER_OK");quit()
