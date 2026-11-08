extends "res://tests/v8_ui_tests.gd"
func run():
	root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app._language_changed(0)
	app.set_option.select(11);app._set_changed(11);await settle()
	expect(app.hero_buttons.size()==4,"new set filter displays four heroes")
	app.engine.interactive=false;app.engine.setup(["william_shakespeare","hamlet","titania","the_wayward_sisters"],1,1313,"globe_theatre");app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
	expect(app.engine.map_id=="globe_theatre" and app.engine.nodes.size()==32,"new 32-space board reaches game UI")
	app.engine.players[0].hand=[card("william_shakespeare","horror")];app._refresh();await settle()
	var view=app.hand_box.get_child(0)
	expect(view._basket_badge.visible and view._basket_badge.text=="Слогов: 2","printed syllable count is visible on hand card")
	app._show_player_info(0);await settle();expect(find_text(app.popup_layer,"Способность и особые карты")!="","in-game character sheet links special state")
	app.engine.players[0].line=[card("william_shakespeare","et_tu_brute"),card("william_shakespeare","alas")]
	app._show_special_state(0);await settle();expect(find_text(app.popup_layer,"6/10 слогов")!="" and find_text(app.popup_layer,"Строка слева направо")!="","line total and ordered cards shown")
	app._hide_popup();await settle();expect(not app.popup_layer.visible and is_instance_valid(app.popup_inspector),"special panel can be hidden for board inspection")
	app._restore_popup();await settle();expect(app.popup_layer.visible,"same special panel reopens")
	app._close_popup();app.engine.players[2].glamour="sleep";app.engine.players[2].glamour_deck.erase("sleep")
	app._show_special_state(2);await settle();expect(find_text(app.popup_layer,"Чары сна")!="" and find_text(app.popup_layer,"Открыты сейчас")!="" and find_text(app.popup_layer,"истощения")!="","all glamour rules and active state readable")
	app._close_popup();app.engine.players[3].cauldron=[card("the_wayward_sisters","ward"),card("the_wayward_sisters","hurly_burly")]
	app._show_special_state(3);await settle();expect(find_text(app.popup_layer,"змея 1 · мышь 1")!="" and find_text(app.popup_layer,"Карты в котле")!="","ingredient counts and real cauldron cards shown")
	app._close_popup();app.I18n.set_language("en");app._show_special_state(0);await settle();expect(find_text(app.popup_layer,"6/10 syllables")!="","new special panel translates into English")
	app._close_popup()
	for language in ["en","nb","es"]:
		app.I18n.set_language(language)
		for owner in range(4):
			app._show_special_state(owner);await settle();expect(not has_cyrillic(app.popup_layer),"whole special panel translated "+language+" "+str(owner));app._close_popup()
	app.I18n.set_language("ru");app._return_menu();await settle()
	app.engine.interactive=false;app.engine.setup(["hamlet","titania"],1,1313,"globe_theatre");app.engine.interactive=true;app._open_match();app.engine._start_turn_ability();app.bot_timer.stop();app._refresh();await settle()
	expect(app.popup_kind=="choice" and find_text(app.popup_layer,"Не быть")!="","Question shown as actual mandatory choice")
	var saved=JSON.stringify(app.engine.pending_choice);app._hide_popup();await settle();app._restore_popup();await settle();expect(JSON.stringify(app.engine.pending_choice)==saved,"hide and reopen does not answer Question")
	app._choose_effect_option(1);await settle();expect(app.engine.pending_choice.action=="v13_fighter" and find_text(app.popup_layer,"Розенкранц")!="","NOT TO BE visibly asks which fighter pays damage")
	print("V13_UI checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
func has_cyrillic(node: Node) -> bool:
	if node is Control and not node.is_visible_in_tree():return false
	if node is Label or node is Button:
		var regex=RegEx.new();regex.compile("[А-Яа-яЁё]")
		if regex.search(node.text)!=null:return true
	for child in node.get_children():
		if has_cyrillic(child):return true
	return false
