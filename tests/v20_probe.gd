extends "res://tests/v19_rules_tests.gd"
func advance(g):
 if g.phase=="effect_choice":
  var p=g.pending_choice.duplicate(true)
  if not g.choose_effect_option(0):print("BAD_CHOICE=",JSON.stringify(p)," RESTORED=",JSON.stringify(g.pending_choice));check(false,"choice rejected")
 else:super.advance(g)
func run():
 var catalog=Model.new()
 for source in catalog.heroes.t_rex.cards:
  var g=game(["t_rex","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[source.duplicate(true),raw_card("versatile",2),raw_card("attack",3)];g.players[0].discard=[raw_card("attack",2)]
  print("CARD ",source.id)
  if source.type=="scheme":g.scheme(0,0)
  else:g.attack(0,foe,0)
  g=stable(g)
 print("PROBE_DONE ",failures);quit()
