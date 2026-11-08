extends "res://tests/v8_engine_tests.gd"
const V9 = ["achilles","bloody_mary","sun_wukong","yennenga"]
func game(ids: Array, manual = false, config = {}):
	var g = super.game(ids,manual,config)
	if ids[0] == "sun_wukong":
		g.fighters[0].hp = 17
		for fid in g._v9.helpers(0): g.fighters[fid].alive = false; g.fighters[fid].hp = 0
	return g
func combat(g, own: int, foe: int, atk: Dictionary, defense = {}):
	g.players[int(g.fighters[own].owner)].hand = [atk]
	var enemy = int(g.fighters[foe].owner)
	g.players[enemy].hand = [] if defense.is_empty() else [defense]
	g.active = int(g.fighters[own].owner)
	check(g.attack(own,foe,0),"launch card combat")
	if g.phase == "attack_notice": g.continue_attack()
	if g.phase == "defend": g.defend(0 if not defense.is_empty() else -1)
func test_new_rules():
	var g = game(["achilles","king_arthur"])
	g.players[0].hand = [raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)]
	g._damage(1,6)
	check(g._v9.enraged(0) and g.players[0].hand.size() == 1,"Patroclus death discards two cards and activates rage")
	var foe = adjacent(g)
	combat(g,0,foe,raw_card("attack",2))
	check(int(g.last_combat.attack_value) == 4 and g.players[0].hand.size() == 1,"Achilles adds two and draws after win")
	g = game(["bloody_mary","king_arthur"])
	g.players[0].hand = [raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)]
	g._start_turn_ability()
	check(g.actions_left == 3,"Mary gets third action with exact three-card hand")
	g = game(["sun_wukong","king_arthur"],true)
	check(g._v9.helpers(0).is_empty(),"no initial clones")
	g._start_turn_ability()
	check(g.pending_choice.action == "v9_clone_start","human chooses summon")
	g.choose_effect_option(0)
	if g.phase == "effect_choice": g.choose_effect_option(0)
	g = clone(g)
	check(g.choose_effect_node(int(g.pending_choice.legal[0])),"choose adjacent clone cell")
	g = stable(g)
	check(g._v9.helpers(0).size() == 1 and int(g.fighters[0].hp) == 16,"summon costs exactly one health")
	for manual in [false,true]:
		g = game(["yennenga","king_arthur"],manual)
		foe = adjacent(g)
		g.fighters[1].node = 7
		g.fighters[2].node = 17
		g.players[0].hand = []
		var hp = int(g.fighters[0].hp)
		combat(g,foe,0,raw_card("attack",5))
		g = stable(g)
		check(int(g.fighters[0].hp) == (hp-5 if manual else hp-1),"Yennenga human chooses to keep damage; bot assigns four to Archers")
	g = game(["yennenga","king_arthur"],true)
	foe = adjacent(g)
	g.fighters[1].node = 7
	g.fighters[2].node = 17
	combat(g,foe,0,raw_card("attack",5))
	check(g.pending_choice.action == "v9_damage","combat pauses for Archer assignment")
	for n in range(4):
		g = clone(g)
		check(g.choose_effect_option(1),"assign one damage to living Archer")
	g = stable(g)
	check(int(g.fighters[0].hp) == 14 and g._v9.helpers(0).is_empty(),"remaining damage reaches Yennenga after both Archers fall")
	for manual in [false,true]:
		g = game(["sun_wukong","king_arthur"],manual)
		foe = adjacent(g)
		var hp = int(g.fighters[foe].hp)
		combat(g,foe,0,raw_card("attack",6),card(g,0,"golden_chain_mail"))
		g = stable(g)
		check(int(g.fighters[0].hp) == 17 and int(g.fighters[foe].hp) == hp-2,"Golden Chain Mail redirects combat damage and prevents damage to defender")
		g = game(["sun_wukong","king_arthur"],manual)
		foe = adjacent(g)
		var atk = raw_card("attack",6)
		atk.effects = [{"kind":"damage","target":"opposing_combatant","amount":3,"timing":"after"}]
		combat(g,foe,0,atk,card(g,0,"bewilderment"))
		g = stable(g)
		check(int(g.fighters[0].hp) == 17,"Bewilderment prevents combat AND after-combat damage")
func test_bonus():
	for hid in V9:
		var cid = {"achilles":"test_for_weakness","bloody_mary":"bloody_requiem","sun_wukong":"ruyi_jingo_bang","yennenga":"rain_of_arrows"}[hid]
		for manual in [false,true]:
			var g = game([hid,"king_arthur"],manual)
			var foe = adjacent(g)
			g.players[1].hand = [raw_card("defense",2),raw_card("defense",1)]
			g.players[0].hand = [card(g,0,cid)]
			g.attack(0,foe,0)
			var attacks = 0
			for n in range(100):
				if g.phase in ["action","game_over","discard"]: break
				if g.phase == "attack_notice": attacks += 1
				g = clone(g)
				advance(g)
			check(g.phase in ["action","game_over","discard"] and g._combat_stack.is_empty(),"nested bonus ends and restores original flow " + hid)
			check(g.players[0].discard.size() == 1,"bonus does not create a physical extra card " + hid)
			check(g.players[1].discard.size() == 2,"opponent can defend both attacks " + hid)
			check(g.actions_left == 1,"bonus spends no extra action " + hid)
			if manual: check(attacks == 2,"both attacks announced " + hid)
			g = game([hid,"king_arthur"],manual)
			foe = adjacent(g)
			combat(g,0,foe,card(g,0,cid),card(g,1,"feint"))
			g = stable(g)
			check(g._combat_stack.is_empty() and g.players[1].discard.size() == 1,"Feint cancels main bonus effect " + hid)
func test_chains():
	for manual in [false,true]:
		var g = game(["yennenga","king_arthur"],manual)
		adjacent(g)
		g.fighters[0].hp = 10
		g.fighters[1].hp = 1
		g.fighters[2].hp = 1
		g.players[0].hand = [card(g,0,"one_with_the_land")]
		var deck = g.players[0].deck.size()
		g.scheme(0,0)
		g = stable(g)
		check(g.fighters[0].hp == 11 and g.fighters[1].hp == 2 and g.fighters[2].hp == 2 and g.players[0].deck.size() == deck-1,"One With the Land moves, heals ALL fighters and draws")
		g = game(["achilles","king_arthur"],manual)
		var foe = adjacent(g)
		g.players[0].hand = [card(g,0,"test_for_weakness")]
		g.players[1].hand = [raw_card("defense",2)]
		g.attack(0,foe,0)
		g = stable(g)
		check(g.players[0].discard.size() == 1 and g.players[1].discard.size() == 1,"bonus original and defense discarded once")
	# Real route, not a guessed shortest path: move through enemy and then leave it.
	var g = game(["yennenga","king_arthur"],true)
	var foe = adjacent(g)
	var hp = int(g.fighters[foe].hp)
	direct(g,[{"kind":"v9_charge"}],card(g,0,"stallion_charge"))
	check(g.pending_choice.legal.has(13),"charge permits moving through enemy")
	g.choose_effect_node(13)
	check(not g.pending_choice.can_skip,"cannot end charge on occupied space")
	g = clone(g)
	g.choose_effect_node(14)
	g.skip_effect()
	g = stable(g)
	check(int(g.fighters[0].node) == 14 and int(g.fighters[foe].hp) == hp-1,"charge chosen route deals exact once-per-enemy damage")
func test_matches_v9():
	var rosters = [["achilles","bloody_mary"],["sun_wukong","yennenga"],["yennenga","beowulf"],["sun_wukong","houdini"],V9,V9,["bloody_mary","achilles","sun_wukong"]]
	for level in range(3):
		for manual in [false,true]:
			for i in range(rosters.size()):
				var g = Model.new()
				g.interactive = manual
				g.setup(rosters[i],level,9200+50*level+i,"hanging_gardens",{"mode":"teams" if i == 5 else "ffa"})
				if not manual:
					for p in g.players: p.bot = true
				var steps = 0
				var prior = failures
				while g.winner < 0 and steps < 3000 and prior == failures:
					advance(g)
					steps += 1
					if steps%19 == 0: g = clone(g)
					validate(g)
				check(g.winner >= 0,"BOL2 match finishes level=%d manual=%s roster=%d phase=%s" % [level,manual,i,g.phase])
				matches += 1
				print("V9_MATCH ",level," ",manual," ",i," steps=",steps)
func run():
	test_new_rules()
	test_bonus()
	test_chains()
	all_catalog_cards_v8()
	test_matches_v9()
	print("V9_ENGINE checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves])
	quit(1 if failures else 0)
