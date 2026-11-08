extends "res://tests/v07_render.gd"
func run():
	folder="res://../../work/verification-v0.17";root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru");app.set_option.select(13);app._set_changed(13);await shot("menu")
	app._show_sorceress_choice();await shot("roles");app._close_popup()
	for main in ["yennefer","triss"]:
		app.engine.interactive=false;await start(["yennefer_triss","philippa","eredin","ciri"],"naglfar",{"mode":"teams","sorceress_hero":main});app.engine.interactive=true;app._refresh();await shot(main)
	app._show_player_info(0);await shot("new-set");app._close_popup();app.engine.players[0].ongoing=card("yennefer_triss","advisor_to_the_king");app.engine._v17.refresh_boosts(0);app._show_special_state(0);await shot("advisor");app._close_popup();app.I18n.set_language("en");app._refresh();await shot("game-en")
	print("V17_RENDER_OK");quit()
