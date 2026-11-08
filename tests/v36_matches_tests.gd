extends "res://tests/v36_edge_tests.gd"
func run():
 for ids in [["shredder","krang"],["krang","svyatogor"],["shredder","king_arthur","krang","mikula"],["shredder","krang","t_rex","tomoe_gozen"],["krang","baba_yaga","shredder","liz_sherman"]]:
  for level in range(3):
   var g=Model.new();g.interactive=true;g.setup(ids,level,3600+level,"marmoreal",{"mode":"teams"if ids.size()==4 and level==2 else"ffa"});var steps=0
   while g.winner<0 and steps<6000:
    advance(g);steps+=1
    if steps%31==0:g=clone(g)
   check(g.winner>=0,"complete match "+str(ids)+str(level));matches+=1
 print("V36_MATCHES checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
