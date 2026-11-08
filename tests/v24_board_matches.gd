extends "res://tests/v23_card_audit_tests.gd"
func run():
 for map in ["hells_kitchen","the_raft","navy_pier","helicarrier","sanctum_sanctorum"]:
  for level in range(3):
   var g=Model.new();g.interactive=true;g.setup(["doctor_strange","winter_soldier","daredevil","cloak_and_dagger"],level,2424,map,{"mode":"teams" if level==2 else "ffa"});var steps=0
   while g.winner<0 and steps<4000:
    advance(g);steps+=1
    if steps%23==0:g=clone(g)
   check(g.winner>=0,"board item match completes "+map+str(level));matches+=1
 print("V24_MATCHES checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
