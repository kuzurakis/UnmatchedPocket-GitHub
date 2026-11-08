extends "res://tests/v13_ui_tests.gd"
func run():
	root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app._language_changed(0)
	app.set_option.select(13);app._set_changed(13);await settle();expect(app.hero_buttons.size()==3,"full Realms Fall offers all three decks")
	app._choose_hero("yennefer_triss");app._show_hero_info("yennefer_triss");await settle();expect(find_text(app.popup_layer,"Выбрать главную героиню")!="","character sheet links role selection")
	for screen in [Vector2i(960,540),Vector2i(1280,720)]:
		root.size=screen;app._show_sorceress_choice();await settle();expect(find_text(app.popup_layer,"14 ОЗ")!="" and find_text(app.popup_layer,"Трисс")!="","both roles and printed health visible")
	app._select_sorceress("triss");app._close_popup();app.placement_option.select(1);app._start_match();app.bot_timer.stop();await settle()
	expect(app.engine.players[0].get("sorceress","")=="triss" and app.engine.fighters[0].name=="Трисс" and app.engine.fighters[1].name=="Йеннифэр","menu selection reaches real match")
	expect(app.engine.fighters[0].hp==14 and app.engine.fighters[1].hp==6,"correct health after role switch")
	for lang in ["en","nb","es"]:
		app.I18n.set_language(lang);app._show_player_info(0);await settle();expect(not has_cyrillic(app.popup_layer),"both-role character sheet translated "+lang);app._close_popup();app.engine.players[0].ongoing=card("yennefer_triss","advisor_to_the_king");app._show_special_state(0);await settle();expect(not has_cyrillic(app.popup_layer),"Advisor panel translated "+lang);app._close_popup()

	app.I18n.set_language("ru");app.engine.interactive=false;app.engine.setup(["king_arthur","yennefer_triss"],1,1717,"naglfar",{"sorceresses":{1:"yennefer"}});app.engine.interactive=true
	app.engine.players[0].hand=[card("king_arthur","excalibur")];app.engine.players[1].hand=[card("yennefer_triss","lodge_of_sorceresses"),card("yennefer_triss","echoing_blast")];app.engine.active=1;app.engine.scheme(app.engine.hero_fighter(1),0);app._refresh();await settle()
	expect(app.popup_kind=="choice" and app.engine.pending_choice.viewer==0,"bot Lodge visibly asks human to commit a card")
	app._choose_effect_option(0);await settle();expect(app.engine.pending_choice.action=="v17_lodge_reveal","actual card button proceeds to simultaneous public reveal")
	print("V17_UI checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
