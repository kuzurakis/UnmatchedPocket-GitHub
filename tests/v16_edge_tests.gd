extends "res://tests/v16_rules_tests.gd"
func run():
	var g=game(["king_arthur","philippa"],true);var foe=adjacent(g);g.players[0].hand=[raw_card("defense",8),raw_card("attack",1)];g.players[1].hand=[card(g,1,"redanian_plot")];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0)
	check(g.pending_choice.action=="v16_pay" and g.pending_choice.viewer==0,"human opponent pays from own hand");g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.last_combat.damage==0 and g.players[0].hand.is_empty() and g.players[0].discard.size()==2,"payment discards victim card, not attacker's card")
	g=game(["philippa","houdini"],true);g.players[0].hand=[card(g,0,"spymasters_ruse")];g.players[1].hand=[card(g,1,"a_magician_never_reveals_his_secrets")];var deck=g.players[1].deck.size();g.scheme(1,0);g=stable(g);check(g.players[1].hand.size()==1 and g.players[1].deck.size()==deck,"Houdini protects hidden hand")
	g=game(["philippa","geralt_of_rivia"],true);g.players[1].ongoing=card(g,1,"gear_tawny_owl");g.players[1].hand=[raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)];g.players[0].hand=[card(g,0,"spymasters_ruse")];g.scheme(1,0);g=stable(g);check(g.players[1].hand.size()==5 and g.players[1].discard.is_empty(),"Owl blocks forced spy discards but not subsequent draw")
	g=game(["philippa","king_arthur"],true);g.players[0].hand=[];g.players[0].deck=[];var hp=g.fighters[0].hp;g.end_turn();g.choose_effect_option(1);g=stable(g);check(g.fighters[0].hp==hp,"declining end draw avoids exhaustion")

	g=game(["king_arthur","philippa","medusa"],true);g.players[2].hand=[]
	for i in range(6):g.players[2].hand.append(raw_card("attack",i))
	direct(g,[{"kind":"v16_spy"}],card(g,1,"spymasters_ruse"),1,2)
	check(g.pending_choice.get("action","")=="v16_spy_public" and g.pending_choice.cards.size()==4 and g.pending_choice.viewer==0,"third player sees public reveal but not hidden remainder")
	g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.players[2].hand.size()==6,"public reveal resumes AI discard and draw once")
	print("V16_EDGES checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
