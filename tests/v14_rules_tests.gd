extends "res://tests/v13_rules_tests.gd"
const V14=["geralt_of_rivia","ciri","ancient_leshen"]
func validate(g):
	var occupied=[]
	for f in g.fighters:
		if not f.alive:continue
		check(f.hp>0 and f.hp<=f.max_hp,"living health within printed bounds")
		if f.get("offboard",false):continue
		check(not occupied.has(f.node),"unique occupied spaces");occupied.append(f.node)
	if g._flow.is_empty() and g.pending_combat.is_empty():
		for p in g.players:
			check(p.hand.size()+p.deck.size()+p.discard.size()+p.get("line",[]).size()+p.get("cauldron",[]).size()+int(not p.get("ongoing",{}).is_empty())==(22 if p.hero_id=="daredevil" else 20 if p.hero_id=="elektra" else 30),"printed deck size conserved including ongoing scheme")
func fill_source(g, n: int, played=""):
	var pool=[];var removed=false
	for c in g.heroes.ciri.cards:
		if not c.get("source",false):continue
		for i in range(int(c.count)):
			if not removed and str(c.id)==played:removed=true;continue
			pool.append(c.duplicate(true))
	g.players[0].discard=pool.slice(0,n)
func stop_at(g, action: String):
	for i in range(35):
		if str(g.pending_choice.get("action",""))==action:return g
		advance(g)
	check(false,"expected decision "+action);return g
func test_gear():
	for sword in ["steel","silver"]:
		for armor in ["medallion","forgotten"]:
			for potion in ["blizzard","owl"]:
				var selected={"sword":sword,"armor":armor,"potion":potion};var g=game(["geralt_of_rivia","ciri"],true,{"geralt_gear":selected})
				var pile=g.players[0].hand+g.players[0].deck;var groups={"sword":0,"armor":0,"potion":0}
				for c in pile:
					if c.has("gear_slot"):check(c.gear_option==selected[c.gear_slot],"unselected gear excluded");groups[c.gear_slot]+=1
				check(pile.size()==30 and groups=={"sword":2,"armor":2,"potion":2},"each gear configuration has exactly 30 cards")
				g=clone(g);check(g.players[0].gear==selected,"gear selection persists through JSON")
	var g=game(["geralt_of_rivia","king_arthur"],true,{"geralt_gear":{"sword":"steel","armor":"medallion","potion":"owl"}})
	g.players[0].hand=[card(g,0,"witcher_senses")];var before=g.players[0].deck.size();var count=g.players[0].deck.filter(func(c):return c.id=="witcher_senses").size()
	g.scheme(0,0);check(g.pending_choice.action=="v14_senses","Senses offers all available gear");g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.players[0].hand.size()==1 and g.players[0].hand[0].has("gear_slot") and g.players[0].deck.size()==before and g.players[0].deck.filter(func(c):return c.id=="witcher_senses").size()==count+1,"deck search reveals gear and shuffles played Senses into deck")
	g=game(["geralt_of_rivia","king_arthur"],true);g.players[0].deck=[];g.players[0].discard=[card(g,0,"gear_sword_of_steel")];g.players[0].hand=[card(g,0,"witcher_senses")]
	g.scheme(0,0);g.choose_effect_option(0);g=stable(g)
	check(g.players[0].hand[0].id=="gear_sword_of_steel" and g.players[0].discard.size()==1 and g.players[0].discard[0].id=="witcher_senses","discard search does not shuffle Senses into deck")
func test_ongoing():
	var g=game(["geralt_of_rivia","bloody_mary"],true);g.players[0].ongoing=card(g,0,"gear_blizzard");g.active=1;g.players[1].hand=[raw_card("attack",2),raw_card("attack",2),raw_card("attack",2)];g._start_turn_ability()
	check(g.actions_left==2,"Blizzard blocks Bloody Mary's hero ability")
	check(not g.gain_actions(1,2) and g.actions_left==2,"Blizzard blocks generic multiple bonus actions")
	direct(g,[{"kind":"gain_action","amount":1}],{},1,0);g=stable(g);check(g.actions_left==2,"Blizzard also blocks queued card bonus")
	g.active=0;g.phase="action";g.end_turn();g=stable(g);check(g.players[0].ongoing.is_empty(),"Blizzard discarded at own end if no attack")
	g=game(["geralt_of_rivia","king_arthur"],true);g.players[0].ongoing=card(g,0,"gear_blizzard");g._v14.attack_started(1);g.end_turn();g=stable(g)
	check(g._v14.ongoing(0)=="gear_blizzard","Dandelion attack also sustains potion")
	g=Model.new();g.setup(["geralt_of_rivia","king_arthur","alice","sinbad"],1,1414,"fayrlund_forest",{"mode":"teams"});g.players[0].ongoing=card(g,0,"gear_blizzard");g.active=2
	check(g.gain_actions(2,1),"Blizzard does not block allied player");g.active=1;check(not g.gain_actions(1,1),"Blizzard blocks opposing team")
	g=game(["geralt_of_rivia","king_arthur"],true);g.players[0].ongoing=card(g,0,"gear_blizzard");g.players[0].hand=[card(g,0,"gear_tawny_owl")];g.scheme(0,0);g=stable(g)
	check(g._v14.ongoing(0)=="gear_tawny_owl" and g.players[0].discard.any(func(c):return c.id=="gear_blizzard") and not g.players[0].discard.any(func(c):return c.id=="gear_tawny_owl"),"new ongoing replaces old and stays outside discard")
	g=game(["ciri","king_arthur"],true);var foe=adjacent(g);g.players[0].ongoing=card(g,0,"unicorn_ally");var deck=g.players[0].deck.size()
	combat(g,0,foe,raw_card("attack",1),raw_card("defense",3));g=stable(g);check(g.players[0].deck.size()==deck-1,"Unicorn Ally draws after attack even on loss")
	deck=g.players[0].deck.size();combat(g,foe,0,raw_card("attack",1),raw_card("defense",3));g=stable(g);check(g.players[0].deck.size()==deck-1,"Unicorn Ally also draws after defense")
	g.active=0;g.phase="action";g.players[0].hand=[]
	for i in range(5):g.players[0].hand.append(raw_card("attack",2))
	g.end_turn();g=stable(g);check(g.players[0].ongoing.is_empty(),"Unicorn Ally checks five-card condition at own end")
	g=game(["ancient_leshen","king_arthur"],true);g.players[0].ongoing=card(g,0,"strength_of_the_pack");g.fighters[0].hp=8;g._start_turn_ability();g=stable(g)
	check(g.fighters[0].hp==9,"Pack heals one at start")
	g.fighters[0].node=0;g.fighters[1].node=24;g.fighters[2].node=23;g.end_turn();g=stable(g)
	check(g.players[0].ongoing.is_empty(),"Pack discards when no Wolves share Leshen zone at end")
func test_owl():
	var g=game(["geralt_of_rivia","king_arthur"],true);g.players[0].ongoing=card(g,0,"gear_tawny_owl");var hand=g.players[0].hand.size()
	g._force_discard(0,2,true);check(g.players[0].hand.size()==hand,"Owl prevents forced random hand discard")
	g.players[0].owl_ignore=false;g._force_discard(0,1,false);check(g.players[0].hand.size()==hand-1,"player may allow discard with Owl")
	g.players[0].owl_ignore=true;g.players[0].hand=[raw_card("attack",2)];g.begin_maneuver(0)
	check(g.players[0].discard.any(func(c):return c.id=="probe"),"Owl never refunds maneuver boost cost");g.finish_maneuver()
	g.players[0].hand=[]
	for i in range(8):g.players[0].hand.append(raw_card("attack",2))
	g.players[0].attacked_turn=g.turn_number;g.phase="action";g.end_turn();check(g.phase=="discard","Owl does not bypass hand limit");g.discard_card(0);check(g.players[0].hand.size()==7,"end-turn discard really removes a card")
	g=game(["geralt_of_rivia","robin_hood"],true);var foe=adjacent(g);g.players[0].ongoing=card(g,0,"gear_tawny_owl");g.players[0].hand=[card(g,0,"damn_youre_ugly"),raw_card("scheme",0)];g.players[1].hand=[card(g,1,"ambush")];g.active=1
	var base=int(g.players[1].hand[0].value);g.attack(foe,0,0);g.continue_attack();g.defend(0);g=stable(g)
	check(g.players[0].hand.size()==1 and g.last_combat.attack_value==base,"Owl prevents Ambush discard and its discarded-card bonus")
	g=game(["geralt_of_rivia","sherlock_holmes"],true);g.players[0].ongoing=card(g,0,"gear_tawny_owl");var held=raw_card("versatile",3);held.boost=4;g.players[0].hand=[held];var hp=g.fighters[0].hp
	g._flow={"kind":"ability","completion":"start_turn","effect_logs":[]};g.combat_report={"kind":"ability"};g._v6._suspicion({"owner":1,"self":g.hero_fighter(1),"opponent":0,"opponent_owner":0,"card":card(g,1,"confirm_suspicion")},3)
	g.choose_effect_option(0);g=stable(g);check(g.players[0].hand.size()==1 and g.fighters[0].hp==hp,"matching Suspicion card is revealed but not discarded and deals no BOOST damage")
func test_source_tiers():
	for n in range(11):
		var g=game(["ciri","king_arthur"],true);var foe=adjacent(g);fill_source(g,n,"lion_cub_of_cintra")
		combat(g,0,foe,card(g,0,"lion_cub_of_cintra"),raw_card("defense",3));g=stable(g)
		check(g.last_combat.attack_value==(7 if n>=5 else 4 if n>=1 else 2),"Lion highest attained tier n="+str(n))
		g=game(["ciri","king_arthur"],true);foe=adjacent(g);fill_source(g,n,"pushed_to_the_brink");var hp=g.fighters[foe].hp
		combat(g,0,foe,card(g,0,"pushed_to_the_brink"),raw_card("defense",5));g=stable(g)
		check(g.fighters[foe].hp==hp-(2 if n>=7 else 1 if n>=2 else 0),"Brink chooses correct damage branch n="+str(n))
		g=game(["ciri","king_arthur"],true);foe=adjacent(g);fill_source(g,n,"the_lady_of_space_and_time");var before=g.players[0].deck.size()
		combat(g,0,foe,card(g,0,"the_lady_of_space_and_time"),raw_card("defense",5));g=stable(g)
		check(g.players[0].hand.size()==(2 if n>=8 else 0) and g.players[0].deck.size()==before+(-1 if n>=8 else 1 if n>=3 else 0),"Lady mandates highest tier n="+str(n))
		g=game(["ciri","king_arthur"],true);foe=adjacent(g);fill_source(g,n,"zireael");g.players[0].hand=[card(g,0,"zireael")];g.players[1].hand=[raw_card("defense",5),raw_card("scheme",0)]
		g.attack(0,foe,0);g.continue_attack();g=stable(g)
		check(g.last_combat.attack_value==(4 if n>=3 else 2) and g.players[1].hand.size()==(0 if n>=5 else 1),"Zireael random discard only at high tier n="+str(n))
		g=game(["ciri","king_arthur"],true);foe=adjacent(g);fill_source(g,n,"child_of_the_elder_blood");g.players[0].hand=[card(g,0,"child_of_the_elder_blood")];hp=g.fighters[foe].hp;var helper=g.fighters[1].hp
		g.scheme(0,0);g=stable(g);var amount=3 if n>=9 else 1 if n>=4 else 0
		check(g.fighters[foe].hp==hp-amount and g.fighters[1].hp==helper-amount,"Elder Blood hits enemies and own helper n="+str(n))
	for n in [6,7]:
		var g=game(["ciri","king_arthur"],true);var foe=adjacent(g);fill_source(g,n,"lion_cub_of_cintra")
		combat(g,0,foe,card(g,0,"lion_cub_of_cintra"),card(g,1,"feint"));g=stable(g)
		check(g.last_combat.attack_cancelled==(n==6) and g.last_combat.attack_value==(2 if n==6 else 7),"seven Source cards prevent cancellation")
	var g=game(["ciri","king_arthur"],true);var foe=adjacent(g);fill_source(g,5);g.players[0].hand=[card(g,0,"channel_the_source"),card(g,0,"lion_cub_of_cintra"),card(g,0,"zireael")]
	g.attack(0,foe,0);g.continue_attack();check(g.pending_choice.action=="v14_channel","Channel offers only Source cards")
	g=clone(g);g.choose_effect_option(0);g=clone(g);g.choose_effect_option(0);g=stable(g)
	check(g.last_combat.attack_value==6 and g._v14.source_count(0)==7,"Channel pays each Source and immediately updates counter")
func test_leshen():
	var g=game(["ancient_leshen","king_arthur"],true);var foe=adjacent(g);g.actions_left=5
	combat(g,0,foe,raw_card("attack",1),raw_card("defense",10));g=stable(g);check(g.last_combat.attack_value==1,"first Leshen attack has no bonus")
	g.fighters[1].node=12;g.fighters[0].node=11;combat(g,1,foe,raw_card("attack",1),raw_card("defense",10));g=stable(g);check(g.last_combat.attack_value==1,"Wolf never receives Leshen bonus")
	g.fighters[0].node=12;g.fighters[1].node=11;combat(g,0,foe,raw_card("attack",1),raw_card("defense",10));g=stable(g);check(g.last_combat.attack_value==4,"second hero attack adds three even with intervening Wolf attack")
	g=game(["ancient_leshen","king_arthur"],true);g.fighters[0].node=0;g.fighters[1].node=10;g.fighters[2].node=20;g.fighters[3].node=4;g.fighters[4].node=24;g.players[0].hand=[raw_card("attack",2)]
	g.begin_maneuver(0);var a=g.legal_moves(0);var b=g.legal_moves(1);a.sort();b.sort();var ea=g._reachable(0,3);var eb=g._reachable(1,5);ea.sort();eb.sort()
	check(a==ea and b==eb,"same BOOST adds to hero move 1 and Wolf move 3 separately")
	g=game(["ancient_leshen","king_arthur"],true);foe=adjacent(g);g.fighters[0].node=0;g.fighters[1].node=10;var before=g.players[0].deck.size();g._enter_node(0,1);g._enter_node(0,0)
	direct(g,[{"kind":"v14_planted"}],card(g,0,"planted_feet"));g=stable(g);check(g.players[0].deck.size()==before,"Planted Feet detects leaving and returning to same space")
	g=game(["ancient_leshen","king_arthur"],true);g.fighters[1].alive=false;g.fighters[1].hp=0;direct(g,[{"kind":"v14_summon_wolf"}],card(g,0,"strength_of_the_pack"))
	check(g.pending_choice.ids==[1],"summon must prefer off-board Wolf");g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.fighters[1].alive and g.fighters[1].hp==1,"summon restores Wolf")
	direct(g,[{"kind":"v14_summon_wolf"}],card(g,0,"strength_of_the_pack"));check(g.pending_choice.ids==[1,2],"when both Wolves live player chooses which to relocate");g.choose_effect_option(1);g=stable(g)
	for living_wolves in [false,true]:
		g=game(["ancient_leshen","king_arthur"],true);foe=adjacent(g)
		if not living_wolves:
			for f in g.fighters:
				if f.owner==0 and not f.hero:f.alive=false;f.hp=0
		g.players[0].hand=[card(g,0,"vanish_into_murder")];before=g.players[0].deck.size();g.scheme(0,0);g=stable(g)
		check(g.fighters[0].get("offboard",false) and g.players[0].deck.size()==before-int(living_wolves),"Vanish draw only when not dormant")
		check(g.active==(0 if living_wolves else 1),"dormant Leshen ends turn immediately")
		if living_wolves:g.end_turn();g=stable(g)
		g.end_turn();g=clone(g);g=stable(g)
		check(not g.fighters[0].get("offboard",false) and g.active==0 and g._valid_fighter(0),"Leshen returns in chosen space next turn")
func test_unicorn_route_and_maps():
	var g=game(["ciri","king_arthur"],true);g.fighters[0].node=20;g.fighters[1].node=0;g.fighters[2].node=1;g.fighters[3].node=2
	combat(g,1,2,card(g,0,"bane_of_the_aen_elle"),raw_card("defense",8));g=stop_at(g,"v14_path")
	for node in [1,2,3]:g=clone(g);g.choose_effect_option(g.pending_choice.choices.find(node))
	g.choose_effect_option(g.pending_choice.choices.find(-1));check(g.pending_choice.ids==[2,3] and g.fighters[1].node==3,"route records both passed enemies but requires one damage target")
	var hp=g.fighters[2].hp;var other=g.fighters[3].hp;g.choose_effect_option(0);g=stable(g)
	check(g.fighters[2].hp==hp-1 and g.fighters[3].hp==other,"unicorn damages exactly selected passed enemy")
	g=Model.new();g.setup(["geralt_of_rivia","king_arthur"],1,1414,"kaer_morhen")
	check(g.board_data.directed_edges.size()==13 and g.nodes.size()==32,"Kaer Morhen has thirteen directed movement edges")
	for edge in g.board_data.directed_edges:
		var a=int(edge.from);var b=int(edge.to)
		for f in g.fighters:f.node=31-int(f.id)
		if g._occupant(a)>=0 or g._occupant(b)>=0:
			for f in g.fighters:
				if f.node in [a,b]:f.node=14+int(f.id)
		g.fighters[0].node=a
		check(g._reachable(0,1).has(b),"arrow permits forward move")
		g.fighters[0].node=b;check(not g._reachable(0,1).has(a),"arrow forbids reverse move")
		g.fighters[2].node=a;check(g._in_range(0,2),"reverse arrow still permits melee attack")
		check(g._v14.board_distance(a,b)==1 and g._v14.board_distance(b,a)==1,"Source range uses undirected adjacency")
func run():
	test_gear();test_ongoing();test_owl();test_source_tiers();test_leshen();test_unicorn_route_and_maps()
	all_catalog_cards_v8()
	for level in range(3):
		for manual in [false,true]:
			for roster in [["geralt_of_rivia","ancient_leshen"],["ciri","geralt_of_rivia"],V14,["geralt_of_rivia","ciri","ancient_leshen","genie"]]:
				var g=Model.new();g.interactive=manual;g.setup(roster,level,1414+level,"kaer_morhen" if matches%2==0 else "fayrlund_forest",{"mode":"teams" if roster.size()==4 else "ffa"})
				if not manual:
					for p in g.players:p.bot=true
				var steps=0;var prior=failures
				while g.winner<0 and steps<3000 and failures==prior:
					advance(g);steps+=1
					if steps%17==0:g=clone(g)
					validate(g)
				check(g.winner>=0,"Witcher match finishes "+str(roster)+" phase="+g.phase);matches+=1
	print("V14_RULES checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves]);quit(1 if failures else 0)
