extends "res://tests/v36_edge_tests.gd"
func run():
 var g=fixture36("medusa");g.difficulty=3;g=clone(g);check(g.difficulty==3,"fourth level survives JSON")
 var state=JSON.stringify(g.save_state());var first=g._master.world(37).save_state();g.players[1].hand.reverse();g.players[1].deck.reverse();var second=g._master.world(37).save_state();check(JSON.stringify(first.players[1].hand)==JSON.stringify(second.players[1].hand),"hidden order cannot affect sampled hand")
 g=fixture36("alice");g.difficulty=3;var foe=g.hero_fighter(1);g.players[0].hand=[raw_card("attack",8),raw_card("scheme",0)];g.players[1].hand=[];g.fighters[foe].hp=1
 var original=JSON.stringify(g.save_state());var choice=g._master.choose([{"kind":"attack","fighter":0,"target":foe,"card":0,"score":8.0}]);check(JSON.stringify(g.save_state())==original,"search leaves real game and RNG untouched");check(choice.kind=="attack","Master recognizes a winning attack")
 g=fixture36("king_arthur");g.difficulty=3;foe=g.hero_fighter(1);g.active=1;g.players[0].hand=[raw_card("defense",2),raw_card("defense",6)];g.players[1].hand=[raw_card("attack",7)];g.attack(foe,0,0);g.continue_attack();g.fighters[0].hp=2;check(g._choose_defense(0,foe)==1,"Master prioritizes survival")
 var catalog=Model.new();var count=0
 for hid in catalog.heroes:
  g=fixture36(hid,false);g.difficulty=3;var before=JSON.stringify(g.save_state());var started=Time.get_ticks_msec();g._bot_action();check(JSON.stringify(g.save_state())!=before,"legal Master decision for "+hid);check(Time.get_ticks_msec()-started<5000,"bounded decision time "+hid);count+=1
 print("V37_MASTER checks=%d failures=%d heroes=%d"%[checks,failures,count]);quit(1 if failures else 0)
