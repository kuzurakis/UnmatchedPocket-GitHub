extends "res://tests/v26_svyatogor_tests.gd"
func run():
 var catalog=Model.new()
 for map in catalog.boards:
  var g=Model.new();g.interactive=true;g.setup(["svyatogor","king_arthur"],1,2727,map,{})
  for turn in range(6):
   g.phase="move";g.active=0;g.maneuver_distance=2;g.maneuver_moved=[];g.door_movement_spent.clear();var legal=g.legal_moves(0)
   for node in legal:
    for state in g._v19.candidates(0,int(node),2):check(int(state.tail)>=0 and int(state.tail)!=int(state.head),"every Svyatogor movement orientation has two distinct cells "+map)
   if not legal.is_empty():
    g.move_fighter(0,int(legal[-1]))
    if g.pending_choice.get("action","")=="v19_orientation":g=clone(g);g.choose_effect_option(g.pending_choice.states.size()-1)
    check(int(g.fighters[0].tail)>=0 and int(g.fighters[0].tail)!=int(g.fighters[0].node),"actual moved footprint cannot collapse "+map)
    check(g._occupant(int(g.fighters[0].tail))==0,"second cell remains occupied "+map)
   g=clone(g)
 print("V27_BASE checks=%d failures=%d maps=%d"%[checks,failures,Model.new().boards.size()]);quit(1 if failures else 0)
