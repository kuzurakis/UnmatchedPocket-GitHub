extends SceneTree
const Model = preload("res://scripts/game_engine.gd")
const NEW = ["buffy","angel","spike","willow"]
var checks = 0
var failures = 0
var matches = 0
var card_runs = 0
var saves = 0

func _initialize(): run.call_deferred()
func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		push_error("BUFFY: " + label)
func game(ids: Array, manual = false, config = {}):
	var g = Model.new()
	g.setup(ids,1,7026,"training",config)
	g.interactive = manual
	for p in g.players: p.bot = true
	g.players[0].bot = not manual
	return g
func card(g, owner: int, id: String):
	for c in g.heroes[g.players[owner].hero_id].cards:
		if str(c.id) == id: return c.duplicate(true)
	check(false,"known card " + id)
	return {}
func raw_card(kind: String, value: int):
	return {"id":"probe","name":"Probe","fighter":"any","type":kind,"value":value,"boost":2,"effects":[]}
func clone(g):
	var other = Model.new()
	check(other.load_state(JSON.parse_string(JSON.stringify(g.save_state()))),"JSON roundtrip " + g.phase)
	saves += 1
	return other
func adjacent(g, own = 0, foe = -1):
	if foe < 0: foe = g.hero_fighter(1)
	var used = [12,13]
	for f in g.fighters:
		if int(f.id) in [own,foe]: continue
		for n in g.nodes:
			if not used.has(int(n.id)):
				f.node = int(n.id)
				used.append(int(n.id))
				break
	g.fighters[own].node = 12
	g.fighters[foe].node = 13
	g.players[1].hand = []
	return foe
func advance(g):
	match g.phase:
		"attack_notice": check(g.continue_attack(),"attack notice")
		"combat_report": check(g.continue_combat(),"combat report")
		"effect_choice": check(g.choose_effect_option(0),"choice " + str(g.pending_choice.get("action","")))
		"effect_move":
			if int(g.pending_choice.get("fighter",-1)) < 0 and not g.pending_choice.get("allowed_fighters",[]).is_empty(): check(g.choose_effect_fighter(int(g.pending_choice.allowed_fighters[0])),"effect fighter")
			if not g.pending_choice.get("legal",[]).is_empty(): check(g.choose_effect_node(int(g.pending_choice.legal[-1])),"effect destination")
			else: check(g.skip_effect(),"skip empty movement")
		"defend":
			var choices = g.legal_defenses()
			check(g.defend(int(choices[0]) if not choices.is_empty() else -1),"defend")
		"action": g._bot_action()
		"move":
			for f in g.fighters:
				if g._valid_fighter(int(f.id),g.active):
					var legal = g.legal_moves(int(f.id))
					if not legal.is_empty(): g.move_fighter(int(f.id),int(legal[-1]))
			g.finish_maneuver()
		"discard": g.discard_card(0)
		"game_over": pass
		_: check(false,"supported phase " + g.phase)
func finish(g):
	for n in range(100):
		if g.phase in ["action","discard","game_over"]: return g
		g = clone(g)
		advance(g)
	check(false,"flow terminates " + str(g._flow))
	return g
func effect(g, kind: String, c = {}, owner = 0):
	var ctx = {"owner":owner,"self":g.hero_fighter(owner),"opponent":g.hero_fighter(1),"opponent_owner":1,"card":c,"value":int(c.get("value",0)),"won":true}
	g._flow = {"kind":"ability","stage":"effects","completion":"start_turn","owner":owner,"effect_logs":[]}
	g.combat_report = {"kind":"ability"}
	g._effect_queue = [{"effect":{"kind":kind},"ctx":ctx}]
	g._pump_effects()

func test_buffy():
	for variant in ["giles","xander"]:
		var g = game(["buffy","angel"],false,{"buffy_sidekick":variant})
		check(g.players[0].buffy_sidekick == variant,"chosen Buffy sidekick " + variant)
		var count = 0
		for c in g.players[0].hand + g.players[0].deck:
			count += 1
			check(not c.has("sidekick_variant") or str(c.sidekick_variant) == variant,"Buffy filters other sidekick cards")
		check(count == 30,"Buffy playable deck has thirty cards")
		g = clone(g)
		check(g.players[0].buffy_sidekick == variant,"sidekick choice survives save")
	var g = game(["buffy","angel"])
	adjacent(g)
	for n in g.nodes: n.move_neighbors = []
	g.nodes[12].move_neighbors = [13]
	g.nodes[13].move_neighbors = [12,14]
	g.nodes[14].move_neighbors = [13]
	check(g._reachable(0,2).has(14) and not g._reachable(0,2).has(13),"Buffy traverses opposing fighter but cannot stop there")
	g.fighters[1].node = 12
	g.fighters[0].node = 0
	check(not g._reachable(1,2).has(14),"Buffy sidekick cannot traverse enemies")
	g = game(["buffy","angel"],true)
	adjacent(g)
	var old_node = int(g.fighters[2].node)
	var old_hp = int(g.fighters[2].hp)
	effect(g,"slayer_s_strength",card(g,0,"slayer_s_strength"))
	check(g.pending_choice.action == "v7_slayer_strength","Slayer's Strength makes one all-or-none decision")
	g = clone(g)
	check(g.choose_effect_option(1),"decline all Slayer movement")
	check(int(g.fighters[2].node) == old_node and int(g.fighters[2].hp) == old_hp,"declined Slayer movement deals no damage")
	g = game(["buffy","angel"],true)
	adjacent(g)
	old_hp = int(g.fighters[2].hp)
	effect(g,"slayer_s_strength",card(g,0,"slayer_s_strength"))
	g = finish(g)
	check(int(g.fighters[2].hp) == old_hp-1,"accepted Slayer movement damages moved fighter once")

func test_angel():
	for fighter in [0,1]:
		for won in [false,true]:
			var g = game(["angel","king_arthur"])
			var foe = adjacent(g,fighter)
			g.players[0].hand = [raw_card("attack",3 if won else 1)]
			g.players[1].hand = [raw_card("defense",2)]
			var deck = g.players[0].deck.size()
			check(g.attack(fighter,foe,0),"Angel/Faith attack")
			check(g.players[0].hand.size() == (0 if won else 1) and g.players[0].deck.size() == deck-(0 if won else 1),"Angel ability draws exactly after lost attack including Faith")
	var g = game(["angel","king_arthur"])
	var foe = adjacent(g)
	g.players[0].hand = [raw_card("defense",1)]
	g.players[1].hand = [raw_card("attack",3)]
	g.active = 1
	var deck = g.players[0].deck.size()
	check(g.attack(foe,0,0),"Angel defending")
	check(g.players[0].hand.is_empty() and g.players[0].deck.size() == deck,"Angel never draws for losing defense")

func test_spike():
	var g = game(["spike","angel"],true)
	g.shadow_tokens.clear()
	for n in range(4):
		effect(g,"shadow_start")
		g = finish(g)
		check(g.shadow_tokens.size() == mini(n+1,3),"Spike places at most three shadows and reuses fourth")
	var ids = []
	for token in g.shadow_tokens:
		check(not ids.has(int(token.id)),"Spike shadow IDs stay unique")
		ids.append(int(token.id))
	g.players[0].hand = [card(g,0,"seek_the_shadows")]
	var before = g.players[0].deck.size()
	check(g.scheme(g.hero_fighter(0),0),"Seek the Shadows scheme")
	g = finish(g)
	check(g.players[0].deck.size() == before-2,"Seek draws two cards")
	var hero_node = int(g.fighters[g.hero_fighter(0)].node)
	var shadow_nodes = []
	for token in g.shadow_tokens: shadow_nodes.append(int(token.node))
	check(shadow_nodes.has(hero_node) and shadow_nodes.size() == 3,"Seek places one shadow under Spike")
	check(shadow_nodes[0] != shadow_nodes[1] and shadow_nodes[1] != shadow_nodes[2] and shadow_nodes[0] != shadow_nodes[2],"Seek moves each of three different shadows to three distinct spaces")
	for node in shadow_nodes: check(node == hero_node or g.nodes[hero_node].neighbors.has(node),"Seek other two shadows adjacent to Spike")

func test_willow():
	for victim in [0,1]:
		var g = game(["willow","angel"])
		g._damage(victim,0)
		check(g.willow_form_for(0) == "willow","zero damage never changes Willow")
		g._damage(victim,1)
		check(g.willow_form_for(0) == "dark","damage to Willow or Tara changes form immediately")
	var g = game(["willow","angel"])
	adjacent(g)
	g.willow_form[0] = "dark"
	g.fighters[1].node = 11
	g.end_turn()
	check(g.willow_form_for(0) == "willow","adjacent Tara restores Willow at end of own turn")
	g = game(["willow","angel"])
	adjacent(g)
	g.willow_form[0] = "dark"
	g.fighters[1].node = 0
	g.end_turn()
	check(g.willow_form_for(0) == "dark","nonadjacent Tara does not restore Willow")
	for dark in [false,true]:
		g = game(["willow","king_arthur"])
		var foe = adjacent(g)
		g.willow_form[0] = "dark" if dark else "willow"
		g.players[0].hand = [card(g,0,"black_magic")]
		g.players[0].deck[-1] = raw_card("attack",1)
		var deck = g.players[0].deck.size()
		check(g.attack(0,foe,0),"Black Magic attack")
		check(int(g.last_combat.attack_value) == (5 if dark else 3) and g.players[0].deck.size() == deck-(1 if dark else 0),"orange blind boost applies only while Dark Willow")
	g = game(["willow","king_arthur"],true)
	var recovered = card(g,0,"feint")
	g.players[0].discard = [recovered]
	var hand = g.players[0].hand.size()
	effect(g,"knowledge_of_the_craft",card(g,0,"knowledge_of_the_craft"))
	check(g.pending_choice.action == "v7_retrieve","retrieval presents discard")
	g = finish(g)
	check(g.players[0].hand.size() == hand+1 and g.players[0].discard.is_empty() and g.players[0].hand[-1].id == recovered.id,"retrieval transfers chosen discard to hand")
	for hero in [false,true]:
		g = game(["willow","angel","buffy","spike"],true,{"mode":"teams"})
		var fid = g.hero_fighter(2) if hero else 1
		g.fighters[fid].alive = false
		g.fighters[fid].hp = 0
		if hero: g.players[2].alive = false
		effect(g,"resurrect",card(g,0,"resurrect"))
		check(g.pending_choice.action == "v7_resurrect" and g.pending_choice.ids.has(fid),"resurrection can select defeated friendly hero or sidekick")
		g = finish(g)
		check(g.fighters[fid].alive and int(g.fighters[fid].hp) == 3 and g.players[int(g.fighters[fid].owner)].alive,"resurrection restores allied fighter and owner with exactly three health")
		check(g._same_zone(int(g.fighters[fid].node),int(g.fighters[0].node)),"resurrection places fighter in Willow zone")

func test_all_cards():
	var catalog = Model.new()
	for hid in NEW:
		for source in catalog.heroes[hid].cards:
			for manual in [false,true]:
				var g = game([hid,"king_arthur"],manual,{"buffy_sidekick":str(source.get("sidekick_variant","giles"))})
				var own = 1 if str(source.fighter) == "sidekick" else 0
				var foe = adjacent(g,own)
				g.players[0].hand = [source.duplicate(true)]
				g.players[0].discard = [raw_card("attack",2)]
				if hid == "willow": g.willow_form[0] = "dark"
				if str(source.id) == "resurrect":
					g.fighters[1].alive = false
					g.fighters[1].hp = 0
				if hid == "spike": g.shadow_tokens = [{"owner":0,"id":0,"node":12},{"owner":0,"id":1,"node":11},{"owner":0,"id":2,"node":14}]
				if str(source.type) == "scheme": check(g.scheme(own,0),"scheme " + hid + "/" + str(source.id))
				elif str(source.type) == "defense":
					g.active = 1
					g.players[1].hand = [raw_card("attack",2)]
					check(g.attack(foe,own,0),"attack into " + str(source.id))
					if manual: g.continue_attack()
					if g.phase == "defend": check(g.defend(0),"defense " + str(source.id))
				else: check(g.attack(own,foe,0),"attack " + hid + "/" + str(source.id))
				g = finish(g)
				check(g.phase in ["action","discard","game_over"],"card stabilizes " + hid + "/" + str(source.id))
				card_runs += 1
	check(card_runs == 100,"all fifty variants execute in human and automatic modes")

func test_effect_results():
	for dark in [false,true]:
		var g = game(["willow","king_arthur"])
		var foe = adjacent(g)
		g.willow_form[0] = "dark" if dark else "willow"
		g.players[0].hand = [card(g,0,"black_magic")]
		g.players[1].hand = [card(g,1,"feint")]
		var before = g.players[0].deck.size()
		check(g.attack(0,foe,0),"cancel orange effect attack")
		check(g.last_combat.attack_cancelled and g.players[0].deck.size() == before and int(g.last_combat.attack_value) == 3,"Feint cancels Dark Willow orange effects")
	var g = game(["willow","king_arthur"])
	var foe = adjacent(g)
	g.willow_form[0] = "dark"
	g.players[0].hand = [card(g,0,"flayed_alive")]
	g.players[0].deck.clear()
	var hp = int(g.fighters[0].hp)
	check(g.attack(0,foe,0),"blind boost empty deck")
	check(int(g.last_combat.attack_value) == 4 and int(g.fighters[0].hp) == hp,"empty blind boost is zero without exhaustion damage")
	g = game(["willow","angel"],true)
	adjacent(g)
	g.fighters[1].node = 11
	g.willow_form[0] = "dark"
	var deck = g.players[0].deck.size()
	effect(g,"love_and_loss",card(g,0,"love_and_loss"))
	check(g.pending_choice.action == "v7_love_damage" and g.pending_choice.ids.has(1),"Dark Love and Loss permits own Tara as target")
	g = finish(g)
	check(g.players[0].deck.size() == deck-4 and g.players[0].discard.size() == 2 and int(g.fighters[1].hp) == 3,"Dark Love and Loss draws two, mills two, deals three to chosen sidekick")
	for shadow in [false,true]:
		g = game(["spike","king_arthur"])
		foe = adjacent(g,1)
		g.shadow_tokens.clear()
		if shadow: g.shadow_tokens.append({"owner":0,"id":0,"node":12})
		g.players[0].hand = [card(g,0,"always_surprising")]
		g.players[0].deck[-1] = raw_card("attack",1)
		deck = g.players[0].deck.size()
		check(g.attack(1,foe,0),"Drusilla blind boost")
		check(int(g.last_combat.attack_value) == (5 if shadow else 3) and g.players[0].deck.size() == deck-1,"Always Surprising doubles boost only on Drusilla shadow")
		g = game(["spike","king_arthur"])
		foe = adjacent(g)
		g.shadow_tokens.clear()
		if shadow: g.shadow_tokens.append({"owner":0,"id":0,"node":13})
		g.players[0].hand = [card(g,0,"the_rush")]
		check(g.attack(0,foe,0),"The Rush attack")
		check(int(g.last_combat.attack_value) == (5 if shadow else 3),"The Rush checks either combatant shadow")
		g = game(["spike","king_arthur"])
		foe = adjacent(g)
		g.shadow_tokens.clear()
		if shadow: g.shadow_tokens.append({"owner":0,"id":0,"node":13})
		var hand = g.players[0].hand.size()
		effect(g,"empathy",card(g,0,"empathy"))
		check(g.players[0].hand.size() == hand+(3 if shadow else 1),"Empathy draws one or three from opposing shadow")
	g = game(["spike","angel"])
	foe = adjacent(g)
	g.shadow_tokens = [{"owner":0,"id":0,"node":12},{"owner":0,"id":1,"node":12},{"owner":0,"id":2,"node":14}]
	hp = int(g.fighters[foe].hp)
	effect(g,"bloody_hell",card(g,0,"bloody_hell"))
	check(int(g.fighters[foe].hp) == hp-3,"Bloody Hell counts two distinct adjacent shadow spaces, not three tokens")
	g = game(["spike","angel"],true)
	foe = adjacent(g)
	g.shadow_tokens = [{"owner":0,"id":0,"node":13}]
	var hand = g.players[1].hand.size()
	g.players[1].hand = [raw_card("attack",1),raw_card("attack",2),raw_card("attack",3)]
	effect(g,"the_sight",card(g,0,"the_sight"))
	g = finish(g)
	check(g.players[1].hand.size() == 1 and g.players[1].discard.size() == 2,"The Sight discards two from selected opponent with shadowed fighter")

func validate(g):
	var occupied = []
	var shadows = []
	for f in g.fighters:
		if not f.alive: continue
		check(int(f.hp) > 0 and int(f.hp) <= int(f.max_hp),"valid living health")
		if bool(f.get("offboard",false)): continue
		check(not occupied.has(int(f.node)),"no fighter overlap")
		occupied.append(int(f.node))
	for token in g.shadow_tokens:
		var key = "%d/%d" % [int(token.owner),int(token.id)]
		check(not shadows.has(key) and int(token.id) >= 0 and int(token.id) < 3,"valid unique shadows per owner")
		shadows.append(key)
	if g._flow.is_empty() and g.pending_combat.is_empty():
		for p in g.players: check(p.hand.size()+p.deck.size()+p.discard.size() == 30,"thirty cards conserved")
func test_matches():
	var rosters = [["buffy","angel"],["spike","willow"],["buffy","willow"],["buffy","spike","willow"],NEW,NEW]
	for board in ["sunnydale_high","the_bronze"]:
		for level in range(3):
			for manual in [false,true]:
				for index in range(rosters.size()):
					var g = Model.new()
					g.interactive = manual
					g.setup(rosters[index],level,7200+level*50+index,board,{"mode":"teams" if index == 5 else "ffa","buffy_sidekick":"xander" if index % 2 else "giles"})
					if not manual:
						for p in g.players: p.bot = true
					check(g.map_id == board,"requested Buffy map loaded")
					var steps = 0
					var prior = failures
					while g.winner < 0 and steps < 2500 and failures == prior:
						advance(g)
						steps += 1
						if steps % 31 == 0: g = clone(g)
						validate(g)
					check(g.winner >= 0 and g.phase == "game_over","match completes board=%s level=%d manual=%s roster=%d steps=%d phase=%s" % [board,level,manual,index,steps,g.phase])
					matches += 1
					print("BUFFY_MATCH board=%s level=%d manual=%s roster=%d steps=%d" % [board,level,manual,index,steps])

func run():
	test_buffy()
	test_angel()
	test_spike()
	test_willow()
	test_effect_results()
	test_all_cards()
	test_matches()
	print("BUFFY_ENGINE_TESTS checks=%d failures=%d matches=%d card_runs=%d saves=%d" % [checks,failures,matches,card_runs,saves])
	quit(1 if failures else 0)
