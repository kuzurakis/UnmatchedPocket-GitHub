extends "res://tests/v9_engine_tests.gd"
func run():
	for manual in [false,true]:
		var g = game(["bloody_mary","king_arthur"],manual)
		var foe = adjacent(g)
		g.players[0].actions_taken = 2
		combat(g,0,foe,card(g,0,"speak_three_times"))
		g = stable(g)
		check(g.last_combat.attack_value == 7,"Speak Three Times uses third action, not action count remaining")
		g = game(["bloody_mary","king_arthur"],manual)
		foe = adjacent(g)
		var hp = int(g.fighters[foe].hp)
		var deck = g.players[0].deck.size()
		combat(g,foe,0,raw_card("attack",3),card(g,0,"broken_glass"))
		g = stable(g)
		check(g.players[0].deck.size() == deck-1 and int(g.fighters[foe].hp) == hp-2,"Broken Glass ties then draws AND deals two damage")
		g = game(["yennenga","king_arthur"],manual)
		foe = adjacent(g)
		g.fighters[1].alive = false
		g.fighters[1].hp = 0
		combat(g,0,foe,card(g,0,"surprise_volley"))
		if manual:
			check(g.pending_choice.action == "v9_archer","Surprise Volley offers Archer placement")
			g = clone(g)
			g.choose_effect_node(int(g.pending_choice.legal[0]))
		g = stable(g)
		check(g.fighters[1].alive and g.fighters[1].hp == 2 and g.last_combat.attacker == 1,"revived Archer becomes actual attacker")
		g = game(["achilles","king_arthur"],manual)
		foe = adjacent(g)
		combat(g,foe,0,raw_card("attack",4),card(g,0,"under_achilles_helm"))
		if manual:
			check(g.pending_choice.action == "v9_helm","Helm offers swap")
			g.choose_effect_option(0)
		g = stable(g)
		check(g.last_combat.target == 1 and g.fighters[1].hp == 4 and g.fighters[0].hp == 18,"Helm changes defender AND applies damage to Patroclus")
		g = game(["sun_wukong","king_arthur"],manual)
		foe = adjacent(g)
		g.fighters[0].hp = 12
		for fid in [1,2]:g.fighters[fid].alive = true; g.fighters[fid].hp = 1
		g.players[0].hand = [card(g,0,"phoenix_form")]
		g.scheme(0,0)
		g = stable(g)
		check(g.fighters[0].hp == 14,"Phoenix heals per living Clone")
		g = game(["sun_wukong","king_arthur"],manual)
		foe = adjacent(g)
		g.players[1].hand = [card(g,1,"excalibur")]
		g.players[0].hand = [card(g,0,"fiery_eyes_that_see")]
		deck = g.players[0].deck.size()
		var enemy_deck = g.players[1].deck.size()
		g.scheme(0,0)
		g = stable(g)
		check(g.players[0].deck.size() == deck-1 and g.players[1].deck.size() == enemy_deck and g.players[1].hand.size() == 1,"Fiery Eyes puts card at bottom AND both players draw")
		check(g.players[1].deck[0].id == "excalibur","chosen enemy card really goes to bottom")
	# Bonus targets remain valid after the first defense moves out of range.
	var g = game(["achilles","king_arthur"],true)
	var foe = adjacent(g)
	g.players[1].bot = false
	g.players[1].hand = [card(g,1,"skirmish"),raw_card("defense",1)]
	g.players[0].hand = [card(g,0,"test_for_weakness")]
	g.attack(0,foe,0);g.continue_attack();g.defend(0);g.continue_combat()
	check(g.phase == "effect_move","first defense prompts Skirmish movement")
	if int(g.pending_choice.get("fighter",-1)) < 0: g.choose_effect_fighter(foe)
	g.choose_effect_node(int(g.pending_choice.legal[-1]))
	check(g.phase == "attack_notice" and g.pending_combat.target == foe,"bonus announcement uses same defender after movement")
	g = stable(g)
	check(g.players[1].discard.size() == 2,"bonus permits second defense outside normal range")
	# Saved route may loop, but each opposing fighter takes damage only once.
	g = game(["yennenga","king_arthur"],true)
	foe = adjacent(g)
	var hp = int(g.fighters[foe].hp)
	direct(g,[{"kind":"v9_charge"}],card(g,0,"stallion_charge"))
	g.choose_effect_node(13)
	g = clone(g)
	g.choose_effect_node(12)
	g.choose_effect_node(13)
	g.choose_effect_node(14)
	g.skip_effect()
	g = stable(g)
	check(int(g.fighters[foe].hp) == hp-1,"Stallion Charge does not hit the same fighter twice after JSON load")
	# New hand-inspection effects respect Houdini's actual privacy card.
	for hid in ["sun_wukong","bloody_mary"]:
		g = game([hid,"houdini"],true)
		adjacent(g)
		g.players[1].hand = [card(g,1,"a_magician_never_reveals_his_secrets")]
		g.players[0].hand = [card(g,0,"fiery_eyes_that_see" if hid == "sun_wukong" else "stolen_memories")]
		g.scheme(0,0)
		g = stable(g)
		check(g.players[1].hand.size() == 1 and g.players[1].discard.is_empty(),"Houdini blocks new peek effect " + hid)
	# The original +1 arrows modify attack only in their pictured direction.
	g = game(["achilles","king_arthur"])
	g.setup(["achilles","king_arthur"],1,99,"hanging_gardens")
	for p in g.players:p.bot = true
	g.fighters[0].node = 1;g.fighters[1].node = 0;g.fighters[2].node = 2;g.fighters[3].node = 6
	combat(g,0,2,raw_card("attack",3),card(g,1,"feint"))
	check(g.last_combat.attack_value == 4,"high ground cannot be canceled by Feint")
	check(g._v9.high_ground(2,1) == 0 and g.nodes[1].neighbors.has(2) and g.nodes[2].neighbors.has(1),"high ground does not restrict reverse movement")
	print("V9_EFFECT_RESULTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
