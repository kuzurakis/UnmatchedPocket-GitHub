extends "res://tests/v10_engine_tests.gd"
var ability_results = []
func run_case(hid: String, n: int):
	var g = game([hid,"king_arthur"],true)
	var foe = adjacent(g)
	var h = g.hero_fighter(0)
	match hid:
		"alice":
			if n == 0:
				g.alice_size[0] = "big";combat(g,h,foe,raw_card("attack",2),card(g,1,"feint"));g=stable(g)
				check(g.last_combat.attack_value == 4,"Alice big attack bonus survives cancellation")
			else:
				g.alice_size[0] = "small";combat(g,foe,h,raw_card("attack",4),raw_card("defense",2));g=stable(g)
				check(g.last_combat.defense_value == 3,"Alice small defense bonus")
		"king_arthur":
			g.players[0].hand = [card(g,0,"excalibur" if n == 0 else "the_aid_of_morgana"),raw_card("versatile",1)]
			g.players[0].hand[1].boost = 3
			g.players[1].hand = [card(g,1,"feint")]
			check(g.attack(h,foe,0,1),"Arthur chooses extra BOOST before revealing defense")
			g.continue_attack();g=stable(g)
			check(g.last_combat.attack_value == (9 if n == 0 else 4),"Arthur keeps BOOST only for effectless Excalibur when cancelled")
		"medusa":
			g.fighters[h].node=0;g.fighters[foe].node=1 if n == 0 else 24
			for id in range(1,4): g.fighters[id].node=id*5
			g.fighters[foe+1].node=23
			var hp=g.fighters[foe].hp;g._start_turn_ability();g=stable(g)
			check(g.fighters[foe].hp == hp-(1 if n == 0 else 0),"Medusa optional gaze only reaches enemy in her zone")
		"sinbad":
			g.players[0].discard.clear()
			if n == 1: g.players[0].discard=[card(g,0,"voyage_home"),card(g,0,"voyage_to_the_island_that_was_a_whale")]
			check(g._movement(0) == 2+2*n,"Sinbad movement counts voyages already in discard")
			g.begin_maneuver();check(g.maneuver_distance == 2+2*n,"maneuver uses current voyage bonus")
		"robin_hood":
			var id = h if n == 0 else h+1
			foe=adjacent(g,id)
			combat(g,id,foe,raw_card("attack",1),raw_card("defense",5))
			g.continue_combat()
			check(g.phase == "effect_move" and g.pending_choice.fighter == id and g.pending_choice.spaces == 2,"Robin ability moves actual attacker including Outlaw after losing")
		"bigfoot":
			g.fighters[h].node=0;g.fighters[foe].node=24 if n == 0 else 1;g.fighters[foe+1].node=23
			g.fighters[h+1].node=5
			var deck=g.players[0].deck.size();g.end_turn();g=stable(g)
			check(g.players[0].deck.size() == deck-(1 if n == 0 else 0),"Bigfoot end draw checks absence of enemies in zone")
		"bruce_lee":
			g.fighters[h].node=0
			g.fighters[foe+1].node=24
			if n == 1: g.fighters[foe].node=1;g.fighters[foe+1].node=5
			g.end_turn()
			check(g.phase == "effect_move" and g.pending_choice.spaces == 1,"Bruce end turn offers one-space move")
			check((g.pending_choice.legal.size() > 1) == (n == 0),"Bruce ability respects occupied enemy spaces")
		"ingen":
			g.traps.clear();g._trap_stock[0]=8
			if n == 0:
				g._start_turn_ability();check(g.phase == "effect_move" and g.pending_choice.action == "place_traps","Muldoon start offers trap")
				var node=int(g.pending_choice.legal[0]);g.choose_effect_node(node);g=stable(g)
				check(g.traps.size() == 1 and g.trap_supply(0) == 7,"trap consumes one stock")
			else:
				g.traps=[{"owner":0,"node":11}];g._trap_stock[0]=7
				var hp=g.fighters[foe].hp;var deck=g.players[0].deck.size();g._enter_node(foe,11)
				check(g.fighters[foe].hp == hp-1 and g.traps.is_empty() and g.players[0].deck.size() == deck-1 and g.trap_supply(0) == 7,"enemy triggers damage, draw, permanent trap removal")
		"raptors":
			g.fighters[1].node=8 if n else 0;g.fighters[2].node=18 if n else 1
			combat(g,h,foe,raw_card("attack",2));g=stable(g)
			check(g.last_combat.attack_value == 2+2*n,"Raptor bonus counts other Raptors adjacent to target")
		"muhammad_ali":
			if n == 0:
				g.fighters[h].node=1;g.fighters[foe].node=3;g.ali_stance[0]="butterfly";g.players[0].hand=[raw_card("attack",2)]
				check(not g._same_zone(1,3) and g.legal_targets(h,0).has(foe),"Butterfly attacks across zones at distance two")
			else:
				g.ali_stance[0]="bee";combat(g,h,foe,raw_card("attack",2),card(g,1,"feint"));g=stable(g)
				check(g.last_combat.attack_value == 4 and g.stance_for(0) == "butterfly","Bee adds two and winning attack flips stance")
		"dracula":
			if n == 1:
				g.fighters[h].node=0
				for f in g.fighters:
					if int(f.id) != h: f.node=10+int(f.id)
			var hp=g.fighters[foe].hp;var deck=g.players[0].deck.size()
			g._start_turn_ability()
			if g.phase == "effect_choice": g.choose_effect_option(g.pending_choice.ids.find(foe))
			g=stable(g)
			check(g.players[0].deck.size() == deck-(1 if n == 0 else 0) and g.fighters[foe].hp == hp-(1 if n == 0 else 0),"Dracula bite needs adjacent fighter and draws after damage")
		"sherlock_holmes":
			var id=h if n == 0 else h+1;foe=adjacent(g,id)
			combat(g,id,foe,card(g,0,"the_game_is_afoot" if n == 0 else "service_revolver"),card(g,1,"feint"));g=stable(g)
			check(not g.last_combat.attack_cancelled,"Holmes and Watson named cards cannot be cancelled")
			foe=adjacent(g,id)
			combat(g,id,foe,card(g,0,"education_never_ends"),card(g,1,"feint"));g=stable(g)
			check(g.last_combat.attack_cancelled,"ANY cards remain cancellable")
		"jekyll_hyde":
			g._start_turn_ability();g.choose_effect_option(n);g=stable(g)
			check(g.form_for(0) == ("jekyll" if n == 0 else "hyde"),"start turn chooses form")
			var hp=g.fighters[h].hp;g.begin_maneuver();g.finish_maneuver();g=stable(g)
			check(g.fighters[h].hp == hp-n,"only Hyde pays one health after maneuver")
			check(g.can_use_card(card(g,0,"forever_hyde"),h) == (n == 1),"Hyde cards require Hyde form")
		"invisible_man":
			g.fog_tokens=[] if n else [{"id":0,"owner":0,"node":12},{"id":1,"owner":0,"node":24}]
			g.players[0].hand=[raw_card("versatile",2)]
			check(g.legal_moves(h).has(24) == (n == 0),"fog spaces form movement link only when present")
			combat(g,foe,h,raw_card("attack",3),raw_card("defense",2));g=stable(g)
			check(g.last_combat.defense_value == 3-n,"fog adds one to defense only on fog")
		"buffy":
			var id=h if n == 0 else h+1;foe=adjacent(g,id)
			check(g._reachable(id,2).has(14) == (n == 0),"Buffy passes enemy, sidekick cannot")
		"angel":
			var id=h if n == 0 else h+1;foe=adjacent(g,id)
			var deck=g.players[0].deck.size();combat(g,id,foe,raw_card("attack",1),raw_card("defense",4));g=stable(g)
			check(g.players[0].deck.size() == deck-1,"Angel and Faith draw after losing their attack")
		"spike":
			g.shadow_tokens=[] if n == 0 else [{"id":0,"owner":0,"node":1},{"id":1,"owner":0,"node":2},{"id":2,"owner":0,"node":3}]
			g._start_turn_ability();g=stable(g)
			check(g.shadow_tokens.size() == (1 if n == 0 else 3),"Spike adds a shadow or reuses one when all three present")
		"willow":
			g.willow_form[0]="willow";g._damage(h if n == 0 else h+1,1)
			check(g.willow_form_for(0) == "dark","damage to Willow or Tara makes Dark Willow")
			g.fighters[h].node=12;g.fighters[h+1].node=11 if n == 0 else 0
			g.end_turn();g=stable(g)
			check(g.willow_form_for(0) == ("willow" if n == 0 else "dark"),"end turn becomes light only adjacent to Tara")
		"little_red":
			g.players[0].discard=[card(g,0,"long_have_i_sought_you" if n == 0 else "what_big_ears_you_have")]
			var discarded=card(g,0,"what_big_ears_you_have" if n == 0 else "once_upon_a_time")
			g.players[0].hand=[card(g,0,"the_wolf_s_skin"),discarded]
			var attack=raw_card("attack",2);attack.effects=[{"timing":"during","kind":"ambush"}]
			g.players[1].hand=[attack];g.active=1
			var deck=g.players[0].deck.size();g.attack(foe,h,0);g.continue_attack();g.defend(0);g=stable(g)
			check(g.players[0].deck.size() == deck-(2 if n == 0 else 0),"basket follows opponent discard during combat, matching and mismatching symbols")
		"beowulf":
			g.players[0].rage=0
			g._damage(h,2)
			if n == 0: g._damage(h,1)
			else: g._damage(h+1,1)
			check(g._v8.rage(0) == (2 if n == 0 else 1),"Rage counts damage events on Beowulf, excludes Wiglaf")
		"houdini":
			g.players[0].hand=[card(g,0,"sleight_of_hand" if n == 0 else "all_part_of_the_show")]
			g.fighters[h].hp=8;var deck=g.players[0].deck.size();g.begin_maneuver(0);g=stable(g)
			check(g.legal_moves(h).has(24),"boosted maneuver enables Houdini teleport")
			check(g.players[0].deck.size() == deck-(2 if n == 0 else 1) and g.fighters[h].hp == (8 if n == 0 else 10),"BOOST ability executes draw/heal before card discard")
		"genie":
			var hand=g.players[0].hand.size();g._start_turn_ability()
			if n == 0: g.choose_effect_option(0)
			else: g.skip_effect()
			g=stable(g)
			check(g.actions_left == (3 if n == 0 else 2) and g.players[0].hand.size() == hand-(1 if n == 0 else 0),"Genie optionally pays one card for extra action")
		"achilles":
			if n == 1: g._damage(h+1,6)
			var deck=g.players[0].deck.size();combat(g,h,foe,raw_card("attack",3),card(g,1,"feint"));g=stable(g)
			check(g.last_combat.attack_value == 3+2*n and g.players[0].deck.size() == deck-n,"Achilles gains attack and win draw only with Patroclus defeated")
		"bloody_mary":
			g.players[0].hand=[raw_card("attack",1),raw_card("attack",1),raw_card("attack",1)]
			if n == 1: g.players[0].hand.append(raw_card("attack",1))
			g._start_turn_ability();g=stable(g)
			check(g.actions_left == (3 if n == 0 else 2),"Mary gets action only at exactly three cards")
		"sun_wukong":
			g.fighters[h].hp=18
			for id in [1,2,3]: g.fighters[id].alive=n==1;g.fighters[id].hp=1 if n else 0;g.fighters[id].node=id-1
			g._start_turn_ability();g=stable(g)
			check(g.fighters[h].hp == 17 and g._v9.helpers(0).size() == (1 if n == 0 else 3),"Wukong summons or relocates Clone for one damage")
		"yennenga":
			g.fighters[1].node=7 if n == 0 else 0;g.fighters[2].node=17 if n == 0 else 1
			if n == 1: g.fighters[h].node=24;g.fighters[foe].node=23
			var hp=g.fighters[h].hp;combat(g,foe,h,raw_card("attack",3))
			if n == 0:
				check(g.pending_choice.action == "v9_damage","Yennenga offers assignment to in-zone Archers")
				g.choose_effect_option(1);g.choose_effect_option(1);g.choose_effect_option(1)
			g=stable(g)
			check(g.fighters[h].hp == hp-(0 if n == 0 else 3) and g.last_combat.damage == 3,"redirected combat damage preserves attacker win; outside-zone Archers ineligible")
		"nikola_tesla":
			g.players[0].coils=1+n;var hp=g.fighters[foe].hp;g._start_turn_ability();g=stable(g)
			check(g.fighters[foe].hp == hp-n and g._v10.coils(0) == 1+n,"Tesla overflow only with both coils and does not discharge")
		"dr_jill_trent":
			g._start_turn_ability();g.choose_effect_option(n);g=stable(g)
			g.fighters[h].hp=8;g.players[1].deck[-1].boost=2
			combat(g,h,foe,raw_card("attack",2 if n == 0 else 5),raw_card("defense",4 if n == 0 else 2));g=stable(g)
			check((g.last_combat.attack_value == 4 and g._v10.gadget(0) == "hypno") if n == 0 else (g.fighters[h].hp == 9 and g._v10.gadget(0) == "tonic"),"chosen gadget uses printed card comparison")
		"annie_christmas":
			g.fighters[h].hp=8 if n == 0 else 14;g.fighters[foe].hp=14
			combat(g,h,foe,raw_card("attack",2),card(g,1,"feint"));g=stable(g)
			check(g.last_combat.attack_value == (4 if n == 0 else 2),"Annie bonus only when lower health; not on equal health")
		"golden_bat":
			if n == 1: g.begin_maneuver();g.finish_maneuver()
			combat(g,h,foe,raw_card("attack",2));g=stable(g)
			check(g.last_combat.attack_value == (4 if n == 0 else 2),"Golden Bat bonus removed even by maneuver without moving")
		"philippa":
			g.players[0].hand=[];var deck=g.players[0].deck.size();g.end_turn();g=clone(g);g.choose_effect_option(n);g=stable(g)
			check(g.players[0].deck.size()==deck-(4 if n==0 else 0) and g.active==1,"Philippa end draw or decline")
		"eredin":
			if n==1:
				for id in g._v15.riders(0):g.fighters[int(id)].alive=false;g.fighters[int(id)].hp=0
			check(g._movement(0)==2+n and g._v15.enraged(0)==(n==1),"Eredin move follows living Riders")
			combat(g,h,foe,raw_card("attack",2),card(g,1,"feint"));g=stable(g)
			check(g.last_combat.attack_value==2+n,"Eredin attack ability survives cancellation")
			g.phase="action";g.actions_left=2
			combat(g,foe,h,raw_card("attack",4),raw_card("defense",2));g=stable(g)
			check(g.last_combat.defense_value==2+n,"Eredin defense ability follows same current rage state")
		_: check(false,"missing hero ability case " + hid)
func run():
	var model=Model.new();model._load_heroes()
	for hid in model.heroes:
		if hid in ["t_rex","dr_ellie_sattler","moon_knight","ghost_rider","ms_marvel","winter_soldier","she_hulk","spider_man","doctor_strange","cloak_and_dagger","daredevil","bullseye","elektra","luke_cage","yennefer_triss","oda_nobunaga","tomoe_gozen","william_shakespeare","hamlet","titania","the_wayward_sisters","geralt_of_rivia","ciri","ancient_leshen"]: continue
		for n in range(2):
			var prior=failures;run_case(str(hid),n)
			ability_results.append({"hero":hid,"scenario":n+1,"passed":prior==failures})
	print("V11_ABILITIES checks=%d failures=%d heroes=%d scenarios=%d" % [checks,failures,model.heroes.size(),ability_results.size()])
	var out=FileAccess.open("res://../../work/v11-ability-results.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"results":ability_results},"  "))
	quit(1 if failures else 0)
