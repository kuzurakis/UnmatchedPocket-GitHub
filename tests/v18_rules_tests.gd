extends "res://tests/v17_rules_tests.gd"
const MARVEL=["daredevil","bullseye","elektra","luke_cage"]
func test_abilities18():
 for count in [0,2,3]:
  for defence in [false,true]:
   var g=game(["daredevil","king_arthur"],true);var foe=adjacent(g);var c=raw_card("defense" if defence else "attack",3)
   g.players[0].hand=[c]
   for i in range(count):g.players[0].hand.append(raw_card("scheme",0))
   g.players[0].deck=[raw_card("attack",1)];g.players[1].hand=[raw_card("attack" if defence else "defense",3)]
   if defence:g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0)
   else:g.attack(0,foe,0);g.continue_attack()
   g=stable(g);check((g.last_combat.defense_value if defence else g.last_combat.attack_value)==(5 if count<=2 else 3),"blind ability hand threshold both combat roles")
 var g=game(["daredevil","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[card(g,0,"man_without_fear")];g.players[0].deck=[raw_card("attack",1),raw_card("attack",1)];g.players[1].hand=[card(g,1,"feint")];g.attack(0,foe,0);g.continue_attack();g=stable(g);check(g.last_combat.attack_value==4 and g.last_combat.attack_cancelled,"Feint cancels card boost but not hero boost")
 for first in [0,1]:
  g=game(["daredevil","king_arthur"],true);foe=adjacent(g);g.players[0].hand=[card(g,0,"man_without_fear")];g.players[0].deck=[raw_card("attack",1),raw_card("attack",1)];g.players[1].hand=[raw_card("defense",20)];g.attack(0,foe,0);g.continue_attack();check(g.pending_choice.action=="v18_order","choose ability/card order");g=clone(g);g.choose_effect_option(first);g=stable(g);check(g.last_combat.attack_value==6 and g.players[0].deck.is_empty(),"two independent boosts in either order")
 g=game(["bullseye","king_arthur"]);foe=g.hero_fighter(1)
 for a in g.nodes:
  for b in g.nodes:
   if a.id==b.id:continue
   g.fighters[0].node=int(a.id);g.fighters[foe].node=int(b.id)
   check(g._in_range(0,foe)==(g._v14.board_distance(int(a.id),int(b.id))<=5 or g._same_zone(int(a.id),int(b.id))),"Bullseye range graph and zone union")
 for attack_value in [1,2,3,7]:
  for defender in [0,1]:
   g=game(["luke_cage","king_arthur"]);foe=adjacent(g,defender);var hp=g.fighters[defender].hp
   combat(g,foe,defender,raw_card("attack",attack_value));g=stable(g)
   check(g.last_combat.damage==maxi(0,attack_value-(2 if defender==0 else 0)),"Luke reduction excludes helper, works without defense")
 g=game(["luke_cage","king_arthur"]);g._damage(0,3);check(g.fighters[0].hp==10,"effect damage not reduced")
func test_resurrection18():
 for teams in [false,true]:
  var g=Model.new();g.interactive=true;g.setup(["elektra","daredevil","bullseye","luke_cage"] if teams else ["elektra","daredevil"],1,1818,"hells_kitchen",{"mode":"teams" if teams else "ffa"});g._damage(0,7)
  check(g.players[0].alive and g._v18.waiting(0) and not g._valid_fighter(0) and not g._check_winner(),"first defeat reserves resurrection even in teams")
  g=clone(g);g.active=0;g.phase="action";g._start_turn_ability();check(g.pending_choice.action=="v18_resurrect","resurrection asks placement")
  g=stable(g);check(g.fighters[0].hp==9 and g.fighters[0].alive and g._v18.resurrected(0),"resurrection at nine health")
  var living=[]
  for f in g.fighters:
   if int(f.owner)==0 and f.alive:living.append(f)
  check(living.size()==5,"all four Hand return")
  for f in living:
   for other in living:
    if f.id!=other.id:check(not g._same_zone(int(f.node),int(other.node)),"resurrected fighters in disjoint zones")
  g._damage(0,9);check(not g._v18.waiting(0) and not g.fighters[0].alive,"second defeat final")
func test_cards18():
 var g=game(["daredevil","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[card(g,0,"devil_of_hell_s_kitchen")];g.players[0].deck=[]
 for i in range(6):var c=raw_card("scheme",i);c.id="discard_"+str(i);g.players[0].discard.append(c)
 g.players[1].hand=[raw_card("defense",20)];g.attack(0,foe,0);g.continue_attack();g=stable(g);check(g.last_combat.attack_value==8 and g.players[0].deck.size()==5 and g.players[0].discard.size()==2,"Devil top four plus played card only, no double discard")
 for won in [false,true]:
  g=game(["bullseye","king_arthur"],true);foe=adjacent(g);g.players[0].won_combat_turn=won
  combat(g,0,foe,card(g,0,"i_m_better_and_ill_prove_it"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==(6 if won else 2),"Bullseye remembers earlier victory only")
 g=game(["bullseye","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"arrogant_but_effective"),raw_card("defense",20));g=stable(g);check(g.players[0].won_combat_turn,"Arrogant records victory despite no combat damage")
 for reborn in [false,true]:
  g=game(["elektra","king_arthur"],true);foe=adjacent(g);g.players[0].elektra_resurrected=reborn;var hp=g.fighters[0].hp;combat(g,0,foe,card(g,0,"mystic_assassin"),raw_card("defense",20));g=stable(g);check(g.fighters[0].hp==hp-(0 if reborn else 3),"Mystic alternative after resurrection")
  g=game(["elektra","king_arthur"],true);foe=adjacent(g);g.players[0].elektra_resurrected=reborn;g.players[0].hand=[card(g,0,"intercept"),card(g,0,"sai")];g.players[1].hand=[raw_card("attack",6)];g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g=stable(g);check(g.last_combat.defense_value==(5 if reborn else 3),"Intercept reveals retained Sai only resurrected")
  g=game(["elektra","king_arthur"],true);g.players[0].elektra_resurrected=reborn;g.players[0].hand=[card(g,0,"mesmerize")];var count=g.players[1].hand.size();g.scheme(0,0);check(g.pending_choice.get("kind","") in ["hand_view","cards"],"Mesmerize really displays hand");g=stable(g);check(g.players[1].hand.size()==count-int(reborn),"Mesmerize discards only resurrected")
 g=game(["luke_cage","king_arthur"],true);foe=adjacent(g);var hp=g.fighters[foe].hp;combat(g,foe,0,raw_card("attack",5),card(g,0,"skin_like_titanium"));g=stable(g);check(g.last_combat.damage==3 and g.fighters[foe].hp==hp-3,"Titanium reflects actual damage after reduction")
func test_routes18():
 var g=game(["daredevil","luke_cage"],true);g.fighters[0].node=0;g.fighters[1].node=1;g.fighters[2].node=2
 for n in g.nodes:n.move_neighbors=[]
 g.nodes[0].move_neighbors=[1];g.nodes[1].move_neighbors=[2];g.nodes[2].move_neighbors=[3]
 g.players[0].hand=[card(g,0,"through_adversity")];g.scheme(0,0)
 for n in [1,2,3]:g=clone(g);check(g.choose_effect_option(g.pending_choice.choices.map(func(v):return int(v)).find(n)),"choose route step")
 g.choose_effect_option(g.pending_choice.choices.map(func(v):return int(v)).find(-1));g=stable(g);check(g.fighters[0].node==3 and g.fighters[1].hp==12 and g.fighters[2].hp==5,"route damages every distinct traversed enemy")
func run():
 test_abilities18();test_resurrection18();test_cards18();test_routes18();all_catalog_cards_v8()
 for level in range(3):
  for roster in [["daredevil","elektra"],["bullseye","luke_cage","daredevil"],["elektra","bullseye","daredevil","luke_cage"]]:
   var g=Model.new();g.interactive=true;g.setup(roster,level,1818,"hells_kitchen",{"mode":"teams" if roster.size()==4 else "ffa"});var steps=0;var prior=failures
   while g.winner<0 and steps<3000 and failures==prior:
    advance(g);steps+=1
    if steps%17==0:g=clone(g)
    validate(g)
   check(g.winner>=0,"Marvel match completes");matches+=1
 print("V18_RULES checks=%d failures=%d matches=%d saves=%d" % [checks,failures,matches,saves]);quit(1 if failures else 0)
