extends "res://tests/v36_edge_tests.gd"
func run():
 var wins=0;var losses=0;var unfinished=0;var max_ms=0
 for pair in [["alice","king_arthur"],["medusa","sinbad"],["shredder","krang"],["svyatogor","mikula"]]:
  for swapped in [false,true]:
   for seed_value in [370,371]:
    var ids=pair.duplicate();if swapped:ids.reverse()
    var g=Model.new();g.interactive=false;g.setup(ids,2,seed_value,"training");var master=seed_value%2;var steps=0
    for p in range(2):g.players[p].ai_skill=3 if p==master else 2
    while g.winner<0 and steps<1800:
     # The defender's controller makes the defense choice, not the active attacker.
     var actor=int(g.pending_combat.defender_owner)if g.phase=="defend"else g.active
     g.difficulty=3 if actor==master else 2
     var t=Time.get_ticks_msec();advance(g);max_ms=maxi(max_ms,Time.get_ticks_msec()-t);steps+=1
    if g.winner==master:wins+=1
    elif g.winner>=0:losses+=1
    else:unfinished+=1
    check(g.winner>=0,"Master/Pro match completes "+str(ids)+str(seed_value));print("MATCH ",ids," master=",master," winner=",g.winner," steps=",steps)
 print("V37_BENCHMARK checks=%d failures=%d master_wins=%d pro_wins=%d unfinished=%d max_decision_ms=%d"%[checks,failures,wins,losses,unfinished,max_ms]);quit(1 if failures else 0)

