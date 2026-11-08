extends "res://tests/v17_rules_tests.gd"
func run():
	for first in [0,1]:
		var g=sorceress("yennefer");var foe=adjacent(g);g.players[0].hand=[card(g,0,"telepathy"),raw_card("defense",1)];g.players[1].hand=[raw_card("defense",8)];g.attack(0,foe,0);g.continue_attack();check(g.pending_choice.action=="v17_order","Yennefer chooses order of her simultaneous immediate effects");g=clone(g);g.choose_effect_option(first)
		g=wait_choice(g,"combat_boost");g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.last_combat.attack_value==5 and g.last_combat.defense_cancelled,"both immediate orders retain uncancellable boost")
	var g=game([W,"philippa","eredin","ciri"],true,{"sorceress_hero":"yennefer"});var hp=[]
	for p in range(4):
		g.players[p].hand=[raw_card("attack",1)];g.players[p].hand[0].boost=[2,3,3,1][p];hp.append(g.fighters[g.hero_fighter(p)].hp)
	g.players[0].hand.push_front(card(g,0,"lodge_of_sorceresses"));g.scheme(0,0);g=clone(g);g.choose_effect_option(0);check(g.pending_choice.cards.size()==4,"all four simultaneous reveals public");g=clone(g);g.choose_effect_option(0);g=stable(g)
	for p in range(4):check(g.fighters[g.hero_fighter(p)].hp==hp[p]-(3 if p in [1,2] else 0),"only tied maximum drawers take damage in four-player game")
	g=sorceress("yennefer");g.players[0].hand=[card(g,0,"lodge_of_sorceresses"),raw_card("attack",1)];g.players[0].hand[1].boost=3;g.players[0].deck=g.players[0].deck.slice(0,1);g.players[1].hand=[raw_card("attack",1)];g.players[1].hand[0].boost=2;var health=g.fighters[0].hp;g.scheme(0,0);g.choose_effect_option(0);g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.fighters[0].hp==health-4 and g.fighters[2].hp==16,"Lodge compares actual cards drawn; exhaustion handled separately")
	g=sorceress("yennefer");var foe=adjacent(g);g.players[0].hand=[card(g,0,"portal_to_anywhere")];g.players[1].hand=[raw_card("defense",8)];g.attack(0,foe,0);g.continue_attack();g=wait_choice(g,"v17_portal");g=clone(g);g.choose_effect_option(1);check(g.pending_choice.fighter==foe and g.phase=="effect_move","portal selects opposing fighter and destination");g=stable(g);check(g.actions_left==2,"portal grants exactly one extra action")

	g=game(["king_arthur",W,"medusa"],true,{"sorceresses":{1:"yennefer"}})
	for p in range(3):g.players[p].hand=[raw_card("attack",1)]
	g.players[1].hand.push_front(card(g,1,"lodge_of_sorceresses"));g.active=1;g.scheme(g.hero_fighter(1),0)
	check(g.pending_choice.action=="v17_lodge_pick" and g.pending_choice.viewer==0 and g.pending_choice.victim==0,"human chooses own commitment even when bot casts Lodge")
	g=clone(g);g.choose_effect_option(0);g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.players[0].hand.size()==3,"bot Lodge resolves human commitment without discarding reveal")
	print("V17_EDGES checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
