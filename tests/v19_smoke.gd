extends SceneTree
func _initialize():
 var g=load("res://scripts/game_engine.gd").new()
 g.setup(["t_rex","dr_ellie_sattler"],1,1919,"t_rex_paddock")
 assert(g.map_id=="t_rex_paddock" and g.players.size()==2 and g.fighters.size()==3)
 assert(g.fighters[0].hp==27 and g.fighters[1].hp==13)
 var other=load("res://scripts/game_engine.gd").new()
 assert(other.load_state(JSON.parse_string(JSON.stringify(g.save_state()))))
 assert(other.fighters[0].get("tail",-1)==g.fighters[0].get("tail",-1))
 print("V19_INTEGRATION_OK")
 quit()
