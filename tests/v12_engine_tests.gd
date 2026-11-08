extends "res://tests/v10_engine_tests.gd"
func run():
	for guess in [4,5]:
		var g=game(["sherlock_holmes","king_arthur"],true);var foe=adjacent(g)
		combat(g,foe,0,raw_card("attack",5),card(g,0,"elementary"))
		check(g.pending_choice.action=="v6_elementary_guess" and g._combat_resolution.is_empty(),"human predicts before attack revealed")
		g=clone(g);g.choose_effect_option(guess);g=stable(g)
		check(g.last_combat.attack_cancelled==(guess==5) and g.last_combat.damage==(0 if guess==5 else 2),"Elementary correct and incorrect prediction outcomes")
	var g=game(["king_arthur","sherlock_holmes"],true);var foe=adjacent(g)
	combat(g,0,foe,raw_card("attack",5),card(g,1,"elementary"))
	check(g.pending_choice.action=="v6_elementary_reveal" and g._combat_resolution.is_empty() and g.pending_choice.cards[0].id=="elementary","bot exposes only its defense and announces prediction")
	g=clone(g);g.choose_effect_option(0);g=stable(g)
	for defending in [false,true]:
		g=game(["golden_bat","king_arthur"],true);foe=adjacent(g)
		if defending: combat(g,foe,0,raw_card("attack",2),card(g,0,"terrifying_roar"))
		else: combat(g,0,foe,card(g,0,"terrifying_roar"))
		g=stable(g);var origin=g.fighters[foe].node
		check(g.fighters[foe].locked_until==g.turn_number,"Roar locks opposing fighter")
		g._auto_move(foe,5);g._auto_place(foe)
		check(g.fighters[foe].node==origin and g._reachable(foe,5)==[origin],"bot ordinary movement and placement cannot bypass Roar")
		g.end_turn();g=stable(g)
		check(g._reachable(foe,2).size()>1,"Roar expires at end of current turn, including attacking use")
	for guards_in_zone in [false,true]:
		g=game(["oda_nobunaga","king_arthur"],true);foe=adjacent(g,1)
		g.fighters[0].node=0 if guards_in_zone else 24;g.fighters[1].node=1;g.fighters[2].node=10;g.fighters[foe].node=2;g.fighters[foe+1].node=23
		combat(g,1,foe,raw_card("attack",3),card(g,1,"feint"));g=stable(g)
		check(g.last_combat.attack_value==(4 if guards_in_zone else 3),"Oda inspires Guard in zone and survives Feint")
	for hero_target in [true,false]:
		g=game(["tomoe_gozen","king_arthur"],true);foe=g.hero_fighter(1) if hero_target else g.hero_fighter(1)+1
		g.fighters[0].node=0;g.fighters[foe].node=1
		var hp=g.fighters[foe].hp;g._enter_node(foe,24)
		check(g.fighters[foe].hp==hp-(1 if hero_target else 0),"Tomoe damages departing hero, never sidekick")
	g=game(["tomoe_gozen","king_arthur"],true);foe=adjacent(g);g.fighters[0].node=0;g.fighters[foe].node=1
	var hp=g.fighters[foe].hp;g._enter_node(0,24)
	check(g.fighters[foe].hp==hp,"moving Tomoe never triggers opportunity damage")
	g=game(["tomoe_gozen","king_arthur"],true);foe=adjacent(g)
	combat(g,foe,0,raw_card("attack",10),card(g,0,"deeds_of_valor"));g=stable(g)
	check(g.last_combat.damage==2 and g.fighters[0].hp==12,"Deeds caps actual combat damage")
	g=game(["tomoe_gozen","yennenga"],true);g.fighters[0].node=0;g.fighters[1].node=1;g.fighters[2].node=15;g.fighters[3].node=20
	g._v9._charge_finish({"fighter":1,"origin":1,"position":4,"visited":[1,2,3,2,3,4],"passed":[]},{"owner":1})
	check(g.fighters[1].hp==13 and g.fighters[1].node==4,"Tomoe triggers twice for two exits along a single charge route")
	all_catalog_cards_v8()
	for roster in [["oda_nobunaga","tomoe_gozen"],["tomoe_gozen","golden_bat"],["oda_nobunaga","dr_jill_trent"],["tomoe_gozen","king_arthur","oda_nobunaga","sherlock_holmes"]]:
		for manual in [false,true]:
			g=Model.new();g.interactive=manual;g.setup(roster,2,1212,"marmoreal",{"mode":"teams" if roster.size()==4 else "ffa"})
			if not manual:
				for p in g.players:p.bot=true
			var steps=0
			while g.winner<0 and steps<2500:
				advance(g);steps+=1
				if steps%17==0:g=clone(g)
				validate(g)
			check(g.winner>=0,"new heroes full match finishes " + str(roster));matches+=1
	print("V12_ENGINE checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves])
	quit(1 if failures else 0)
