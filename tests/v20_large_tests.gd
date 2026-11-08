extends "res://tests/v19_rules_tests.gd"
func run():
 var g=game(["t_rex","king_arthur"],true);var fid=0
 # Explicit synthetic geometry: short links all overlap. Endpoints stay in
 # one fighter, and every query must reject enemy-occupied parts of its base.
 g.board_data={"width":100,"height":100,"node_radius":100}
 g.fighters[0].node=0;g.fighters[0].tail=1;g.fighters[1].node=24;g.fighters[2].node=23
 check(g._occupant(0)==fid and g._occupant(1)==fid,"same fighter occupies both cells")
 var states=g._v19.paths(fid,1)
 check(states.any(func(s):return int(s.head)==2 and int(s.tail)==1),"can start movement from tail")
 check(not states.any(func(s):return int(s.head)==6 and int(s.tail)==0),"tail always comes from actual last step")
 for s in states:
  check(g._occupant(int(s.head)) in [-1,fid] and (int(s.tail)<0 or g._occupant(int(s.tail)) in [-1,fid]),"both endpoints free")
 g.fighters[1].node=2;g.fighters[2].node=3
 check(not g._v19.reach(fid,1).has(2),"enemy blocks head")
 check(not g._v19.candidates(fid,3,1).any(func(s):return int(s.tail)==2),"enemy blocks tail")
 g.fighters[1].node=24;g.fighters[2].node=23
 g.phase="move";g.maneuver_distance=2
 check(g.move_fighter(fid,6),"movement offers orientation")
 check(g.pending_choice.get("action","")=="v19_orientation","multiple reachable orientations offered")
 var before=g.fighters[0].duplicate(true);g=clone(g)
 check(g.fighters[0].node==before.node and g.fighters[0].tail==before.tail,"choosing orientation has not moved yet")
 var chosen=int(g.pending_choice.states[-1].tail);g.choose_effect_option(g.pending_choice.states.size()-1)
 check(g.fighters[0].node==6 and g.fighters[0].tail==chosen,"chosen footprint actually applied")
 g=clone(g);check(int(g.fighters[0].tail)==chosen,"footprint survives JSON")
 g.fighters[0].locked_until=g.turn_number
 check(g._v19.reach(0,5).size()==1,"roar prevents movement of whole base")
 var oldhp=g.fighters[0].hp;g._damage_many([0],2);check(g.fighters[0].hp==oldhp-2,"one fighter one damage packet")
 g=game(["king_arthur","t_rex"],true);g.fighters[g.hero_fighter(1)].node=0;g.fighters[g.hero_fighter(1)].tail=1
 g._resolve_spirit_spaces(0,[0,1]);check(g.fighters[g.hero_fighter(1)].hp==25,"Restless Spirits hits two cells once")
 print("V20_LARGE checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
