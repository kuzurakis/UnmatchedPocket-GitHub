extends "res://tests/v15_rules_tests.gd"
func test_draw_and_scheme():
	for n in range(6):
		for accept in [false,true]:
			var g=game(["philippa","king_arthur"],true);g.players[0].hand=[]
			for i in range(n):g.players[0].hand.append(raw_card("attack",2))
			var deck=g.players[0].deck.size();g.end_turn()
			if n<4:
				check(g.pending_choice.action=="v16_end_draw","optional end draw offered");g=clone(g);g.choose_effect_option(0 if accept else 1)
			g=stable(g);check(g.players[0].hand.size()==(4 if accept and n<4 else n) and g.players[0].deck.size()==deck-(4-n if accept and n<4 else 0),"exact end draw, once only");check(g.active==1,"end ability resumes next player")
	for hp in [2,12]:
		var g=game(["philippa","king_arthur"],true);g.fighters[0].hp=hp;g.players[0].hand=[card(g,0,"backup_plan")];g.scheme(0,0);g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.fighters[0].hp==5,"Backup sets to five even when reducing health")
	var g=game(["philippa","king_arthur"],true);var foe=adjacent(g);g.players[0].hand=[card(g,0,"polymorphy")];g.scheme(0,0);g=stable(g);check(g._movement(0)==5 and g._v14.ongoing(0)=="polymorphy","Polymorphy places and persists")
	g.fighters[0].node=0;g.fighters[foe].node=1;g.fighters[foe+1].node=24;g.end_turn();g=stable(g);check(g._v14.ongoing(0)=="polymorphy","Polymorphy retained with enemy in zone")
	g.active=0;g.phase="action";g.turn_number+=1;g.fighters[foe].node=23;g.end_turn();g=stable(g);check(g._v14.ongoing(0)=="" and g._movement(0)==2,"Polymorphy expires without enemy")
func test_combat16():
	var g=game(["philippa","alice"],true);var foe=adjacent(g);g.alice_size[1]="big"
	combat(g,foe,0,raw_card("attack",4),card(g,0,"paralyzing_fetters"));g=stable(g);check(g.last_combat.attack_value==4 and g.last_combat.damage==2,"Fetters suppresses even hero ability bonus")
	g=game(["philippa","king_arthur"],true);foe=adjacent(g);g.players[0].hand=[card(g,0,"owlform"),raw_card("scheme",0),raw_card("scheme",0)];g.players[1].hand=[raw_card("defense",10)];g.attack(0,foe,0);g.continue_attack();g=clone(g);g.choose_effect_option(0);g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.last_combat.attack_value==5 and g.players[0].hand.is_empty(),"Owlform pays each card, adds exactly one")
	g=game(["philippa","king_arthur"],true);foe=adjacent(g);g.players[0].hand=[card(g,0,"blinding_dust"),raw_card("scheme",0)];g.players[1].hand=[raw_card("attack",1)];var hp=g.fighters[foe].hp;g.active=1;g.attack(foe,0,0);g.continue_attack();g.defend(0);g=wait_choice(g,"v16_dust");g=clone(g);g.choose_effect_option(0);g=stable(g);check(g.fighters[foe].hp==hp-2 and g.players[0].hand.is_empty(),"Dust pays actual BOOST damage")
	for mode in ["redanian_plot","cunning"]:
		g=game(["philippa","king_arthur"],true);foe=adjacent(g);g.players[0].bot=true;g.players[1].bot=false;g.players[0].hand=[card(g,0,mode)];g.players[1].hand=[raw_card("defense",8),raw_card("attack",1)];hp=g.fighters[foe].hp;g.attack(0,foe,0);g.continue_attack();g.defend(0);g=wait_choice(g,"v16_pay");g=clone(g);check(g.skip_effect(),"victim can refuse payment");g=stable(g);check(g.last_combat.damage==2 if mode=="redanian_plot" else g.fighters[foe].hp==hp-2,"decline correctly ignores value or deals damage")
	g=game(["philippa","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"regicide"),raw_card("defense",10));g=stable(g);check(g.last_combat.attack_value==6,"Regicide against hero")
	for maneuvered in [false,true]:
		g=game(["philippa","king_arthur"],true);foe=adjacent(g);hp=g.fighters[foe].hp
		if maneuvered:g.players[0].maneuvered_turn=g.turn_number
		combat(g,0,foe,card(g,0,"lightning_bolt"),raw_card("defense",10));g=stable(g);check(g.fighters[foe].hp==hp-int(not maneuvered),"Bolt checks actual maneuver action")
	g=game(["philippa","king_arthur"],true);foe=adjacent(g);hp=g.fighters[foe].hp;combat(g,0,foe,card(g,0,"chain_lightning"),raw_card("defense",10));g=wait_choice(g,"v16_zone");g=clone(g);g.choose_effect_option(g.pending_choice.zones.map(func(v):return int(v)).find(int(g.nodes[int(g.fighters[foe].node)].zones[0])));g=stable(g);check(g.fighters[foe].hp==hp-1,"Chain damages chosen single zone")
	g=game(["philippa","king_arthur"],true);foe=adjacent(g);combat(g,0,foe,card(g,0,"spellbreaker"),card(g,1,"skirmish"));g=stable(g);check(g.active==1 and g.last_combat.defense_cancelled,"Spellbreaker cancels and finishes turn")
func test_spy16():
	for count in range(7):
		var g=game(["philippa","king_arthur"],true);g.players[1].bot=false;g.players[1].hand=[]
		for i in range(count):var c=raw_card("attack",i);c.id="test_"+str(i);g.players[1].hand.append(c)
		var deck=g.players[1].deck.size();g.players[0].hand=[card(g,0,"spymasters_ruse")];g.scheme(1,0)
		if count>4:
			check(g.pending_choice.action=="v16_reveal_four" and g.pending_choice.owner==1,"victim chooses four, not whole-hand reveal")
			for i in range(4):g=clone(g);g.choose_effect_option(0)
		if count>0:check(g.pending_choice.cards.size()==mini(count,4),"attacker sees only chosen four")
		g=stable(g);check(g.players[1].hand.size()==count-mini(2,count)+2 and g.players[1].deck.size()==deck-2,"Spy discards up to two then draws exactly two")
func run():
	test_draw_and_scheme();test_combat16();test_spy16();all_catalog_cards_v8()
	for level in range(3):
		for roster in [["philippa","eredin"],["philippa","geralt_of_rivia","ciri"],["philippa","eredin","geralt_of_rivia","ancient_leshen"]]:
			var g=Model.new();g.interactive=true;g.setup(roster,level,1616,"naglfar",{"mode":"teams" if roster.size()==4 else "ffa"});var steps=0;var prior=failures
			while g.winner<0 and steps<3000 and failures==prior:
				advance(g);steps+=1
				if steps%17==0:g=clone(g)
				validate(g)
			check(g.winner>=0,"Philippa match completes");matches+=1
	print("V16_RULES checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves]);quit(1 if failures else 0)
