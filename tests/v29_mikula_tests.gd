extends "res://tests/v23_card_audit_tests.gd"
func fixture(manual=true):
 var g=game(["mikula","king_arthur"],manual);g=stable(g);adjacent(g);g.players[0].pouch_node=12;return g
func run():
 var g=fixture();check(g.fighters[0].hp==16 and not g._v19.large(0),"Mikula normal fighter stats");check(g._v29.near(0,0),"pouch on hero space activates marked effects")
 g.players[0].pouch_node=24;check(not g._v29.near(0,0),"distant pouch deactivates effects")
 for source in g.heroes.mikula.cards:
  for manual in [false,true]:
   g=fixture(manual);var foe=g.hero_fighter(1);g.players[0].hand=[source.duplicate(true),raw_card("attack",1)];g.players[1].hand=[raw_card("attack",4),raw_card("defense",2)];g.fighters[0].hp=8
   if source.type=="scheme":check(g.scheme(0,0),"scheme "+source.id)
   elif source.type=="defense":combat(g,foe,0,raw_card("attack",5),source)
   else:check(g.attack(0,foe,0),"attack "+source.id)
   g=stable(g);check(g.phase in ["action","discard","game_over"],"entire Mikula chain "+source.id)
 for close in [true,false]:
  g=fixture();var foe=g.hero_fighter(1);g.players[0].pouch_node=12 if close else 24
  combat(g,0,foe,card(g,0,"mikula_07"),card(g,1,"feint"));g=stable(g);check(g.last_combat.attack_value==(4 if close else 2),"marked value survives cancel only near bag")
  g=fixture();foe=g.hero_fighter(1);g.players[0].pouch_node=12 if close else 24;g.fighters[0].hp=8
  combat(g,0,foe,card(g,0,"mikula_05"),card(g,1,"feint"));g=stable(g);check(g.fighters[0].hp==(9 if close else 8),"marked After Combat heal survives cancellation")
 g=fixture();var foe=g.hero_fighter(1);g.players[0].pouch_node=int(g.fighters[foe].node);var hp=g.fighters[foe].hp;combat(g,foe,0,raw_card("attack",3),raw_card("defense",20));g=stable(g);check(g.fighters[foe].hp==hp-1 and g.last_combat.attack_value==5,"enemy on pouch pays HP and gains attack two")
 g=fixture();var saved=g.players[0].pouch_node;g=clone(g);check(g.players[0].pouch_node==saved,"pouch saved")
 for active in [false,true]:
  g=fixture();g.players[0].pouch_node=12 if active else 24;g.players[0].hand=[card(g,0,"mikula_11")];var count=g.players[1].deck.size();g.scheme(0,0);g=stable(g);check(g.players[0].hand.size()==(3 if active else 2),"plough replaces own discard while active");check(g.players[1].deck.size()==count-int(active),"plough mills chosen enemy only while active")
 for level in range(3):
  g=Model.new();g.interactive=true;g.setup(["mikula","svyatogor","medusa","king_arthur"],level,2929,"marmoreal",{"mode":"teams"if level==2 else"ffa"});var steps=0
  while g.winner<0 and steps<3000:
   advance(g);steps+=1
   if steps%19==0:g=clone(g)
  check(g.winner>=0,"Mikula full match completes");matches+=1
 print("V29_MIKULA checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
