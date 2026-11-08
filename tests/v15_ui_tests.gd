extends "res://tests/v13_ui_tests.gd"
func run():
	root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app._language_changed(0)
	app.set_option.select(13);app._set_changed(13);await settle();expect(app.hero_buttons.size()==3,"Realms Fall filter offers implemented Eredin")
	app._choose_hero("eredin");app._show_hero_info("eredin");await settle();expect(find_text(app.popup_layer,"Пока все ваши Всадники")!="","Eredin sheet opens")
	app._close_popup();app.engine.interactive=false;app.engine.setup(["eredin","geralt_of_rivia","ciri","ancient_leshen"],1,1515,"naglfar",{"mode":"teams"});app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
	expect(app.engine.nodes.size()==28 and app.engine.fighters.size()==12,"Naglfar and Riders reach actual UI")
	app._show_map_rules(true);await settle();expect(find_text(app.popup_layer,"палубы")!="","Naglfar connector rules visible");app._hide_popup();await settle();expect(not app.popup_layer.visible,"board rules hide for inspection");app._restore_popup();await settle();expect(app.popup_layer.visible,"same rules panel returns");app._close_popup()
	app._show_player_info(0);await settle();expect(find_text(app.popup_layer,"ярости")!="","in-game Eredin ability readable");app._close_popup()
	for f in app.engine.fighters:
		if f.owner==0 and not f.hero:f.alive=false;f.hp=0
	app.engine.players[0].ongoing=card("eredin","might_of_the_aen_elle");app._refresh();await settle()
	for language in ["en","nb","es"]:
		app.I18n.set_language(language);app._show_player_info(0);await settle();expect(not has_cyrillic(app.popup_layer),"Eredin full sheet translated "+language);app._close_popup()
		app._show_special_state(0);await settle();expect(not has_cyrillic(app.popup_layer),"rage and ongoing translated "+language);app._close_popup()
	app.I18n.set_language("ru");app.engine.players[0].hand=[card("eredin","implacable")];app.engine.fighters[app.engine.hero_fighter(1)].node=app.engine.nodes[int(app.engine.fighters[0].node)].neighbors[0];app.selected_card=-1;app.selected_fighter=0;app._refresh();await settle();app._select_card(0);app._play_selected();await settle();expect(app.attack_mode,"Implacable uses real attack interaction while enraged")

	app.engine.combat_report={"kind":"combat","stage":"combat","attacker":app.engine.hero_fighter(1),"target":app.engine.hero_fighter(2),"defense_card_owner":0,"attack_card":card("geralt_of_rivia","igni"),"defense_card":card("eredin","portal_defense"),"attack_value":3,"defense_value":0,"damage":3};app._show_combat_report();await settle()
	var found=false
	for view in cards_under(app.popup_layer):
		if view.card_data.id=="portal_defense":found=view.card_hero_id=="eredin" and not view.card_image_path.is_empty()
	expect(found,"allied replacement report shows Eredin original defense scan")
	print("V15_UI checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)

func has_cyrillic(node: Node) -> bool:
	if node is Control and not node.is_visible_in_tree():return false
	var bad=false
	if node is Label or node is Button:
		var regex=RegEx.new();regex.compile("[А-Яа-яЁё]")
		if regex.search(node.text)!=null:print("UNTRANSLATED ",app.I18n.language," ",node.text);bad=true
	for child in node.get_children():
		if has_cyrillic(child):bad=true
	return bad

func cards_under(node: Node) -> Array:
	var result=[]
	if node.get_script()==preload("res://scripts/card_view.gd"):result.append(node)
	for child in node.get_children():result.append_array(cards_under(child))
	return result
