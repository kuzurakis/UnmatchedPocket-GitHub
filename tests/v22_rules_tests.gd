extends "res://tests/v21_rules_tests.gd"
func run():
 var g=game(["spider_man","king_arthur"],true);var foe=adjacent(g)
 combat(g,0,foe,card(g,0,"right_in_the_face"),raw_card("defense",8));g=stable(g);var count=g.players[1].hand.size();g._draw(1,2);check(g.players[1].hand.size()==count,"Spider blocks all draws this turn")
 g.turn_number+=1;g._draw(1,1);check(g.players[1].hand.size()==count+1,"draw lock expires")
 g=game(["spider_man","king_arthur"],true);foe=adjacent(g);combat(g,foe,0,raw_card("attack",9),card(g,0,"web_shooters"));g=stable(g);check(g.last_combat.damage==2,"web combat cap")
 g=game(["cloak_and_dagger","king_arthur"],true);check(g.fighters[0].hp==8 and g.fighters[1].hp==8,"two hero health pools")
 g._damage(0,8);check(g.players[0].alive and g.fighters[1].alive,"one hero can survive the other")
 for own in [0,1]:
  g=game(["cloak_and_dagger","king_arthur"],true);foe=adjacent(g,own);g.players[1].hand=[raw_card("defense",0),raw_card("attack",1)];g.players[0].hand=[raw_card("attack",3)];g.attack(own,foe,0);g.continue_attack();g=stable(g)
  check(g.players[1].hand.size()==(0 if own==0 else 1),"Cloak attack discards; Dagger preserves hand")
  check(g.actions_left==(2 if own==1 else 1),"Dagger attack gains action")
 g=game(["doctor_strange","king_arthur"],true);check(g.fighters[1].hp==6 and g.fighters[1].ranged,"Wong printed stats")
 foe=adjacent(g);var hp=g.fighters[0].hp;combat(g,0,foe,card(g,0,"cloak_of_levitation"),raw_card("defense",9));g=stable(g);check(g.fighters[0].hp==hp-1 and g.players[0].deck[0].id=="cloak_of_levitation","Pact pays HP and sends actual played card to bottom")
 g=game(["she_hulk","king_arthur"],true);foe=adjacent(g);g._flow.clear();g.pending_choice.clear();g.phase="action";g.actions_left=2;combat(g,0,foe,card(g,0,"the_savage_she_hulk"),raw_card("defense",12));g=stable(g);check(g.last_combat.attack_value==9,"Savage spends remaining action for nine")
 g=game(["doctor_strange","king_arthur"],true);foe=adjacent(g);g.players[0].deck=[];hp=g.fighters[0].hp;combat(g,0,foe,card(g,0,"bolts_of_balthakk"),raw_card("defense",9));g=stable(g);check(g.fighters[0].hp==hp-1 and g.players[0].hand.any(func(c):return c.id=="bolts_of_balthakk"),"Pact bottom insertion precedes draw with empty deck")
 g=game(["alice","king_arthur"]);foe=adjacent(g);var origin=g.fighters[0].node;var target_origin=g.fighters[foe].node
 direct(g,[{"kind":"move","fixed_fighter":foe,"spaces":1}]);check(g.fighters[0].node==origin and g.fighters[foe].node!=target_origin,"bot moves the explicitly targeted enemy, not caster")
 g=game(["alice","king_arthur"],true);foe=adjacent(g);direct(g,[{"kind":"move","fixed_fighter":foe,"spaces":1}]);check(g.pending_choice.allowed_fighters==[foe],"manual movement targets same enemy")
 for level in range(3):
  g=Model.new();g.setup(["she_hulk","spider_man","doctor_strange","cloak_and_dagger"],level,2222,"sanctum_sanctorum",{"mode":"teams"});g.interactive=true;var steps=0
  while g.winner<0 and steps<3000:
   advance(g);steps+=1
   if steps%19==0:g=clone(g)
  check(g.winner>=0,"new four hero match finishes")
 print("V22_RULES checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)

