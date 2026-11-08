extends "res://tests/v18_rules_tests.gd"
func run():
 var g=game(["t_rex","dr_ellie_sattler"],true)
 check(g.fighters[0].hp==27 and g.players[0].move==1,"T Rex printed stats")
 check(g.players[0].hand.size()+g.players[0].deck.size()==30,"complete Rex deck")
 check(g.players[1].hand.size()+g.players[1].deck.size()==30,"complete Sattler deck")
 var old=g.players[0].deck.size();g.end_turn();check(g.players[0].deck.size()==old-1,"mandatory end draw")
 var tokens=[]
 for i in range(6):g._v19.add_token(1,3)
 check(g.players[1].insight.size()==5,"insight supply and stacking")
 all_catalog_cards_v8()
 print("V19_RULES checks=%d failures=%d cards=%d"%[checks,failures,card_runs]);quit(1 if failures else 0)
