extends "res://tests/v32_board_tests.gd"
func run():
 var g=santa32();var foe=g.hero_fighter(1);g.fighters[0].node=21;g.fighters[foe].node=27;g.fighters[1].node=13
 print("BELT ",g.board_data.conveyor," FIND ",g.board_data.conveyor.find(21)," I ",g._int_array(g.board_data.conveyor).find(21))
 print("PLAN ",g._v32.conveyor_plan()," FLAG ",g.players[0].get("v32_end_turn",-1)," PHASE ",g.phase)
 for f in g.fighters:print(f.id," ",f.node," alive ",f.alive," large ",g._v19.large(int(f.id))," reloc ",g._v13.can_relocate(int(f.id)))
 g._v32.end_board();print("AFTER ",g.phase," ",g.pending_choice," POS ",g.fighters[0].node);quit()
