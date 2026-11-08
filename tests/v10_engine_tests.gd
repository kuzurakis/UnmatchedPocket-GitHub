extends "res://tests/v9_engine_tests.gd"
const V10 = ["nikola_tesla","dr_jill_trent","annie_christmas","golden_bat"]
func test_tesla():
	for count in range(3):
		var g = game(["nikola_tesla","king_arthur"],true)
		var foe = adjacent(g)
		g.players[0].coils = 2
		g.players[0].hand = [card(g,0,"death_ray")]
		g.attack(0,foe,0);g.continue_attack()
		check(g.pending_choice.action == "v10_coils","Tesla asks coil cost")
		g = clone(g)
		g.choose_effect_option(count)
		g = stable(g)
		check(int(g.last_combat.attack_value) == [3,5,7][count] and g._v10.coils(0) == 2-count,"Death Ray exact coil value and cost")
		g = game(["nikola_tesla","king_arthur"],true)
		foe = adjacent(g)
		g.players[0].coils = 2
		g.fighters[0].hp = 10
		var deck = g.players[0].deck.size()
		combat(g,foe,0,raw_card("attack",1),card(g,0,"intense_experimentation"))
		g.continue_combat();g.choose_effect_option(count)
		g = stable(g)
		check(g.players[0].deck.size() == deck-count-1 and g.fighters[0].hp == (11 if count == 2 else 10),"Experimentation draws correct replacement amount AND heals for two coils")
	var g = game(["nikola_tesla","king_arthur"],true)
	var foe = adjacent(g)
	g.players[0].coils = 2
	var hp = int(g.fighters[foe].hp)
	g._start_turn_ability()
	check(g.phase == "effect_move" and int(g.fighters[foe].hp) == hp-1,"Tesla overflow damages then offers enemy movement")
	g = stable(g)
	check(g._v10.coils(0) == 2,"overflow does not discharge coils")
	g.players[0].coils = 0
	g.end_turn()
	check(g.pending_choice.action == "v10_end_charge","end of turn offers optional charge")
	g.choose_effect_option(0)
	g = stable(g)
	check(g.active == 1 and g._v10.coils(0) == 1,"charge finishes turn exactly once")
func test_gadgets():
	var g = game(["dr_jill_trent","king_arthur"],true)
	var foe = adjacent(g)
	g.players[0].gadget = "hypno"
	g.players[1].deck[-1] = raw_card("attack",1)
	combat(g,0,foe,card(g,0,"battle_of_wits"),raw_card("defense",4))
	check(g.pending_choice.action == "v10_reveal","gadget reveals top deck with a visible window")
	g = stable(g)
	check(g.last_combat.attack_value == 4,"Hypnoray adds revealed BOOST")
	g = game(["dr_jill_trent","king_arthur"],true)
	foe = adjacent(g)
	g.players[0].gadget = "hypno"
	combat(g,0,foe,card(g,0,"battle_of_wits"),card(g,1,"feint"))
	g = stable(g)
	check(g.last_combat.attack_cancelled,"opponent Feint cancels ordinary Jill card effects")
	g = game(["dr_jill_trent","king_arthur"])
	foe = adjacent(g)
	g.players[0].gadget = "tonic"
	g.fighters[0].hp = 8
	combat(g,0,foe,card(g,0,"energizing_spray"),card(g,1,"feint"))
	check(g.fighters[0].hp == 9 and g.last_combat.attack_cancelled,"Tonic hero ability heals even when Feint cancels attack card")
	g = game(["dr_jill_trent","king_arthur"],true)
	foe = adjacent(g)
	g.players[0].gadget = "tonic"
	g.players[0].deck[-1] = raw_card("attack",1)
	g.players[0].deck[-1].boost = 4
	g.players[1].deck[-1] = raw_card("attack",1)
	g.players[1].deck[-1].boost = 1
	var hp = int(g.fighters[foe].hp)
	combat(g,0,foe,card(g,0,"battle_of_wits"),raw_card("defense",2))
	g = stable(g)
	check(g.fighters[foe].hp == hp-3 and g.players[0].deck[-1].boost == 4 and g.players[1].deck[-1].boost == 1,"Battle of Wits reveals both cards, deals three and leaves cards on top")
func test_annie_bat():
	var g = game(["annie_christmas","king_arthur"],true)
	var foe = adjacent(g)
	g.fighters[0].hp = 8
	combat(g,0,foe,card(g,0,"lagniappe"))
	check(g.pending_choice.action == "v10_lagniappe","Lagniappe asks damage payment")
	var deck = g.players[0].deck.size()
	g.choose_effect_option(2)
	g = stable(g)
	check(g.fighters[0].hp == 6 and g.players[0].deck.size() == deck-2 and g.last_combat.attack_value == 7,"Lagniappe damage and draw turn on Annie attack bonus")
	g = game(["annie_christmas","king_arthur"])
	foe = adjacent(g)
	g.fighters[0].hp = 1
	combat(g,foe,0,raw_card("attack",10),card(g,0,"mississippi_queen"))
	check(g.fighters[0].hp == 1 and g.last_combat.damage == 0,"Queen prevents lethal damage and defender wins with no damage taken")
	for maneuver in [false,true]:
		g = game(["golden_bat","king_arthur"])
		foe = adjacent(g)
		if maneuver: g.begin_maneuver();g.finish_maneuver()
		combat(g,0,foe,card(g,0,"super_strength"),card(g,1,"feint"))
		check(g.last_combat.attack_value == (5 if maneuver else 7),"Golden Bat bonus depends on taking maneuver, including zero movement")
	g = game(["golden_bat","king_arthur"],true)
	adjacent(g)
	g.players[0].hand = [card(g,0,"alpine_fortress")]
	g.players[0].discard = [card(g,0,"super_strength")]
	deck = g.players[0].deck.size()
	g.scheme(0,0)
	g = stable(g)
	check(g.players[0].deck.size() == deck-1 and g.players[0].hand.size() == 2,"Fortress shuffles, draws two AND finishes movement")
func test_deck_order():
	var g = game(["dr_jill_trent","king_arthur"],true)
	adjacent(g)
	var originals = [raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)]
	for c in originals: c.id = "top"+str(int(c.value));c.name = c.id
	g.players[1].deck = originals.duplicate(true)
	direct(g,[{"kind":"v10_inspect","bottom":true}],card(g,0,"insightful_deduction"))
	check(g.pending_choice.cards.size() == 3 and g.players[1].deck.is_empty(),"inspection holds all three cards in saved choice")
	g = clone(g);g.choose_effect_option(1)
	g = clone(g);g.choose_effect_option(0)
	g = clone(g);g.choose_effect_option(0)
	g = stable(g)
	check(g.players[1].deck[0].id == "top2" and g.players[1].deck[-1].id == "top3","inspection puts chosen card at bottom and chosen first card on top")
	g = game(["dr_jill_trent","king_arthur"],true)
	adjacent(g)
	g.players[0].discard = [card(g,0,"hypnotist"),card(g,0,"ace_fighter"),card(g,0,"battle_of_wits")]
	g.players[0].hand = [card(g,0,"helpful_assistant")]
	var deck = g.players[0].deck.size()
	g.scheme(1,0)
	check(g.pending_choice.indices.size() == 2,"Assistant only offers Jill banner cards, not Daisy cards")
	g.choose_effect_option(0)
	g = clone(g);g.skip_effect()
	g = stable(g)
	check(g.players[0].deck.size() == deck and g.players[0].hand.size() == 1,"Assistant shuffles selected one and mandatory draw still runs after early finish")
func matches_v10():
	var rosters = [["nikola_tesla","dr_jill_trent"],["annie_christmas","golden_bat"],["dr_jill_trent","sun_wukong"],["golden_bat","yennenga"],V10,V10]
	for level in range(3):
		for manual in [false,true]:
			for i in range(rosters.size()):
				var g = Model.new()
				g.interactive = manual
				g.setup(rosters[i],level,10100+level*50+i,"point_pleasant" if i%2 == 0 else "mcminnville_or",{"mode":"teams" if i == 5 else "ffa"})
				if not manual:
					for p in g.players: p.bot = true
				var steps = 0
				var prior = failures
				while g.winner < 0 and steps < 3000 and prior == failures:
					advance(g)
					steps += 1
					if steps%23 == 0: g = clone(g)
					validate(g)
				check(g.winner >= 0,"TTA game completes level=%d manual=%s roster=%d phase=%s" % [level,manual,i,g.phase])
				matches += 1
				print("V10_MATCH ",level," ",manual," ",i," steps=",steps)
func run():
	test_tesla()
	test_gadgets()
	test_annie_bat()
	test_deck_order()
	all_catalog_cards_v8()
	matches_v10()
	print("V10_ENGINE checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves])
	quit(1 if failures else 0)
