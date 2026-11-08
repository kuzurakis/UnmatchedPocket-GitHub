extends "res://tests/v19_rules_tests.gd"
func run():
 for level in range(3):
  var g=Model.new();g.setup(["t_rex","dr_ellie_sattler"],level,1919,"t_rex_paddock");g.interactive=true;var steps=0
  while g.winner<0 and steps<1500:
   advance(g);steps+=1
   if steps%19==0:g=clone(g)
  check(g.winner>=0,"new hero duel terminates")
 print("V19_MATCHES checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
