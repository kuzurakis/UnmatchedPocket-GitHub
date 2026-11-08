extends "res://tests/v13_ui_tests.gd"
func cards_under(node: Node) -> Array:
	var result=[]
	if node.get_script()==preload("res://scripts/card_view.gd"):result.append(node)
	for child in node.get_children():result.append_array(cards_under(child))
	return result
func run():
	root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app._language_changed(0)
	app.set_option.select(12);app._set_changed(12);app._choose_hero("geralt_of_rivia");await settle();expect(app.hero_buttons.size()==3,"Witcher set filters three heroes")
	app._show_hero_info("geralt_of_rivia");await settle();expect(find_text(app.popup_layer,"Выбрать снаряжение Геральта")!="","hero sheet links gear setup")
	for screen in [Vector2i(960,540),Vector2i(1280,720)]:
		root.size=screen;await settle();app._show_geralt_gear();await settle();var choices=cards_under(app.popup_layer)
		expect(choices.size()==6,"six equipment cards offered at "+str(screen))
		for view in choices:
			var panel=view.get_parent();expect(panel.get_global_rect().end.x<=app.get_viewport_rect().end.x-12,"equipment description column fits viewport")
		app._close_popup()
	var selected={"sword":"silver","armor":"forgotten","potion":"blizzard"};app._show_geralt_gear();await settle()
	for view in cards_under(app.popup_layer):
		if selected[str(view.get_meta("gear_slot"))]==str(view.get_meta("gear_option")):view.button_pressed=true;view.pressed.emit()
	expect(app.geralt_gear==selected,"actual card buttons update all three gear choices")
	app._close_popup();app.placement_option.select(1);app._start_match();app.bot_timer.stop();await settle()
	expect(app.engine.players[0].gear==selected,"menu gear reaches real game setup")
	var pile=app.engine.players[0].hand+app.engine.players[0].deck
	expect(pile.size()==30 and pile.all(func(c):return not c.has("gear_slot") or str(c.gear_option)==selected[str(c.gear_slot)]),"game deck excludes unselected gear")
	app.engine.players[0].ongoing=card("geralt_of_rivia","gear_tawny_owl");app._show_player_info(0);await settle();app._show_special_state(0);await settle()
	expect(find_text(app.popup_layer,"Активный постоянный приём")!="" and find_text(app.popup_layer,"Неясыть")!="","ongoing scheme visible in character panel")
	var toggles=find_toggles(app.popup_layer);expect(toggles.size()==1,"Owl preference is a real control");toggles[0].button_pressed=false;await settle();expect(not app.engine.players[0].owl_ignore,"Owl preference updates saved engine state")
	app._close_popup();app._return_menu();await settle();app.engine.interactive=false;app.engine.setup(["ciri","geralt_of_rivia","ancient_leshen"],1,1414,"kaer_morhen");app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
	app.engine.players[0].hand=[card("ciri","lion_cub_of_cintra")];app.engine.players[0].discard=[]
	for i in range(7):app.engine.players[0].discard.append(card("ciri","zireael"))
	app._refresh();await settle();expect(app.hand_box.get_child(0)._basket_badge.text=="Источник","Source badge visible on hand card")
	app._show_special_state(0);await settle();expect(find_text(app.popup_layer,"Источник: 7")!="" and find_text(app.popup_layer,"эффекты нельзя отменить")!="","Source count and protection visibly reported")
	app._hide_popup();await settle();app._restore_popup();await settle();expect(app.engine._v14.source_count(0)==7,"hide and restore preserves Source state")
	for lang in ["en","nb","es"]:
		app.I18n.set_language(lang)
		for owner in range(3):app._show_special_state(owner);await settle();expect(not has_cyrillic(app.popup_layer),"Witcher state translated "+lang+" "+str(owner));app._close_popup()
		app._show_geralt_gear();await settle();expect(not has_cyrillic(app.popup_layer),"all gear descriptions translated "+lang);app._close_popup()
	print("V14_UI checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
func find_toggles(node: Node) -> Array:
	var result=[]
	if node is CheckButton:result.append(node)
	for child in node.get_children():result.append_array(find_toggles(child))
	return result
