extends "res://tests/v10_engine_tests.gd"
func run():
	var g = game(["nikola_tesla","king_arthur"],true)
	var foe = adjacent(g)
	g.players[0].coils = 2
	combat(g,foe,0,raw_card("attack",9),card(g,0,"polyphase_coils"))
	g.choose_effect_option(2)
	g = stable(g)
	check(g.last_combat.damage == 0 and g.last_combat.attack_cancelled and g.fighters[0].hp == 14,"two-coil Polyphase both cancels effects and ignores opposing value")
	g = game(["nikola_tesla","king_arthur"],true)
	foe = adjacent(g)
	g.players[0].coils = 2
	g.players[1].deck[-1].boost = 4
	var top = g.players[1].deck[-1].id
	var deck = g.players[1].deck.size()
	combat(g,0,foe,card(g,0,"x_ray_radiation"))
	check(g.pending_choice.action == "v10_reveal" and g.players[1].deck.size() == deck,"X-ray shows card before spending or discarding")
	g = clone(g);g.choose_effect_option(0)
	check(g.pending_choice.action == "v10_coils","X-ray continues to optional coil decision")
	g.choose_effect_option(2)
	g = stable(g)
	check(g.players[1].deck.size() == deck-1 and g.players[1].discard[-1].id == top and g.last_combat.attack_value == 8,"X-ray discards revealed card AND adds its BOOST")
	g = game(["king_arthur","annie_christmas"],true)
	foe = adjacent(g)
	g.players[1].hand = [card(g,1,"quite_a_pair"),card(g,1,"lagniappe"),card(g,1,"lagniappe")]
	g.players[0].hand = [raw_card("attack",3)]
	g.attack(0,foe,0);g.continue_attack()
	check(g.pending_choice.action == "v10_reveal" and g.pending_choice.cards.size() == 2 and g.pending_choice.viewer == 0,"bot reveals matching pair to human rather than silently cancelling")
	g = stable(g)
	check(g.players[1].hand.size() == 2 and g.last_combat.attack_cancelled,"pair cancels without discarding revealed cards")
	g = game(["king_arthur","annie_christmas"],true)
	var charlie = 3
	adjacent(g,0,charlie)
	g.players[1].hand = [card(g,1,"bottom_dealing")]
	g.players[0].hand = []
	g.active = 1
	g.attack(charlie,0,0);g.continue_attack();g.defend(-1)
	check(g.pending_choice.action == "v10_reveal" and g.pending_choice.card_owners == [1],"bot Bottom Dealing publicly reveals its card before deciding placement")
	g = stable(g)
	for manual in [false,true]:
		g = game(["golden_bat","king_arthur"],manual)
		adjacent(g)
		direct(g,[{"kind":"v10_roar"},{"kind":"place","target":"self"},{"kind":"move","target":"all_enemies","spaces":2}])
		var before = g.fighters.map(func(f):return f.node)
		g = stable(g)
		check(g.fighters.map(func(f):return f.node) == before,"Roar prevents placement and enemy movement in same turn")
		g.turn_number += 1
		check(g._effect_reachable(0,1,false).size() > 1,"Roar movement lock expires next turn")
	print("V10_EFFECT_RESULTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
