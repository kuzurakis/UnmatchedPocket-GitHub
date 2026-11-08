extends "res://tests/v18_rules_tests.gd"
func run():
 var g=game(["moon_knight","king_arthur"],true);var foe=adjacent(g)
 g.players[0].moon_form=1;var hp=g.fighters[0].hp;g._damage(0,3);check(g.fighters[0].hp==hp,"Khonshu ignores effect damage")
 combat(g,0,foe,raw_card("attack",3),raw_card("defense",8));g=stable(g);check(g.last_combat.attack_value==5,"Khonshu attack +2")
 g=game(["moon_knight","king_arthur"],true);foe=adjacent(g);g.players[0].moon_form=2;combat(g,foe,0,raw_card("attack",4),raw_card("defense",2));g=stable(g);check(g.last_combat.defense_value==3,"Mr Knight defense +1")
 g=game(["moon_knight","king_arthur"],true);g.end_turn();check(g._v21.form(0)==1,"mandatory end identity change");g=clone(g);check(g._v21.form(0)==1,"identity saved")
 g=game(["winter_soldier","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"feint"),card(g,1,"feint"));g=stable(g);check(not g.last_combat.attack_cancelled and g.last_combat.defense_cancelled,"Winter uncancellable Feint still cancels")
 for suppressed in [false,true]:
  g=game(["winter_soldier","king_arthur"],true);foe=adjacent(g);g.players[0].redroom_off=g.turn_number if suppressed else -1;hp=g.fighters[0].hp;combat(g,0,foe,card(g,0,"programmed_to_kill"),raw_card("defense",0));g=stable(g);check(g.fighters[0].hp==hp-(0 if suppressed else 2),"Red Room suppression only own turn")
 g=game(["ghost_rider","king_arthur"],true);g.fighters[0].node=0;g.fighters[1].node=1;g.fighters[2].node=24
 for n in g.nodes:n.move_neighbors=[]
 g.nodes[0].move_neighbors=[1];g.nodes[1].move_neighbors=[0,2];g.nodes[2].move_neighbors=[1]
 hp=g.fighters[1].hp;g.begin_maneuver();check(g.pending_choice.action=="v21_cycle","cycle offered after maneuver draw");g=clone(g);g.choose_effect_option(0);check(g.pending_choice.action=="v18_path" and g._v21.fire(0)==4,"cycle pays one and asks route")
 for n in [1,2]:g.choose_effect_option(g.pending_choice.choices.map(func(v):return int(v)).find(n))
 g.choose_effect_option(g.pending_choice.choices.map(func(v):return int(v)).find(-1));g=stable(g);check(g.fighters[1].hp==hp-1 and g.fighters[0].node==2,"cycle damages crossed enemy once")
 check(g.phase=="move" and g.legal_moves(0).is_empty() and not g.boost_maneuver(0),"cycle cannot move or boost again")
 g=game(["ms_marvel","king_arthur"],true);g.fighters[0].node=0;g.fighters[1].node=2;check(g._in_range(0,1),"Ms Marvel range two")
 foe=adjacent(g);combat(g,0,foe,card(g,0,"embiggen"),raw_card("defense",10));g=stable(g);check(g.last_combat.attack_value==6,"Embiggen compares number of zones")
 for level in range(3):
  g=Model.new();g.setup(["moon_knight","ghost_rider","ms_marvel","winter_soldier"],level,2121,"helicarrier",{"mode":"teams"});g.interactive=true;var steps=0
  while g.winner<0 and steps<2000:
   advance(g);steps+=1
   if steps%23==0:g=clone(g)
  check(g.winner>=0,"new four hero team match completes")
 print("V21_RULES checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
