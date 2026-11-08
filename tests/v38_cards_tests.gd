extends "res://tests/v36_edge_tests.gd"
const NATURE=["birds","moose","kraken","godzilla"]
func fixture38(hid: String,manual=true):
 var g=game([hid,"king_arthur"],manual);g=stable(g);adjacent(g)
 if g._v19.large(0):g._v19.body(0,int(g.fighters[0].node),-1)
 return g
func c38(g,p: int,n: int):return card(g,p,"nature_"+str(g.players[p].hero_id)+"_"+str(n))
func run():
 var catalog=Model.new()
 for hid in NATURE:
  for source in catalog.heroes[hid].cards:
   for defending in ([false,true]if source.type=="versatile"else[false]):
    for manual in [false,true]:
     var g=fixture38(hid,manual);var fid=1 if source.fighter=="sidekick"else 0
     if fid==1:g.fighters[fid].alive=true;g.fighters[fid].hp=1;g.fighters[fid].reserve=false
     var foe=adjacent(g,fid);g.players[0].hand=[source.duplicate(true),raw_card("attack",2),raw_card("defense",2)];g.players[1].hand=[raw_card("attack",3),raw_card("defense",2)]
     if source.type=="scheme":check(g.scheme(fid,0),"scheme "+source.id)
     elif source.type=="defense"or defending:combat(g,foe,fid,raw_card("attack",4),source)
     else:check(g.attack(fid,foe,0),"attack "+source.id)
     g=stable(g);check(g.phase in["action","discard","game_over"],"completed "+source.id+str(manual));card_runs+=1
 print("V38_CARDS checks=%d failures=%d scenarios=%d"%[checks,failures,card_runs]);quit(1 if failures else 0)
