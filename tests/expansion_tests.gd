extends SceneTree
const Model = preload("res://scripts/game_engine.gd")
var checks = 0
var failures = 0
var matches = 0

func _initialize(): run.call_deferred()
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("EXPANSION: " + label)
func game(ids: Array, mode = "ffa", board = "training"):
	var g = Model.new()
	g.setup(ids,1,52,board,{"mode":mode})
	for p in g.players: p.bot = true
	return g
func card(g, owner: int, id: String) -> Dictionary:
	for c in g.heroes[g.players[owner].hero_id].cards:
		if str(c.id) == id: return c.duplicate(true)
	check(false,"known card " + id)
	return {}
func clone(g):
	var restored = Model.new()
	check(restored.load_state(JSON.parse_string(JSON.stringify(g.save_state()))),"JSON round trip")
	return restored
func adjacent(g, own = -1, foe = -1):
	if own < 0: own = g.hero_fighter(0)
	if foe < 0: foe = g.hero_fighter(1)
	var used = [12,13]
	for f in g.fighters:
		if int(f.id) in [own,foe]: continue
		for n in g.nodes:
			if not int(n.id) in used:
				f.node = int(n.id)
				used.append(int(n.id))
				break
	g.fighters[own].node = 12
	g.fighters[foe].node = 13
	g.players[1].hand = []
	return foe
func advance(g):
	match g.phase:
		"attack_notice": check(g.continue_attack(),"notice")
		"combat_report": check(g.continue_combat(),"report")
		"effect_choice": check(g.choose_effect_option(0),"choose effect")
		"effect_move":
			if int(g.pending_choice.get("fighter",-1)) < 0 and not g.pending_choice.get("allowed_fighters",[]).is_empty():
				check(g.choose_effect_fighter(int(g.pending_choice.allowed_fighters[0])),"choose fighter")
			if not g.pending_choice.get("legal",[]).is_empty(): check(g.choose_effect_node(int(g.pending_choice.legal[-1])),"choose node")
			else: check(g.skip_effect(),"skip empty movement")
		"defend":
			var legal = g.legal_defenses()
			check(g.defend(int(legal[0]) if not legal.is_empty() else -1),"defend")
		"action": g._bot_action()
		"move":
			for f in g.fighters:
				if f.alive and int(f.owner) == int(g.active):
					var legal = g.legal_moves(int(f.id))
					if not legal.is_empty(): g.move_fighter(int(f.id),int(legal[-1]))
			g.finish_maneuver()
		"discard": g.discard_card(0)
		_: check(false,"supported phase " + str(g.phase))
func finish(g):
	for step in range(40):
		if g.phase in ["action","discard","game_over"]: return
		advance(g)
	check(false,"effect flow finishes")
func run():
	test_medusa_sinbad()
	test_bruce()
	test_traps()
	test_raptors_and_timing()
	test_all_cards()
	test_matches()
	print("EXPANSION_TESTS checks=%d failures=%d matches=%d" % [checks,failures,matches])
	quit(1 if failures else 0)

func test_medusa_sinbad():
	var g = game(["medusa","king_arthur","sinbad","robin_hood"],"teams")
	var foe = adjacent(g)
	var ally = g.hero_fighter(2)
	g.fighters[ally].node = 17
	g.interactive = true
	g.players[0].bot = false
	var hp = int(g.fighters[foe].hp)
	g._start_turn_ability()
	check(g.phase == "effect_choice" and g.pending_choice.allowed_fighters.has(foe),"Medusa offers enemy in shared zone")
	check(not g.pending_choice.allowed_fighters.has(ally),"Medusa cannot hit allied bot")
	g = clone(g)
	g.choose_effect_option(g.pending_choice.allowed_fighters.find(foe))
	check(g.fighters[foe].hp == hp-1 and g.phase == "combat_report", "Medusa exact one damage and report")
	g.continue_combat()
	check(g.actions_left == 2 and g.phase == "action", "Medusa does not spend action")
	g._start_turn_ability()
	check(g.skip_effect(),"Medusa may skip optional damage")
	finish(g)
	check(g.fighters[foe].hp == hp-1,"skipping does not damage")
	g = game(["sinbad","king_arthur"])
	g.players[0].discard = [card(g,0,"voyage_home")]
	g.players[0].hand = [card(g,0,"voyage_to_the_island_that_was_a_whale")]
	check(not g.begin_maneuver(0) and g.actions_left == 2,"Voyage without BOOST rejected without spending action")
	check(g._movement(0) == 3,"discarded voyage grants movement")
	g.players[0].discard = [card(g,0,"voyage_to_the_island_that_was_a_whale")]
	g.players[0].hand = [card(g,0,"voyage_home")]
	g.begin_maneuver(0)
	check(g.maneuver_distance == 5,"Home adds printed BOOST and newly discarded voyage movement")
	g = clone(g)
	check(g.maneuver_distance == 5 and g._voyages(0) == 2,"Sinbad movement bonus survives save")
	for attack_id in ["voyage_to_the_island_that_was_a_whale","regroup"]:
		g = game(["sinbad","king_arthur"])
		foe = adjacent(g)
		g.players[0].discard = [card(g,0,"voyage_home")]
		g.players[0].hand = [card(g,0,attack_id)]
		g.attack(g.hero_fighter(0),foe,0)
		check(g.last_combat.attack_value == (3 if attack_id.begins_with("voyage_") else 1),"voyage attack bonus applies only to printed voyage effect")
	g = game(["sinbad","king_arthur"])
	foe = adjacent(g)
	g.players[0].discard = [card(g,0,"voyage_home")]
	g.players[0].hand = [card(g,0,"voyage_to_the_island_that_was_a_whale")]
	g.players[1].hand = [card(g,1,"feint")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 2,"Feint cancels printed voyage attack bonus")

func test_bruce():
	var g = game(["bruce_lee","king_arthur"])
	var foe = adjacent(g)
	g.players[0].hand = [card(g,0,"jeet_kune_do_wrist_lock")]
	g.attack(0,foe,0)
	check(g.actions_left == 2,"Jeet Kune Do grants additional action after attack")
	g = game(["bruce_lee","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"jeet_kune_do_wrist_lock")]
	g.players[1].hand = [card(g,1,"feint")]
	g.attack(0,foe,0)
	check(g.actions_left == 1,"cancelled Jeet Kune Do grants no action")
	g = game(["bruce_lee","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"little_dragon")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 6 and g.players[0].hand.size() == 2,"empty-hand Little Dragon value six then draws two")
	g = game(["bruce_lee","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"nunchaku"),card(g,0,"feint")]
	g.scheme(0,0)
	check(g.actions_left == 2 and g.players[0].turn_attack_bonus == 1,"Nunchaku action refund and turn bonus")
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 3,"Nunchaku increases ordinary attack")
	g = game(["bruce_lee","king_arthur"])
	foe = adjacent(g,0,g.hero_fighter(1)+1)
	g.fighters[foe].hp = 2
	g.players[0].hand = [card(g,0,"one_inch_punch")]
	g.scheme(0,0)
	check(g.players[0].hand.size() == 1 and g.players[0].hand[0].id == "one_inch_punch","One Inch Punch returns after defeating a sidekick while match continues")
	g = game(["bruce_lee","king_arthur"])
	g.players[0].discard = [card(g,0,"jeet_kune_do_wrist_lock")]
	g.players[0].hand = [card(g,0,"hoo_whaaaaaa")]
	g.interactive = true
	g.players[0].bot = false
	g.scheme(0,0)
	check(g.phase == "effect_choice" and g.pending_choice.action == "retrieve_tag","Bruce chooses exact Jeet Kune Do retrieval")
	g.choose_effect_option(0)
	finish(g)
	check(g.players[0].hand[0].id == "jeet_kune_do_wrist_lock" and g.actions_left == 2,"retrieval and action gain both resolve")

func test_traps():
	var g = game(["ingen","king_arthur"])
	g.traps.clear()
	g._trap_stock[0] = 8
	var foe = g.hero_fighter(1)
	var hero = g.hero_fighter(0)
	adjacent(g)
	g.fighters[hero].node = 5
	g.fighters[1].node = 21
	g.fighters[2].node = 22
	g.fighters[3].node = 23
	g.fighters[5].node = 24
	check(g._place_trap(0,1) and g.trap_supply(0) == 7,"trap placement spends finite token")
	g = clone(g)
	check(g.traps.size() == 1 and g.trap_supply(0) == 7,"trap and remaining stock survive JSON")
	g.fighters[foe].node = 2
	g.active = 1
	g.phase = "action"
	g.begin_maneuver()
	check(g.legal_moves(foe).has(1) and not g.legal_moves(foe).has(0),"enemy trap blocks movement past it")
	var hp = int(g.fighters[foe].hp)
	var hand = g.players[0].hand.size()
	g.move_fighter(foe,1)
	check(g.fighters[foe].hp == hp-1 and g.traps.is_empty(),"trap entering deals one damage and removes token")
	check(g.players[0].hand.size() == hand+1 and g.trap_supply(0) == 7,"removed trap draws one card and is not replenished")
	g = game(["ingen","king_arthur","robin_hood","bigfoot"],"teams")
	g.traps.clear()
	g._trap_stock[0] = 8
	adjacent(g)
	var legal = g.legal_trap_nodes(0)
	check(not legal.is_empty(),"trap has an empty hero-zone space")
	var node = int(legal[0])
	g._place_trap(0,node)
	var ally = g.hero_fighter(2)
	hp = int(g.fighters[ally].hp)
	g._enter_node(ally,node)
	check(g.traps.size() == 1 and g.fighters[ally].hp == hp,"ally may enter trap freely")
	g = game(["ingen","king_arthur"])
	foe = adjacent(g)
	g.traps = [{"owner":0,"node":8}]
	g._trap_stock[0] = 7
	var worker = 1
	g.fighters[worker].node = 7
	hp = int(g.fighters[foe].hp)
	hand = g.players[0].hand.size()
	g._detonate_trap(0,8)
	check(g.fighters[foe].hp == hp-1 and g.traps.is_empty() and g.players[0].hand.size() == hand+1,"remote detonation damages adjacent enemy and draws on return")
	g = game(["ingen","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"shoot_her")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 5,"Muldoon first action Shoot Her value five")
	g.players[0].actions_taken = 17
	g.active = 1
	g.phase = "action"
	g.end_turn()
	check(g.players[0].actions_taken == 0,"action ordinal resets on next own turn")
	g.players[0].hand = [card(g,0,"shoot_her")]
	g.players[1].hand = []
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 5,"Shoot Her first-action bonus works on later turns")

func test_raptors_and_timing():
	var g = game(["raptors","king_arthur"])
	var foe = adjacent(g)
	g.fighters[1].node = 8
	g.fighters[2].node = 18
	g.players[0].hand = [card(g,0,"eviscerate")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 7,"two other adjacent Raptors give attack plus two")
	g = game(["raptors","king_arthur"])
	g.players[0].deck = []
	g._draw(0)
	check(g.fighters[0].hp == 5 and g.fighters[1].hp == 5 and g.fighters[2].hp == 5,"exhaustion damages each of three heroes")
	g._damage(0,7)
	check(g.players[0].alive and g.hero_fighter(0) == 1,"one Raptor defeat retains faction and living representative")
	g._damage(1,7)
	check(g.players[0].alive,"two Raptor defeats do not eliminate faction")
	g._damage(2,7)
	check(not g.players[0].alive and g._check_winner() and g.winner == 1,"only last Raptor defeat loses")
	g = game(["raptors","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"decoy")]
	g.players[1].hand = [card(g,1,"feint")]
	g.active = 1
	g.interactive = true
	g.players[0].bot = false
	g.attack(foe,0,0)
	g.continue_attack()
	g.defend(0)
	check(g.phase == "effect_move" and g.pending_choice.kind == "decoy","defender immediate Decoy acts before attacker Feint")
	g = clone(g)
	g.choose_effect_fighter(1)
	var destination = int(g.pending_choice.legal[0])
	g.choose_effect_node(destination)
	check(g.phase == "combat_report" and g.fighters[1].node == destination and g.combat_report.defense_cancelled,"later Feint does not undo resolved immediate placement")
	g = game(["medusa","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"second_shot_3"),card(g,0,"gaze_of_stone")]
	g.interactive = true
	g.players[0].bot = false
	g.attack(0,foe,0)
	g.continue_attack()
	check(g.phase == "effect_choice" and g.pending_choice.action == "combat_boost","printed optional BOOST waits for human after reveal")
	g = clone(g)
	g.choose_effect_option(0)
	check(g.phase == "combat_report" and g.combat_report.attack_value == 7,"chosen combat BOOST survives saved pre-combat context")
	g = game(["raptors","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"disengage")]
	g.interactive = true
	g.players[0].bot = false
	g.attack(0,foe,0)
	g.continue_attack()
	g.continue_combat()
	check(g.phase == "effect_move" and g.pending_choice.legal.has(12),"same-zone placement permits staying in the fighter's own space")
	g.choose_effect_node(12)
	check(g.phase == "combat_report" and g.fighters[0].node == 12,"mandatory placement can finish without changing space")
	g = game(["bruce_lee","king_arthur"],"ffa","raptor_paddock")
	for edge in g.board_data.directed_edges:
		var a = int(edge.from)
		var b = int(edge.to)
		check(g.nodes[a].neighbors.has(b) and g.nodes[b].neighbors.has(a),"one-way path remains physically adjacent both ways")
		check(g.nodes[a].move_neighbors.has(b) and not g.nodes[b].move_neighbors.has(a),"one-way path allows only printed movement direction")
		adjacent(g)
		g.fighters[0].node = b
		g.fighters[g.hero_fighter(1)].node = a
		check(g._in_range(0,g.hero_fighter(1)),"melee attack ignores arrow direction")

func test_all_cards():
	var catalog = Model.new()
	var count = 0
	for hid in ["bruce_lee","ingen","raptors"]:
		for source in catalog.heroes[hid].cards:
			for interactive_mode in [false,true]:
				var g = game([hid,"king_arthur"])
				var own = 1 if str(source.fighter) == "sidekick" else 0
				var foe = adjacent(g,own)
				g.players[0].hand = [source.duplicate(true)]
				g.interactive = interactive_mode
				g.players[0].bot = not interactive_mode
				if str(source.type) == "scheme": check(g.scheme(own,0),"new scheme " + str(source.id))
				elif str(source.type) == "defense":
					g.active = 1
					g.players[1].hand = [card(g,1,"excalibur")]
					check(g.attack(foe,own,0),"attack for new defense")
					if interactive_mode: g.continue_attack()
					if g.phase == "defend": check(g.defend(0),"new defense " + str(source.id))
				else: check(g.attack(own,foe,0),"new attack " + str(source.id))
				finish(g)
				check(g.phase in ["action","discard","game_over"],"new card resolves to stable phase " + str(source.id))
			count += 1
	check(count == 39,"all thirty-nine new definitions executed in auto and interactive modes")

func validate(g):
	var occupied: Array = []
	for f in g.fighters:
		if not f.alive: continue
		check(int(f.node) >= 0 and int(f.node) < g.nodes.size(),"live fighter on board")
		check(int(f.hp) > 0 and int(f.hp) <= int(f.max_hp),"live health in range")
		check(not occupied.has(int(f.node)),"live fighters do not overlap")
		occupied.append(int(f.node))
	if g._flow.is_empty() and g.pending_combat.is_empty():
		for p in g.players: check(p.hand.size()+p.deck.size()+p.discard.size() == 30,"card conservation at stable state")
func test_matches():
	var rosters = [["bruce_lee","medusa"],["ingen","raptors"],["raptors","bruce_lee"],["sinbad","ingen"],["bruce_lee","ingen","raptors"],["medusa","sinbad","bruce_lee","raptors"],["ingen","raptors","robin_hood","bigfoot"]]
	for level in range(3):
		for interactive_mode in [false,true]:
			for index in range(rosters.size()):
				var ids: Array = rosters[index]
				var board = "raptor_paddock" if ids.size() == 2 else "marmoreal"
				var g = Model.new()
				g.interactive = interactive_mode
				g.setup(ids,level,1300+level*10+index,board,{"mode":"teams" if index == 6 else "ffa"})
				if not interactive_mode:
					for p in g.players: p.bot = true
				var steps = 0
				var previous = failures
				while g.winner < 0 and steps < 3000 and failures == previous:
					advance(g)
					steps += 1
					if steps%11 == 0: g = clone(g)
					validate(g)
				check(g.winner >= 0 and g.phase == "game_over","expansion match terminates level=%d roster=%s interactive=%s steps=%d" % [level,ids,interactive_mode,steps])
				matches += 1
				print("EXPANSION_MATCH level=%d interactive=%s roster=%s steps=%d" % [level,interactive_mode,ids,steps])
