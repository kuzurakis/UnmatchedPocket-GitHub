extends "res://tests/v23_card_audit_tests.gd"
func run():
 var g=game(["svyatogor","king_arthur"],true);check(g.fighters[0].hp==28 and g._v19.large(0),"Svyatogor stats and large base");var hp=g.fighters[0].hp;g.begin_maneuver();check(g.fighters[0].hp==hp-1,"maneuver costs one HP");g.finish_maneuver();g=stable(g);g.begin_maneuver();check(g.fighters[0].hp==hp-2,"each maneuver costs HP");g=clone(g);check(g._v19.large(0),"saved fan large fighter")
 for source in g.heroes.svyatogor.cards:
  for manual in [false,true]:
   var model=game(["svyatogor","king_arthur"],manual);var foe=adjacent(model);model.fighters[0].tail=-1;model.players[0].hand=[source.duplicate(true),raw_card("attack",2)];model.players[1].hand=[raw_card("defense",2)];model.fighters[0].hp=24
   if source.type=="scheme":check(model.scheme(0,0),"fan scheme "+source.id)
   elif source.type=="defense":combat(model,foe,0,raw_card("attack",6),source)
   else:check(model.attack(0,foe,0),"fan attack "+source.id)
   model=stable(model);check(model.phase in ["action","discard","game_over"],"fan complete "+source.id)
 for amount in [0,4,5,25,27]:
  g=game(["svyatogor","king_arthur"],true);var foe=adjacent(g);g.fighters[0].hp=int(g.heroes.svyatogor.health)-amount;combat(g,0,foe,card(g,0,"svyatogor_13"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==3+int(amount/6),"Last Breath floor per six health")
 g=game(["svyatogor","king_arthur"],true);var foe=adjacent(g);var hp0=g.fighters[0].hp;combat(g,0,foe,card(g,0,"svyatogor_09"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==6 and g.fighters[0].hp==hp0-2,"optional paid six")
 print("V26_SVYATOGOR checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
