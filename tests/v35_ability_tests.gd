extends "res://tests/v35_hellboy_tests.gd"
func fixture(hid: String,manual=true):
 var g=game([hid,"king_arthur"],manual);g=stable(g);adjacent(g);return g
func run():
 var g=fixture("hellboy");var foe=g.hero_fighter(1);var d=card(g,0,"hb_855")
 g.players[0].discard=[]
 for i in range(6):g.players[0].discard.append(d.duplicate(true))
 check(g._v35.anung(0)and g._v35.attack_bonus(0)==2,"six destiny cards activate Anung")
 combat(g,0,foe,card(g,0,"hb_86"),raw_card("defense",20));g=stable(g);check(g.last_combat.attack_value==8,"Anung adds two to Hellboy attack")
 g.players[0].discard.resize(5);check(not g._v35.anung(0),"five destiny cards restore Occult")
 g=fixture("hellboy");g.fighters[0].node=int(g.players[1].starting_space);var size=g.players[0].hand.size();g._v35.start_turn();g=stable(g);check(g.players[0].hand.size()==size+2,"Occult draws two at enemy starting space")
 g=fixture("abe_sapien");foe=g.hero_fighter(1);combat(g,0,foe,raw_card("attack",2),raw_card("defense",0));g=stable(g);check(g.players[0].intuition==1,"adjacent combat damage activates intuition")
 g=clone(g);g.active=1;g.actions_left=2;g.players[1].hand=[raw_card("attack",2)];g.players[0].hand=[raw_card("defense",1)];g.attack(foe,0,0);check(g.pending_combat.face_up and g.players[0].hand.size()==2 and g.players[0].intuition==0,"intuition draws and exposes attack before defense")
 g=fixture("liz_sherman");var fire=card(g,0,"hb_859");g.players[0].hand=[];g._discard(0,fire,"deck");check(g.players[0].hand.size()==1,"burning deck discard returns to hand");g.players[0].hand=[];g._discard(0,fire,"played");check(g.players[0].hand.is_empty()and g.players[0].discard[-1].id==fire.id,"played burning card goes to discard");g._discard(0,fire,"limit");check(g.players[0].hand.is_empty(),"hand-limit discard does not return burning card")
 g=fixture("baba_yaga");g.fighters[0].node=12;g.fighters[1].node=13;var hp=g.fighters[0].hp;g._damage(0,2);g._v9.flush_damage();g=stable(g);check(g.fighters[0].hp==hp and g.fighters[1].hp==1,"effect damage can transfer whole packet to Koschei")
 g=fixture("baba_yaga");g.players[0].ongoing=card(g,0,"hb_841");g.fighters[0].node=12;g.fighters[1].node=13;hp=g.fighters[0].hp;g._damage(0,2);g._v9.flush_damage();g=stable(g);check(g.fighters[0].hp==hp and not g.fighters[1].alive,"Mortality adds one once before redirect")
 g=fixture("baba_yaga");g.players[0].ongoing=card(g,0,"hb_844");check(not g.gain_actions(0,1),"Pact of Time blocks action gains");g._v34.grant_free(0);check(not g._v34.has_free(0),"Pact of Time also blocks free attacks");g.players[0].ongoing=card(g,0,"hb_843");check(g._v33.limit(1)==3,"Pact of Secrecy affects opponents' hand limit")
 for hid in HELLBOY:
  for level in range(3):
   g=Model.new();g.interactive=true;g.setup([hid]+HELLBOY.filter(func(x):return x!=hid),level,3500+level,"bprd_hq"if level!=2 else"pandemonium",{"mode":"teams"if level==2 else"ffa"});var steps=0
   while g.winner<0 and steps<5500:
    advance(g);steps+=1
    if steps%31==0:g=clone(g)
   check(g.winner>=0,"complete Hellboy match "+hid+str(level));matches+=1
 print("V35_ABILITIES checks=%d failures=%d matches=%d"%[checks,failures,matches]);quit(1 if failures else 0)
