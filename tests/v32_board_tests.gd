extends "res://tests/v32_legends_tests.gd"
func santa32(ids=["king_arthur","medusa"],manual=true):
 var g=Model.new();g.interactive=manual;g.setup(ids,1,3232,"santas_workshop");g=stable(g)
 var used=[]
 for f in g.fighters:
  if f.alive:
   for node in [0,1,2,3,4,5,6,16,17,18]:
    if not used.has(node):f.node=node;used.append(node);break
 return g
func run():
 var g=santa32();var foe=g.hero_fighter(1)
 for f in g.fighters:
  if int(f.id)!=0:f.offboard=true
 for edge in g.board_data.one_way:
  g.fighters[0].node=int(edge[0]);check(g._reachable_options(0,1,true).has(int(edge[1])),"orange arrow permits forward move "+str(edge))
  g.fighters[0].node=int(edge[1]);check(not g._reachable_options(0,1,true).has(int(edge[0])),"orange arrow rejects reverse move "+str(edge))
 g=santa32();foe=g.hero_fighter(1);g.fighters[0].node=0;g.fighters[foe].node=19;check(g.fighters_adjacent(0,foe)and g.fighters_adjacent(foe,0),"one-way movement does not remove adjacency")
 g=santa32();foe=g.hero_fighter(1);g.fighters[0].node=21;g.fighters[foe].node=27;g.fighters[1].node=13;var plan=g._v32.conveyor_plan();check(plan.get(0,-9)==27 and plan.get(foe,-9)==13 and plan.get(1,-9)==12,"conveyor chains move into simultaneously vacated spaces")
 g._v32.end_board();g=stable(g);check(g.fighters[0].node==27 and g.fighters[foe].node==13 and g.fighters[1].node==12,"simultaneous movement committed for both players")
 g=santa32();foe=g.hero_fighter(1);g.fighters[0].node=12;g.fighters[1].node=13;g.fighters[foe].node=11;g.fighters[foe].locked_until=g.turn_number;plan=g._v32.conveyor_plan();check(not plan.has(0)and not plan.has(1)and not plan.has(foe),"stationary locked occupant blocks the entire upstream chain")
 g=santa32();g.fighters[0].node=10;g.fighters[1].node=11;g._v32.end_board();check(g.pending_choice.action=="v32_bin"and g.fighters[0].node==10 and g.fighters[1].node==11,"gift-bin choice pauses before simultaneous commit")
 g=clone(g);g=stable(g);check(g.fighters[1].node==10 and g.nodes[int(g.fighters[0].node)].zones.has(int(g.board_data.gift_zone)),"end fighter exits to chosen bin and upstream fighter advances")
 g=santa32(["t_rex","medusa"]);g.fighters[0].node=21;g.fighters[0].tail=20;check(not g._v32.conveyor_plan().has(0),"large fighter is never carried by conveyor")
 g=santa32(["squirrel_girl","king_arthur"]);var sq=g._v31.squirrels(0)
 for i in range(1,6):g.fighters[i].alive=true;g.fighters[i].reserve=false;g.fighters[i].node=27;g.fighters[i].locked_until=g.turn_number
 g.fighters[5].node=21;g.fighters[5].erase("locked_until");check(not g._v32.conveyor_plan().has(5),"conveyor cannot put fifth small fighter into occupied stack")
 var h=Model.new()
 for map in ["venice","santas_workshop"]:
  var b=h.boards[map]
  check(b.starts.size()==4 and b.nodes.size()in[33,34],"new map has graph and four starts "+map)
  for node in b.nodes:
   check(node.id>=0 and node.id<b.nodes.size()and node.zones.size()>0,"map node in range with zone")
   for other in node.neighbors:check(h._int_array(b.nodes[int(other)].neighbors).has(int(node.id)),"combat adjacency symmetric")
 print("V32_BOARDS checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
