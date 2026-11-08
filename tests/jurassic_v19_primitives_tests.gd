extends SceneTree
const R = preload("res://scripts/jurassic_rules_v19.gd")
func _initialize():
 var t=[]
 assert(R.insight_after_move(t,0,1,false))
 assert(not R.insight_after_move(t,1,1,false))
 assert(not R.insight_after_move(t,1,2,true))
 for i in range(4):assert(R.insight_add(t,1))
 assert(t==[1,1,1,1,1] and not R.insight_add(t,2))
 assert(R.insight_clear(t)==5 and t.is_empty())
 var n=[{"neighbors":[1]},{"neighbors":[0,2]},{"neighbors":[1,3]},{"neighbors":[2,4]},{"neighbors":[3]}]
 assert(R.large_attack_reach(n,1,0)==[2,3])
 assert(R.large_attack_reach(n,0,-1)==[1,2])
 print("JURASSIC_PRIMITIVES_OK")
 quit()
