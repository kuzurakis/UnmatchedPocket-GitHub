extends "res://tests/v14_rules_tests.gd"
func kill_riders(g, except=-1):
	for id in g._v15.riders(0):
		if int(id)!=except:g.fighters[int(id)].alive=false;g.fighters[int(id)].hp=0
func wait_choice(g, action):
	for i in range(30):
		if g.pending_choice.get("action",g.pending_choice.get("kind",""))==action:return g
		if g.phase in ["action","game_over"]:break
		advance(g)
	check(false,"expected "+action);return g
func test_rage():
	var g=game(["eredin","king_arthur"],true);var foe=adjacent(g)
	check(not g._v15.enraged(0) and g._movement(0)==2 and g._v15.riders(0).size()==4,"four Riders, ordinary move 2")
	kill_riders(g,4);check(not g._v15.enraged(0),"one survivor prevents rage")
	g._damage(4,1);g=clone(g);check(g._v15.enraged(0) and g._movement(0)==3,"last defeat activates rage immediately and persists")
	combat(g,0,foe,raw_card("attack",3),raw_card("defense",8));g=stable(g);check(g.last_combat.attack_value==4,"rage adds exactly one to attack")
	combat(g,foe,0,raw_card("attack",3),raw_card("defense",3));g=stable(g);check(g.last_combat.defense_value==4,"rage also adds one to defense")
	combat(g,foe,0,raw_card("attack",1));g=stable(g);check(g.last_combat.defense_value==0,"no bonus without defense card")
	direct(g,[{"kind":"v15_revive"}],card(g,0,"unyielding_hordes"));g=clone(g);g.choose_effect_option(0);check(g.phase=="effect_move","revival requests destination")
	g=clone(g);g.choose_effect_node(int(g.pending_choice.legal[-1]));g=stable(g)
	check(not g._v15.enraged(0) and g._movement(0)==2 and g.fighters[1].hp==1,"returning Rider immediately ends rage")
func test_strikes():
	for rage in [false,true]:
		var g=game(["eredin","king_arthur"],true);var foe=adjacent(g)
		if rage:kill_riders(g)
		combat(g,0,foe,card(g,0,"brutal_strike"),card(g,1,"feint"));g=stable(g)
		check(not g.last_combat.attack_cancelled and g.last_combat.damage==(3 if rage else 2),"Brutal Strike ignores immediate card and resists cancel")
		g=game(["eredin","king_arthur"],true);foe=adjacent(g)
		if rage:kill_riders(g)
		combat(g,0,foe,card(g,0,"brutal_strike"),raw_card("defense",6));g=stable(g)
		check(g.last_combat.damage==0,"Brutal Strike respects defense without immediate effect")
		g=game(["eredin","king_arthur"],true);foe=adjacent(g)
		if rage:kill_riders(g)
		g.players[1].hand=[raw_card("scheme",0)];var n=g.players[1].deck.size()
		g.players[0].hand=[card(g,0,"backhand")];g.attack(0,foe,0);g.continue_attack();g=stable(g)
		check(g.players[1].hand.is_empty() and g.players[1].deck.size()==n+int(not rage) and g.players[1].discard.size()==int(rage),"Backhand random topdeck versus enraged discard")
	var g=game(["eredin","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[card(g,0,"foul_purpose")];g.fighters[0].node=0;g.fighters[foe].node=24
	check(not g.legal_targets(0,0).has(foe),"Foul Purpose ordinary range")
	kill_riders(g);check(g.legal_targets(0,0).has(foe),"enraged Foul Purpose targets any space")
	g.attack(0,foe,0);check(g.pending_combat.face_up,"global attack publicly revealed before defense");g=stable(g)
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"foul_purpose"),raw_card("defense",8));g=wait_choice(g,"v15_sacrifice")
	g=clone(g);g.choose_effect_fighter(1);g=stable(g)
	check(not g.fighters[1].alive and g.players[0].hand.any(func(c):return c.id=="foul_purpose") and not g.players[0].discard.any(func(c):return c.id=="foul_purpose"),"Foul Purpose pays Rider and returns only played card")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"foul_purpose"),raw_card("defense",8));g=wait_choice(g,"v15_sacrifice");check(g.skip_effect(),"sacrifice optional");g=stable(g)
	check(g._v15.riders(0).size()==4 and g.players[0].discard.any(func(c):return c.id=="foul_purpose"),"decline keeps Riders, discards attack")
func test_hordes_and_hunt():
	var g=game(["eredin","king_arthur"],true);var foe=adjacent(g,1);g.fighters[0].node=0;g.fighters[2].node=14;g.fighters[3].alive=false;g.fighters[3].hp=0
	combat(g,1,foe,card(g,0,"unyielding_hordes"),raw_card("defense",10));check(g.pending_choice.action=="v15_revive","Hordes revives during immediate step")
	g=clone(g);g.choose_effect_option(0);g=clone(g);g.choose_effect_node(18);g=stable(g)
	check(g.fighters[3].alive and g.last_combat.attack_value==3,"Hordes counts other friendly neighbors including revived Rider")
	for rage in [false,true]:
		g=game(["eredin","king_arthur"],true);foe=adjacent(g)
		if rage:kill_riders(g)
		# Two friendly fighters adjacent to the same target must not double the packet.
		g.fighters[1].node=14;var hp=g.fighters[foe].hp
		combat(g,0,foe,card(g,0,"wild_hunt"),raw_card("defense",10));g=stable(g)
		check(g.fighters[foe].hp==hp-(2 if rage else 1),"Hunt applies once per enemy, correct rage branch")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"skirmish"));g=wait_choice(g,"move")
	check(g.phase=="effect_move" and g.pending_choice.allowed_fighters.has(0) and g.pending_choice.allowed_fighters.has(foe),"Skirmish winning combat offers either fighter")
	g=stable(g)
func test_icy_implacable():
	var g=game(["eredin","king_arthur"],true);var foe=adjacent(g);kill_riders(g,1)
	combat(g,foe,0,raw_card("attack",7),card(g,0,"icy_guile"));check(g.pending_choice.action=="v15_sacrifice","Icy Guile optional during sacrifice")
	g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.last_combat.damage==0 and g._v15.enraged(0) and g.last_combat.defense_value==3,"last sacrifice ignores attack and activates same-combat bonus")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);kill_riders(g)
	combat(g,0,foe,card(g,0,"icy_guile"),card(g,1,"skirmish"));g=stable(g)
	check(g.last_combat.defense_cancelled,"enraged Icy Guile cancels remaining effects")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);g.players[0].hand=[card(g,0,"implacable"),raw_card("scheme",0)]
	check(g.legal_targets(0,0).is_empty(),"Implacable cannot attack without rage");kill_riders(g);check(g.legal_targets(0,0).has(foe),"Implacable may attack in rage")
	g.attack(0,foe,0);g.continue_attack();check(g.pending_choice.action=="combat_boost","Implacable offers paid boost");g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.last_combat.attack_value==6 and g.players[0].hand.is_empty(),"boost plus rage attack totals six, cost paid")
	g=game(["eredin","king_arthur"],true);foe=adjacent(g);g.players[0].hand=[card(g,0,"implacable"),raw_card("scheme",0)];g.players[1].hand=[raw_card("attack",6)];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g.choose_effect_option(0);g=stable(g)
	check(g.last_combat.defense_value==5 and g.last_combat.damage==1,"Implacable normal defense boost works")
func test_portal():
	for locked in [false,true]:
		var g=game(["eredin","king_arthur"],true);var foe=adjacent(g);g.fighters[1].node=11;var hp=g.fighters[0].hp
		if locked:g.fighters[1].locked_until=g.turn_number
		combat(g,foe,0,raw_card("attack",3),card(g,0,"portal_defense"))
		if not locked:
			check(g.pending_choice.action=="v15_portal","portal choice before combat damage");g=clone(g);g.choose_effect_option(0)
		g=stable(g)
		check(g.last_combat.target==(0 if locked else 1),"portal updates actual defender and respects movement lock")
		check(g.fighters[0].hp==hp-(3 if locked else 0),"portal damage received by replacement only")
		check(g.players[0].discard.any(func(c):return c.id=="portal_defense"),"defense goes to Eredin discard")
	var g=game(["eredin","king_arthur"],true);var foe=adjacent(g);kill_riders(g,1);g.fighters[1].node=11;var deck=g.players[0].deck.size()
	combat(g,foe,0,raw_card("attack",4),card(g,0,"portal_defense"));g.choose_effect_option(0);g=stable(g)
	check(g._v15.enraged(0) and g.players[0].deck.size()==deck-2,"last Rider dies as defender, after-combat rage draws two")
func test_schemes():
	var g=game(["eredin","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[card(g,0,"might_of_the_aen_elle")];var deck=g.players[0].deck.size()
	g.scheme(0,0);g=stable(g);check(g.actions_left==2 and g.players[0].deck.size()==deck-1 and g._v14.ongoing(0)=="might_of_the_aen_elle","Might draws, gains action, stays outside discard")
	var hp=g.fighters[0].hp;g._damage(0,3);g._damage_many([0],2);check(g.fighters[0].hp==hp,"Might stops direct and area effect damage")
	g._damage(1,1);check(not g.fighters[1].alive,"Might protects Eredin only")
	combat(g,foe,0,raw_card("attack",2));g=stable(g);check(g.fighters[0].hp==hp-2,"Might allows combat damage")
	g.players[0].deck=[];g._draw(0);check(g.fighters[0].hp==hp-4,"Might allows exhaustion damage")
	g.phase="action";g.active=0;g.end_turn();g=stable(g);check(g._v14.ongoing(0)=="","Might discarded on own end without attack")
	g=game(["eredin","king_arthur"],true);g.players[0].ongoing=card(g,0,"might_of_the_aen_elle");g._v14.attack_started(1);g.end_turn();g=stable(g);check(g._v14.ongoing(0)=="might_of_the_aen_elle","Rider attack sustains ongoing Might")
	g=game(["eredin","king_arthur"],true);g.players[0].hand=[card(g,0,"close_for_the_kill")];deck=g.players[0].deck.size();g.scheme(0,0)
	check(g.phase=="effect_move" and g.pending_choice.allowed_fighters.size()==5,"Close for the Kill offers all five fighters");g=stable(g);check(g.players[0].deck.size()==deck-2,"Close draws exactly two cards")
func test_maps():
	for board in ["naglfar","streets_of_novigrad"]:
		var g=Model.new();g.setup(["eredin","geralt_of_rivia","ciri","ancient_leshen"],1,1515,board,{"mode":"teams"})
		check(g.nodes.size()==(28 if board=="naglfar" else 34) and g.start_slots.size()==4,"new board exact size and four starts")
		for n in g.nodes:
			for other in n.neighbors:check(g.nodes[int(other)].neighbors.has(int(n.id)),"board adjacency symmetric including deck connectors")
		validate(g)
func run():
	test_rage();test_strikes();test_hordes_and_hunt();test_icy_implacable();test_portal();test_schemes();test_maps()
	all_catalog_cards_v8()
	for level in range(3):
		for manual in [false,true]:
			for roster in [["eredin","ciri"],["eredin","ancient_leshen","geralt_of_rivia"],["eredin","geralt_of_rivia","ciri","oda_nobunaga"]]:
				var g=Model.new();g.interactive=manual;g.setup(roster,level,1515+level,"naglfar" if matches%2==0 else "streets_of_novigrad",{"mode":"teams" if roster.size()==4 else "ffa"})
				if not manual:
					for p in g.players:p.bot=true
				var steps=0;var prior=failures
				while g.winner<0 and steps<3000 and failures==prior:
					advance(g);steps+=1
					if steps%17==0:g=clone(g)
					validate(g)
				check(g.winner>=0,"Eredin match finishes "+str(roster)+" "+g.phase);matches+=1
	print("V15_RULES checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves]);quit(1 if failures else 0)
