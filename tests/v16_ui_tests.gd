extends "res://tests/v13_ui_tests.gd"
func run():
	root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app._language_changed(0)
	app.set_option.select(13);app._set_changed(13);await settle();expect(app.hero_buttons.size()==3,"Realms Fall now offers Eredin and Philippa")
	app.engine.interactive=false;app.engine.setup(["philippa","eredin"],1,1616,"naglfar");app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
	app.engine.players[0].ongoing=card("philippa","polymorphy")
	for lang in ["en","nb","es"]:
		app.I18n.set_language(lang);app._show_player_info(0);await settle();expect(not has_cyrillic(app.popup_layer),"Philippa sheet translated "+lang);app._close_popup();app._show_special_state(0);await settle();expect(not has_cyrillic(app.popup_layer),"Polymorphy translated "+lang);app._close_popup()
	app.I18n.set_language("ru");app.engine.players[0].hand=[card("philippa","regicide")];app.engine.end_turn();app._refresh();await settle();expect(app.popup_kind=="choice" and find_text(app.popup_layer,"Добрать до 4 карт")!="","end draw is visible decision")
	var saved=JSON.stringify(app.engine.pending_choice);app._hide_popup();await settle();app._restore_popup();await settle();expect(JSON.stringify(app.engine.pending_choice)==saved,"hide/restore preserves pending draw");app._choose_effect_option(0);await settle();expect(app.engine.players[0].hand.size()==4,"actual UI draws to four")
	app.engine.interactive=false;app.engine.setup(["philippa","eredin"],1,1616,"naglfar");app.engine.interactive=true;app.engine.players[0].hand=[card("philippa","spymasters_ruse")];app.engine.scheme(1,0);app._refresh();await settle();expect(app.engine.pending_choice.cards.size()==4,"spy popup shows only four revealed cards")
	print("V16_UI checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
