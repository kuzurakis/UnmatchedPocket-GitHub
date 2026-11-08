extends "res://tests/v16_rules_tests.gd"
const W="yennefer_triss"
func sorceress(main: String, manual=true):return game([W,"king_arthur"],manual,{"sorceress_hero":main})
func test_roles17():
	for main in ["yennefer","triss"]:
		var g=sorceress(main);check(g.fighters[0].name==("Йеннифэр" if main=="yennefer" else "Трисс") and g.fighters[0].hp==14 and g.fighters[1].hp==6,"chosen hero 14, helper 6")
		check(g._card_usable(card(g,0,"incinerate"),0)==(main=="yennefer") and g._card_usable(card(g,0,"merigolds_hailstorm"),1)==(main=="yennefer"),"named cards follow actual fighter, not hero role");g=clone(g);check(g._v17.main_for(0)==main,"role survives save")
	var g=sorceress("yennefer");var foe=adjacent(g);g.players[0].hand=[raw_card("attack",2),raw_card("defense",1)];g.players[1].hand=[card(g,1,"feint")];g.attack(0,foe,0);g.continue_attack();check(g.pending_choice.action=="combat_boost","Yennefer ability offers boost after opposing Feint")
	g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.last_combat.attack_cancelled and g.last_combat.attack_value==4,"uncancellable ability survives cancelled attack effects")
	g=sorceress("triss");foe=adjacent(g,1);combat(g,1,foe,raw_card("attack",2),raw_card("defense",8));g=stable(g);check(g.last_combat.attack_value==2,"helper Yennefer has no boost ability")
	for own in [0,1]:
		g=sorceress("triss");g.fighters[0].node=0;g.fighters[1].node=1;g.fighters[2].node=24;g.fighters[3].node=23;g.players[0].hand=[card(g,0,"advisor_to_the_king")];g.scheme(own,0)
		g=stable(g);check(g.fighters[1].hp==(4 if own==0 else 6),"Triss mandatory scheme damage may hit friendly; helper scheme has no ability")
func test_advisor17():
	var g=sorceress("yennefer");g.players[0].hand=[card(g,0,"advisor_to_the_king")];g.fighters[0].hp=9;g.fighters[1].hp=3;g.scheme(0,0);g=stable(g)
	check(g.fighters[0].hp==10 and g.fighters[1].hp==4,"Advisor heals both actual fighters")
	for c in g.players[0].hand+g.players[0].deck+g.players[0].discard+[g.players[0].ongoing]:check(c.boost==c.printed_boost+1,"Advisor updates every owned pile without changing printed base")
	g=clone(g);var c=g.players[0].hand[0];var value=int(c.boost);g.begin_maneuver(0);check(g.maneuver_distance==2+value,"maneuver spends increased boost");g.finish_maneuver();g.end_turn();g=stable(g)
	check(g._v14.ongoing(0)=="","Advisor discarded if no attack")
	for held in g.players[0].hand+g.players[0].deck+g.players[0].discard:check(held.boost==held.printed_boost,"bonus removed from every pile exactly once")
func test_costs17():
	var g=game(["king_arthur",W],true,{"sorceresses":{1:"yennefer"}});var foe=adjacent(g);g.players[0].hand=[raw_card("defense",3),raw_card("attack",1),raw_card("attack",1)];g.players[1].hand=[card(g,1,"incinerate")];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0)
	check(g.pending_choice.action=="v17_pay","Incinerate offers actual victim a two-card payment");g=clone(g);g.choose_effect_option(0);check(not g.pending_choice.can_skip,"two-card payment cannot stop halfway");g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.last_combat.damage==0 and g.players[0].hand.is_empty(),"paid two cards ignores Incinerate")
	g=sorceress("triss");foe=adjacent(g);g.players[0].hand=[card(g,0,"telepathy")];g.players[1].hand=[raw_card("defense",8)];g.attack(0,foe,0);g.continue_attack();g=stable(g);check(g.last_combat.defense_cancelled,"Telepathy cancels when no payment available")
	for branch in range(3):
		g=game(["king_arthur",W],true,{"sorceresses":{1:"triss"}});foe=adjacent(g);g.players[0].hand=[raw_card("defense",10),raw_card("attack",1),raw_card("attack",1)];g.players[1].hand=[card(g,1,"merigolds_hailstorm")];var deck=g.players[0].deck.size();var hp=g.fighters[0].hp;g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g=wait_choice(g,"v17_hail");g=clone(g);g.choose_effect_option(branch);g=stable(g)
		check(g.players[0].hand.size()==(0 if branch==0 else 2) and g.fighters[0].hp==hp-(3 if branch==1 else 0) and g.players[0].deck.size()==deck-(4 if branch==2 else 0),"all Hailstorm choices have exact consequences")
func test_lodge17():
	for same in [false,true]:
		var g=sorceress("triss");g.fighters[0].node=0;g.fighters[1].node=10;g.players[0].hand=[card(g,0,"lodge_of_sorceresses"),raw_card("attack",1)];g.players[1].hand=[raw_card("attack",1)];g.players[1].hand[0].boost=2 if same else 3;var hp0=g.fighters[0].hp;var hp1=g.fighters[2].hp;g.scheme(0,0)
		check(g.pending_choice.action=="v17_lodge_pick" and g.pending_choice.cards.size()==1,"only own card visible before simultaneous reveal");g=clone(g);g.choose_effect_option(0);check(g.pending_choice.action=="v17_lodge_reveal" and g.pending_choice.cards.size()==2,"all commitments revealed together");g=clone(g);g.choose_effect_option(0);g=stable(g)
		check(g.players[0].hand.size()==3 and g.players[1].hand.size()==(3 if same else 4),"revealed cards stay in hand and draw exact boost")
		check(g.fighters[0].hp==hp0-(2 if same else 0) and g.fighters[2].hp==hp1-(2 if same else 3),"Lodge handles unique leader and ties")
func run():
	test_roles17();test_advisor17();test_costs17();test_lodge17();all_catalog_cards_v8()
	for main in ["yennefer","triss"]:
		for level in range(3):
			for manual in [false,true]:
				var g=Model.new();g.interactive=manual;g.setup([W,"philippa","eredin","ciri"],level,1717,"naglfar",{"mode":"teams","sorceress_hero":main})
				if not manual:
					for p in g.players:p.bot=true
				var steps=0;var prior=failures
				while g.winner<0 and steps<3000 and failures==prior:
					advance(g);steps+=1
					if steps%17==0:g=clone(g)
					validate(g)
				check(g.winner>=0,"sorceress match finishes");matches+=1
	print("V17_RULES checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves]);quit(1 if failures else 0)
