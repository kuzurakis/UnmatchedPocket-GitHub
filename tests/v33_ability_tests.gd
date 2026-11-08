extends "res://tests/v33_tmnt_tests.gd"
func run():
 for manual in [false,true]:
  var g=game(["donatello","king_arthur"],manual);g=stable(g);var foe=adjacent(g)
  combat(g,0,foe,card(g,0,"tmnt_721"),raw_card("defense",20));g=stable(g);check(g._v33.bonus(0,true)==1,"invention attack applies after card");g=clone(g);check(g._v33.bonus(1,true)==1,"saved bonus applies to Metalhead")
  g=game(["michelangelo","king_arthur"],manual);g=stable(g);check(g.players[0].hand.size()==3,"Mikey starts with three");check(g._v33.limit(0)==3,"Mikey limit three");foe=adjacent(g);g.players[0].hand=[card(g,0,"tmnt_73")];g.scheme(0,0);g=stable(g);check(g.players[0].hand.size()==1,"scheme draws exactly one from ability");check(g._v33.bonus(0,true)==1 and g._v33.bonus(1,true)==0,"nunchaku only hero")
  g=game(["raphael","king_arthur"],manual);g=stable(g);foe=adjacent(g);var actions=g.actions_left;combat(g,0,foe,raw_card("attack",1),raw_card("defense",10));g=stable(g);check(g.actions_left>=actions,"first lost attack gains action");g._v33.lost(0);check(g.players[0].anger_used,"anger used once")
  g=game(["donatello","king_arthur"],manual);g=stable(g);g.players[0].inventions=[721,722,724];g=clone(g);check(g._v33.bonus(0,true)==1 and g._v33.bonus(1,false)==1,"all invention bonuses restored from JSON")
  g=game(["leonardo","king_arthur"],manual);g=stable(g);check(g.phase=="action","Leo optional start movement completes")
 for hid in TURTLES:
  for level in range(3):
   var g=Model.new();g.interactive=true;g.setup([hid]+TURTLES.filter(func(x):return x!=hid),level,3330+level,"venice",{"mode":"teams"if level==2 else"ffa"});var steps=0
   while g.winner<0 and steps<4500:
    advance(g);steps+=1
    if steps%31==0:g=clone(g)
   check(g.winner>=0,"complete turtle match "+hid+str(level));matches+=1
 print("V33_ABILITIES checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
