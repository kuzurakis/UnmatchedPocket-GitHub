extends "res://tests/v38_cards_tests.gd"
func run():
 var g=fixture38("birds");check(g._living_heroes(0).size()==6 and g.fighters[0].hp==2,"six Birds with two health")
 for i in range(1,6):check(g.fighters.any(func(f):return int(f.owner)==0 and int(f.id)!=i and g.fighters_adjacent(i,int(f.id))),"connected flock setup")
 g=fixture38("moose");g.fighters[0].node=12;g.fighters[0].tail=11;var foe=g.hero_fighter(1);g.fighters[foe].node=10;check(g._in_range(0,foe)and g._v38.bonus(0,foe)==0,"Moose tail melee without head bonus");g.fighters[foe].node=13;check(g._v38.bonus(0,foe)==2,"Moose head bonus");g.fighters[foe].node=14;check(not g._in_range(0,foe),"Moose has no reach two");check(g._v19.paths(0,1).all(func(s):return int(s.head)!=11),"Moose cannot move head into old tail")
 g=fixture38("kraken");check(g._v19.large(0)and g._v38.own(0).size()==1,"Kraken starts with three reserve Tentacles");g.players[0].hand=[c38(g,0,1)];g.scheme(0,0);g=stable(g);check(g._v38.own(0).size()==2,"Lurking summons a Tentacle")
 var team=Model.new();team.interactive=false;team.setup(["kraken","moose","medusa","alice"],2,3839,"training",{"mode":"teams"});var ally=range(1,4).filter(func(p):return team.are_allies(0,p))[0];var enemy=range(1,4).filter(func(p):return team.is_enemy(0,p))[0];team.fighters[0].node=0;team.fighters[0].tail=1;team.fighters[team.hero_fighter(ally)].node=12;team.fighters[team.hero_fighter(enemy)].node=13;check(team._v38.friends_adj({"owner":0,"self":0,"opponent":team.hero_fighter(enemy)}).has(team.hero_fighter(ally)),"friendly fighter includes teammate in 2v2")
 var helper=1;foe=g.hero_fighter(1);g.fighters[helper].node=12;g.fighters[foe].node=13;g.fighters[0].node=0;g.fighters[0].tail=1;check(g._v38.in_range(0,foe),"Kraken attacks adjacent to distant Tentacle")
 for hero in ["kraken","godzilla"]:
  g=fixture38(hero);foe=g.hero_fighter(1);var defense=c38(g,0,2 if hero=="kraken"else 13);combat(g,foe,0,raw_card("attack",5),defense);g=stable(g);check(g.last_combat.damage==(3 if hero=="kraken"else 2),"damage halving rounding "+hero)
 g=fixture38("godzilla");var c=c38(g,0,8);g.players[0].hand=[c];g.scheme(0,0);g=stable(g);check(g._v38.charge(0).size()==1 and g._v38.charge(0)[0].boost==4,"scheme enters charge even on end turn");g.active=0;g.phase="action";g.actions_left=2;foe=adjacent(g);combat(g,0,foe,c38(g,0,1),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==4,"charge increases attack")
 g=fixture38("godzilla");g.players[1].discard=[raw_card("attack",2)];g.players[1].discard[0].boost=3;g._v38.add_charge(0,1,1);check(g.players[1].discard.is_empty()and g._v38.bonus(0,0)==3,"foreign card enters charge");g=clone(g);g._damage(0,1);check(g._v38.charge(0).is_empty()and g.players[1].discard.size()==1,"damage returns foreign charge to original owner")
 g=fixture38("birds");foe=g.hero_fighter(1);g.players[0].hand=[c38(g,0,9)];g.players[1].hand=[raw_card("attack",8)];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g=wait_choice(g,"v38_roost");check(g.pending_choice.ids.size()==6,"Roost offers any Bird");g=clone(g);g.choose_effect_option(1);g=stable(g);check(g.fighters[0].hp==2 and not g.fighters[1].alive,"Roost replaces lethal damage with chosen defeat")
 g=fixture38("moose");g.players[0].hand=[c38(g,0,1)];var head=g.fighters[0].node;var tail=g.fighters[0].tail;g._v38.start_turn();g=wait_choice(g,"v38_alert");g=clone(g);g.choose_effect_option(1);g=stable(g);check(g.fighters[0].node==tail and g.fighters[0].tail==head,"Always Alert swaps orientation")
 for mode in ["ffa","teams"]:
  g=Model.new();g.interactive=false;g.setup(NATURE,2,3838,"marmoreal",{"mode":mode});var steps=0
  while g.winner<0 and steps<4000:
   advance(g);steps+=1
   if steps%47==0:g=clone(g)
  check(g.winner>=0,"complete Nature match "+mode)
 print("V38_ABILITIES checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
