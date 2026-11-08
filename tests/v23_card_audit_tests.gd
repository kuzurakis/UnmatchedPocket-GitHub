extends "res://tests/v22_rules_tests.gd"
func run():
 var g=game(["t_rex","king_arthur"],true);var foe=adjacent(g);var hp=g.fighters[0].hp;g.players[0].hand=[card(g,0,"15000_pounds_of_muscle")];g.players[1].hand=[raw_card("defense",99)]
 g.attack(0,foe,0);g.continue_attack();check(g.phase=="combat_report" and g.fighters[0].hp==hp,"Muscle self damage waits for After Combat")
 g=clone(g);g.continue_combat();g=stable(g);check(g.fighters[0].hp==hp-2,"Muscle self damage resolves after combat")
 test_optional23();test_large23()
 print("V23_TIMING checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)

func test_optional23():
 var g=game(["she_hulk","king_arthur"],true);var foe=adjacent(g);g._flow.clear();g.pending_choice.clear();g.phase="action";g.players[0].discard=[raw_card("attack",2)]
 combat(g,0,foe,card(g,0,"sensational"),raw_card("defense",0));g=wait_choice(g,"v22_sensational");var n=g.players[0].deck.size();g=clone(g);g.choose_effect_option(1);g=stable(g)
 check(g.players[0].deck.size()==n and g.players[0].discard.size()==2,"Sensational can decline without recycling")
 g=game(["cloak_and_dagger","king_arthur"],true);g.fighters[0].hp=1;g.fighters[1].hp=2;g.players[0].hand=[card(g,0,"chosen_fate")];g.scheme(0,0)
 check(g.pending_choice.action=="v22_fate_target","Chosen Fate selects own fighter")
 g=clone(g);g.choose_effect_option(0);check(g.pending_choice.options.size()==5,"Chosen Fate offers all zero through four damage values")
 g=clone(g);g.choose_effect_option(4);g=stable(g);check(not g.fighters[0].alive and g.fighters[1].hp==6 and g.players[0].hand.size()==2,"Chosen Fate heals assigned damage and draws after lethal payment")
 for accept in [false,true]:
  g=game(["moon_knight","king_arthur"],true);foe=adjacent(g);g.players[1].deck=[raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)];combat(g,0,foe,card(g,0,"thats_the_part_i_like"),raw_card("defense",0));g=wait_choice(g,"v21_optional")
  check(g.pending_choice.get("cards",[]).is_empty(),"Moon Knight decides to look before top cards are disclosed")
  g=clone(g);g.choose_effect_option(0 if accept else 1)
  if accept:
   check(g.pending_choice.action=="v21_top_discard" and g.pending_choice.cards.size()==3 and not g.pending_choice.can_skip,"after accepting top-three effect a discard is mandatory")
   g=clone(g);g.choose_effect_option(1);check(g.pending_choice.action=="v21_top_order","remaining cards ask order");g=clone(g);g.choose_effect_option(0)
  g=stable(g);check(g.players[1].deck.size()==(2 if accept else 3),"Moon Knight exact deck change for both branches")
func test_large23():
 var g=game(["t_rex","winter_soldier"],true);g.fighters[0].node=0;g.fighters[0].tail=1;g.fighters[1].node=2
 check(g.fighters_adjacent(0,1) and g.fighters_adjacent(1,0),"adjacency includes tail in both directions")
 check(g._v14._adjacent(1).has(0),"shared adjacent damage/conditions include large base tail")
 check(g.fighters_distance(0,1)==1,"range distance starts from nearest occupied cell")
 g._snapshot_positions();g.fighters[0].node=1;g.fighters[0].tail=0;check(not g.changed_start_space(0),"rotation on same two cells does not activate Momentous Shift")
 g=clone(g);check(not g.changed_start_space(0),"start footprint survives JSON save")
 g.fighters[0].node=2;g.fighters[0].tail=1;check(g.changed_start_space(0),"new occupied cell activates Momentous Shift")
 g=game(["tomoe_gozen","t_rex"],true);var rex=g.hero_fighter(1);g.fighters[0].node=0;g.fighters[rex].node=10;g.fighters[rex].tail=1
 for node in g.nodes:node.zones=[1]
 g.nodes[0].zones=[0];g.nodes[1].zones=[0]
 var hp=g.fighters[rex].hp;g.fighters[rex].chosen_tail=23;g._enter_node(rex,24)
 check(g.fighters[rex].hp==hp-1,"Tomoe detects departure from zone occupied by tail only")
 g=game(["t_rex","king_arthur"],true);g.board_data={"width":100,"height":100,"node_radius":100};g.fighters[0].node=0;g.fighters[0].tail=1;g.fighters[1].node=24;g.fighters[2].node=23;g._snapshot_positions()
 var foe=g.hero_fighter(1);g.fighters[foe].node=2;combat(g,0,foe,card(g,0,"momentous_shift"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==3,"unmoved T Rex Shift stays printed value")

 g=game(["t_rex","king_arthur"],true);g.board_data={"width":100,"height":100,"node_radius":100};g.fighters[0].node=0;g.fighters[0].tail=1;g.fighters[1].node=24;g.fighters[2].node=23
 check(g._swap_combatants(0,1),"large fighter swap succeeds with a legal new footprint")
 check(g.fighters[0].node==24 and g.fighters[1].node==0 and g.nodes[24].neighbors.has(int(g.fighters[0].tail)),"swap rebuilds tail beside destination rather than leaving ghost tail")
 check(g._occupant(1)==-1 and g._occupant(int(g.fighters[0].tail))==0,"swap frees previous tail and occupies new one")
 g=game(["t_rex","king_arthur"],true);g.fighters[0].node=0;g.fighters[0].tail=1;g.fighters[1].node=24;g.nodes[24].neighbors=[]
 check(not g._swap_combatants(0,1) and g.fighters[0].node==0 and g.fighters[0].tail==1 and g.fighters[1].node==24,"impossible large swap leaves both footprints intact")

 g=game(["t_rex","king_arthur"],true);g._snapshot_positions();var legacy=g.save_state();legacy.version=22;legacy.erase("turn_start_tails")
 check(g.load_state(JSON.parse_string(JSON.stringify(legacy))) and not g.changed_start_space(0),"old saves do not grant false movement bonus without a start-tail snapshot")
