extends "res://tests/v36_edge_tests.gd"
func run():
 for mode in ["ffa","teams"]:
  var g=Model.new();g.interactive=false;g.setup(["medusa","krang","shredder","svyatogor"],2,3737,"marmoreal",{"mode":mode});var steps=0
  for p in range(4):g.players[p].ai_skill=3 if p==0 else 2
  while g.winner<0 and steps<2200:
   g.difficulty=3 if g.active==0 else 2;advance(g);steps+=1
  check(g.winner>=0,"Master completes four-player "+mode)
 print("V37_MODES checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
