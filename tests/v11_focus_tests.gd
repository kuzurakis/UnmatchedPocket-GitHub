extends "res://tests/v10_engine_tests.gd"
func run():
	var g = game(["little_red","king_arthur"])
	var symbols = []
	for pile in [g.players[0].hand,g.players[0].deck]:
		for c in pile:
			if c.id == "into_the_woods": symbols.append(c.basket_symbol)
	symbols.sort()
	check(symbols == ["flower","knife","pelt"],"Into the Woods has one physical copy per basket symbol")
	for symbol in ["pelt","knife","flower","wild"]:
		g = game(["little_red","king_arthur"],true)
		var foe = adjacent(g)
		g.players[0].discard = [card(g,0,"what_s_that_in_my_basket")]
		g.players[0].discard[-1].basket_symbol = symbol
		var deck = g.players[0].deck.size()
		combat(g,foe,0,raw_card("attack",2),card(g,0,"the_wolf_s_skin"))
		g = stable(g)
		check(g.players[0].deck.size() == deck-(2 if symbol in ["pelt","wild"] else 0),"Wolf Skin reads current top discard " + symbol)
		g = game(["little_red","king_arthur"],true)
		foe = adjacent(g)
		g.players[0].discard = [{"id":"prior","name":"Prior","basket_symbol":symbol}]
		var hp = g.fighters[foe].hp
		combat(g,0,foe,card(g,0,"once_upon_a_time"))
		g = stable(g)
		check(g.fighters[foe].hp == hp-2-(3 if symbol in ["knife","wild"] else 0),"Once Upon a Time uses basket before this combat card enters discard " + symbol)
	g = game(["yennenga","ingen"],true)
	adjacent(g)
	g.fighters[1].node = 7;g.fighters[2].node = 17
	g.traps = [{"id":0,"owner":1,"node":11}]
	g.begin_maneuver()
	check(g.move_fighter(0,11),"Yennenga enters enemy trap")
	check(g.phase == "effect_choice" and g.pending_choice.get("action","") == "v9_damage","trap damage allocation opens immediately before any other movement/action")
	if g.phase == "effect_choice": g.choose_effect_option(1)
	g = stable(g)
	check(g.fighters[0].hp == 15 and g.fighters[1].hp == 1,"trap damage redirects to chosen in-zone Archer")
	for manual in [false,true]:
		g = game(["king_arthur","yennenga"],manual)
		var y = g.hero_fighter(1)
		g.fighters[y].node = 13
		g.fighters[y+1].node = 7;g.fighters[y+1].hp = 1
		g.fighters[y+2].node = 17;g.fighters[y+2].hp = 1
		g.fighters[0].node = 12
		direct(g,[{"kind":"adjacent_damage","target":"opponents","amount":1}])
		g = stable(g)
		check(g.fighters[y].hp == 14 and not g.fighters[y+1].alive and not g.fighters[y+2].alive,"simultaneous AoE cannot disappear into an Archer already receiving lethal damage")
	# Old v0.10 saves retain their cards while the three formerly wild copies
	# acquire distinct printed symbols. Re-saving must not reshuffle that identity.
	g = game(["little_red","king_arthur"])
	var state = g.save_state();state.version=10
	for pile in ["deck","hand","discard"]:
		for copy in state.players[0][pile]:
			if copy.id == "into_the_woods": copy.erase("basket_copy");copy.basket_symbol="wild"
	check(g.load_state(JSON.parse_string(JSON.stringify(state))),"legacy Red save loads")
	symbols=[]
	for pile in [g.players[0].deck,g.players[0].hand,g.players[0].discard]:
		for copy in pile:
			if copy.id == "into_the_woods": symbols.append(copy.basket_symbol)
	symbols.sort();check(symbols == ["flower","knife","pelt"],"legacy copies receive one symbol each without losing cards")
	var before=JSON.stringify(g.players[0]);g=clone(g)
	check(JSON.stringify(g.players[0]) == before,"new copy identities stable after JSON save")
	# Allocation is per incoming event; absorbing all combat damage still counts
	# as damage dealt for the attacker and their draw effect.
	g = game(["yennenga","robin_hood"],true)
	var foe=adjacent(g);g.fighters[1].node=7;g.fighters[2].node=17
	var deck=g.players[1].deck.size();var hp=g.fighters[0].hp
	combat(g,foe,0,card(g,1,"disarming_shot"))
	for i in range(4): g=clone(g);g.choose_effect_option(1)
	g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.players[1].deck.size() == deck-4 and g.last_combat.damage == 4 and g.fighters[0].hp == hp,"Disarming Shot draws full dealt damage even when all four redirected")
	# Exhaustion damages every Archer first and is never redirected away.
	g = game(["yennenga","king_arthur"],true);g.players[0].deck.clear()
	g.begin_maneuver()
	check(g.fighters[0].hp == 13 and not g.fighters[1].alive and not g.fighters[2].alive and g._deferred_damage.is_empty(),"exhaustion damages all fighters without disappearing")
	# Resolve a separate damage event completely before continuing the next one.
	g = game(["yennenga","king_arthur"],true);foe=adjacent(g);g.fighters[1].node=7;g.fighters[2].node=17
	direct(g,[{"kind":"damage","target":"opposing_combatant","amount":1},{"kind":"damage","target":"opposing_combatant","amount":2}],{},1,0)
	check(g.pending_choice.amount == 1,"first effect packet awaits distribution")
	g.choose_effect_option(1);g=clone(g)
	check(g.pending_choice.amount == 2 and g.fighters[1].hp == 1,"second effect packet starts after first resolves")
	g.choose_effect_option(1);g.choose_effect_option(1);g=stable(g)
	check(g.fighters[0].hp == 15 and g.fighters[2].hp == 1,"multiple events conserve damage and use surviving Archers")
	# A lethal immediate effect ends the duel before a defeated attacker hits.
	g = game(["king_arthur","beowulf"],true);foe=adjacent(g)
	g.fighters[0].hp=5;g.players[1].rage=2
	var enemy_hp=g.fighters[foe].hp
	combat(g,0,foe,card(g,0,"excalibur"),card(g,1,"the_equal_of_grendel"))
	check(g.phase == "game_over" and g.winner == 1 and g.fighters[foe].hp == enemy_hp,"immediate lethal damage ends duel before combat damage")
	# In FFA the match continues after Patroclus falls, but a defeated fighter
	# cannot pay a later self-damage cost to turn Doom into value five.
	g=Model.new();g.setup(["achilles","beowulf","alice"],1,1111,"training")
	g.fighters[0].node=0;g.fighters[1].node=12;g.fighters[1].hp=1;g.fighters[2].node=13;g.fighters[3].node=17;g.fighters[4].node=24;g.fighters[5].node=23
	g.players[1].rage=2
	combat(g,1,2,card(g,0,"the_day_of_your_doom"),card(g,1,"the_equal_of_grendel"));g=stable(g)
	check(not g.fighters[1].alive and g.last_combat.attack_value == 3,"dead Patroclus cannot pay during-combat self-damage")
	# Restless Spirits' kill reward waits until Yennenga has redirected damage.
	g=game(["yennenga","king_arthur"],true);g.players[1].bot=false;g.active=1
	g.fighters[0].node=13;g.fighters[1].node=3;g.fighters[2].node=18;g.fighters[3].node=0;g.fighters[4].node=12
	g.players[1].hand=[card(g,1,"restless_spirits")]
	deck=g.players[1].deck.size()
	check(g.scheme(4,0),"Merlin starts Spirits against Yennenga")
	g.choose_effect_node(13);g.choose_effect_node(14)
	check(g.pending_choice.action == "v9_damage","Spirits pauses for damage assignment")
	g.choose_effect_option(1);g.choose_effect_option(1);g=stable(g)
	check(g.players[1].deck.size() == deck-1 and g.fighters[0].hp == 15 and not g.fighters[1].alive,"Spirits draws for Archer defeated by redirected damage")
	for adjacent_jill in [false,true]:
		g=game(["dr_jill_trent","king_arthur"],true);foe=adjacent(g,1)
		g.fighters[0].node=11 if adjacent_jill else 0;g.players[0].gadget="hypno";g.players[1].deck[-1].boost=3
		var defense=raw_card("defense",4);defense.effects=[{"timing":"immediately","kind":"cancel"}]
		combat(g,1,foe,card(g,0,"sisters_in_arms"),defense);g=stable(g)
		check(g.last_combat.attack_value == (6 if adjacent_jill else 3) and not g.last_combat.attack_cancelled,"Sisters gives adjacent Daisy the gadget and remains uncancellable")
	# A mid-combat BOOST changes the basket before Red's later DURING effect.
	g=game(["little_red","sun_wukong"],true);foe=adjacent(g);g.players[1].bot=false
	g.players[0].discard=[card(g,0,"what_big_ears_you_have")]
	g.players[0].hand=[card(g,0,"stones_in_the_belly"),card(g,0,"long_have_i_sought_you")]
	g.players[1].hand=[card(g,1,"tortoise_form"),raw_card("versatile",3)]
	g.attack(0,foe,0);g.continue_attack();g.defend(0)
	check(g.pending_choice.get("action","") == "combat_boost","Tortoise Form offers attacker optional BOOST")
	g.choose_effect_option(0)
	check(g._v8.basket(0) == "knife" and g.last_combat.attack_value == 6 and g.players[1].hand.is_empty(),"BOOST changes basket in time for Stones to discard and add opposing BOOST")
	g=stable(g);check(g._v8.basket(0) == "flower","played combat card becomes basket only after all its effects")
	print("V11_FOCUS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
