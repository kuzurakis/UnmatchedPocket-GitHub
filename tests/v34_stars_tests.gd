extends "res://tests/v32_legends_tests.gd"
const STARS=["george_washington","rosie_the_riveter","john_henry","wyatt_earp"]
func run():
 for hid in STARS:
  var catalog=Model.new()
  for source in catalog.heroes[hid].cards:
   for defending in ([false,true]if source.type=="versatile"else[false]):
    for manual in [false,true]:
     var g=game([hid,"king_arthur"],manual);g=stable(g);var fid=1 if source.fighter=="sidekick"else 0;var foe=adjacent(g,fid)
     g.players[0].hand=[source.duplicate(true),raw_card("defense",2),raw_card("attack",2)];g.players[0].discard=[raw_card("scheme",0),raw_card("versatile",2),raw_card("defense",2),raw_card("attack",2)]
     if source.type=="scheme":check(g.scheme(fid,0),"scheme "+hid+source.id)
     elif source.type=="defense"or defending:combat(g,foe,fid,raw_card("attack",4),source)
     else:check(g.attack(fid,foe,0),"attack "+hid+source.id)
     g=stable(g);check(g.phase in["action","discard","game_over"],"completed "+hid+source.id);card_runs+=1
 print("V34_CARDS checks=%d failures=%d scenarios=%d"%[checks,failures,card_runs]);quit(1 if failures else 0)
