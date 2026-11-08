extends SceneTree
const Model = preload("res://scripts/game_engine.gd")
var checks = 0
var failures = 0
var app
func _initialize(): run.call_deferred()
func expect(ok: bool,label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("MULDOON: " + label)
func settle():
	for n in range(4): await process_frame
func card(g,id: String):
	for c in g.heroes.ingen.cards:
		if str(c.id) == id: return c.duplicate(true)
	expect(false,"known card " + id)
	return {}
func game(ids = ["ingen","king_arthur"]):
	var g = Model.new()
	g.setup(ids,1,707,"training")
	g.interactive = true
	g.traps.clear()
	g._trap_stock[0] = 8
	return g
func clone(g):
	var other = Model.new()
	expect(other.load_state(JSON.parse_string(JSON.stringify(g.save_state()))),"resume suspended trap or selection state")
	return other
func choose_kind(g,kind: String):
	var found = -1
	for i in range(g.pending_choice.get("_options",[]).size()):
		if str(g.pending_choice._options[i].kind) == kind: found = i; break
	expect(found >= 0,"distinct effect remains selectable: " + kind)
	if found >= 0: expect(g.choose_effect_option(found),"effect selection accepted")
func finish(g):
	for n in range(50):
		match g.phase:
			"action","discard","game_over": return g
			"combat_report": g.continue_combat()
			"effect_move":
				g = clone(g)
				if not g.pending_choice.get("legal",[]).is_empty(): expect(g.choose_effect_node(int(g.pending_choice.legal[-1])),"manual token/revival destination accepted")
				else: expect(g.skip_effect(),"skip empty placement")
			_: expect(false,"supported resolution " + g.phase); return g
	expect(false,"placement terminates")
	return g
func test_combinations():
	for pair in [["place_traps","draw"],["draw","place_traps"],["place_traps","revive_all"],["revive_all","place_traps"],["draw","revive_all"],["revive_all","draw"]]:
		var g = game()
		for f in g.fighters:
			if int(f.owner) == 0 and not f.hero: f.alive = false; f.hp = 0
		g.players[0].hand = [card(g,"call_for_backup")]
		expect(g.scheme(g.hero_fighter(0),0),"Call for Backup starts")
		choose_kind(g,pair[0])
		expect(g.phase == "effect_choice" and g.traps.is_empty() and g.players[0].hand.is_empty(),"first choice is held until both effects are chosen")
		expect(g.pending_choice._options.size() == 2,"cannot choose same effect twice")
		g = clone(g)
		choose_kind(g,pair[1])
		g = finish(g)
		expect(g.traps.size() == (3 if "place_traps" in pair else 0),"chosen trap effect places three tokens")
		expect(g.trap_supply(0) == (5 if "place_traps" in pair else 8),"only actual placements spend the finite reserve")
		expect(g.players[0].hand.size() == (2 if "draw" in pair else 0),"chosen draw happens once")
		var workers = 0
		for f in g.fighters:
			if int(f.owner) == 0 and not f.hero and f.alive: workers += 1
		expect(workers == (3 if "revive_all" in pair else 0),"chosen revival restores every worker")
		expect(g.actions_left == 1 and g.phase == "action","scheme costs exactly one action")
func test_legal_spaces():
	var g = game(["ingen","invisible_man","spike"])
	var legal = g.legal_trap_nodes(0,true)
	var zone = g.legal_trap_nodes(0)
	var outside = -1
	for node in legal:
		if not node in zone: outside = int(node); break
	expect(outside >= 0,"board has free spaces outside Muldoon zone")
	expect(not g._place_trap(0,outside) and g.trap_supply(0) == 8,"normal start ability cannot place outside zone")
	expect(g._place_trap(0,outside,true) and g.trap_supply(0) == 7,"card placement accepts a free space outside zone")
	expect(not g._place_trap(0,outside,true) and g.trap_supply(0) == 7,"duplicate trap is rejected without spending stock")
	legal = g.legal_trap_nodes(0,true)
	var fog_space = int(legal[0])
	var shadow_space = int(legal[1])
	g.fog_tokens[0].node = fog_space
	g.shadow_tokens.append({"owner":2,"id":0,"node":shadow_space})
	expect(not g.legal_trap_nodes(0,true).has(fog_space) and not g._place_trap(0,fog_space,true),"fog prevents trap placement")
	expect(not g.legal_trap_nodes(0,true).has(shadow_space) and not g._place_trap(0,shadow_space,true),"shadow prevents trap placement")
	expect(not g._place_trap(0,int(g.fighters[g.hero_fighter(1)].node),true),"fighter prevents trap placement")
	for stock in [0,2]:
		g = game()
		g._trap_stock[0] = stock
		g.players[0].hand = [card(g,"call_for_backup")]
		g.scheme(g.hero_fighter(0),0)
		choose_kind(g,"place_traps")
		choose_kind(g,"draw")
		g = finish(g)
		expect(g.traps.size() == stock and g.trap_supply(0) == 0,"exhausted reserve limits placement, never replenishes")
		expect(g.players[0].hand.size() == 2 and g.phase == "action","no reserve cannot block the other chosen effect")
	g = game()
	g.players[0].hand = [card(g,"call_for_backup")]
	g.scheme(g.hero_fighter(0),0)
	choose_kind(g,"place_traps")
	choose_kind(g,"draw")
	g.choose_effect_node(int(g.pending_choice.legal[0]))
	expect(g.skip_effect(),"may stop before placing all three")
	g = finish(g)
	expect(g.traps.size() == 1 and g.trap_supply(0) == 7 and g.players[0].hand.size() == 2,"early stop preserves unspent tokens and completes draw")
func test_detonation():
	var g = game()
	var own = g.hero_fighter(0)
	var foe = g.hero_fighter(1)
	for f in g.fighters:
		if int(f.id) not in [own,foe,1]: f.alive = false; f.hp = 0
	g.fighters[own].node = 0
	g.fighters[1].node = 11
	g.fighters[foe].node = 13
	g.traps = [{"owner":0,"node":12}]
	g._trap_stock[0] = 7
	g.players[0].hand = [card(g,"remote_detonation")]
	var hp = int(g.fighters[foe].hp)
	expect(g.scheme(own,0) and g.phase == "effect_move" and 12 in g.pending_choice.legal,"hero can play Any detonation when a worker shares trap zone")
	expect(g.choose_effect_node(12),"select a trap for remote detonation")
	g = finish(g)
	expect(g.fighters[foe].hp == hp-1 and g.traps.is_empty(),"remote blast damages adjacent enemy and removes trap")
	expect(g.players[0].hand.size() == 1 and g.trap_supply(0) == 7,"removing trap draws one without recycling stock")
	g.traps = [{"owner":0,"node":12}]
	g.fighters[1].alive = false
	g.fighters[1].hp = 0
	g.players[0].hand = [card(g,"remote_detonation")]
	g.scheme(own,0)
	g = finish(g)
	expect(g.traps.size() == 1 and g.players[0].hand.is_empty(),"without a live worker detonation has no effect or draw")
func test_ui():
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	app.engine.setup(["ingen","king_arthur"],1,707,"marmoreal")
	app._open_match()
	app.bot_timer.stop()
	await settle()
	if app.engine.phase == "effect_move": app._skip_ability()
	await settle()
	if app.engine.phase == "combat_report": app._continue_combat()
	await settle()
	var e = app.engine
	e.traps.clear()
	e._trap_stock[0] = 8
	e.players[0].hand = [card(e,"call_for_backup")]
	app.selected_card = -1
	app._refresh()
	app._select_card(0)
	app._play_selected()
	await settle()
	expect(app.popup_kind == "choice","scheme opens effect-selection modal")
	app._choose_effect_option(0)
	await settle()
	expect(e.phase == "effect_choice" and e.traps.is_empty(),"UI asks for second effect before placing traps")
	app._choose_effect_option(1)
	await settle()
	expect(e.phase == "effect_move" and not app.board.highlighted.is_empty(),"UI exposes legal map targets for traps")
	for step in range(3):
		var target = int(e.pending_choice.legal[-1])
		for node in e.pending_choice.legal:
			if not e._same_zone(int(e.fighters[e.hero_fighter(0)].node),int(node)): target = int(node); break
		app._on_node(target)
		await settle()
		expect(e.traps.size() == step+1,"board tap places a real trap")
		if step == 0:
			app._save_match()
			app._return_menu()
			await settle()
			app._resume_match()
			app.bot_timer.stop()
			await settle()
			e = app.engine
			expect(e.pending_choice.remaining_count == 2 and e.trap_supply(0) == 7 and e.traps.size() == 1,"resume preserves remaining placements and spent stock")
	expect(e.phase == "combat_report" and e.players[0].hand.size() == 2,"after third tap remaining effect draws cards and waits for report")
	app._continue_combat()
	await settle()
	expect(e.phase == "action" and e.actions_left == 1,"confirmed trap scheme returns control")
	app.started = false
func run():
	root.size = Vector2i(1280,720)
	test_combinations()
	test_legal_spaces()
	test_detonation()
	await test_ui()
	print("MULDOON_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
