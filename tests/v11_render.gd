extends "res://tests/v07_render.gd"
func run():
	folder="res://../../work/verification-v0.11"
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
	app.I18n.set_language("ru");app.language_option.select(0);app.set_option.select(6);app._set_changed(6)
	await shot("menu")
	app.engine.interactive=false;await start(["little_red","yennenga"],"heorot");app.engine.interactive=true
	var copies=[]
	for pile in [app.engine.players[0].deck,app.engine.players[0].hand]:
		for c in pile:
			if c.id == "into_the_woods": copies.append(c.duplicate(true))
	app.engine.players[0].hand=copies+[card("little_red","the_wolf_s_skin"),card("little_red","once_upon_a_time")]
	app.engine.players[0].discard=[card("little_red","long_have_i_sought_you")]
	app._refresh();app._select_card(3);await shot("game-ru")
	app._show_discards(0);await shot("basket-discard");app._close_popup()
	app._show_player_info(0);await shot("character");app._close_popup()
	app._show_hero_info("little_red");await shot("new-set");app._close_popup()
	app.I18n.set_language("en");app._refresh();await shot("game-en")
	app.I18n.set_language("ru")
	app.engine.interactive=false;await start(["yennenga","king_arthur"],"hanging_gardens");app.engine.interactive=true
	var e=app.engine
	e.fighters[0].node=21;e.fighters[1].node=20;e.fighters[2].node=23;e.fighters[3].node=22;e.fighters[4].node=5
	var shared=[]
	for node in e.nodes:
		if int(node.id) not in [21,22,5] and e._same_zone(21,int(node.id)): shared.append(int(node.id))
	e.fighters[1].node=shared[0];e.fighters[2].node=shared[1]
	e.fighters[1].hp=1;e.active=1;e.players[0].hand=[]
	e.players[1].hand=[{"id":"probe","name":"Проверка атаки","type":"attack","value":5,"fighter":"any","boost":2,"effects":[]}]
	e.attack(3,0,0);e.continue_attack();e.defend(-1);app._refresh();await shot("yennenga")
	app._choose_effect_option(1);await shot("yennenga-split")
	app._hide_popup();app._toggle_inspector_zoom();await shot("hidden-zoom")
	app._restore_popup();app._show_map_rules(true);await shot("map-rules")
	print("V11_RENDER_OK");quit()
