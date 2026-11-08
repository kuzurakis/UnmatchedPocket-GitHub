extends "res://tests/v23_card_audit_tests.gd"
var item_cases=0
func item_game(id: int, manual=true):
 var g=game(["king_arthur","medusa"],manual);adjacent(g);g.battlefield_items=[{"id":id,"node":12,"used":false}];g.fighters[0].hp=10;return g
func test_all_items():
 var model=Model.new()
 for key in model._v24.definitions:
  var id=int(key);var d=model._v24.definitions[key]
  for manual in [false,true]:
   var g=item_game(id,manual);var foe=g.hero_fighter(1)
   if d.type=="versatile":
    combat(g,0,foe,raw_card("attack",3),raw_card("defense",10));g=stable(g);check(g.last_combat.attack_value==3+int(d.value),"item adds exact printed attack value "+key)
    g=item_game(id,manual);foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",7),raw_card("defense",3));g=stable(g);check(g.last_combat.defense_value==3+int(d.value),"item adds exact printed defense value "+key)
    g=item_game(id,manual);foe=g.hero_fighter(1);combat(g,0,foe,raw_card("attack",3),card(g,1,"feint"));g=stable(g);check(g.last_combat.attack_value==3 and g.battlefield_items[0].used,"Feint cancels consumed combat item "+key)
   else:
    g.players[0].hand=[raw_card("versatile",1),raw_card("attack",2)];g.players[0].discard=[raw_card("attack",4),raw_card("scheme",0)];g.players[0].deck=[]
    for v in [1,2,3,4,5,6]:g.players[0].deck.append(raw_card("attack",v))
    if id==4:g.players[0].deck.append(card(g,0,"the_lady_of_the_lake"))
    var hp=g.fighters.map(func(f):return int(f.hp));var nodes_before=g.fighters.map(func(f):return int(f.node))
    check(g._v24.use(0,0),"activate scheme item "+key);g=stable(g);check(g.battlefield_items[0].used,"scheme item used only once "+key);check(not g._v24.use(0,0),"consumed item cannot repeat "+key)
    match id:
     1:check(g.fighters.map(func(f):return int(f.node))!=nodes_before or not manual,"Astral Ring moves fighters")
     4:
      check(g.players[0].discard.any(func(c):return c.id=="the_lady_of_the_lake") and g.actions_left==1,"Brazier plays actual scheme at no additional action")
     5:check(g.players[0].hand.size()==4 and g.players[0].deck.size()==4,"Bugle draws three and bottoms one")
     7:check(g.fighters[0].hp==hp[0]-1 and g.fighters[foe].hp==hp[foe]-1,"electric floor damages friendly and enemy including user")
     9:check(g.players[0].hand.is_empty() and g.players[1].hand.is_empty(),"EMP discards exact two from both players")
     11:check(g.fighters[0].hp==12 and g.players[0].hand.size()==3,"first aid exact health and draw")
     15:check(g.actions_left==2,"balloons restore spent action after moving")
     17:check(g.fighters.map(func(f):return int(f.hp))!=hp,"turret deals its two damage")
     20:check(g._v24.global_attack(0),"Map enables next attack flag")
     22:check(g.players[0].hand.size()==3 and g.players[0].discard.size()==1,"Payphone returns any discarded card")
     24:check(g.fighters[0].node!=12,"rocket pack places actual item user")
     25:check(g.players[0].hand.size()==3 and g.players[0].discard.size()==4,"secret documents discard before draw")
     26:check(g.players[0].hand.size()==3,"camera draws after hand view")
     29:check(g.fighters[0].hp==13,"slushie recovers three")
     30:check(g.players[0].deck.size()==6,"Zazoom reorders without changing deck count")
   item_cases+=1
func test_item_edges():
 var g=item_game(10);var foe=g.hero_fighter(1);g.players[0].hand=[raw_card("attack",3)];g.players[1].hand=[];g.attack(0,foe,0)
 check(g.pending_choice.action=="v24_combat_item" and not g.pending_combat.has("defense_card"),"attacker item decision occurs before defense")
 g=clone(g);g.choose_effect_option(1);g=stable(g);check(not g.battlefield_items[0].used and g.last_combat.attack_value==3,"declining keeps token on field")
 g=item_game(10);foe=g.hero_fighter(1);g.players[0].hand=[];g.players[1].hand=[raw_card("attack",4)];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(-1);g=stable(g)
 check(not g.battlefield_items[0].used,"cannot use combat item without playing defense card")
 for order in [0,1]:
  g=item_game(10);foe=g.hero_fighter(1);g.players[0].hand=[card(g,0,"momentous_shift")];g.players[1].hand=[raw_card("defense",20)];g.turn_start_nodes[0]=0;g.attack(0,foe,0);g.choose_effect_option(0);g.continue_attack()
  check(g.pending_choice.action=="v24_order","item/card during effects can be ordered");g=clone(g);g.choose_effect_option(order);g=stable(g)
  check(g.last_combat.attack_value==(7 if order==0 else 5),"card replacement vs item additive respects chosen order")
 g=item_game(20);g._v24.use(0,0);g=stable(g);foe=g.hero_fighter(1);g.fighters[foe].node=24;g.players[0].hand=[raw_card("attack",1),raw_card("attack",1)];check(g.legal_targets(0,0).has(foe),"Map permits distant target")
 g.attack(0,foe,0);g=stable(g);check(not g._v24.global_attack(0),"Map consumed by next attack")
 g=item_game(20);g._v24.use(0,0);g=stable(g);g.end_turn();g=stable(g);check(not g._v24.global_attack(0),"Map expires with turn")
 g=item_game(26);g.players[0].hand=[];g._v24.use(0,0);check(g.pending_choice.action=="v24_camera","camera lets player choose opponent");g.choose_effect_option(0);check(g.pending_choice.kind=="hand_view" and g.pending_choice.cards.size()==0,"camera opens even empty hand");g=stable(g)
 g=item_game(30);g.players[0].deck=[]
 for id in ["a","b","c"]:
  var c=raw_card("attack",1);c.id=id;c.name=id;g.players[0].deck.append(c)
 g.players[1].deck=[];g._v24.use(0,0);g.choose_effect_option(0);g=clone(g);check(g.pending_choice.cards.size()==3,"Zazoom really reveals top three")
 for i in range(3):g.choose_effect_option(0)
 g=stable(g);check(g.players[0].deck.map(func(c):return c.id)==["c","b","a"],"first chosen Zazoom card becomes top")
func test_board_graphs():
 var catalog=Model.new()
 for id in catalog.boards:
  var g=Model.new();g.setup(["king_arthur","medusa"],1,2424,id,{})
  for n in g.nodes:
   for link in n.neighbors:check(g.nodes[int(link)].neighbors.has(int(n.id)),"attack graph symmetric "+id)
   for z in n.zones:check(int(z)>=0 and int(z)<g.board_data.zone_keys.size(),"zone index valid "+id)
  for edge in g.board_data.get("directed_edges",[]):
   var a=int(edge.from);var b=int(edge.to);check(g.nodes[a].get("move_neighbors",g.nodes[a].neighbors).has(b) and not g.nodes[b].get("move_neighbors",g.nodes[b].neighbors).has(a),"one-way movement graph "+id)
   check(g.nodes[a].neighbors.has(b) and g.nodes[b].neighbors.has(a),"arrows keep attack adjacency "+id)
  for a in g.board_data.get("secret_passages",[]):
   for b in g.board_data.secret_passages:
    if int(a)!=int(b):check(g.nodes[int(a)].move_neighbors.has(int(b)),"passages link all entrances "+id)
  if g.board_data.has("item_slots"):
   check(g.battlefield_items.size()==6,"all six board items placed "+id)
   for token in g.battlefield_items:check(g.board_data.item_slots[g._v24.definition(token).type].map(func(v):return int(v)).has(int(token.node)),"items match printed slot types "+id)
  else:check(g.battlefield_items.is_empty(),"no items added to ordinary board "+id)
  g=clone(g);check(g.map_id==id,"board state survives save")
func test_doors_and_height():
 var g=Model.new();g.interactive=true;g.setup(["t_rex","king_arthur"],1,2424,"heorot",{});g.fighters[0].node=17;g.fighters[0].tail=19;g.phase="move";g.maneuver_distance=4
 check(not g.toggle_door(0,0) and not g.door_states[0],"large base blocks closing its straddled door")
 g.fighters[0].node=0;g.fighters[0].tail=17;check(g._v8.door_adjacent(0,0),"tail may operate adjacent door")
 check(g.toggle_door(0,0),"door closes after base stops straddling")
 g=Model.new();g.interactive=true;g.setup(["king_arthur","ingen"],1,2424,"heorot",{});g.fighters[0].node=17;g.phase="move";g.maneuver_distance=4;g.traps=[{"owner":1,"node":19}];g._enter_node(0,19)
 check(g.door_movement_spent.get(0,0)==4,"trap consumes remaining maneuver movement")
 check(g.toggle_door(0,0) and not g.toggle_door(0,0),"after trap may close but not open door")
 g=Model.new();g.interactive=true;g.setup(["t_rex","king_arthur"],1,2424,"hanging_gardens",{});g.fighters[0].node=0;g.fighters[0].tail=1;g.fighters[1].node=2
 check(g._v9.fighter_high_ground(0,1)==1,"high ground recognizes tail")
 g.fighters[0].node=1;g.fighters[0].tail=21;g.fighters[1].node=2;g.fighters[1].tail=3
 check(g._v9.fighter_high_ground(0,1)==1,"high ground never stacks beyond one")
func run():
 test_all_items();test_item_edges();test_board_graphs();test_doors_and_height();test_combo_edges()
 print("V24_BOARDS checks=%d failures=%d item_modes=%d maps=%d"%[checks,failures,item_cases,Model.new().boards.size()]);quit(1 if failures else 0)

func test_combo_edges():
 for manual in [true,false]:
  var g=game(["doctor_strange","king_arthur"],manual);var foe=adjacent(g);g.battlefield_items=[{"id":10,"node":12,"used":false}]
  g.players[0].deck=[raw_card("attack",1),raw_card("attack",1)];g.players[0].deck[0].boost=2;g.players[0].deck[1].boost=2
  combat(g,0,foe,card(g,0,"seven_suns_of_cinnibus"),raw_card("defense",20));g=stable(g)
  check(g.last_combat.attack_value==0,"Seven Suns ignores value above seven including item applied after card")
 var g=Model.new();g.interactive=true;g.setup(["daredevil","king_arthur"],1,24,"training",{});var foe=adjacent(g);g._flow.clear();g.pending_choice.clear();g.phase="action";g.battlefield_items=[{"id":10,"node":12,"used":false}];g.players[0].hand=[card(g,0,"man_without_fear")];g.players[0].deck=[raw_card("attack",1),raw_card("attack",1)]
 g.attack(0,foe,0);g.choose_effect_option(0);g.continue_attack()
 check(g.pending_choice.action=="v24_order" and g.pending_choice.groups.size()==3,"Daredevil can order item, card effect and hero ability independently")
 g=stable(g);check(g.last_combat.attack_value==8,"Daredevil two independent boosts plus combat item")
 g=Model.new();g.interactive=true;g.setup(["king_arthur","medusa","alice","sinbad"],1,24,"training",{});g._flow.clear();g.pending_choice.clear();g.phase="action";g.battlefield_items=[{"id":9,"node":int(g.fighters[0].node),"used":false}]
 for player in g.players:player.hand=[raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)]
 g._v24.use(0,0);g=stable(g)
 check(g.players.all(func(player):return player.hand.size()==1),"EMP reaches all four owners and each chooses own discards")
 g=item_game(4);g.players[0].hand=[card(g,0,"the_lady_of_the_lake")];g.players[0].deck=[card(g,0,"prophecy")];g._v24.use(0,0);g=stable(g)
 check(g.players[0].deck.size()==1 and g.players[0].hand.size()==1 and g.actions_left==1,"Brazier does not play another fighter's scheme or take scheme from hand")

 g=Model.new();g.interactive=true;g.setup(["king_arthur","medusa"],1,24,"heorot",{});g.fighters[0].node=18;g.fighters[1].node=17;g.phase="move";g.maneuver_distance=3
 for f in g.fighters:
  if int(f.id)>1:f.node=int(f.id)-2
 check(g.enter_friendly_transit(0,17),"Heorot may interact with door while passing through friendly occupied cell")
 g=clone(g);g.finish_maneuver();check(g.phase=="move","cannot finish movement sharing a cell")
 check(g.toggle_door(0,0) and g.toggle_door(0,0),"transiting fighter may close then pay to open door")
 check(g.move_fighter(0,19),"transiting fighter must leave to an empty cell")
 g.finish_maneuver();check(g.phase!="move" and not g.fighters[0].has("friendly_transit"),"valid endpoint completes maneuver and clears transit")
