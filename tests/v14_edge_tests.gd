extends "res://tests/v14_rules_tests.gd"
func run():
	var g=game(["geralt_of_rivia","titania"],true);g.players[0].ongoing=card(g,0,"gear_blizzard");g.players[1].glamour="rhyme";g.active=1;g.logs.clear()
	direct(g,[{"kind":"gain_action","amount":2}],{},1,0);g=stable(g)
	check(g.actions_left==2 and g.logs.any(func(x):return str(x).contains("Пурга")) and not g.logs.any(func(x):return str(x).begins_with("Дополнительное действие")),"blocked card bonus logs only the block")
	g._v13.scheme_complete(1);check(g.actions_left==2 and not g.logs.has("Чары рифмы: +1 действие."),"blocked Rhyme does not claim action was gained")
	g=game(["geralt_of_rivia","bloody_mary"],true);g.players[0].ongoing=card(g,0,"gear_blizzard");g.active=1;g.players[1].hand=[raw_card("attack",1),raw_card("attack",1),raw_card("attack",1)];g.logs.clear();g._start_turn_ability()
	check(g.actions_left==2 and not g.logs.has("Кровавая Мэри: ровно 3 карты — дополнительное действие."),"blocked Mary does not claim action was gained")
	g=game(["geralt_of_rivia","muhammad_ali"],true);g.players[0].ongoing=card(g,0,"gear_blizzard");g.active=1;g.players[1].combat_damage_turn=6;g.logs.clear()
	g._v6.run({"kind":"the_greatest"},{"owner":1,"self":g.hero_fighter(1),"opponent":0,"opponent_owner":0,"card":card(g,1,"the_greatest")})
	check(g.actions_left==2 and not g.logs.any(func(x):return str(x).begins_with("Величайший")),"blocked Ali bonus also logs no gained action")
	print("V14_EDGES checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
