extends SceneTree
var checks = 0
var failures = 0
var app

func _initialize():
	run.call_deferred()

func expect(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("UI TEST: " + label)

func settle():
	await process_frame
	await process_frame

func select_metadata(option: OptionButton, value: String) -> bool:
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == value:
			option.select(i)
			return true
	return false

func new_match(hero = "alice", count = 2, map_id = "", enemy = ""):
	if app.started:
		app._return_menu()
		await settle()
	for i in range(app.sets.size()):
		if hero in app.sets[i].hero_ids:
			app.set_option.select(i)
			app._set_changed(i)
			break
	app._choose_hero(hero)
	app.count_option.select(count - 2)
	app._opponent_changed(count - 2)
	if enemy!="":expect(select_metadata(app.opponent_options[0],enemy),"fixed opponent for deterministic mechanic scenario")
	if map_id != "":
		expect(select_metadata(app.map_option, map_id), "requested map offered for player count")
		app._map_changed(0)
	app.placement_option.select(1)
	app._start_match()
	app.bot_timer.stop()
	await settle()

func card(hero: String, id: String) -> Dictionary:
	for c in app.engine.heroes[hero].cards:
		if str(c.id) == id or str(c.effect) == id:
			return c.duplicate(true)
	return {}

func nearby_enemy() -> int:
	var e = app.engine
	var human = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[human].node)
	var target = int(e.nodes[home].neighbors[0])
	var used = [home, target]
	for f in e.fighters:
		if f.id in [human, foe]: continue
		for node in e.nodes:
			if not int(node.id) in used:
				f.node = int(node.id)
				used.append(int(node.id))
				break
	e.fighters[foe].node = target
	return foe

func finish_reports():
	for i in range(30):
		match app.engine.phase:
			"attack_notice": app._continue_attack()
			"combat_report": app._continue_combat()
			"effect_move": app._finish_move()
			"effect_choice": app._choose_effect_option(0)
			_: return
		await settle()
	expect(false, "interactive flow must finish")

func run():
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app._language_changed(0)
	app.set_option.select(0)
	app._set_changed(0)
	await settle()
	expect(app.heroes.size() == 56, "forty playable factions loaded")
	expect(app.boards.size() == 28, "twenty-two real maps available")
	expect(app.sets.size() == 20 and app.set_option.item_count == 20, "fourteen official sets in menu")
	expect(app.card_images.size() == 56 and app.avatars.size() == 56, "all forty card and avatar catalogs loaded")
	await test_set_catalog()
	app.size_option.select(1)
	await new_match("alice", 4, "marmoreal")
	var e = app.engine
	expect(e.players.size() == 4 and e.nodes.size() == 31, "four-player Marmoreal setup")
	expect(e.interactive, "interactive pacing enabled")
	expect(e.alice_size[0] == "small", "Alice size follows menu")
	expect(app.game_ui.get_combined_minimum_size().x <= 1280, "game width fits")
	expect(app.game_ui.get_combined_minimum_size().y <= 800, "game height fits")
	expect(app.hand_box.get_child(0).card_image_path != "", "real card image in hand")
	var hand_count = e.players[0].hand.size()
	app._begin_move()
	expect(e.phase == "move" and e.players[0].hand.size() == hand_count + 1, "maneuver draws first")
	var drawn_index = e.players[0].hand.size() - 1
	var boost = int(e.players[0].hand[drawn_index].boost)
	var distance = e.maneuver_distance
	app._select_card(drawn_index)
	app._toggle_boost()
	expect(e.maneuver_boosted and e.maneuver_distance == distance + boost, "fresh draw can boost via UI")
	var legal = e.legal_moves(app.selected_fighter)
	expect(not legal.is_empty(), "real board has reachable cells")
	if not legal.is_empty():
		app._on_node(legal[-1])
		expect(e.fighters[app.selected_fighter].node == legal[-1], "tap real cell moves fighter")
	app._finish_move()
	expect(e.phase == "action" and e.actions_left == 1, "one maneuver leaves one action")
	var saved = int(e.fighters[e.hero_fighter(0)].node)
	app._save_match()
	app._return_menu()
	await settle()
	app._resume_match()
	await settle()
	expect(app.engine.fighters[app.engine.hero_fighter(0)].node == saved, "real map position survives save")
	expect(app.engine.alice_size[0] == "small", "Alice setup survives save")
	# Opponents, team order and manually selected starting cells from the menu.
	app._return_menu()
	await settle()
	app.count_option.select(3)
	app._opponent_changed(3)
	var wanted = ["king_arthur","medusa","sinbad"]
	for i in range(3):
		for option_index in range(app.opponent_options[i].item_count):
			if str(app.opponent_options[i].get_item_metadata(option_index)) == wanted[i]:
				app.opponent_options[i].select(option_index)
	app.start_slot_option.select(2)
	app._start_match()
	app.bot_timer.stop()
	await settle()
	e = app.engine
	expect(e.match_mode == "teams" and e.are_allies(0,2), "menu creates human and allied bot team")
	expect(e.players[1].hero_id == "king_arthur" and e.players[2].hero_id == "medusa" and e.players[3].hero_id == "sinbad", "menu preserves selected heroes and roles")
	expect(e.phase == "setup" and e.start_slots[0] == 2, "chosen hero start enters manual placement")
	for placement_step in range(8):
		if e.setup_fighter < 0: break
		var legal_start = e.legal_setup_nodes(e.setup_fighter)
		expect(not legal_start.is_empty(), "setup UI offers legal cells")
		app._on_node(int(legal_start[-1]))
	app._finish_move()
	await settle()
	expect(e.phase == "action" and app.hand_section.visible, "setup finishes and hand returns")
	var own_discard = card("alice","feint")
	e.players[0].discard.append(own_discard)
	app._show_discards(0)
	await settle()
	expect(app.popup_layer != null and has_texture(app.popup_layer), "public discard cards have images")
	app._zoom_discard_card(own_discard,"alice",0)
	app._close_popup()
	await settle()
	expect(app.popup_layer != null, "card zoom returns to discard browser")
	app._close_popup()
	await new_match("alice", 2,"","king_arthur")
	e = app.engine
	var foe = nearby_enemy()
	e.players[1].hand = []
	e.players[0].hand = [card("alice", "i_m_late_i_m_late")]
	app._refresh()
	app._select_card(0)
	app._play_selected()
	app._on_node(int(e.fighters[foe].node))
	await settle()
	expect(e.phase == "attack_notice" and app.popup_kind == "attack", "attack waits for notification")
	var old_hp = int(e.fighters[foe].hp)
	app._bot_tick()
	expect(e.phase == "attack_notice" and e.fighters[foe].hp == old_hp, "bots cannot skip announcement")
	app._continue_attack()
	await settle()
	expect(e.phase == "combat_report" and app.popup_kind == "report", "cards in persistent report")
	expect(e.fighters[foe].hp < old_hp, "combat damage reported")
	app._continue_combat()
	await settle()
	expect(e.phase == "effect_move", "after-combat movement waits for human")
	expect(not app.board.highlighted.is_empty(), "effect destinations highlighted")
	var moving = int(e.pending_choice.fighter)
	var original_node = int(e.fighters[moving].node)
	var destination = original_node
	for n in e.pending_choice.legal:
		if int(n) != original_node:
			destination = int(n)
			break
	app._on_node(destination)
	await settle()
	expect(destination != original_node and e.fighters[moving].node == destination, "human chooses effect destination")
	expect(e.phase == "combat_report" and e.combat_report.stage == "effects", "effects get separate report")
	app._continue_combat()
	await settle()
	expect(e.phase == "action", "confirmation resumes actions")
	e.active = 1
	e.actions_left = 2
	e.phase = "action"
	foe = nearby_enemy()
	var enemy_attack = card(str(e.players[1].hero_id), "feint")
	if enemy_attack.is_empty():
		for candidate in e.heroes[e.players[1].hero_id].cards:
			if e._attack_type(candidate) and e.can_use_card(candidate,foe):
				enemy_attack = candidate.duplicate(true)
				break
	e.players[1].hand = [enemy_attack]
	e.players[0].hand = [card("alice", "feint")]
	expect(e.attack(foe, e.hero_fighter(0), 0), "bot attack begins")
	await settle()
	app._continue_attack()
	await settle()
	expect(e.phase == "defend" and app.popup_layer == null, "notice transitions to defense")
	expect("feint" not in app.hint_label.text.to_lower(), "facedown identity hidden")
	app._select_card(0)
	app._play_selected()
	await settle()
	expect(e.phase == "combat_report", "defense resolves into report")
	await finish_reports()
	expect(e.pending_combat.is_empty(), "combat flow cleared")
	e.logs.append("Старое событие")
	e.logs.append("Новое событие")
	app._show_log()
	await settle()
	expect(find_text(app.popup_layer, "Старое событие").begins_with("Новое событие"), "journal newest first")
	app._close_popup()
	e.players[0].hand = [card("alice", "looking_glass")]
	e.players[0].hand[0].text = "Длинное описание эффекта. ".repeat(100)
	app.selected_card = -1
	app._select_card(0)
	await settle()
	app.detail_scroll.scroll_vertical = 100
	await settle()
	expect(app.detail_scroll.scroll_vertical > 0, "long description scrolls")
	var scroll_position = app.detail_scroll.scroll_vertical
	app._refresh()
	await settle()
	expect(app.detail_scroll.scroll_vertical == scroll_position, "refresh preserves scroll")
	app._zoom_selected()
	await settle()
	expect(app.popup_layer != null and has_texture(app.popup_layer), "zoom shows actual front")
	app._close_popup()
	await new_match("king_arthur", 2,"","medusa")
	e = app.engine
	foe = nearby_enemy()
	e.players[1].hand = []
	e.players[0].hand = [card("king_arthur", "feint"), card("king_arthur", "excalibur")]
	app._refresh()
	app._select_card(0)
	app._toggle_boost()
	app._select_card(1)
	app._play_selected()
	old_hp = int(e.fighters[foe].hp)
	app._on_node(int(e.fighters[foe].node))
	app._continue_attack()
	await settle()
	expect(e.players[0].hand.is_empty(), "Arthur spends attack and boost")
	expect(e.fighters[foe].hp == old_hp - 7, "Arthur applies six plus one boost")
	await finish_reports()
	for entry in [{"hero":"robin_hood","map":"sherwood_forest","nodes":30},{"hero":"bigfoot","map":"yukon","nodes":31}]:
		await new_match(entry.hero,2,entry.map)
		expect(app.engine.players[0].hero_id == entry.hero and app.engine.nodes.size() == entry.nodes, "new hero starts on its real two-player map")
		expect(app.engine.start_slots.size() == 2 and app.engine.start_slots[0] != app.engine.start_slots[1], "two-player map uses two different official starts")
		expect(app.hand_box.get_child(0).card_image_path != "", "new hero hand uses real card image")
	print("UI_TESTS checks=%d failures=%d" % [checks, failures])
	app.started = false
	quit(1 if failures else 0)

func test_set_catalog():
	for index in range(app.sets.size()):
		app.set_option.select(index)
		app._set_changed(index)
		await settle()
		var box = app.sets[index]
		var shown: Array = []
		for entry in app.hero_buttons: shown.append(str(entry.id))
		expect(shown.size() == box.hero_ids.size(), "set menu displays correct number of heroes")
		for id in box.hero_ids:
			expect(str(id) in shown, "hero belongs to displayed set: " + str(id))
			var hero = app._hero_data(str(id))
			expect(int(hero.cards.reduce(func(total,c): return total+int(c.count),0)) == (35 if str(id) == "buffy" else 36 if str(id)=="geralt_of_rivia" else 22 if str(id)=="daredevil" else 20 if str(id)=="elektra" else 30), "catalog includes alternate Buffy packs and Geralt gear")
			app._hero_card_pressed(str(id))
			await settle()
			expect(app.chosen_hero == id and app.popup_layer != null, "hero card selects hero and opens full rules")
			expect(find_text(app.popup_layer,str(hero.ability)) != "", "full hero ability appears without menu truncation")
			expect(has_texture(app.popup_layer), "full hero rules show actual portrait")
			app._close_popup()
			await settle()
	app.count_option.select(0)
	app._opponent_changed(0)
	expect(app.map_option.item_count == 28, "duel offers all twenty-two maps")
	for id in ["sherwood_forest","yukon","raptor_paddock","thrilla_in_manilla","tsing_shan_monastery"]:
		expect(select_metadata(app.map_option,id), "new official duel map listed")
		app._map_changed(0)
		expect(app.start_slot_option.item_count == 2, "new duel map exposes only its two printed starts")
	for mode in [1,2,3]:
		app.count_option.select(mode)
		app._opponent_changed(mode)
		expect(app.map_option.item_count == 19, "three/four-player modes filter out two-start maps")
		for i in range(app.map_option.item_count):
			expect(str(app.map_option.get_item_metadata(i)) in ["marmoreal", "sarpedon", "soho", "baskerville_manor", "sunnydale_high", "the_bronze", "hanging_gardens", "point_pleasant", "mcminnville_or", "globe_theatre", "kaer_morhen", "fayrlund_forest", "naglfar", "streets_of_novigrad", "hells_kitchen", "the_raft", "navy_pier", "helicarrier", "sanctum_sanctorum"], "multiplayer offers four-start boards only")
		expect(app.start_slot_option.item_count == 4, "multiplayer start selection matches printed four starts")
	app.count_option.select(0)
	app._opponent_changed(0)
	app.set_option.select(0)
	app._set_changed(0)
	await settle()

func find_text(node: Node, contains: String) -> String:
	if node is Label and contains in node.text: return node.text
	for child in node.get_children():
		var found = find_text(child, contains)
		if found != "": return found
	return ""

func has_texture(node: Node) -> bool:
	if node is TextureRect and node.texture != null: return true
	for child in node.get_children():
		if has_texture(child): return true
	return false
