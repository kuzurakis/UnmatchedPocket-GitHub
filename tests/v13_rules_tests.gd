extends "res://tests/v12_engine_tests.gd"
const V13=["william_shakespeare","hamlet","titania","the_wayward_sisters"]
func game(ids: Array, manual=false, config={}):
	var g=super.game(ids,manual,config)
	# Unit fixtures start before a decision; full matches below use real setup.
	if ids[0]=="hamlet":
		g._flow.clear();g._effect_queue.clear();g.pending_choice.clear();g.phase="action";g.actions_left=2;g.players[0].question="be"
		for f in g.fighters:
			if f.owner==0: f.hp=f.max_hp
	return g
func validate(g):
	var occupied=[]
	for f in g.fighters:
		if not f.alive: continue
		check(int(f.hp)>0 and int(f.hp)<=int(f.max_hp),"living printed health")
		if f.get("offboard",false): continue
		check(not occupied.has(int(f.node)),"unique occupied spaces");occupied.append(int(f.node))
	if g._flow.is_empty() and g.pending_combat.is_empty():
		for p in g.players:
			check(p.hand.size()+p.deck.size()+p.discard.size()+p.get("line",[]).size()+p.get("cauldron",[]).size()==30,"cards conserved across all special piles")
			if p.hero_id=="titania":
				var ids=p.glamour_deck.duplicate();ids.append_array(p.glamour_discard)
				if not str(p.glamour).is_empty(): ids.append(p.glamour)
				check(ids.size()==6 and ids.all(func(id):return ids.count(id)==1),"six unique glamours conserved")
func test_question():
	var g=game(["hamlet","king_arthur"],true);var foe=adjacent(g)
	g._start_turn_ability();check(g.pending_choice.action=="v13_question","Question prompts at turn start")
	g=clone(g);g.choose_effect_option(0);g=stable(g);var deck=g.players[0].deck.size()
	g.begin_maneuver();check(g.players[0].deck.size()==deck-2,"TO BE mandatory maneuver draw is two");g.finish_maneuver()
	g._start_turn_ability();g.choose_effect_option(1);check(g.pending_choice.action=="v13_fighter","NOT TO BE chooses own damage recipient")
	g=clone(g);g.choose_effect_option(1);g=stable(g)
	check(g.players[0].question=="not_be" and g.fighters[1].hp==4 and g.fighters[0].hp==15,"sidekick may pay the two damage")
	combat(g,0,foe,raw_card("attack",3));g=stable(g);check(g.last_combat.attack_value==5,"Hamlet gains exactly two in NOT TO BE")
	g=game(["hamlet","king_arthur"],true);foe=adjacent(g,1);g.players[0].question="not_be"
	combat(g,1,foe,raw_card("attack",3));g=stable(g);check(g.last_combat.attack_value==3,"Question never boosts sidekick")
	for i in range(2):
		g._start_turn_ability();g=clone(g);g.choose_effect_option(1);g.choose_effect_option(0);g=stable(g)
	check(g.fighters[0].hp==11,"repeating NOT TO BE pays each time")
func test_glamours():
	var g=game(["titania","king_arthur"],true);var foe=adjacent(g)
	g.players[0].glamour="sleep";var hp=g.fighters[0].hp;var sh=g.fighters[1].hp
	g._damage(0,3);g._damage(1,2);g._damage_many([0,1],2)
	check(g.fighters[0].hp==hp and g.fighters[1].hp==sh,"Sleep prevents direct and area effect damage to both fighters")
	g.players[0].deck.clear();g._draw(0)
	check(g.fighters[0].hp==hp and g.fighters[1].hp==sh,"Sleep also prevents exhaustion damage")
	combat(g,foe,0,raw_card("attack",3));g=stable(g);check(g.fighters[0].hp==hp-3,"Sleep does not stop combat damage")
	g=game(["titania","king_arthur"],true);foe=adjacent(g)
	g.fighters[0].node=0;g.fighters[1].node=10;g.fighters[foe].node=1;g.fighters[foe+1].node=20
	g.players[0].glamour="greed";check(not g._reachable(0,2).has(2),"normal movement is blocked by enemy")
	g.players[0].glamour="invisibility";check(g._reachable(0,2).has(2) and not g._reachable(0,2).has(1),"Invisibility passes through, never ends on occupied enemy")
	g=game(["titania","king_arthur"],true);foe=adjacent(g);g.players[0].glamour="jealousy"
	g.players[0].hand=[card(g,0,"but_a_dream"),card(g,0,"fairy_song")];g.players[1].hand=[raw_card("attack",3)];g.active=1
	g.attack(foe,0,0);g.continue_attack()
	check(g.pending_choice.action=="v13_jealousy" and g.pending_combat.target==0,"Jealousy asks before defense card selection")
	g=clone(g);g.choose_effect_option(0)
	check(g.phase=="defend" and g.pending_combat.target==1 and g.fighters[1].node==12 and not g.legal_defenses().has(0) and g.legal_defenses().has(1),"swap changes defender and recalculates usable defenses")
	g.defend(1);g=stable(g)
	g=game(["titania","king_arthur"],true);foe=adjacent(g);g.players[0].glamour="love";g.begin_maneuver()
	check(g.phase=="effect_choice" and g.pending_choice.action=="v13_fighter","Love interrupts maneuver before own movement")
	g.choose_effect_option(0);check(g.phase=="effect_move" and g.pending_choice.spaces==1,"Love moves chosen enemy at most one")
	g=stable(g);check(g.phase=="move" and g.active==0,"Love resumes the same maneuver")
	g=game(["titania","king_arthur"],true);foe=adjacent(g);g.players[0].glamour="rhyme";g.players[0].hand=[card(g,0,"a_momentary_glance")];g.scheme(0,0);g.choose_effect_option(g.pending_choice.allowed_fighters.find(foe));g=stable(g)
	check(g.actions_left==2 and g.fighters[foe].hp==16,"Rhyme refunds scheme action after full effect")
	g=game(["titania","king_arthur"],true);g.players[0].glamour="greed";deck_case(g,false)
	g=game(["titania","king_arthur"],true);g.players[0].glamour="greed";deck_case(g,true)
	g=game(["titania","king_arthur"]);g.players[0].glamour="";g.players[0].glamour_deck=[];g.players[0].glamour_discard=["sleep"]
	g._start_turn_ability();check(g.players[0].glamour=="" and g.players[0].glamour_deck.is_empty(),"empty glamour deck does not reshuffle")
	g.players[0].glamour_deck=["love"];g._start_turn_ability();check(g.players[0].glamour=="love","next start flips top glamour")
	g._v13._discard_glamour(0);check(g.players[0].glamour=="","discard never flips immediately")
func deck_case(g, take: bool):
	var deck=g.players[0].deck.size();g.end_turn();check(g.pending_choice.action=="v13_greed","Greed offers optional end turn draw")
	g=clone(g);g.choose_effect_option(0 if take else 1);g=stable(g)
	check(g.players[0].deck.size()==deck-int(take) and g.active==1,"Greed draws at most once and finishes turn")
func test_sisters():
	var g=game(["the_wayward_sisters","king_arthur"],true);var foe=adjacent(g)
	check(g._living_heroes(0).size()==3,"three independent Sisters")
	g._discard(0,card(g,0,"ward"));g._discard_from_opponent(0,card(g,0,"hurly_burly"))
	check(g.players[0].discard.is_empty() and g.players[0].cauldron.size()==2,"all normal and opponent discards enter cauldron")
	g.players[0].cauldron=[card(g,0,"ward"),card(g,0,"hurly_burly")]
	combat(g,0,foe,card(g,0,"double_double"),raw_card("defense",8))
	for i in range(20):
		if g.phase=="effect_choice" and g.pending_choice.action=="v13_spell": break
		advance(g)
	check(g.pending_choice.action=="v13_spell" and g.pending_choice.ids.size()==4,"attack card supplies final ingredient before spell choice")
	g=clone(g);g.choose_effect_option(g.pending_choice.ids.find(3));g=stable(g)
	check(g.players[0].cauldron.is_empty() and g.players[0].discard.size()==3 and g.actions_left==2,"one spell gains action and discards entire cauldron including attack")
	g=game(["the_wayward_sisters","king_arthur"],true);foe=adjacent(g);g.players[0].cauldron=[card(g,0,"ward"),card(g,0,"hurly_burly")]
	combat(g,0,foe,card(g,0,"double_double"),raw_card("defense",8))
	for i in range(20):
		if g.phase=="effect_choice" and g.pending_choice.action=="v13_spell": break
		advance(g)
	check(g.skip_effect(),"casting after attack is optional");g=stable(g);check(g.players[0].cauldron.size()==3 and g.players[0].discard.is_empty(),"decline retains ingredients")
	g=game(["the_wayward_sisters","king_arthur"],true);foe=adjacent(g);g.players[0].cauldron=[card(g,0,"ward"),card(g,0,"hurly_burly")]
	combat(g,foe,0,raw_card("attack",1),card(g,0,"toil_and_trouble"));g=stable(g)
	check(g.players[0].cauldron.size()==3 and not g.logs.any(func(x):return str(x).begins_with("Заклинание сестёр")),"defense adds ingredient but never casts")
	g=game(["the_wayward_sisters","king_arthur"],true);g.players[0].hand=[card(g,0,"something_wicked_this_way_comes")]
	g.scheme(0,0);check(g.pending_choice.ids==[0,1,2,3],"scheme permits all spells with empty cauldron")
	g.choose_effect_option(3);check(g.pending_choice.ids==[0,1,2],"second spell must differ")
	g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.players[0].cauldron.size()==1 and g.players[0].cauldron[0].id=="something_wicked_this_way_comes","free spells retain cauldron; scheme itself enters it normally")
	g._damage(0,6);g._damage(1,6);check(g.players[0].alive and g._living_heroes(0).size()==1,"two defeated Sisters do not eliminate player")
func test_lines():
	for source in Model.new().heroes.william_shakespeare.cards:
		var g=game(["william_shakespeare","king_arthur"],true);var own=1 if source.fighter=="sidekick" else 0;var foe=adjacent(g,own)
		g.players[0].line=[card(g,0,"et_tu_brute")]
		if int(source.syllables)==2: g.players[0].line.append(card(g,0,"et_tu_brute"))
		elif int(source.syllables)==4: g.players[0].line.append(card(g,0,"alas"))
		g.fighters[0].hp=8
		if source.id=="once_more_unto_the_breach":
			for f in g.fighters:
				if f.owner==0 and not f.hero: f.alive=false;f.hp=0
		var before=g.players[0].deck.size();var ehp=g.fighters[foe].hp
		combat(g,own,foe,source.duplicate(true),raw_card("defense",10))
		if source.id=="again":
			for i in range(10):
				if g.pending_choice.get("action","")=="v13_again": break
				advance(g)
			g.choose_effect_option(1)
		g=stable(g)
		check(g.players[0].line.is_empty(),"exact ten completes and clears line "+str(source.id))
		match str(source.id):
			"horror": check(g.fighters[foe].hp==ehp-2,"Horror completion deals one per other card")
			"my_kingdom_for_a_horse": check(g.actions_left==3,"Horse completion gains two actions")
			"all_are_punished","such_sweet_sorrow","again": check(g.players[0].deck.size()==before-1,"completion draws one "+str(source.id))
			"places_places":
				for f in g.fighters:
					if f.owner==0 and not f.hero and f.alive: check(not g._same_zone(int(f.node),int(g.fighters[0].node)),"Places completion finds zone without Actors")
			"once_more_unto_the_breach": check(g.fighters.slice(1,4).all(func(f):return f.alive and f.hp==1 and g._same_zone(int(f.node),int(g.fighters[0].node))),"all three Actors restored in Shakespeare zone")
			"alas": check(g.players[0].deck.size()==before-2 and g.fighters[0].hp==11,"Alas ordinary loss heal plus completion draw and heal")
			"the_ides_of_march": check(g.fighters[foe].hp==ehp-2,"Ides completion deals two")
			"deceive": check(g.players[0].hand.any(func(c):return c.id=="deceive") and not g.players[0].discard.any(func(c):return c.id=="deceive"),"Deceive returns itself without later discard")
			"et_tu_brute": check(g.fighters.slice(0,4).all(func(f):return f.alive),"Brute completion places every own fighter")
			"revise": check(g.players[0].deck.size()==before-1 and g.fighters[foe].node!=13,"Revise completion also moves opposing fighter")
	var g=game(["william_shakespeare","king_arthur"],true);var foe=adjacent(g)
	g.players[0].line=[card(g,0,"my_kingdom_for_a_horse"),card(g,0,"et_tu_brute")];var before=g.actions_left
	combat(g,0,foe,card(g,0,"my_kingdom_for_a_horse"),raw_card("defense",10));g=stable(g)
	check(g.players[0].line.is_empty() and g.actions_left==before-1,"overshooting ten clears line without completion")
	g=game(["william_shakespeare","king_arthur"],true);foe=adjacent(g);g.players[0].line=[card(g,0,"et_tu_brute"),card(g,0,"et_tu_brute")]
	combat(g,0,foe,card(g,0,"deceive"),card(g,1,"feint"));g=stable(g)
	check(g.last_combat.attack_cancelled and g.players[0].hand.any(func(c):return c.id=="deceive"),"Feint cannot cancel ability's completion effect")
func run():
	test_question();test_glamours();test_sisters();test_lines()
	all_catalog_cards_v8()
	for level in range(3):
		for manual in [false,true]:
			for roster in [["william_shakespeare","titania"],["hamlet","the_wayward_sisters"],["the_wayward_sisters","titania"],V13,V13]:
				var g=Model.new();g.interactive=manual;g.setup(roster,level,1313+level,"globe_theatre",{"mode":"teams" if matches%2==1 and roster.size()==4 else "ffa"})
				if not manual:
					for p in g.players:p.bot=true
				var steps=0;var prior=failures
				while g.winner<0 and steps<3000 and failures==prior:
					advance(g);steps+=1
					if steps%19==0:g=clone(g)
					validate(g)
				check(g.winner>=0,"new hero match finishes "+str(roster)+" phase="+g.phase);matches+=1
	print("V13_RULES checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves])
	quit(1 if failures else 0)
