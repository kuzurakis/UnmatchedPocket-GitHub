extends SceneTree

var app
var checks = 0
var failures = 0

func _initialize(): run.call_deferred()
func settle():
	for i in range(4): await process_frame
func expect(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("ABILITY_UI: " + label)
func card(hero: String, id: String) -> Dictionary:
	for c in app.engine.heroes[hero].cards:
		if str(c.id) == id: return c.duplicate(true)
	return {}
func find_text(node: Node, fragment: String) -> String:
	if node is Label and fragment in node.text: return node.text
	for child in node.get_children():
		var found = find_text(child,fragment)
		if not found.is_empty(): return found
	return ""
func start(own: String, enemy = "king_arthur", manual = false):
	if app.started:
		app._return_menu()
		await settle()
	app.engine.setup([own,enemy],1,23,"marmoreal",{"human_placement":manual})
	app._open_match()
	app.bot_timer.stop()
	await settle()
func finish_reports():
	for i in range(20):
		if app.engine.phase == "combat_report": app._continue_combat()
		elif app.engine.phase == "effect_move": app._finish_move()
		elif app.engine.phase == "effect_choice": app._choose_effect_option(0)
		else: return
		await settle()
	expect(false,"reports finish")
func put_enemies_near_hero() -> int:
	var e = app.engine
	var hero = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[hero].node)
	var target = int(e.nodes[home].neighbors[0])
	var used = [home,target]
	for f in e.fighters:
		if int(f.id) in [hero,foe]: continue
		for n in e.nodes:
			if not int(n.id) in used:
				f.node = int(n.id)
				used.append(int(n.id))
				break
	e.fighters[foe].node = target
	return foe
func run():
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	await start("medusa")
	await finish_reports()
	var e = app.engine
	var foe = put_enemies_near_hero()
	var hp = int(e.fighters[foe].hp)
	e.active = 1
	e.phase = "action"
	e.actions_left = 0
	e.end_turn()
	await settle()
	expect(e.active == 0 and e.phase == "effect_choice", "Medusa beginning of turn opens target selection")
	expect(app.popup_kind == "choice", "Medusa target selection visible")
	expect(e.fighters[foe].hp == hp, "Medusa does not damage before target is chosen")
	if e.phase == "effect_choice":
		expect(foe in e.pending_choice.get("allowed_fighters",[]),"enemy in Medusa zone is selectable")
		app._save_match()
		app._return_menu()
		await settle()
		app._resume_match()
		await settle()
		e = app.engine
		expect(e.phase == "effect_choice" and app.popup_kind == "choice", "Medusa pending target survives resume")
		app._choose_effect_option(e.pending_choice.allowed_fighters.find(foe))
		await settle()
		expect(e.fighters[foe].hp == hp-1,"Medusa selected enemy takes exactly one damage")
		expect(e.phase == "combat_report" and app.popup_kind == "report", "Medusa damage has persistent ability report")
		expect(find_text(app.popup_layer,"Медузы") != "", "ability report identifies Medusa")
		app._continue_combat()
		await settle()
		expect(e.phase == "action" and e.actions_left == 2,"Medusa ability costs no action")
	await start("sinbad")
	e = app.engine
	e.players[0].discard = [card("sinbad","voyage_to_the_cannibals_with_the_root_of_madness")]
	e.players[0].hand = [card("sinbad","voyage_home"),card("sinbad","voyage_to_the_island_that_was_a_whale")]
	app.selected_card = -1
	app._refresh()
	app._select_card(1)
	expect(app.boost_button.disabled,"Voyage without printed BOOST disables boost button")
	expect(app.hand_box.get_child(1)._stats.text.contains("—"),"Voyage without BOOST shows dash, not zero")
	app._select_card(0)
	app._toggle_boost()
	app._begin_move()
	expect(e.maneuver_distance == 5,"Home BOOST includes printed boost and new discarded voyage")
	expect(e._voyages(0) == 2,"Home enters discard before movement distance is finalized")
	expect(app.state_label.text.contains("2"),"Sinbad voyage count visible beside board")
	app._finish_move()
	await settle()
	await start("raptors","king_arthur",true)
	e = app.engine
	var positions: Array = []
	for step in range(3):
		var fid = int(e.setup_fighter)
		expect(fid >= 0,"each Raptor has individual placement")
		if fid < 0: break
		var legal = e.legal_setup_nodes(fid)
		expect(not legal.is_empty(),"Raptor has valid setup space")
		if legal.is_empty(): break
		positions.append(int(legal[0]))
		app._on_node(int(legal[0]))
	app._finish_move()
	await settle()
	expect(e.phase == "action" and positions.size() == 3,"all three Raptor heroes finish setup")
	expect(find_text(app.hud_left,"7 / 7 / 7") != "","HUD shows all three Raptor health values")
	var first = e.hero_fighter(0)
	e._damage(first,7)
	app._refresh()
	expect(e.players[0].alive,"losing one Raptor does not eliminate faction")
	expect(find_text(app.hud_left,"0 / 7 / 7") != "","HUD keeps defeated Raptor health alongside survivors")
	await start("ingen")
	e = app.engine
	expect(e.phase == "effect_move" and not e.pending_choice.get("legal",[]).is_empty(),"Muldoon beginning of turn offers trap cells")
	if e.phase == "effect_move" and not e.pending_choice.get("legal",[]).is_empty():
		app._on_node(int(e.pending_choice.legal[0]))
		await settle()
		expect(e.traps.size() == 1 and e.trap_supply(0) == 7,"placing trap consumes one of eight tokens")
		expect(e.phase == "combat_report", "trap placement has ability report")
		await finish_reports()
	await start("bruce_lee")
	e = app.engine
	var bruce = e.hero_fighter(0)
	var original = int(e.fighters[bruce].node)
	e.actions_left = 0
	e.end_turn()
	await settle()
	expect(e.phase == "effect_move", "Bruce end-of-turn movement waits for human")
	if e.phase == "effect_move":
		var destination = original
		for node in e.pending_choice.legal:
			if int(node) != original: destination = int(node); break
		app._on_node(destination)
		await settle()
		expect(destination != original and int(e.fighters[bruce].node) == destination,"Bruce can choose one-space step")
		await finish_reports()
	app.started = false
	print("ABILITY_UI_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
