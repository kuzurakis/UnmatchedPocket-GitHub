extends "res://tests/v23_card_audit_tests.gd"
func run():
 for level in range(3):
  for roster in [["svyatogor","medusa"],["svyatogor","king_arthur","alice"],["svyatogor","medusa","sinbad","alice"]]:
   var g=Model.new();g.interactive=true;g.setup(roster,level,2626,"marmoreal",{"mode":"teams"if roster.size()==4 else"ffa"});var steps=0
   while g.winner<0 and steps<3000:
    advance(g);steps+=1
    if steps%23==0:g=clone(g)
   check(g.winner>=0,"fan match completes");matches+=1
 print("V26_MATCHES checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
