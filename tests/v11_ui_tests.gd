extends "res://tests/v8_ui_tests.gd"
func run():
	root.size=Vector2i(1280,720)
	app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
	app._language_changed(0)
	app.engine.interactive=false;app.engine.setup(["little_red","king_arthur"],1,1111,"heorot")
	app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
	var copies=[]
	for pile in [app.engine.players[0].hand,app.engine.players[0].deck]:
		for c in pile:
			if c.id == "into_the_woods": copies.append(c.duplicate(true))
	app.engine.players[0].hand=copies
	app.engine.players[0].discard=[card("little_red","the_wolf_s_skin")]
	app._refresh();app._select_card(0);await settle()
	expect(app.detail_text.text.contains("Текущая корзинка: Нож") and app.detail_text.text.contains("Верхняя карта сброса:"),"selected Red card shows actual current basket")
	var labels=[]
	for view in app.hand_box.get_children():
		if view.get_script() == preload("res://scripts/card_view.gd"):
			expect(view._basket_badge.visible,"Red card has visible symbol badge")
			labels.append(view._basket_badge.text)
	labels.sort();expect(labels == ["Нож","Цветок","Шкура"],"three physical Woods copies display three distinct symbols")
	app._show_discards(0);await settle()
	expect(find_text(app.popup_layer,"Текущая корзинка: Нож") != "","discard browser identifies top-card basket")
	app._close_popup();app._return_menu();await settle()
	app.engine.interactive=false;app.engine.setup(["yennenga","king_arthur"],1,1111,"training")
	app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
	var g=app.engine;var foe=nearby_enemy()
	g.fighters[0].node=12;g.fighters[1].node=11;g.fighters[2].node=13;g.fighters[foe].node=17
	g.fighters[1].hp=1
	g.nodes[12].zones=[0];g.nodes[11].zones=[0];g.nodes[13].zones=[0]
	g.players[0].hand=[];g.players[1].hand=[{"id":"probe","name":"Probe","fighter":"any","type":"attack","value":3,"boost":1,"effects":[]}]
	g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(-1);app._refresh();await settle()
	expect(app.popup_kind == "choice" and g.pending_choice.action == "v9_damage","real combat UI shows Yennenga allocation")
	app._choose_effect_option(1);await settle()
	expect(not g.fighters[1].alive and g.pending_choice.ids == [2],"dead Archer disappears from choices")
	expect(find_text(app.popup_layer,"лучнику №2") != "" and find_text(app.popup_layer,"клетка 14") != "","surviving Archer retains token number and shows actual cell")
	var original=JSON.stringify(g.save_state());app._hide_popup();app._toggle_inspector_zoom();await settle()
	app._bot_tick();expect(JSON.stringify(g.save_state()) == original,"allocation can be hidden to inspect field without advancing")
	app._restore_popup();app._choose_effect_option(1);await settle();app._choose_effect_option(0);await settle()
	expect(g.fighters[0].hp == 14 and g.fighters[2].hp == 1 and g.last_combat.damage == 3,"UI commits chosen split and preserves combat result")
	print("V11_UI checks=%d failures=%d" % [checks,failures])
	app.started=false;app.queue_free();await process_frame;quit(1 if failures else 0)
