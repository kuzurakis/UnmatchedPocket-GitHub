extends "res://tests/v18_rules_tests.gd"
func test_choices18():
 for boost in [false,true]:
  var g=game(["bullseye","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[card(g,0,"i_never_miss"),raw_card("scheme",0)];g.players[1].hand=[raw_card("defense",20)];var deck=g.players[0].deck.size();g.attack(0,foe,0);g.continue_attack();check(g.pending_choice.action=="v18_never_boost","Never Miss offers boost or skip");g=clone(g)
  if boost:g.choose_effect_option(0)
  else:g.skip_effect()
  g=stable(g);check(g.last_combat.attack_value==(5 if boost else 3) and g.players[0].deck.size()==deck-int(not boost),"Never Miss draw only when not boosting")
 var g=game(["elektra","king_arthur"],true);var foe=adjacent(g,1);g.players[0].hand=[card(g,0,"the_fist")];g.players[1].hand=[raw_card("defense",20)];g.attack(1,foe,0);g.continue_attack();g=wait_choice(g,"v18_fist");g=clone(g);g.choose_effect_option(0);g=stable(g);check(not g.fighters[1].alive and g.players[0].hand.size()==1 and g.players[0].hand[0].id=="the_fist" and g.actions_left==2,"Fist sacrifices actual attacking Hand, returns card, gains action")
 for mode in ["elektra","luke_cage"]:
  g=game([mode,"king_arthur"],true);var own=0 if mode=="elektra" else 1;var replacement=1 if mode=="elektra" else 0;foe=adjacent(g,own);var old=int(g.fighters[own].node);var other=int(g.fighters[replacement].node);g.players[0].hand=[card(g,0,"snakeroot_clan" if mode=="elektra" else "got_my_back")];g.players[1].hand=[raw_card("attack",4)];g.active=1;g.attack(foe,own,0);g.continue_attack();g.defend(0);check(g.pending_choice.action=="v18_swap","optional defender substitution offered");g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.last_combat.target==replacement and int(g.fighters[replacement].node)==old and int(g.fighters[own].node)==other,"actual defender and positions replaced")
 g=game(["luke_cage","king_arthur"],true);foe=adjacent(g);g.players[1].hand=[raw_card("attack",1)];g.players[1].hand[0].effects=[{"timing":"after","kind":"draw","amount":3}];g.players[0].hand=[card(g,0,"trash_talk")];var count=g.players[1].deck.size();g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g=stable(g);check(g.active==0 and g.players[1].deck.size()==count,"Trash Talk ends attacking turn and blocks remaining effects")
 g=game(["bullseye","king_arthur"],true);foe=adjacent(g);g.fighters[0].node=0;g.fighters[foe].node=1;g.players[0].hand=[card(g,0,"tactical_retreat")];g.players[1].hand=[raw_card("attack",1)];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g=wait_choice(g,"v18_retreat");var origin=int(g.fighters[0].node)
 for n in g.pending_choice.legal:check(not g.nodes[int(n)].zones.any(func(z):return g.nodes[origin].zones.has(z)),"retreat excludes every shared printed zone")
 g=clone(g);g.choose_effect_node(int(g.pending_choice.legal[-1]));g=stable(g);check(not g._same_zone(origin,int(g.fighters[0].node)),"retreat chosen node actually entered")
 g=game(["daredevil","king_arthur"],true);g.players[0].deck=[];g.players[0].hand=[card(g,0,"take_a_knee")];foe=adjacent(g);combat(g,0,foe,card(g,0,"take_a_knee"),raw_card("defense",20));g=stable(g);check(g.fighters[0].hp==17,"empty-deck blind/heal discard causes no exhaustion")
 g=game(["luke_cage","king_arthur"],true);g.fighters[0].node=0;g.fighters[1].node=24;g.fighters[2].node=2;g.fighters[3].node=22;g.players[0].hand=[card(g,0,"wheres_my_money")];g.scheme(0,0);check(g.pending_choice.action=="v18_retreat","money chooses free adjacent landing")
 for n in g.pending_choice.legal:check(g.nodes[2].neighbors.has(int(n)),"money uses nearest enemy only")
 g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.actions_left==2,"money gains action after placement")
func run():
 test_choices18();print("V18_EDGES checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
