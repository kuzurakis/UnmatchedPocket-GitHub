extends "res://tests/buffy_engine_tests.gd"
const V8 = ["little_red","beowulf","houdini","genie"]
func game(ids: Array, manual = false, config = {}):
	var g = super.game(ids,manual,config)
	# Fixtures begin before start-of-turn abilities. Full matches use real setup.
	if ids[0] == "genie":
		while not g.players[0].discard.is_empty(): g.players[0].hand.append(g.players[0].discard.pop_back())
		g.actions_left = 2
	return g

func stable(g):
	for n in range(160):
		if g.phase in ["action","discard","game_over","move"]: return g
		g = clone(g)
		advance(g)
	check(false,"v8 complete effect chain " + str(g._flow))
	return g
func direct(g, effects: Array, c = {}, owner = 0, opponent = 1):
	var ctx = {"owner":owner,"self":g.hero_fighter(owner),"opponent":g.hero_fighter(opponent),"opponent_owner":opponent,"card":c,"value":int(c.get("value",0)),"won":true}
	g._flow = {"kind":"ability","stage":"effects","completion":"start_turn","effect_logs":[]}
	g.combat_report = {"kind":"ability"}
	g._effect_queue = []
	for ef in effects: g._effect_queue.append({"effect":ef,"ctx":ctx.duplicate(true)})
	g._pump_effects()
	return ctx
func test_red_v8():
	var g = game(["little_red","beowulf"])
	check(g._v8.basket(0) == "wild","virtual initial basket is wild")
	check(g.players[0].hand.size()+g.players[0].deck.size() == 30,"initial basket does not count as a card")
	for symbol in ["wild","pelt","knife","flower"]:
		g = game(["little_red","beowulf"],true)
		adjacent(g)
		g.players[0].discard = [] if symbol == "wild" else [{"id":"basket","basket_symbol":symbol}]
		g.players[0].hand = [card(g,0,"never_leave_the_path")]
		var deck = g.players[0].deck.size()
		var hp = int(g.fighters[g.hero_fighter(1)].hp)
		check(g.scheme(0,0),"Never Leave The Path " + symbol)
		if symbol == "wild":
			check(g.pending_choice.action == "v8_path","wild basket chooses one effect")
			g = clone(g)
			check(g.choose_effect_option(2),"choose flower only")
		g = stable(g)
		check(g._v8.basket(0) == "pelt","resolved scheme becomes basket")
		check(g.players[0].deck.size() == deck-(3 if symbol in ["flower","wild"] else 0),"path only selected draw effect")
		check(g.actions_left == (2 if symbol == "pelt" else 1),"path action only for pelt")
		check(int(g.fighters[g.hero_fighter(1)].hp) == hp-(2 if symbol == "knife" else 0),"path zone damage only for knife")
	for symbol in ["knife","pelt","wild"]:
		g = game(["little_red","beowulf"],true)
		var foe = adjacent(g)
		g.players[0].discard = [{"basket_symbol":symbol}]
		g.players[0].hand = [card(g,0,"what_big_ears_you_have")]
		g.active = 1
		g.players[1].hand = [raw_card("attack",3)]
		g.attack(foe,0,0)
		g.continue_attack()
		check(g.legal_defenses().has(0) == (symbol != "pelt"),"ears defend only with knife or star")
	g = game(["little_red","beowulf"])
	var foe = adjacent(g)
	g.players[0].hand = [card(g,0,"once_upon_a_time")]
	g.players[0].discard = [{"basket_symbol":"knife"}]
	g.players[1].rage = 0
	var hp = int(g.fighters[foe].hp)
	g.attack(0,foe,0)
	check(int(g.fighters[foe].hp) == hp-5 and g._v8.rage(1) == 2,"combat and after damage both happen and grant separate rage")
	g = game(["little_red","beowulf"])
	foe = adjacent(g)
	g.players[0].discard = [{"basket_symbol":"pelt"}]
	g.players[0].hand = [card(g,0,"what_large_hands_you_have")]
	g.attack(0,foe,0)
	check(g.players[0].hand.size() == 1 and g.players[0].discard.size() == 1,"large hands returns itself without losing old basket")
	g = game(["little_red","beowulf"],true)
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"what_large_hands_you_have")]
	g.players[0].discard = []
	g.attack(0,foe,0)
	g.continue_attack()
	g.continue_combat()
	check(g.pending_choice.modes.has("self") and not g.pending_choice.modes.has("basket"),"initial wild basket permits self-return but virtual Basket cannot enter hand")
	g.choose_effect_option(0)
	g = stable(g)
	check(g.players[0].hand.size() == 1 and g.players[0].discard.is_empty(),"Large Hands returns itself with initial Basket")

func test_beowulf_v8():
	var g = game(["beowulf","king_arthur"])
	check(g._v8.rage(0) == 1,"Beowulf starts with one rage")
	g._damage(1,1)
	check(g._v8.rage(0) == 1,"Wiglaf damage grants no rage")
	g._damage(0,2)
	g._damage(0,1)
	g._damage(0,1)
	check(g._v8.rage(0) == 3,"separate damage events cap rage at three")
	for manual in [false,true]:
		g = game(["beowulf","king_arthur"],manual)
		var foe = adjacent(g)
		g.players[0].rage = 3
		g.players[0].hand = [card(g,0,"the_war_king")]
		g.attack(0,foe,0)
		if manual:
			g.continue_attack()
			check(g.pending_choice.action == "v8_war","war king asks how much rage")
			g = clone(g)
			g.choose_effect_option(3)
		g = stable(g)
		check(int(g.last_combat.attack_value) == 7 and g._v8.rage(0) == 0,"war king spends three for exact seven")
		g = game(["beowulf","king_arthur"],manual)
		adjacent(g)
		g.players[0].rage = 3
		g.fighters[0].hp = 10
		g.players[0].hand = [card(g,0,"golden_drinking_horn")]
		var deck = g.players[0].deck.size()
		g.scheme(0,0)
		if manual:
			g.choose_effect_option(3)
			check(g.pending_choice.remaining_count == 3,"horn selects three distinct effects")
		g = stable(g)
		check(g.players[0].deck.size() == deck-2 and int(g.fighters[0].hp) == 12 and g._v8.rage(0) == 0,"horn resolves draw, movement AND healing")

func test_houdini_v8():
	for bonus in ["sleight_of_hand","flourish","all_part_of_the_show","and_the_beautiful_bess"]:
		var g = game(["houdini","king_arthur"],true)
		adjacent(g)
		g.fighters[0].hp = 8
		g.players[0].hand = [card(g,0,bonus)]
		var deck = g.players[0].deck.size()
		g.begin_maneuver(0)
		g = stable(g)
		check(g.phase == "move","boost bonus resumes maneuver " + bonus)
		check(g.players[0].deck.size() == deck-(2 if bonus in ["sleight_of_hand","flourish"] else 1),"mandatory draw AND boost draw " + bonus)
		check(int(g.fighters[0].hp) == (10 if bonus == "all_part_of_the_show" else 8),"boost heal " + bonus)
		check(g.actions_left == (2 if bonus == "and_the_beautiful_bess" else 1),"boost action " + bonus)
		check(g.legal_moves(0).has(24),"boosted Houdini can place anywhere")
		check(not g.legal_moves(1).has(24),"Bess retains ordinary boosted movement")
	var g = game(["houdini","king_arthur"],true)
	var foe = adjacent(g)
	g.players[0].hand = [card(g,0,"misdirection")]
	g.begin_maneuver(0)
	check(g.pending_choice.action == "v8_boost_damage" and g.players[0].discard.is_empty(),"boost damage chooses before boost card enters discard")
	var hp = int(g.fighters[foe].hp)
	g = clone(g)
	g.choose_effect_option(g.pending_choice.ids.find(foe))
	g = stable(g)
	check(int(g.fighters[foe].hp) == hp-2 and g.players[0].discard.size() == 1 and g.phase == "move","boost damage then discard then maneuver actual hp=%d expected=%d discard=%d phase=%s" % [int(g.fighters[foe].hp),hp-2,g.players[0].discard.size(),g.phase])
	for fid in [0,1]:
		g = game(["houdini","king_arthur"],true)
		foe = adjacent(g,fid)
		g.fighters[fid].hp = 1
		g.players[0].hand = [card(g,0,"all_part_of_the_show")]
		g.players[1].hand = [raw_card("attack",6)]
		g.active = 1
		g.attack(foe,fid,0)
		g.continue_attack()
		g.defend(0)
		g = stable(g)
		check(g.fighters[fid].alive and int(g.fighters[fid].hp) == 4 and g.players[0].alive and g.winner < 0,"Show revives defeated Houdini or Bess before checking winner")
	g = game(["houdini","king_arthur"],true)
	foe = adjacent(g)
	g.players[0].hand = [card(g,0,"the_big_reveal"),card(g,0,"flourish"),card(g,0,"sleight_of_hand")]
	var deck = g.players[0].deck.size()
	g.attack(0,foe,0)
	g.continue_attack()
	for n in range(2):
		check(g.pending_choice.action == "combat_boost","Big Reveal boost decision " + str(n))
		g.choose_effect_option(0)
	g = stable(g)
	check(g.players[0].deck.size() == deck-2,"both Big Reveal boost bonuses draw")
	check(int(g.last_combat.attack_value) == 7,"Big Reveal adds BOTH boost values")
	check(g.players[0].discard.size() == 2,"Big Reveal returns one boost, discards the other and itself")
	for accept in [0,1]:
		g = game(["houdini","medusa"],true)
		g.players[0].hand = [card(g,0,"a_magician_never_reveals_his_secrets"),card(g,0,"and_the_beautiful_bess")]
		direct(g,[{"kind":"reveal_choose_discard","amount":1}],raw_card("scheme",0),1,0)
		check(g.pending_choice.action == "v8_guard","Houdini gets optional privacy decision against bot")
		g = clone(g)
		g.choose_effect_option(accept)
		g = stable(g)
		check(g.players[0].discard.size() == (0 if accept == 0 else 1),"secret card blocks entire peek/discard effect or permits it")
	g = game(["houdini","sherlock_holmes"],true)
	g.players[0].hand = [card(g,0,"a_magician_never_reveals_his_secrets")]
	var guarded = g._v8.guard_effect({"kind":"reveal_choose_discard"},{"owner":1,"opponent_owner":0,"card":card(g,1,"eliminate_the_impossible")})
	check(not guarded and g.pending_choice.is_empty(),"Secrets cannot cancel Sherlock’s uncancellable named card")

func test_genie_v8():
	var g = game(["genie","king_arthur"],true)
	var before = g.players[0].hand.size()
	g._start_turn_ability()
	check(g.pending_choice.action == "v8_pay","Genie offers discard at start")
	g = clone(g)
	g.choose_effect_option(0)
	g = stable(g)
	check(g.players[0].hand.size() == before-1 and g.actions_left == 3,"Genie gains exact third action")
	g = game(["genie","king_arthur"],true)
	adjacent(g)
	g.players[0].hand = [card(g,0,"imprisoned_wrath"),raw_card("attack",1),raw_card("attack",2)]
	var foe = g.hero_fighter(1)
	g.attack(0,foe,0)
	g.continue_attack()
	g.continue_combat()
	check(g.pending_choice.action == "v8_pay","Wrath offers two card payment")
	g.choose_effect_option(0)
	check(g.players[0].hand.size() == 2 and g.players[0].discard.is_empty(),"partial payment reserves cards without discarding")
	g.skip_effect()
	g = stable(g)
	check(g.players[0].hand.size() == 2,"cancel half selected payment costs nothing")
	g = game(["genie","king_arthur"],true)
	adjacent(g)
	g.players[0].hand = [card(g,0,"three_wishes"),card(g,0,"feint")]
	g.scheme(0,0)
	g.choose_effect_option(1)
	g = stable(g)
	check(g.actions_left == 2 and bool(g.players[0].fixed_four),"three wishes gives action AND selected effect")
	g.interactive = false
	g.players[0].bot = true
	g.attack(0,g.hero_fighter(1),0)
	check(int(g.last_combat.attack_value) == 4,"three wishes locks card at four")
	g.end_turn()
	check(not bool(g.players[0].fixed_four),"fixed four expires at end of Genie turn")

func test_boards_v8():
	var g = Model.new()
	g.setup(["little_red","beowulf"],1,88,"heorot")
	check(g.nodes.size() == 30 and g.door_states == [false,false,false],"Heorot has thirty spaces and three open doors")
	g.fighters[0].node = 17
	g.fighters[1].node = 0
	g.fighters[2].node = 19
	g.fighters[3].node = 1
	check(g._same_zone(17,19),"door initially shares zone")
	check(not g.toggle_door(0,0),"cannot operate door outside maneuver")
	g.begin_maneuver()
	check(g.toggle_door(0,0),"close adjacent door for free")
	check(not g.nodes[17].neighbors.has(19) and not g.nodes[17].neighbors.has(26),"door removes both crossing edges")
	check(not g._same_zone(17,19) and not g._in_range(0,2),"closed door blocks shared zone and attacks")
	g = clone(g)
	check(not g.nodes[17].neighbors.has(19) and g.door_states[0],"closed graph restored after save")
	check(g.toggle_door(0,0) and int(g.door_movement_spent[0]) == 1,"open door costs one movement")
	check(g.nodes[17].neighbors.has(19) and g._same_zone(17,19),"opening restores adjacency and zone")
	g.finish_maneuver()
	check(not g.toggle_door(0,0),"card movement cannot operate doors")
	g.setup(["houdini","genie"],1,88,"king_solomons_mine")
	check(g.board_data.secret_passages.size() == 6,"Solomon has six secret passages")
	check(g.nodes[0].move_neighbors.has(21) and not g.nodes[0].neighbors.has(21),"secret passage changes movement only")

func test_chained_outcomes_v8():
	for manual in [false,true]:
		var g = game(["little_red","king_arthur"],manual)
		var foe = adjacent(g)
		g.players[0].discard = [{"id":"basket","basket_symbol":"flower"}]
		g.players[0].hand = [card(g,0,"what_big_eyes_you_have")]
		g.players[1].hand = [card(g,1,"excalibur")]
		g.active = 1
		g.attack(foe,0,0)
		if manual: g.continue_attack(); g.defend(0)
		g = stable(g)
		check(g.last_combat.attack_cancelled and int(g.last_combat.damage) == 0,"Big Eyes cancels effects AND ignores opposing value")
		g = game(["little_red","king_arthur"],manual)
		foe = adjacent(g)
		g.players[0].discard = [{"id":"basket","basket_symbol":"knife"}]
		g.players[0].hand = [card(g,0,"stones_in_the_belly")]
		g.players[1].hand = [card(g,1,"excalibur")]
		g.attack(0,foe,0)
		if manual: g.continue_attack()
		g = stable(g)
		check(g.players[1].discard.size() == 1 and int(g.last_combat.attack_value) == 5,"Stones discards random enemy card AND adds its boost")
		g = game(["houdini","king_arthur"],manual)
		foe = adjacent(g)
		g.players[0].hand = [card(g,0,"set_the_stage")]
		var deck = g.players[0].deck.size()
		g.scheme(1,0)
		g = stable(g)
		check(g.players[0].deck.size() == deck-2 and g.players[0].hand.size() == 2,"Set The Stage draws three AND puts one back")
		g = game(["houdini","king_arthur"],manual)
		foe = adjacent(g)
		g.players[0].hand = [card(g,0,"for_my_next_trick")]
		deck = g.players[0].deck.size()
		g.attack(0,foe,0)
		if manual: g.continue_attack()
		g = stable(g)
		check(g.players[0].deck.size() == deck-1 and g.actions_left == 2,"Next Trick finishes movement, draws AND grants action")
		g = game(["houdini","king_arthur"],manual)
		foe = adjacent(g)
		g.players[0].hand = [card(g,0,"sleight_of_hand"),card(g,0,"for_my_next_trick")]
		deck = g.players[0].deck.size()
		g.attack(0,foe,0)
		if manual:
			g.continue_attack()
			check(g.pending_choice.action == "v8_sleight","Sleight offers a different attack")
			g.choose_effect_option(0)
		g = stable(g)
		check(g.last_combat.attack_card.id == "for_my_next_trick" and g.players[0].hand.size() == 2 and g.players[0].deck.size() == deck-1 and g.actions_left == 2,"Sleight returns old card AND replacement resolves entire effect chain")
		g = game(["genie","king_arthur"],manual)
		foe = adjacent(g)
		g.players[0].hand = [card(g,0,"prisoners_torment")]
		g.players[1].hand = [raw_card("attack",3)]
		g.active = 1
		deck = g.players[0].deck.size()
		g.attack(foe,0,0)
		if manual: g.continue_attack(); g.defend(0)
		g = stable(g)
		check(int(g.last_combat.damage) == 2 and g.players[0].deck.size() == deck-2,"Torment draws exact combat damage")
		g = game(["genie","king_arthur"],manual)
		foe = adjacent(g)
		g.players[0].hand = [card(g,0,"wishing_for_more_wishes")]
		deck = g.players[0].deck.size()
		var enemy_deck = g.players[1].deck.size()
		g.attack(0,foe,0)
		if manual: g.continue_attack()
		g = stable(g)
		check(g.players[0].deck.size() == deck-3 and g.players[1].deck.size() == enemy_deck-1,"More Wishes draws for opponent AND self")
	# Spending two cards must complete the damage after the payment choices.
	var g = game(["genie","king_arthur"],true)
	var foe = adjacent(g)
	g.players[0].hand = [card(g,0,"imprisoned_wrath"),raw_card("attack",1),raw_card("attack",2)]
	var hp = int(g.fighters[foe].hp)
	g.attack(0,foe,0)
	g.continue_attack()
	g.continue_combat()
	g.choose_effect_option(0)
	g = clone(g)
	g.choose_effect_option(0)
	check(g.phase == "effect_choice" and g.pending_choice.action == "damage","Wrath continues into target choice after paying both cards")
	g.choose_effect_option(0)
	g = stable(g)
	check(g.players[0].discard.size() == 3 and int(g.fighters[foe].hp) == hp-5,"Wrath completes combat damage, two discards AND effect damage")
	# The Beautiful Bess draws under every opponent discard path, including random.
	g = game(["houdini","king_arthur"])
	g.players[0].hand = [card(g,0,"and_the_beautiful_bess")]
	var deck = g.players[0].deck.size()
	g._force_discard(0,1,true)
	check(g.players[0].deck.size() == deck-1 and g.players[0].hand.size() == 1,"Bess draws when an enemy effect discards her")

func all_catalog_cards_v8():
	var catalog = Model.new()
	for hid in catalog.heroes:
		for source in catalog.heroes[hid].cards:
			for manual in [false,true]:
				var g = game([hid,"king_arthur"],manual,{"buffy_sidekick":str(source.get("sidekick_variant","giles"))})
				var own = 1 if str(source.fighter) == "sidekick" else 0
				if hid=="yennefer_triss" and source.fighter=="Трисс":own=1
				var foe = adjacent(g,own)
				g.players[0].hand = [source.duplicate(true),raw_card("versatile",2),raw_card("attack",3)]
				g.players[0].discard = [raw_card("attack",2)]
				g.players[0].rage = 3
				g.jekyll_form[0] = str(source.fighter) if str(source.fighter) in ["jekyll","hyde"] else "jekyll"
				if hid == "willow": g.willow_form[0] = "dark"
				if str(source.id) in ["resurrect","revive_sidekick"]: g.fighters[1].alive = false; g.fighters[1].hp = 0
				if source.type == "scheme": check(g.scheme(own,0),"catalog scheme " + hid + "/" + str(source.id))
				elif source.type == "defense":
					g.active = 1
					g.players[1].hand = [raw_card("attack",4)]
					check(g.attack(foe,own,0),"catalog defend " + str(source.id))
					if manual: g.continue_attack()
					if g.phase == "defend": check(g.defend(0),"catalog defense selection")
				else: check(g.attack(own,foe,0),"catalog attack " + hid + "/" + str(source.id))
				g = stable(g)
				check(g.phase in ["action","discard","game_over"],"whole card chain reaches stable phase " + hid + "/" + str(source.id))
				card_runs += 1
	check(card_runs == catalog.heroes.values().reduce(func(total,h): return total+h.cards.size(),0)*2,"all 284 card definitions execute in human and automatic modes")
func matches_v8():
	var rosters = [["little_red","beowulf"],["houdini","genie"],["houdini","sherlock_holmes"],["beowulf","dracula"],["genie","invisible_man"],["little_red","willow"],V8,V8]
	for level in range(3):
		for manual in [false,true]:
			for i in range(rosters.size()):
				var g = Model.new()
				g.interactive = manual
				g.setup(rosters[i],level,8200+level*50+i,"heorot" if i%2==0 else "king_solomons_mine",{"mode":"teams" if i==7 else "ffa"})
				if not manual:
					for p in g.players: p.bot = true
				var steps = 0
				var prior = failures
				while g.winner < 0 and steps < 3000 and failures == prior:
					advance(g)
					steps += 1
					if steps%31 == 0: g = clone(g)
					validate(g)
				check(g.winner >= 0,"v8 match finishes level=%d human=%s roster=%d phase=%s steps=%d" % [level,manual,i,g.phase,steps])
				matches += 1
				print("V8_MATCH level=%d human=%s roster=%d steps=%d" % [level,manual,i,steps])
func run():
	test_red_v8()
	test_beowulf_v8()
	test_houdini_v8()
	test_genie_v8()
	test_boards_v8()
	test_chained_outcomes_v8()
	all_catalog_cards_v8()
	matches_v8()
	print("V8_ENGINE checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves])
	quit(1 if failures else 0)
