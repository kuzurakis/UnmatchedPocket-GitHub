extends "res://tests/v34_stars_tests.gd"
func run():
 var g=game(["rosie_the_riveter","king_arthur"],true);g=stable(g);check(g._v34.active_upgrades(0)==[0],"Rosie first activation is engine");g._v34.upgrade(0,true);g._v34.upgrade(0,false);check(g.players[0].upgrades==[1,2,3,0]and g._v34.active_upgrades(0)==[1],"deactivation moves first active to end");g._v34.upgrade(0,true);g._v34.upgrade(0,true);check(g.fighters[0].ranged and not g.fighters[1].ranged,"rocket upgrades Rosie only");g=clone(g);check(g._v34.attack_bonus(0)==1 and g._v34.attack_bonus(1)==0,"attack upgrade saved and hero only")
 g=game(["john_henry","king_arthur"],true);g=stable(g);check(g.players[0].tracks.size()==1,"mandatory track summoned");g.players[0].tracks=[13,14];g.fighters[0].node=12;g._v34.rail_finish({"owner":0},0,[13,14,13,12]);check(g.players[0].used_paths.size()==2,"undirected paths counted once");g=clone(g);check(g.players[0].tracks.size()==2 and not g._v34.momentum(0),"track and paths roundtrip")
 g=game(["wyatt_earp","king_arthur"],true);g=stable(g);var foe=adjacent(g);g.actions_left=0;g._v34.grant_free(0,foe);g.players[0].hand=[raw_card("attack",1),raw_card("scheme",0)];check(g.legal_targets(0,0).has(foe),"free attack usable after two normal actions");check(not g.scheme(0,1) and g.actions_left==0,"free action cannot buy scheme")
 g=game(["john_henry","king_arthur"],true);g=stable(g);foe=adjacent(g);combat(g,foe,0,raw_card("attack",20),card(g,0,"sns_776"));g=stable(g);check(g.fighters[0].hp==15,"Deeds of Valor caps combat damage at two")
 for hid in STARS:
  for level in range(3):
   g=Model.new();g.interactive=true;g.setup([hid]+STARS.filter(func(x):return x!=hid),level,3400+level,"the_white_house"if level!=2 else"the_alamo",{"mode":"teams"if level==2 else"ffa"});var steps=0
   while g.winner<0 and steps<5000:
    advance(g);steps+=1
    if steps%31==0:g=clone(g)
   check(g.winner>=0,"full stars match "+hid+str(level));matches+=1
 print("V34_ABILITIES checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
