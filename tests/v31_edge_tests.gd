extends "res://tests/v31_marvel_tests.gd"
func run():
 for hid in MARVEL31:
  var catalog=Model.new()
  for source in catalog.heroes[hid].cards:
   if source.type!="versatile":continue
   for manual in [false,true]:
    var g=fixture31(hid,manual);var fid=1 if source.fighter=="sidekick"else 0
    if hid=="squirrel_girl":sq31(g,4,13)
    var foe=adjacent(g,fid);combat(g,foe,fid,raw_card("attack",4),source);g=stable(g);check(g.phase in ["action","discard","game_over"],"versatile card on defense "+hid+":"+source.id);card_runs+=1
 var g=fixture31("black_panther");var foe=g.hero_fighter(1);var top=raw_card("attack",3);top._suit_owner=1;top.boost=3;g.players[0].suit=[top];g.players[0].hand=[card(g,0,"vibranium_shockwave")];g.players[1].hand=[raw_card("defense",20)];var size=g.players[0].deck.size();g.attack(0,foe,0);g=stable(g)
 check(g.last_combat.attack_value==5 and g.players[0].deck.size()==size-1 and g.players[1].discard.size()==2,"stored combat BOOST returns card and draws immediately")
 g=fixture31("black_panther");foe=g.hero_fighter(1);size=g.players[1].deck.size();combat(g,0,foe,card(g,0,"analyze_and_adjust"),card(g,1,"feint"));g=stable(g);check(g.players[1].deck.size()==size and g.players[0].suit.is_empty(),"cancelled Panther card cannot steal after combat")
 g=fixture31("black_widow");var m=card(g,0,"the_kinshasa_directive");g.players[0].hand=[m];g.fighters[0].node=0;check(g.scheme(0,0),"Kinshasa allowed on exact own start");g=stable(g)
 g=fixture31("black_widow");g.fighters[0].node=4;check(g._v31.mission_allowed(0,card(g,0,"the_madripoor_sanction")),"Madripoor exact enemy start");g.fighters[0].node=3;check(not g._v31.mission_allowed(0,card(g,0,"the_madripoor_sanction")),"Madripoor rejects adjacent space")
 g=fixture31("squirrel_girl");sq31(g,4,13);foe=g.hero_fighter(1);g.fighters[foe].node=13;g.fighters[0].node=12;g.players[0].hand=[card(g,0,"nutwork_of_spies")];g.players[1].hand=[raw_card("attack",2),raw_card("attack",3),raw_card("attack",4)];g.scheme(0,0)
 check(g.phase=="effect_choice" and g.pending_choice.cards.size()==3,"Nutwork exposes hand to owner before choice");g=clone(g);g=stable(g);check(g.players[1].hand.size()==1,"Nutwork discards two with four adjacent squirrels")
 g=fixture31("squirrel_girl");sq31(g,8,0)
 for i in range(1,9):g.fighters[i].node=i+1
 var count=g._v31.squirrels(0).size();g._start_ability(0,"Summon",[{"kind":"v31_summon","where":"adjacent","amount":1,"empty":true}],"start_turn");check(g.pending_choice.action=="v31_summon_source","all eight on board asks which squirrel to relocate");g=stable(g);check(g._v31.squirrels(0).size()==count,"summoning at supply limit relocates instead of creating ninth")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.fighters[0].node=0;g.fighters[foe].node=12;g.players[0].hand=[card(g,0,"xavier_institute_faculty"),card(g,0,"underrated_super_heroes")];check(g.legal_targets(0,0).has(foe)and not g.legal_targets(0,1).has(foe),"only Xavier card allows ranged attack")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.fighters[0].hp=5;g.players[0].deadpool_conditions.owns_set=false;var hp=g.fighters[foe].hp;combat(g,0,foe,card(g,0,"deadpool_merc_for_hire_llc"),raw_card("defense",20));g=stable(g);check(g.fighters[foe].hp==hp,"physical ownership bonus off by default")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.players[0].deadpool_conditions.owns_set=true;hp=g.fighters[foe].hp;combat(g,0,foe,card(g,0,"deadpool_merc_for_hire_llc"),raw_card("defense",20));g=stable(g);check(g.fighters[foe].hp==hp-1,"physical ownership bonus can be enabled")
 g=fixture31("deadpool");foe=g.hero_fighter(1);g.players[1].real_name="Alice";combat(g,0,foe,card(g,0,"call_me"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==3 and g.players[0].signed_names.has("alice"),"Call Me writes signature after first use")
 g.actions_left=2;combat(g,0,foe,card(g,0,"call_me"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==4,"Call Me reads signature on subsequent use")
 g=Model.new();g.interactive=true;g.setup(["deadpool","medusa"],1,3132,"marmoreal");g=stable(g);g.fighters[0].node=0;foe=g.hero_fighter(1);g.fighters[foe].node=1;g.players[1].deadpool_conditions.mirror=true;hp=g.fighters[foe].hp;combat(g,0,foe,card(g,0,"gaze_of_stone"),raw_card("defense",0));g=stable(g);check(g.fighters[foe].hp==hp-10,"Gaze mirror routes extra eight to Medusa")
 g=fixture31("black_panther");var unusable=raw_card("attack",1);unusable.boost=0;unusable.voyage=true;unusable._suit_owner=1;g.players[0].suit=[unusable];size=g.players[0].hand.size();check(not g._v31.suit_maneuver(0,0)and g.players[0].suit.size()==1 and g.players[0].hand.size()==size,"unboostable stolen card stays in suit")
 g=game(["black_panther","houdini"],true);g=stable(g);g.fighters[0].hp=8;g.players[1].deck=[card(g,1,"all_part_of_the_show")];g._v31.store(ctx31(g),1);check(g._v31.suit_maneuver(0,0),"Panther can boost with stolen Houdini card");g=stable(g);check(g.fighters[0].hp==10 and g.players[1].discard[-1].id=="all_part_of_the_show","stolen Houdini BOOST effect resolves and card returns to owner")
 g=fixture31("squirrel_girl",false);sq31(g,4,13);foe=g.hero_fighter(1);g.fighters[foe].node=13;hp=g.fighters[foe].hp;g._v31.run({"kind":"v31_card","stage":"scheme"},ctx31(g,card(g,0,"horde_of_squirrels")));check(g.fighters[foe].hp==hp-2,"Horde bot prefers legal enemy over own fighter")
 print("V31_EDGE checks=%d failures=%d defense_cards=%d"%[checks,failures,card_runs]);quit(1 if failures else 0)
