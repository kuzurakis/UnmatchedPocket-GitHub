extends "res://tests/v36_villains_tests.gd"
func fixture36(hid: String,manual=true,enemy="king_arthur"):
 var g=game([hid,enemy],manual);g=stable(g);adjacent(g);return g
func c36(g,p: int,n: int):return card(g,p,"tmntv_"+str(n))
func run():
 test_foot();test_krang();test_svyatogor()
 print("V36_EDGES checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
func test_foot():
 var g=fixture36("shredder");check(g._v36.feet(0).size()==1,"mandatory start deployment")
 g.players[0].foot=[[13,14],[8,13]];var foe=g.hero_fighter(1);g.fighters[0].node=0;g.fighters[1].node=1;g.fighters[foe].node=13;g.players[0].hand=[c36(g,0,486)]
 check(g.legal_targets(0,0).has(foe),"remote Foot attack by Shredder");g.players[0].hand=[raw_card("attack",1)];check(g.legal_targets(1,0).has(foe),"remote Foot attack by helper")
 combat(g,0,foe,c36(g,0,486),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==5,"Long Shot remote becomes five")
 g=fixture36("shredder");foe=g.hero_fighter(1);g.players[0].foot=[[12,13],[8,13]];combat(g,1,foe,c36(g,0,765),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==6,"two soldiers activate Gang Up")
 g=fixture36("shredder");g.players[0].foot=[[12,13],[11,12],[7,12]];var ctx={"owner":0,"self":0,"opponent":g.hero_fighter(1),"opponent_owner":1,"card":c36(g,0,772)};var actions=g.actions_left;g._v36.run({"kind":"v36_card","number":772},ctx);check(g.actions_left==actions+3,"Obedient Subjects gains per adjacent Foot")
 g=fixture36("shredder");g.fighters[1].hp=0;g.fighters[1].alive=false;g.players[0].hand=[c36(g,0,766)];check(g.scheme(0,0),"revival scheme starts");g=stable(g);check(g.fighters[1].alive and g.fighters[1].hp==3 and g.fighters_distance(0,1)<=1,"revive and nearest placement")
 for remove in [false,true]:
  g=fixture36("shredder",true,"alice");g.players[0].foot=[[12,13]];g.active=1;g.players[1].bot=false;g.actions_left=2;var mover=g.hero_fighter(1);g.fighters[mover].node=13;g.fighters[0].node=23;g.players[1].hand=[raw_card("attack",2)];check(g.begin_maneuver(0),"boosted maneuver");check(g.move_fighter(mover,12),"cross actual Foot edge");g.finish_maneuver();check(g.pending_choice.action=="v36_remove","optional removal is visible");g=clone(g);g.choose_effect_option(0 if remove else 1);g=stable(g);check(g._v36.feet(0).size()==(0 if remove else 1),"remove or preserve crossed soldier");g.finish_maneuver()
 g=fixture36("shredder",false,"alice");g.players[0].foot=[[12,13]];g.active=1;g.phase="move";g.maneuver_boosted=false;g._enter_node(g.hero_fighter(1),12);check(g.players[1].get("foot_crossed",[]).is_empty(),"unboosted maneuver cannot remove")
 g.maneuver_boosted=true;g.phase="effects";g._enter_node(g.hero_fighter(1),13);check(g.players[1].get("foot_crossed",[]).is_empty(),"effect movement cannot remove")
 g=fixture36("houdini",true,"shredder");g.players[1].foot=[[12,13]];g.maneuver_boosted=true;g.phase="move";g._v36.crossed(0,12,13,[12]);check(g.players[0].get("foot_crossed",[]).is_empty(),"Houdini placement never counts as crossing a path")
 g=fixture36("svyatogor",true,"shredder");g.players[1].foot=[[11,6],[12,6]];g.maneuver_boosted=true;g.phase="move";g.fighters[0].node=6;g.fighters[0].tail=11;g.nodes[12].neighbors.append(6);g._v36.crossed(0,12,6,[12,11]);check(g.players[0].foot_crossed.size()==1 and g.players[0].foot_crossed[0].edge==[11,6],"large fighter crosses the chosen base end on a triangle")
 g=fixture36("shredder");g.players[0].foot=g._v36.edges(0,true).slice(0,10);foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",10),c36(g,0,769));g=stable(g);check(g.last_combat.damage==0,"ten soldiers ignore opposing value")
 g=fixture36("shredder");foe=g.hero_fighter(1);var opposing=raw_card("attack",3);opposing.effects=[{"kind":"add_value","amount":8,"timing":"during"}];combat(g,foe,0,opposing,c36(g,0,771));g=stable(g);check(g.last_combat.attack_value==3,"Disrupting Strike locks printed value")
 g=fixture36("shredder");foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",4),c36(g,0,770));g=stable(g);check(g.actions_left==2,"All According to Plan grants attacker action");check(g.players[1].plan_penalty==2,"end-turn penalty registered")
 g.players[1].hand=[raw_card("attack",2),raw_card("attack",2),raw_card("attack",2)];g.end_turn();g=stable(g);check(g.players[1].hand.size()==1,"Plan exact forced discard at end")
 g=fixture36("shredder");g.active=1;g.actions_left=2;g.players[1].plan_penalty=2;g.players[1].plan_owner=0;g.players[1].hand=[]
 for i in range(9):g.players[1].hand.append(raw_card("attack",2))
 g.end_turn();g=stable(g);check(g.players[1].hand.size()==7,"Plan resolves before hand-limit discard")
 g=fixture36("shredder");g.players[0].plan_penalty=2;g.players[0].scheme_turn=g.turn_number;g.players[0].hand=[raw_card("attack",2)];g.end_turn();g=stable(g);check(g.players[0].hand.size()==1,"scheme played prevents penalty")
func test_krang():
 var g=fixture36("krang");check(g._v36.machines(0)==1 and g._movement(0)==2,"Krang one machine and move two")
 for i in range(5):g._v36.activate(0)
 check(g._v36.machines(0)==3 and g._movement(0)==4,"three-machine cap")
 g.players[0].hand=[c36(g,0,754)];check(g.scheme(0,0),"IQ scheme");check(g.pending_choice.action=="v36_die"and g._v36.machines(0)==3,"IQ activates before draw roll");g=clone(g);g.choose_effect_option(1);check(g._v36.machines(0)==2 and g.pending_choice.action=="v36_die","one reroll costs one machine");g=clone(g);g.choose_effect_option(0);check(g.pending_choice.action=="v36_die"and g.pending_choice.mode=="heal","heal has separate roll");g=stable(g)
 g=fixture36("krang");g.players[0].hand=[c36(g,0,754)];check(g.begin_maneuver(0),"dice BOOST maneuver starts after draw");check(g.pending_choice.action=="v36_die","variable BOOST roll visible");g=clone(g);g.choose_effect_option(1);check(g._v36.machines(0)==0,"BOOST reroll can spend machine");check(g.phase=="move"and g.maneuver_boosted,"BOOST returns to maneuver");check(g.maneuver_distance==1+g._maneuver_boost,"machine cost updates same maneuver budget");check(g.players[0].discard[-1].boost==0,"dice BOOST printed value restored in discard")
 g=fixture36("krang");var foe=g.hero_fighter(1);g.fighters[0].node=0;g.fighters[foe].node=2;g.nodes[0].zones=[0];g.nodes[2].zones=[0];g.players[0].hand=[c36(g,0,759)];check(g.legal_targets(0,0).has(foe),"Missiles ranged target legal");g.attack(0,foe,0);check(g.pending_combat.face_up,"Missiles attack revealed")
 g=fixture36("krang");foe=g.hero_fighter(1);var hp=g.fighters[foe].hp;g.players[0].machines=0;var ctx={"owner":0,"self":0,"opponent":foe,"opponent_owner":1,"card":c36(g,0,758)};g._flow={"kind":"ability","stage":"effects","completion":"action","effect_logs":[]};g.combat_report={};g.fighters[0].node=12;g.fighters[foe].node=13;g._v36.wings_finish(ctx,[13,14]);check(g.fighters[0].node==14 and g.fighters[foe].hp==hp-1,"Wings damages traversed enemy and ends free")
 g=fixture36("krang");foe=g.hero_fighter(1);g.players[0].machines=0;g.fighters[0].node=12;g.fighters[foe].node=13;combat(g,0,foe,c36(g,0,755),raw_card("defense",20));g=wait_choice(g,"v36_portal_fighter");g=clone(g);g.choose_effect_option(1);g=stable(g);check(g.fighters[foe].locked_until==g.turn_number,"Portal locks selected combatant")
 g=fixture36("krang");foe=g.hero_fighter(1);combat(g,foe,0,raw_card("attack",7),c36(g,0,757));g=stable(g);check(g.last_combat.attack_value==3 and g.active==0,"Minimizer reduces attack and ends enemy turn")
func test_svyatogor():
 var g=fixture36("svyatogor");check(g.heroes.svyatogor.move==1 and g._movement(0)==1 and g.fighters[0].max_hp==28,"revised stats")
 for missing in [0,5,6,11,12,23,24,27]:
  g=fixture36("svyatogor");var foe=g.hero_fighter(1);g.fighters[0].hp=28-missing;combat(g,0,foe,card(g,0,"svyatogor_13"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==3+int(missing/6),"Last Breath threshold "+str(missing))
 for defense in [1,2,3]:
  g=fixture36("svyatogor");var foe=g.hero_fighter(1);combat(g,0,foe,card(g,0,"svyatogor_02"),raw_card("defense",defense));g=stable(g);check(g.last_combat.attack_value==(5 if defense<=2 else 3),"Above Forest threshold "+str(defense))
 g=fixture36("svyatogor");var foe=g.hero_fighter(1);var hp=g.fighters[0].hp;combat(g,0,foe,card(g,0,"svyatogor_01"),raw_card("defense",20));g=stable(g);check(g.fighters[0].hp==hp-2,"Giant Strength pays two after combat")
 g=fixture36("svyatogor");foe=g.hero_fighter(1);hp=g.fighters[0].hp;combat(g,foe,0,raw_card("attack",2),card(g,0,"svyatogor_12"));g=stable(g);check(g.last_combat.defense_value==6 and g.fighters[0].hp==hp-2,"Stone Coffin six and self damage")
 g=fixture36("svyatogor");foe=g.hero_fighter(1);g.fighters[0].node=12;g.fighters[0].tail=11;g.fighters[foe].node=13;var helper=g.fighters.filter(func(f):return int(f.owner)==1 and not f.hero)[0];helper.node=7;helper.hp=4;hp=helper.hp;g._v26.extras({"kind":"v26_stomp"},{"self":0});check(helper.hp==hp-1,"Stomp also affects adjacent helpers")
