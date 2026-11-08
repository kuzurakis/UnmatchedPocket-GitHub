extends "res://tests/v22_rules_tests.gd"
var last_branch=false
var label23=""
var coverage=[]
func advance(g):
 if last_branch and g.phase=="effect_choice":
  check(g.choose_effect_option(g.pending_choice.options.size()-1),label23+" alternate option "+str(g.pending_choice.get("action","")))
 else:super.advance(g)
func run():
 var catalog=Model.new()
 for hid in catalog.heroes:
  for source in catalog.heroes[hid].cards:
   var roles=["scheme"] if source.type=="scheme" else ["defense"] if source.type=="defense" else ["attack","defense"] if source.type=="versatile" else ["attack"]
   for role in roles:
    for branch in range(2):
     label23=str(hid)+"/"+str(source.id)+" "+role+" "+str(branch);last_branch=branch==1;var prior=failures
     var g=game([hid,"king_arthur"],true,{"buffy_sidekick":str(source.get("sidekick_variant","giles"))})
     var own=1 if str(source.fighter)=="sidekick" else 0
     if hid=="yennefer_triss" and source.fighter=="Трисс":own=1
     var foe=adjacent(g,own);g.players[0].hand=[source.duplicate(true),raw_card("versatile",2),raw_card("attack",3)]
     g.players[0].discard=[raw_card("attack",2)];g.players[0].rage=3;g.jekyll_form[0]=str(source.fighter) if str(source.fighter)in["jekyll","hyde"]else"jekyll"
     if hid=="willow":g.willow_form[0]="dark"
     if source.id in ["resurrect","revive_sidekick"]:g.fighters[1].alive=false;g.fighters[1].hp=0
     if role=="scheme":check(g.scheme(own,0),label23+" start")
     elif role=="defense":
      g.active=1;g.players[1].hand=[raw_card("attack",1 if branch==0 else 9)];check(g.attack(foe,own,0),label23+" incoming");g.continue_attack()
      if g.phase=="defend":check(g.defend(0),label23+" defense")
     else:
      g.players[1].hand=[raw_card("defense",0 if branch==0 else 12)];check(g.attack(own,foe,0),label23+" attack")
     g=stable(g);check(g.phase in ["action","discard","game_over"],label23+" terminates")
     for f in g.fighters:check(int(f.hp)==f.hp and f.hp>=0 and f.hp<=f.max_hp,label23+" health range")
     coverage.append({"hero":hid,"card":source.id,"role":role,"branch":branch,"passed":failures==prior})
 var out=FileAccess.open("res://../../work/v23-matrix-results.json",FileAccess.WRITE);out.store_string(JSON.stringify({"scenarios":coverage.size(),"checks":checks,"failures":failures,"results":coverage},"  "))
 print("V23_MATRIX checks=%d failures=%d scenarios=%d"%[checks,failures,coverage.size()]);quit(1 if failures else 0)
