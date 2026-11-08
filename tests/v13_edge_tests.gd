extends "res://tests/v13_rules_tests.gd"
func run():
	for hero in ["william_shakespeare","the_wayward_sisters"]:
		var g=game([hero,"hamlet"],true);var foe=adjacent(g)
		if hero=="william_shakespeare": g.players[0].line=[card(g,0,"et_tu_brute"),card(g,0,"et_tu_brute")]
		else: g.players[0].cauldron=[card(g,0,"ward"),card(g,0,"hurly_burly")]
		var c=card(g,0,"horror" if hero=="william_shakespeare" else "double_double")
		combat(g,0,foe,c,card(g,1,"the_rest_is_silence"));g=stable(g)
		check(g.active==1,"Rest is Silence ends attacking player's turn")
		if hero=="william_shakespeare":check(g.players[0].line.size()==2 and g.players[0].discard.any(func(x):return x.id=="horror"),"ended turn skips line addition and completion")
		else:check(g.players[0].cauldron.size()==3 and not g.logs.any(func(x):return str(x).begins_with("Заклинание сестёр")),"ended turn still collects discard but skips post-attack spell")
	var g=game(["titania","william_shakespeare"],true);var foe=adjacent(g);g.players[0].glamour="greed";var deck=g.players[0].deck.size()
	combat(g,foe,0,card(g,1,"horror"),card(g,0,"but_a_dream"));g=stable(g)
	check(g.last_combat.damage==0 and g.last_combat.attack_cancelled and g.players[1].hand.any(func(c):return c.id=="horror") and g.players[1].line.is_empty() and g.players[1].discard.is_empty(),"But a Dream ignores, cancels and returns attack without adding it to Shakespeare's line")
	check(g.players[0].deck.size()==deck-1,"But a Dream also resolves its after-combat draw")
	g=game(["titania","king_arthur"],true);foe=adjacent(g);g.players[0].glamour="greed"
	combat(g,0,foe,card(g,0,"fairy_song"),card(g,1,"feint"));g=stable(g)
	check(g.last_combat.attack_cancelled and g.players[0].glamour=="greed","cancelled Fairy Song cannot spend glamour for its value")
	for damage_hero in [false,true]:
		g=game(["hamlet","king_arthur"],true);foe=adjacent(g)
		for f in g.fighters:
			if f.owner==0:f.erase("damaged_turn")
		g._damage(0 if damage_hero else 1,2);var hp=g.fighters[foe].hp
		combat(g,0,foe,card(g,0,"blood_will_have_blood"),raw_card("defense",10));g=stable(g)
		check(g.fighters[foe].hp==hp-int(damage_hero),"Blood tracks Hamlet's actual damage, never sidekick's")
	print("V13_EDGES checks=%d failures=%d saves=%d" % [checks,failures,saves]);quit(1 if failures else 0)
