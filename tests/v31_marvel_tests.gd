extends "res://tests/v26_svyatogor_tests.gd"
const MARVEL31=["black_panther","black_widow","squirrel_girl","deadpool"]
func fixture31(hid: String,manual=true):
 var g=game([hid,"king_arthur"],manual);g=stable(g);adjacent(g);return g
func ctx31(g,c={},self_id=0):
 return {"owner":0,"self":self_id,"opponent":g.hero_fighter(1),"opponent_owner":1,"card":c,"value":int(c.get("value",0)),"won":true,"cancelled":false,"_combat_slot":"a"}
func sq31(g,count: int,node: int):
 for i in range(count):
  var f=g.fighters[i+1];f.node=node;f.alive=true;f.hp=1;f.reserve=false;f.placed=true
func run():
 test_suit31();test_widow31();test_small31();test_deadpool31();all_cards31();matches31()
 print("V31_MARVEL checks=%d failures=%d cards=%d matches=%d"%[checks,failures,card_runs,matches]);quit(1 if failures else 0)
func test_suit31():
 var g=fixture31("black_panther");var c=raw_card("attack",2);c.id="stolen";c.boost=4;g.players[1].deck=[c];g._v31.store(ctx31(g),2)
 check(g.players[0].suit.size()==1 and g.players[1].deck.is_empty(),"store reveals only available cards without exhaustion")
 g=clone(g);var n=g.players[0].hand.size();check(g._v31.suit_maneuver(0,0),"stored card can boost maneuver")
 check(g.players[0].hand.size()==n+2 and g.players[0].suit.is_empty()and g.players[1].discard[-1].id=="stolen","Panther draws mandatory plus boost and stolen card returns to original discard")
 g=fixture31("black_panther");var foe=g.hero_fighter(1);g.players[0].hand=[card(g,0,"wakanda_forever"),raw_card("attack",1),raw_card("attack",1)];g.players[0].deck=[raw_card("attack",1),raw_card("attack",1),raw_card("attack",1)]
 g.players[1].hand=[raw_card("defense",20)];g.attack(0,foe,0);g=stable(g);check(g.last_combat.attack_value>=5 and g.players[0].deck.size()==1,"two boosts independently draw two cards")
 g=fixture31("black_panther");foe=g.hero_fighter(1);combat(g,0,foe,card(g,0,"anti_metal_claws"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value>=3,"anti metal claws adds opposing BOOST")
func test_widow31():
 for seed_value in range(12):
  var g=Model.new();g.setup(["black_widow","medusa"],1,seed_value+3100,"marmoreal")
  check(g.players[0].hand.size()==6 and g.players[0].hand.filter(func(c):return c.id=="the_moscow_protocol").size()==1,"six starting cards with Moscow guaranteed")
 var g=fixture31("black_widow");var c=card(g,0,"the_moscow_protocol");g.players[0].hand=[c];check(not g.scheme(0,0),"Moscow mission cannot be played before damage")
 g._damage(g.hero_fighter(1),1);check(g.scheme(0,0),"Moscow after damage allowed");g=stable(g);check(g.players[0].hand.any(func(x):return x.type=="scheme"),"acquire reveals a mission")
 g=fixture31("black_widow");c=card(g,0,"the_budapest_gambit");g.players[0].hand=[c,raw_card("attack",1),raw_card("attack",1),raw_card("attack",1)];check(not g._v31.mission_allowed(0,c),"Budapest excludes itself but requires at most two other cards");g.players[0].hand.pop_back();check(g._v31.mission_allowed(0,c),"Budapest exact two other cards")
 g=fixture31("black_widow");var foe=g.hero_fighter(1);g.fighters[1].node=7;g.fighters[0].node=12;var hero_hp=g.fighters[0].hp;var helper_hp=g.fighters[1].hp;combat(g,foe,0,raw_card("attack",6),card(g,0,"double_identity"));g=stable(g)
 check(g.fighters[0].hp==hero_hp and g.fighters[1].hp==helper_hp-3 and g.last_combat.target==1,"Double Identity switches actual defender and damage target")
 g=fixture31("black_widow");foe=g.hero_fighter(1);combat(g,0,foe,card(g,0,"caught_in_a_web"),card(g,1,"regroup"));g=stable(g);check(g.players[1].hand.size()==0,"web suppresses only opposing After Combat")
 g=fixture31("black_widow");foe=g.hero_fighter(1);g.fighters[1].hp=1;g.fighters[1].node=12;g.fighters[0].node=7;combat(g,foe,1,raw_card("attack",4),card(g,0,"life_model_decoy"));g=stable(g);check(g.fighters[1].alive and g.fighters[1].hp==3 and g.fighters_adjacent(0,1),"Maria returns adjacent at three HP")
func test_small31():
 var g=fixture31("squirrel_girl");check(g._v31.squirrels(0).size()==1,"mandatory first-turn summon only one squirrel")
 sq31(g,4,13);var foe=g.hero_fighter(1);g.fighters[foe].node=13
 check(g._v31.can_end(1,13)and not g._v31.can_end(5,13),"four small fighters may share enemy cell but fifth cannot")
 check(g.fighters_adjacent(1,foe)and g.fighters_adjacent(foe,1),"shared-space adjacency symmetric")
 check(g._reachable(1,1).has(12),"small fighter can pass opposing hero")
 g._damage(1,1);check(not g.fighters[1].alive and not g.fighters[2].alive and not g.fighters[3].alive and not g.fighters[4].alive and g.fighters[foe].alive,"damage defeats full squirrel stack but not normal fighter")
 g=fixture31("squirrel_girl");sq31(g,4,13);foe=g.hero_fighter(1);combat(g,0,foe,card(g,0,"kick_butts"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==5,"Kick Butts counts four sharing target space")
 g=fixture31("squirrel_girl");sq31(g,4,13);foe=g.hero_fighter(1);combat(g,0,foe,card(g,0,"unbeatable_squirrel_girl"),card(g,1,"feint"));g=stable(g);check(g.last_combat.attack_cancelled,"defender Feint cancels Squirrel Girl before her immediate effect")
 g=fixture31("squirrel_girl");sq31(g,4,13);foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",20),card(g,0,"unbeatable_squirrel_girl"));g=stable(g);check(g.last_combat.damage==0 and g.last_combat.attack_cancelled,"four squirrels cancel and ignore attack value")
func test_deadpool31():
 var g=fixture31("deadpool");var foe=g.hero_fighter(1);g.fighters[0].hp=5;combat(g,0,foe,card(g,0,"feint"),raw_card("defense",20));g=stable(g);check(g.fighters[0].hp==6,"Deadpool heals after losing attack")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.players[1].real_name="Logan";combat(g,0,foe,card(g,0,"underrated_super_heroes"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==11,"Logan adds five to attack")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.players[0].deadpool_conditions.food=true;combat(g,0,foe,card(g,0,"chimichanga_break"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==5,"food condition applied")
 g=fixture31("deadpool");foe=g.hero_fighter(1);combat(g,0,foe,card(g,0,"i_m_not_wearing_pants"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==5,"unsleeved digital card value five")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.players[0].deck=[card(g,0,"underrated_super_heroes")];combat(g,0,foe,card(g,0,"time_out_time_out_time_out"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==6 and g.last_combat.attack_card.id=="underrated_super_heroes","Time Out replaces card and resulting value")
func all_cards31():
 var catalog=Model.new()
 for hid in MARVEL31:
  for source in catalog.heroes[hid].cards:
   for manual in [false,true]:
    var g=fixture31(hid,manual);var fid=0
    if source.fighter=="sidekick":fid=1
    if hid=="squirrel_girl":sq31(g,4,13)
    var foe=adjacent(g,fid);g.players[0].hand=[source.duplicate(true),raw_card("attack",1),raw_card("defense",1)];g.players[1].hand=[raw_card("defense",2),raw_card("attack",3)];g.fighters[0].hp=6
    if hid=="black_widow":
     if source.id=="the_budapest_gambit":g.players[0].hand=[source.duplicate(true)]
     if source.id=="the_kinshasa_directive":g.fighters[0].node=int(g.board_data.get("starts",[0,4,24,20])[int(g.start_slots[0])])
     if source.id=="the_madripoor_sanction":g.fighters[0].node=int(g.board_data.get("starts",[0,4,24,20])[int(g.start_slots[1])])
     g.fighters[foe].damaged_turn=g.turn_number
    if source.type=="scheme":check(g.scheme(fid,0),"scheme starts "+hid+":"+source.id)
    elif source.type=="defense":combat(g,foe,fid,raw_card("attack",5),source)
    else:check(g.attack(fid,foe,0),"attack starts "+hid+":"+source.id)
    g=stable(g);check(g.phase in ["action","discard","game_over"],"card chain ends "+hid+":"+source.id);card_runs+=1
func matches31():
 for hid in MARVEL31:
  for skill in range(3):
   var g=Model.new();g.interactive=true;g.setup([hid,"black_panther"if hid!="black_panther"else"squirrel_girl","black_widow"if hid!="black_widow"else"deadpool","svyatogor"],skill,3131+skill,"marmoreal",{"mode":"teams"if skill==2 else"ffa"});var steps=0
   while g.winner<0 and steps<3000:
    advance(g);steps+=1
    if steps%31==0:g=clone(g)
   check(g.winner>=0,"full new-hero match completes "+hid+":"+str(skill));matches+=1
