extends SceneTree
const Model = preload("res://scripts/game_engine.gd")
const NEW = ["muhammad_ali","dracula","sherlock_holmes","jekyll_hyde","invisible_man"]
var checks = 0
var failures = 0
var matches = 0
var card_runs = 0

func _initialize(): run.call_deferred()
func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		push_error("V6: " + label)
func game(ids: Array, mode = "ffa", board = "training"):
	var g = Model.new()
	g.setup(ids,1,6026,board,{"mode":mode})
	for p in g.players: p.bot = true
	return g
func card(g,owner: int,id: String):
	for c in g.heroes[g.players[owner].hero_id].cards:
		if str(c.id) == id: return c.duplicate(true)
	check(false,"known card " + id)
	return {}
func clone(g):
	var other = Model.new()
	check(other.load_state(JSON.parse_string(JSON.stringify(g.save_state()))),"JSON roundtrip " + g.phase)
	return other
func adjacent(g,own = -1,foe = -1):
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
		"attack_notice": check(g.continue_attack(),"attack notice")
		"combat_report": check(g.continue_combat(),"combat report")
		"effect_choice": check(g.choose_effect_option(0),"effect option " + str(g.pending_choice.get("action","")))
		"effect_move":
			if int(g.pending_choice.get("fighter",-1)) < 0 and not g.pending_choice.get("allowed_fighters",[]).is_empty(): g.choose_effect_fighter(int(g.pending_choice.allowed_fighters[0]))
			if not g.pending_choice.get("legal",[]).is_empty(): check(g.choose_effect_node(int(g.pending_choice.legal[-1])),"effect node")
			else: check(g.skip_effect(),"skip empty effect " + JSON.stringify(g.pending_choice))
		"defend":
			var choices = g.legal_defenses()
			check(g.defend(int(choices[0]) if not choices.is_empty() else -1),"defend")
		"action": g._bot_action()
		"move":
			for f in g.fighters:
				if g._valid_fighter(int(f.id),g.active):
					var legal = g.legal_moves(int(f.id))
					if not legal.is_empty(): g.move_fighter(int(f.id),int(legal[-1]))
			g.finish_maneuver()
		"discard": g.discard_card(0)
		"game_over": pass
		_: check(false,"supported phase " + g.phase)
func finish(g):
	for step in range(80):
		if g.phase in ["action","discard","game_over"]: return
		advance(g)
	check(false,"card flow terminates " + str(g._flow))
func ability(g,effects: Array,owner = 0):
	g._start_ability(owner,"Проверка правил",effects,"start_turn")

func test_ali():
	var g = game(["muhammad_ali","king_arthur"])
	var foe = adjacent(g)
	g.fighters[0].node = 11
	check(g.stance_for(0) == "butterfly" and g._in_range(0,foe),"butterfly attacks at graph distance two")
	g.nodes[11].zones = [91]
	g.nodes[13].zones = [92]
	check(g._in_range(0,foe),"butterfly ignores intervening space and zones")
	g.players[0].hand = [card(g,0,"jab")]
	g.attack(0,foe,0)
	check(g.stance_for(0) == "bee","winning attack changes stance after effects")
	check(g.last_combat.attack_value == 1,"butterfly attack does not get bee damage retroactively")
	g = game(["muhammad_ali","invisible_man"])
	foe = adjacent(g)
	g.ali_stance[0] = "bee"
	g.players[0].hand = [card(g,0,"momentous_shift")]
	g.players[1].hand = [card(g,1,"impossible_to_see")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 2,"bee adds two after Impossible to See locks card effects at zero")
	check(g.last_combat.damage == 0 and g.stance_for(0) == "bee","lost attack keeps bee stance")
	g = game(["muhammad_ali","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"close_and_clinch")]
	g.attack(0,foe,0)
	var old = int(g.fighters[0].node)
	g._enter_node(0,0)
	check(g.fighters[0].node == old and g._reachable(0,5) == [old],"clinch prevents further movement this turn")
	g = game(["muhammad_ali","king_arthur"])
	foe = adjacent(g)
	g.players[0].combat_damage_turn = 2
	g.players[0].hand = [card(g,0,"the_greatest")]
	g.attack(0,foe,0)
	check(g.actions_left == 3,"The Greatest counts cumulative combat damage this turn")
	g = game(["muhammad_ali","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"jab")]
	g.players[1].hand = [card(g,1,"excalibur")]
	g.active = 1
	g.attack(foe,0,0)
	check(g.stance_for(0) == "butterfly","defending never changes Ali stance")

func test_dracula():
	var g = game(["dracula","king_arthur"])
	var foe = adjacent(g)
	g.interactive = true
	g.players[0].bot = false
	var hp = int(g.fighters[foe].hp)
	var count = g.players[0].hand.size()
	g._start_turn_ability()
	check(g.phase == "effect_choice" and g.pending_choice.can_skip,"Dracula bite is optional")
	g = clone(g)
	g.choose_effect_option(0)
	finish(g)
	check(g.fighters[foe].hp == hp-1 and g.players[0].hand.size() == count+1,"bite damages chosen adjacent fighter then draws")
	g = game(["dracula","king_arthur"])
	foe = adjacent(g)
	g.fighters[1].node = 8
	g.fighters[2].node = 18
	g.fighters[3].node = 14
	g.players[0].hand = [card(g,0,"feeding_frenzy")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 5,"Feeding Frenzy counts living sisters in defender zone")
	g = game(["dracula","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"beastform"),card(g,0,"mistform"),card(g,0,"exploit")]
	g.interactive = true
	g.players[0].bot = false
	g.attack(0,foe,0)
	g.continue_attack()
	check(g.pending_choice.action == "v6_power","Beastform human chooses number of discards")
	g = clone(g)
	g.choose_effect_option(0)
	g.skip_effect()
	check(g.combat_report.attack_value == 7 and g.players[0].hand.size() == 1,"Beastform can discard exactly one and stop")
	finish(g)
	g = game(["dracula","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"do_my_bidding")]
	g.players[1].hand = [card(g,1,"excalibur"),card(g,1,"feint")]
	g.active = 1
	g.interactive = true
	g.players[0].bot = false
	g.attack(foe,0,0)
	g.continue_attack()
	g.defend(0)
	check(g.pending_choice.kind == "hand_view" and g.players[1].hand.size() == 2,"Do My Bidding returns original attack before showing full hand")
	g = clone(g)
	g.choose_effect_option(0)
	check(g.pending_choice.action == "v6_bidding","Do My Bidding attack selection follows full hand view")
	g.choose_effect_option(0)
	finish(g)
	check(str(g.last_combat.attack_card.id) == "feint" and g.last_combat.defense_cancelled,"replacement attack runs its immediate effects")
	check(g.players[1].hand.size() == 1 and str(g.players[1].hand[0].id) == "excalibur","unused original attack stays in hand")

func test_sherlock():
	var g = game(["sherlock_holmes","king_arthur"])
	var foe = adjacent(g)
	g.players[0].hand = [card(g,0,"counterpunch")]
	g.players[1].hand = [card(g,1,"feint")]
	g.attack(0,foe,0)
	check(not g.last_combat.attack_cancelled and g.fighters[foe].hp == 15,"Holmes named card ignores Feint and Counterpunch resolves")
	g = game(["sherlock_holmes","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"study_methods")]
	g.players[1].hand = [card(g,1,"feint")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_cancelled,"Sherlock ANY cards can be canceled")
	g = game(["sherlock_holmes","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"elementary")]
	g.players[1].hand = [card(g,1,"excalibur")]
	g.active = 1
	g.interactive = true
	g.players[0].bot = false
	g.attack(foe,0,0)
	g.continue_attack()
	g.defend(0)
	check(g.pending_choice.action == "v6_elementary_guess" and g.pending_combat.attack_card.id == "excalibur","Elementary pauses to predict before combat effects")
	g = clone(g)
	g.choose_effect_option(6)
	check(g.combat_report.damage == 0 and g.combat_report.attack_cancelled,"correct Elementary prediction cancels effects and ignores attack")
	finish(g)
	g = game(["sherlock_holmes","king_arthur"])
	foe = adjacent(g)
	g.interactive = true
	g.players[0].bot = false
	g.players[0].hand = [card(g,0,"confirm_suspicion")]
	g.players[1].hand = [card(g,1,"excalibur"),card(g,1,"the_holy_grail")]
	g.scheme(0,0)
	check(g.pending_choice.action == "v6_suspicion_value","Confirm Suspicion asks value without looking at enemy hand")
	g = clone(g)
	g.choose_effect_option(6)
	finish(g)
	check(g.players[1].hand.size() == 1 and g.fighters[foe].hp == 15,"Confirm Suspicion discards matching attack and deals BOOST damage")

func test_jekyll():
	var g = game(["jekyll_hyde","king_arthur"])
	var foe = adjacent(g)
	g.players[0].hand = [card(g,0,"forever_hyde"),card(g,0,"with_haste")]
	check(not g.can_use_card(g.players[0].hand[0],0) and g.can_use_card(g.players[0].hand[1],0),"Jekyll form filters named cards")
	g.jekyll_form[0] = "hyde"
	check(g.can_use_card(g.players[0].hand[0],0) and not g.can_use_card(g.players[0].hand[1],0),"Hyde form flips card access")
	g.interactive = true
	g.players[0].bot = false
	g._start_turn_ability()
	check(g.pending_choice.action == "v6_form","start turn offers optional choice of either form")
	g.choose_effect_option(1)
	finish(g)
	var hp = int(g.fighters[0].hp)
	g.begin_maneuver()
	check(g.fighters[0].hp == hp,"Hyde maneuver damage waits until movement ends")
	g.finish_maneuver()
	check(g.fighters[0].hp == hp-1,"Hyde takes one after maneuver")
	g = game(["jekyll_hyde","king_arthur"])
	foe = adjacent(g)
	g.jekyll_form[0] = "hyde"
	g.players[0].hand = [card(g,0,"forever_hyde"),card(g,0,"with_haste"),card(g,0,"scientific_method"),card(g,0,"feint")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 9 and g.players[0].hand.size() == 1,"Forever Hyde discards only Jekyll cards for plus two each")
	g = game(["jekyll_hyde","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"scientific_method")]
	g.players[1].hand = [card(g,1,"excalibur")]
	g.active = 1
	var before = g.players[0].deck.size()
	g.attack(foe,0,0)
	check(g.players[0].hand.size() == 4 and g.players[0].deck.size() == before-4,"Scientific Method draws combat damage suffered")

func test_fog():
	var g = game(["invisible_man","king_arthur"])
	var foe = adjacent(g)
	check(g.fog_tokens.size() == 3,"Invisible Man starts with three fog tokens")
	g.fog_tokens[0].node = 12
	g.fog_tokens[1].node = 20
	g.fog_tokens[2].node = 21
	check(g._reachable(0,1).has(20),"fog spaces connect with one movement step")
	g.fighters[foe].node = 20
	check(not g._reachable(0,1).has(20),"enemy on fog blocks movement")
	g.fighters[foe].node = 13
	g.players[0].hand = [card(g,0,"impossible_to_see")]
	g.players[1].hand = [card(g,1,"feint")]
	g.active = 1
	g.attack(foe,0,0)
	check(g.last_combat.defense_value == 3,"fog defense is a hero ability and survives cancel effects")
	g = game(["invisible_man","king_arthur"])
	foe = adjacent(g)
	g.fog_tokens[0].node = 12
	g.players[0].hand = [card(g,0,"impossible_to_see")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 2,"fog does not add to attacks")
	g = game(["bruce_lee","invisible_man"])
	foe = adjacent(g)
	g.players[0].turn_attack_bonus = 2
	g.players[0].hand = [card(g,0,"feint")]
	g.players[1].hand = [card(g,1,"impossible_to_see")]
	g.attack(0,foe,0)
	check(g.last_combat.attack_value == 0,"Impossible to See blocks earlier turn bonuses originating from card effects")
	g = game(["invisible_man","king_arthur"])
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"vanish")]
	g.scheme(0,0)
	check(bool(g.fighters[0].get("offboard",false)) and not g._in_range(foe,0) and g._occupant(12) < 0,"Vanish removes living hero as a target and occupant")
	g = clone(g)
	g.end_turn()
	if g.active == 1: g.end_turn()
	check(not bool(g.fighters[0].get("offboard",false)) and g._valid_fighter(0),"Vanish returns at next own turn")
	g = game(["invisible_man","king_arthur"])
	g.players[0].actions_taken = 1
	g.actions_left = 2
	g.players[0].hand = [card(g,0,"vanish")]
	g.scheme(0,0)
	check(g.active == 1 and bool(g.fighters[0].offboard),"Vanish ends turn even with extra actions because the player is dormant")
	var hidden_hp = int(g.fighters[0].hp)
	var hidden_hand = g.players[0].hand.size()
	g._damage(0,3)
	g._draw(0,2)
	g._force_discard(0,1,false)
	check(g.fighters[0].hp == hidden_hp and g.players[0].hand.size() == hidden_hand,"dormant hero and hand cannot be damaged, drawn or discarded")
	check(g._public_target(g.hero_fighter(1)) == -1,"bots cannot pursue a dormant fighter")
	g = Model.new()
	g.interactive = true
	g.setup(["invisible_man","king_arthur"],1,9,"training",{"human_placement":true})
	g.place_setup_fighter(0,int(g.legal_setup_nodes(0)[0]))
	g.finish_setup()
	check(g.phase == "effect_move" and g.pending_choice.action == "v6_setup_fog","manual fog placement follows hero placement")
	for n in range(3):
		g = clone(g)
		g.choose_effect_node(int(g.pending_choice.legal[0]))
	finish(g)
	check(g.fog_tokens.size() == 3,"all three fog setup choices survive saves")

func test_choices_and_compatibility():
	var g = game(["invisible_man","king_arthur"])
	adjacent(g)
	g.interactive = true
	g.players[0].bot = false
	var ctx = {"owner":0,"self":0,"opponent":g.hero_fighter(1),"opponent_owner":1,"card":{"name":"Проверка тумана"},"value":0,"won":true}
	ability(g,[{"kind":"covert_preparation"}])
	check(g.pending_choice.action == "v6_fog_token","fog movement offers token selection")
	g = clone(g)
	var first = int(g.pending_choice.indices[0])
	g.choose_effect_option(0)
	var destination = int(g.pending_choice.legal[-1])
	g.choose_effect_node(destination)
	check(g.fog_tokens[first].node == destination,"chosen fog moves to chosen destination")
	finish(g)
	g = game(["invisible_man","king_arthur"])
	adjacent(g)
	g.players[0].bot = false
	g.interactive = true
	g.players[1].hand = []
	g._start_ability(0,"Сбить с толку",[{"kind":"confound"}],"start_turn")
	# Ability contexts have no opposing owner; supply an actual combat context.
	g._flow = {"kind":"ability","stage":"effects","completion":"start_turn","owner":0,"effect_logs":[]}
	g._effect_queue = [{"effect":{"kind":"confound"},"ctx":ctx}]
	g._pump_effects()
	var ids = []
	for token in range(3):
		check(g.phase == "effect_choice" and g.pending_choice.action == "v6_fog_token","Confound visits each fog token")
		if g.phase != "effect_choice": break
		ids.append(int(g.pending_choice.indices[0]))
		g.choose_effect_option(0)
		g.choose_effect_node(int(g.pending_choice.legal[-1]))
	finish(g)
	check(ids.size() == 3 and ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2],"Confound moves all three different tokens exactly once")
	g = game(["sherlock_holmes","king_arthur"])
	var guess = g._v6._guess(1)
	g.players[1].hand = [card(g,1,"feint")]
	check(g._v6._guess(1) == guess,"bot deductions do not inspect hidden hand")
	for version in range(1,7):
		var state = g.save_state()
		state.version = version
		if version < 6:
			state.erase("ali_stance")
			state.erase("jekyll_form")
			state.erase("fog_tokens")
		var restored = Model.new()
		check(restored.load_state(JSON.parse_string(JSON.stringify(state))),"save version %d remains readable" % version)

func test_new_boards():
	for board in ["soho","baskerville_manor","thrilla_in_manilla","tsing_shan_monastery"]:
		var probe = Model.new()
		check(probe.boards.has(board),"new board exists " + board)
		if not probe.boards.has(board): continue
		if board == "baskerville_manor":
			var passages = probe.boards[board].get("secret_passages",[])
			probe.setup(["muhammad_ali","bruce_lee"],1,6030,board)
			if passages.size() >= 2:
				var a = int(passages[0])
				var b = int(passages[-1])
				probe.fighters[0].node = a
				probe.fighters[1].node = b
				check(probe.nodes[a].move_neighbors.has(b) and not probe.nodes[a].neighbors.has(b),"secret passages are movement links only")
		for level in range(3):
			for manual in [false,true]:
				var g = Model.new()
				g.interactive = manual
				g.setup(["muhammad_ali","invisible_man"],level,6200+level,board)
				if not manual:
					for p in g.players: p.bot = true
				var step = 0
				var prior = failures
				while g.winner < 0 and step < 2000 and prior == failures:
					advance(g)
					step += 1
					validate(g)
				check(g.winner >= 0,"new board match finishes " + board)
				matches += 1
				print("V6_BOARD_MATCH board=%s level=%d human=%s steps=%d" % [board,level,manual,step])

func test_all_cards():
	var catalog = Model.new()
	for hid in NEW:
		for source in catalog.heroes[hid].cards:
			for manual in [false,true]:
				var g = game([hid,"king_arthur"])
				var own = 1 if str(source.fighter) == "sidekick" else 0
				var foe = adjacent(g,own)
				g.jekyll_form[0] = str(source.fighter) if str(source.fighter) in ["hyde","jekyll"] else "jekyll"
				g.players[0].hand = [source.duplicate(true)]
				g.interactive = manual
				g.players[0].bot = not manual
				if str(source.type) == "scheme": check(g.scheme(own,0),"scheme " + hid + "/" + str(source.id))
				elif str(source.type) == "defense":
					g.active = 1
					g.players[1].hand = [card(g,1,"excalibur")]
					check(g.attack(foe,own,0),"attack into defense " + str(source.id))
					if manual: g.continue_attack()
					if g.phase == "defend": check(g.defend(0),"defense " + str(source.id))
				else: check(g.attack(own,foe,0),"attack " + hid + "/" + str(source.id))
				for step in range(80):
					if g.phase in ["action","discard","game_over"]: break
					g = clone(g)
					advance(g)
				check(g.phase in ["action","discard","game_over"],"card reaches stable phase " + hid + "/" + str(source.id))
				card_runs += 1
	check(card_runs == 132,"all sixty-six definitions execute in automatic and human modes")

func validate(g):
	var occupied = []
	var fog_spaces = []
	for f in g.fighters:
		if not f.alive: continue
		check(int(f.hp) > 0 and int(f.hp) <= int(f.max_hp),"living fighter health")
		if bool(f.get("offboard",false)): continue
		check(not occupied.has(int(f.node)),"fighters never overlap")
		occupied.append(int(f.node))
	for fog in g.fog_tokens:
		check(not fog_spaces.has(int(fog.node)),"fog spaces distinct")
		fog_spaces.append(int(fog.node))
	if g._flow.is_empty() and g.pending_combat.is_empty():
		for p in g.players: check(p.hand.size()+p.deck.size()+p.discard.size() == 30,"card conservation")

func test_matches():
	var rosters = [["muhammad_ali","dracula"],["sherlock_holmes","jekyll_hyde"],["invisible_man","muhammad_ali"],["jekyll_hyde","dracula"],["invisible_man","sherlock_holmes"],["muhammad_ali","bruce_lee"],["sherlock_holmes","raptors"],["dracula","invisible_man","jekyll_hyde"],["sherlock_holmes","muhammad_ali","dracula","invisible_man"],["jekyll_hyde","ingen","invisible_man","bruce_lee"]]
	for level in range(3):
		for manual in [false,true]:
			for index in range(rosters.size()):
				var g = Model.new()
				g.interactive = manual
				g.setup(rosters[index],level,6100+level*50+index,"training",{"mode":"teams" if index == 9 else "ffa"})
				if not manual:
					for p in g.players: p.bot = true
				var step = 0
				var prior = failures
				while g.winner < 0 and step < 2500 and failures == prior:
					advance(g)
					step += 1
					if step % 13 == 0: g = clone(g)
					validate(g)
				check(g.winner >= 0 and g.phase == "game_over","match terminates level=%d human=%s roster=%s phase=%s steps=%d" % [level,manual,rosters[index],g.phase,step])
				matches += 1
				print("V6_MATCH level=%d human=%s roster=%s steps=%d" % [level,manual,rosters[index],step])

func run():
	test_ali()
	test_dracula()
	test_sherlock()
	test_jekyll()
	test_fog()
	test_choices_and_compatibility()
	test_all_cards()
	test_matches()
	test_new_boards()
	print("V6_ENGINE_TESTS checks=%d failures=%d matches=%d card_runs=%d" % [checks,failures,matches,card_runs])
	quit(1 if failures else 0)
