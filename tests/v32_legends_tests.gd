extends "res://tests/v31_marvel_tests.gd"
const LEGENDS32=["blackbeard","loki","chupacabra","pandora"]
func fixture32(hid: String,manual=true,enemy="king_arthur"):
 var g=game([hid,enemy],manual);g=stable(g);adjacent(g)
 if hid=="blackbeard":g.players[0].doubloons=3
 return g
func c32(g,p: int,n: int):return card(g,p,"bol3_"+str(n))
func run():
 all_cards32();test_tricks32();test_pirate32();test_pandora32();test_chupa32();matches32()
 print("V32_LEGENDS checks=%d failures=%d cards=%d matches=%d"%[checks,failures,card_runs,matches]);quit(1 if failures else 0)
func all_cards32():
 var catalog=Model.new()
 for hid in LEGENDS32:
  for source in catalog.heroes[hid].cards:
   for defending in ([false,true]if source.type=="versatile"else[false]):
    for manual in [false,true]:
     var g=fixture32(hid,manual);var fid=1 if source.fighter=="sidekick"else 0
     if hid=="pandora"and fid==1:g._v32._summoned(1,7)
     var foe=adjacent(g,fid);g.fighters[0].hp=6;g.players[0].hand=[source.duplicate(true),raw_card("attack",1),raw_card("defense",1)];g.players[1].hand=[raw_card("attack",3),raw_card("defense",2)]
     if source.type=="scheme":check(g.scheme(fid,0),"scheme "+hid+":"+source.id)
     elif source.type=="defense"or defending:combat(g,foe,fid,raw_card("attack",5),source)
     else:check(g.attack(fid,foe,0),"attack "+hid+":"+source.id)
     g=stable(g);check(g.phase in["action","discard","game_over"],"chain finishes "+hid+":"+source.id);card_runs+=1
func test_tricks32():
 var g=fixture32("loki");var foe=g.hero_fighter(1);var trick=c32(g,0,654);trick.trick_owner=0;var n=g.players[0].hand.size();combat(g,0,foe,trick,raw_card("defense",20));g=stable(g)
 check(g.players[1].hand.any(func(c):return c.get("trick",false))and not g.players[0].discard.any(func(c):return c.id=="bol3_654"),"Loki played Trick goes to actual opponent hand")
 check(g._movement(0)==3,"each opposing Trick adds movement")
 g.active=1;g.actions_left=2;g.players[1].hand=[trick.duplicate(true)];g.fighters[foe].hp=10;combat(g,foe,0,trick,raw_card("defense",20));g=stable(g);check(g.fighters[foe].hp==8 and g.players[0].discard[-1].id=="bol3_654","borrowed Trick has non-Loki penalty and returns to Loki discard")
 g=fixture32("loki");trick=c32(g,0,659);trick.trick_owner=0;g.players[1].hand=[trick];g._discard_from_opponent(1,g.players[1].hand.pop_back());check(g.players[0].trick_returns.size()==1,"foreign hand discard queues return to Loki")
 g._v32.flush_returns("action");g=stable(g);check(g.players[0].hand.any(func(c):return c.id=="bol3_659"),"Loki chooses hand on forced discard")
 g=fixture32("loki");trick=c32(g,0,658);trick.trick_owner=0;g._discard(1,trick,"deck");check(g.players[0].discard[-1].id=="bol3_658" and g.players[0].trick_returns.is_empty(),"deck discard is not hand discard")
 check(not g.can_boost_card(trick),"Tricks cannot BOOST")
 g=fixture32("loki");foe=g.hero_fighter(1);g.players[0].hand=[c32(g,0,656)];g.players[1].hand=[raw_card("defense",5),raw_card("defense",1)];g.attack(0,foe,0);g=stable(g);check(g.last_combat.defense_value==1 or g.last_combat.defense_value==5,"Looking for Trouble replaces defense with a legal choice")
 g=fixture32("loki");foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",2),c32(g,0,658));g=stable(g);check(g.last_combat.attack_value==0,"Sindri penalty clamps at zero")
func test_pirate32():
 var g=fixture32("blackbeard");var foe=g.hero_fighter(1);g.players[0].doubloons=2;g._damage(0,1,false);check(g.players[0].doubloons==2,"effect damage does not pay doubloon")
 g._damage(0,1,true);check(g.players[0].doubloons==1,"combat damage pays exactly one doubloon")
 g._damage(1,1,true);check(g.players[0].doubloons==1,"Sea Dog combat damage does not pay")
 g=fixture32("blackbeard");g.players[0].doubloons=3;foe=g.hero_fighter(1);g.players[1].hand=[raw_card("defense",1),raw_card("attack",1)];var n=g.players[1].hand.size();combat(g,0,foe,c32(g,0,685),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==5,"Avast attack printed five")
 g=fixture32("blackbeard");foe=g.hero_fighter(1);g.players[0].doubloons=1;combat(g,0,foe,c32(g,0,689),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==3 and g.players[0].doubloons==3,"Queen Anne value seven minus two for each of two paid doubloons")
func test_pandora32():
 var g=fixture32("pandora");g.players[0].box=["pain","toil","misfortune"];g.players[0].miseries=[];var hp=g.fighters[0].hp;g._start_ability(0,"Box",[{"kind":"v32_box_draw"}],"start_turn");g=stable(g)
 check(g.players[0].miseries.size()==2 and g.fighters[0].hp==hp-2,"three feather threshold deals revealed card count, not feather count")
 g=clone(g);check(g.players[0].box.size()+g.players[0].miseries.size()==3,"box and revealed state saved without duplication")
 g._v32.reset_box(0);check(g.players[0].miseries.is_empty()and g.players[0].box.size()==3,"all revealed miseries reshuffle at end of turn")
 g=fixture32("pandora");g.players[0].miseries=["toil","hope","greed"];var foe=g.hero_fighter(1);combat(g,0,foe,c32(g,0,665),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==7,"Hera adds revealed three and Toil adds separate hero bonus")
func test_chupa32():
 for hp in [7,8]:
  var g=fixture32("chupacabra");var foe=g.hero_fighter(1);g.fighters[0].hp=hp;combat(g,0,foe,c32(g,0,682),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==(5 if hp==7 else 3),"Wounded Beast exact threshold")
 var g=fixture32("chupacabra");var foe=g.hero_fighter(1);combat(g,0,foe,c32(g,0,676),raw_card("defense",4));g=stable(g);check(g.last_combat.attack_value==8,"Struggle doubles printed opposing value")
 g=fixture32("chupacabra");foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",4),c32(g,0,679));g=stable(g);check(g.players[0].hand.any(func(c):return c.id=="bol3_679"),"Natural Toughness returns after lost defense")
func matches32():
 for hid in LEGENDS32:
  for level in range(3):
   var ids=[hid]+LEGENDS32.filter(func(x):return x!=hid);var g=Model.new();g.interactive=true;g.setup(ids,level,3200+level,"santas_workshop"if level==2 else"venice",{"mode":"teams"if level==2 else"ffa"});var steps=0
   while g.winner<0 and steps<4000:
    advance(g);steps+=1
    if steps%29==0:g=clone(g)
   check(g.winner>=0,"full match new legends "+hid+":"+str(level));matches+=1
