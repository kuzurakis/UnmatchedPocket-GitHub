extends "res://tests/v15_rules_tests.gd"
func run():
	var g=game(["eredin","king_arthur","alice","sinbad"],true,{"mode":"teams"});var foe=adjacent(g);var ally=g.hero_fighter(2);g.fighters[ally].node=11
	combat(g,foe,0,raw_card("attack",3),card(g,0,"portal_defense"));check(g.pending_choice.ids.has(ally),"portal accepts adjacent teammate fighter")
	var hp=g.fighters[ally].hp;var ownhp=g.fighters[0].hp;g=clone(g);g.choose_effect_fighter(ally);g=stable(g)
	check(g.last_combat.defense_card_owner==0 and g.last_combat.target==ally and g.fighters[ally].hp==hp-3 and g.fighters[0].hp==ownhp,"allied replacement actually takes damage")
	check(g.players[0].discard.any(func(c):return c.id=="portal_defense") and not g.players[2].discard.any(func(c):return c.id=="portal_defense"),"allied portal preserves original defense card owner")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g,1);kill_riders(g,1);g.players[0].ongoing=card(g,0,"might_of_the_aen_elle")
	combat(g,foe,1,raw_card("attack",3),card(g,0,"icy_guile"));g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(not g.fighters[1].alive and g._v15.enraged(0) and g.last_combat.damage==0,"Rider can sacrifice itself while defending; Might cannot prevent defeat payment")
	g=game(["eredin","geralt_of_rivia"],true);foe=adjacent(g);kill_riders(g);g.players[1].ongoing=card(g,1,"gear_tawny_owl");g.players[0].hand=[card(g,0,"backhand")];g.players[1].hand=[raw_card("scheme",0)];g.attack(0,foe,0);g.continue_attack();g=stable(g)
	check(g.players[1].hand.size()==1 and g.players[1].discard.is_empty(),"Owl blocks enraged Backhand forced discard")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g,1);g.fighters[2].alive=false;g.fighters[2].hp=0
	combat(g,1,foe,card(g,0,"unyielding_hordes"),card(g,1,"feint"));g=stable(g)
	check(not g.fighters[2].alive and g.last_combat.attack_cancelled,"cancelled Hordes neither revives nor adds neighbor bonus")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);g.players[0].hand=[card(g,0,"close_for_the_kill")];g.fighters[0].node=0;g.fighters[foe].node=1;g.fighters[1].node=10;g.fighters[2].node=11;g.fighters[3].node=12;g.fighters[4].node=13;g.fighters[foe+1].node=24
	g.scheme(0,0);g.choose_effect_fighter(0);check(g.pending_choice.legal.has(2) and not g.pending_choice.legal.has(1),"Close passes through enemy but cannot end on occupied space")
	g=clone(g);g.choose_effect_node(2);g=stable(g);check(g.fighters[0].node==2,"through-enemy move survives save/load and executes")
	g=game(["eredin","ancient_leshen"],true);kill_riders(g);g.players[0].hand=[card(g,0,"foul_purpose")];var absent=g.hero_fighter(1);g.fighters[absent].offboard=true
	check(not g.legal_targets(0,0).has(absent),"global attack excludes off-board Leshen")

	for board in ["naglfar","streets_of_novigrad"]:
		for slot in range(4):
			g=Model.new();g.setup(["eredin","king_arthur"],1,1515,board,{"start_slots":[slot,(slot+1)%4],"human_placement":true})
			var count=0
			while g.setup_fighter>=0 and count<10:
				var legal=g.legal_setup_nodes(g.setup_fighter);check(not legal.is_empty(),"manual Eredin deployment has room for every Rider")
				if legal.is_empty():break
				g.place_setup_fighter(g.setup_fighter,int(legal[-1]));count+=1
			check(g.finish_setup() and count==5,"all four starting zones fit hero plus four Riders "+board+" "+str(slot))
			validate(g)
	print("V15_EDGES checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
