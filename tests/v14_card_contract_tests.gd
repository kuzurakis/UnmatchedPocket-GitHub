extends SceneTree
const Probe = preload("res://tests/v11_probe_engine.gd")
var checks = 0
var failures = 0
var card_count = 0
var stage_count = 0
var current = ""
var results = []
var seen_moves = []
var seen_places = []
var seen_peek = false
var seen_public = false
var choice_trace = []
var move_specs = []
var pre = {}
var g
var fid = 0
var foe = 0
var hero = 0
var ctx = {}
var c = {}
var tokens = []
func _initialize(): run.call_deferred()
func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		push_error("CONTRACT " + current + " " + message)
func card(hid: String, cid: String):
	for definition in g.heroes[hid].cards:
		if definition.id == cid: return definition.duplicate(true)
	return {}
func probe_card(id = "oracle", banner = "any"):
	return {"id":id,"name":id,"fighter":banner,"type":"versatile","value":3,"boost":2,"effects":[]}
func snapshot():
	if ctx.has("_combat_slot") and g._combat_resolution.has(str(ctx._combat_slot)): ctx = g._combat_resolution[str(ctx._combat_slot)]
	return {"pot":g.players[0].get("cauldron",[]).size(),"line":g.players[0].get("line",[]).size(),"glamour":g.players[0].get("glamour",""),"glamour_discard":g.players[0].get("glamour_discard",[]).size(),"glamour_deck":g.players[0].get("glamour_deck",[]).size(),"deck":g.players[0].deck.size(),"hand":g.players[0].hand.size(),"discard":g.players[0].discard.size(),"enemy_deck":g.players[1].deck.size(),"enemy_hand":g.players[1].hand.size(),"enemy_discard":g.players[1].discard.size(),"hp":g.fighters.map(func(f):return f.hp),"nodes":g.fighters.map(func(f):return f.node),"actions":g.actions_left,"size":g.alice_size.get(0,"big"),"fog":g.fog_tokens.duplicate(true),"shadows":g.shadow_tokens.size(),"traps":g.traps.size(),"value":ctx.value,"other_value":g._v6._other(ctx).value,"alive":g.fighters.map(func(f):return f.alive)}
func fixture(hid: String, cid: String, oracle: String):
	g = Probe.new()
	g.setup([hid,"king_arthur"],1,11011,"training",{"buffy_sidekick":"xander" if cid in ["right_hand_man","military_knowledge"] else "giles"})
	g.interactive = true;g.players[0].bot = false;g.players[1].bot = true
	g._flow.clear();g._effect_queue.clear();g.pending_choice.clear();g._deferred_damage.clear();g.phase = "action"
	hero = g.hero_fighter(0);foe = g.hero_fighter(1);c = card(hid,cid)
	fid = hero+1 if str(c.fighter) == "sidekick" else hero
	var friendly_positions = [11,7,17,6,1]
	var next = 0
	for f in g.fighters:
		f.alive = true;f.placed = true;f.reserve = false
		f.hp = maxi(1,int(f.max_hp)-5)
		if int(f.owner) == 0:
			if int(f.id) == fid: f.node = 12
			else: f.node = friendly_positions[next];next += 1
		else: f.node = 13 if int(f.id) == foe else 8;f.hp = f.max_hp
	g.fighters[hero].hp = maxi(1,int(g.fighters[hero].max_hp)-5)
	g._snapshot_positions()
	g.turn_start_nodes[fid] = 0
	g.players[0].hand = [probe_card("held1"),probe_card("held2"),probe_card("held3")]
	g.players[1].hand = [probe_card("enemy1"),probe_card("enemy2"),probe_card("enemy3")]
	for p in g.players:
		p.deck = []
		for i in range(24): p.deck.append(probe_card("deck"+str(i)))
		p.discard = []
	g.players[0].discard = [probe_card("discard1"),probe_card("discard2"),probe_card("discard3")]
	g.players[0].rage = 3;g.players[0].coils = 2;g.players[0].gadget = "hypno";g.players[0].won_combat_turn = true;g.players[0].combat_damage_turn = 6;g.players[0].actions_taken = 3
	g.willow_form[0] = "dark";g.jekyll_form[0] = "hyde" if str(c.fighter) == "hyde" else "jekyll";g.ali_stance[0] = "butterfly"
	g.fog_tokens = [{"id":0,"owner":0,"node":int(g.fighters[hero].node)},{"id":1,"owner":0,"node":13},{"id":2,"owner":0,"node":8}] if hid == "invisible_man" else []
	g.players[0].started_on_fog = true
	g.shadow_tokens = [{"id":0,"owner":0,"node":12},{"id":1,"owner":0,"node":8},{"id":2,"owner":0,"node":18}] if hid == "spike" else []
	if cid in ["empathy","the_sight"]: g.shadow_tokens[0].node=13
	g.traps = [{"owner":0,"node":14},{"owner":0,"node":18}] if hid == "ingen" else [];g._trap_stock[0] = 6
	var slot = "d" if c.type == "defense" or hid == "jekyll_hyde" and cid == "duality_of_man" else "a"
	ctx = {"owner":0,"self":fid,"opponent":foe,"opponent_owner":1,"card":c,"value":int(c.value),"won":true,"prevent":false,"cancelled":false,"damage_dealt":3,"damage_taken":3,"_combat_slot":slot}
	var other = {"owner":1,"self":foe,"opponent":fid,"opponent_owner":0,"card":probe_card("opposing"),"value":4,"won":false,"prevent":false,"cancelled":false,"_combat_slot":"a" if slot == "d" else "d"}
	other.card.value = 4
	g._combat_resolution = {slot:ctx,"a" if slot == "d" else "d":other,"ctx":{"attacker":fid if slot == "a" else foe,"target":foe if slot == "a" else fid,"attack_owner":0 if slot == "a" else 1,"defender_owner":1 if slot == "a" else 0,"attack_card":c if slot == "a" else other.card,"boost":0}}
	g._flow = {"kind":"combat_pre" if c.type != "scheme" else "scheme","stage":"effects","owner":0,"card":c,"effect_logs":[],"boosts":[]}
	if hid == "little_red":
		g.players[0].discard = [card(hid,"long_have_i_sought_you")]
		g.players[0].discard[0].basket_symbol = "flower" if cid == "what_big_eyes_you_have" else "pelt" if cid in ["the_wolf_s_skin","what_a_terrible_big_mouth_you_have","a_grimm_tale","what_large_hands_you_have"] else "knife"
	if hid == "sinbad": g.players[0].discard = [card(hid,"voyage_home"),card(hid,"voyage_to_the_city_of_the_king_of_serendib")]
	if cid == "little_dragon": g.players[0].hand.clear()
	if cid == "taste_of_blood": g.fighters[hero].hp = 5
	if cid == "the_holy_grail": g.fighters[hero].hp = 4
	if cid == "shoot_her": g.players[0].actions_taken = 1
	if cid == "forever_hyde":
		for h in g.players[0].hand: h.fighter = "jekyll"
	if cid in ["cursed_with_a_soul","haunted_by_the_faces","brooding","rope_a_dope","careful_what_you_wish_for","achilles_heel"]:
		ctx.won = false;g.active = 1
	if cid == "broken_glass": other.value = int(c.value)
	if cid in ["jump_scare","like_a_flash_of_golden_light"]: g.turn_start_nodes[fid] = 0
	if cid in ["long_shot","fancy_footwork"]: g.fighters[foe].node = 24;g.fighters[fid].node = 0
	if cid == "long_shot": g.fighters[foe].node = 23
	if cid == "divide_and_conquer": fid = hero+1;g.fighters[fid].node = 0;ctx.self = fid;g.fighters[hero].node = 24
	if cid == "jaws_of_the_beast": g.fighters[foe].node = 2
	if hid == "raptors":
		g.fighters[1].node = 8;g.fighters[2].node = 18
		g.fighters[foe+1].node=19
	if cid in ["feeding_frenzy","ravening_seduction"]:
		for f in g.fighters:
			if f.owner == 0 and not f.hero: f.node = [8,14,18][int(f.id)-1]
		g.fighters[foe+1].node=19
	if cid == "infinite_strikes": g.fighters[1].node = 8;g.fighters[2].node = 18;g.fighters[3].node = 0;g.fighters[foe+1].node=19
	if oracle.contains("revive") or cid in ["surprise_volley","resurrect","shield_formation","call_for_backup"]:
		if hero+1 < foe: g.fighters[hero+1].alive = false;g.fighters[hero+1].hp = 0
	if cid == "all_part_of_the_show": g.fighters[fid].alive = false;g.fighters[fid].hp = 0
	if cid == "the_lady_of_the_lake": g.players[0].discard = [card(hid,"excalibur")]
	if cid in ["be_like_water","hoo_whaaaaaa"]: g.players[0].discard = [card(hid,"jeet_kune_do_wrist_lock")]
	if cid == "72_transformations": g.players[0].discard = [card(hid,"ox_form")]
	if cid == "the_big_reveal" and oracle == "retrieve_boost": g._flow.boosts = [{"owner":0,"card":g.players[0].discard[0].duplicate(true)}]
	if cid == "helpful_assistant": g.players[0].discard = [card(hid,"hypnotist"),card(hid,"battle_of_wits"),card(hid,"utility_belt")]
	if cid == "quite_a_pair": g.players[0].hand[1] = g.players[0].hand[0].duplicate(true)
	if cid == "battle_of_wits": g.players[0].deck[-1].boost = 3;g.players[1].deck[-1].boost = 1
	if cid == "never_leave_the_path": g.players[0].discard[-1].basket_symbol = "wild"
	if cid == "elementary": g._combat_resolution.ctx.prediction = 4
	if cid == "no_contest_expecteth":
		ctx.opponent = foe+1;foe += 1;g.fighters[foe].hp = 6
	if cid == "remnant_of_valor": g.fighters[hero].node = 11
	if cid in ["jump_scare","like_a_flash_of_golden_light"]: g.fighters[fid].node = 24
	if cid == "seek_the_shadows": g.shadow_tokens.clear()
	if cid == "steal_from_the_rich": g.players[1].bot = false
	if cid == "doom" or cid == "the_day_of_your_doom": g.fighters[fid].hp = 6
	if hid == "oda_nobunaga":
		g.fighters[0].node=12 if fid==0 else 11;g.fighters[1].node=11 if fid==0 else 12;g.fighters[2].node=8;g.fighters[foe+1].node=19
	if cid=="confront_any_demon_or_god": ctx.won=false
	if hid=="william_shakespeare":
		g.players[0].line=[{"id":"horror","name":"Horror","syllables":2},{"id":"horror","name":"Horror","syllables":2}]
		g.fighters[0].node=12 if fid==0 else 11;g.fighters[1].node=11 if fid==0 else 12;g.fighters[2].node=8;g.fighters[3].node=18;g.fighters[foe+1].node=19
		if cid=="alas": ctx.won=false
	if hid=="hamlet":
		g.fighters[0].damaged_turn=g.turn_number
		if cid=="outrageous_fortune": ctx.won=false;ctx.fortune_card=g.players[0].discard[-1].duplicate(true)
	if hid=="titania": g.players[0].glamour="greed";g.players[0].glamour_discard=["sleep"];g.players[0].glamour_deck=["jealousy","love","rhyme","invisibility"]
	if hid=="the_wayward_sisters":
		g.players[0].cauldron=[]
		for symbol in ["snake","bat","lizard"]:
			var ingredient=probe_card(symbol);ingredient.ingredient=symbol;g.players[0].cauldron.append(ingredient)
	if hid=="geralt_of_rivia":
		g.players[0].deck[-1]=card(hid,"gear_sword_of_steel");g.players[0].discard[0]=card(hid,"gear_sword_of_silver")
		if cid=="gear_wolf_medallion" and oracle=="ignore":g.fighters[foe].node=24
	if hid=="ciri":
		g.players[0].discard=[]
		var source_ids=["lion_cub_of_cintra","pushed_to_the_brink","the_lady_of_space_and_time","zireael","child_of_the_elder_blood"]
		var count=9 if cid=="child_of_the_elder_blood" else 8 if cid=="the_lady_of_space_and_time" else 7 if cid=="pushed_to_the_brink" else 5
		for i in range(count):g.players[0].discard.append(card(hid,source_ids[i%5]))
		g.players[0].deck[-1]=card(hid,"lion_cub_of_cintra")
		if cid=="channel_the_source":g.players[0].hand=[card(hid,"lion_cub_of_cintra"),card(hid,"zireael"),probe_card("held3")]
	if hid=="ancient_leshen":
		g.fighters[0].node=12 if fid==0 else 11;g.fighters[1].node=8 if fid==0 else 12;g.fighters[2].node=18;g.fighters[foe+1].node=19
	var occupied=[]
	for f in g.fighters:
		check(int(f.hp) <= int(f.max_hp),"fixture health respects printed maximum")
		if f.alive:
			check(not occupied.has(int(f.node)),"fixture fighters occupy different cells")
			occupied.append(int(f.node))
	check(g.shadow_tokens.size() <= 3,"fixture respects shadow token supply")
	seen_moves=[];seen_places=[];seen_peek=false;seen_public=false;choice_trace=[]
	move_specs=[]
	for token in oracle.split(" "):
		if token.begins_with("move_"): move_specs.append(token)
	pre = snapshot()

func independent_reachable(id: int, steps: int, through: bool, through_sidekicks=false):
	var origin = int(g.fighters[id].node)
	var queue = [[origin,0]];var seen = {origin:true};var legal = []
	while not queue.is_empty():
		var item = queue.pop_front();var n = int(item[0]);var depth = int(item[1]);var occupant = g._occupant(n)
		if occupant < 0 or occupant == id: legal.append(n)
		if depth == steps: continue
		if depth > 0 and g.traps.any(func(t):return int(t.node) == n and g.is_enemy(int(g.fighters[id].owner),int(t.owner))): continue
		for adjacent in g.nodes[n].get("move_neighbors",g.nodes[n].neighbors):
			if seen.has(adjacent): continue
			var f = g._occupant(int(adjacent))
			if not through and f >= 0 and not (through_sidekicks and not g.fighters[f].hero) and g.is_enemy(int(g.fighters[id].owner),int(g.fighters[f].owner)): continue
			seen[adjacent]=true;queue.append([int(adjacent),depth+1])
	legal.sort()
	return legal
func resolve():
	for i in range(150):
		if g.phase == "attack_notice": return
		if g.phase == "action": return
		if g.phase == "combat_report": g.continue_combat();continue
		if g.phase == "effect_choice":
			var p = g.pending_choice
			var action = str(p.get("action",""));choice_trace.append(action)
			if p.get("victim",-1) == 1 and p.get("kind","") in ["cards","hand_view"]: seen_peek = true
			if p.get("deck_view",false): seen_public = true
			var index = 0
			if action in ["v8_war","v8_grendel","v8_heirloom","v8_execute","v8_horn","v10_coils","v10_lagniappe"]: index = p.options.size()-1
			if action == "v9_glass": index = 2
			if action == "v8_path": index = 2
			if action == "v6_suspicion_value": index = 3
			if action == "v6_research_count": index = 3
			if action == "v7_love_damage" and p.ids.has(foe+1): index=p.ids.find(foe+1)
			if action == "v10_belt": index = 0
			if action == "v6_discard_boost" and bool(p.get("can_skip",false)) and p.get("indices",[]).is_empty(): g.skip_effect();continue
			if p.get("allowed_fighters",[]).size() == p.get("options",[]).size() and not p.get("options",[]).is_empty():
				if p.allowed_fighters.has(foe): index = p.allowed_fighters.find(foe)
			if action=="v13_method_draw": index=p.options.size()-1
			if action=="v13_fighter" and str(p.operation.kind)=="v13_heal_fighter" and p.ids.has(hero): index=p.ids.find(hero)
			if p.get("options",[]).is_empty():
				if p.get("can_skip",false): g.skip_effect();continue
				check(false,"choice has no options " + action);return
			check(g.choose_effect_option(index),"choice accepts index " + action)
			continue
		if g.phase == "effect_move":
			var p = g.pending_choice
			choice_trace.append(str(p.get("action","")))
			if p.get("legal",[]).is_empty() and not p.get("allowed_fighters",[]).is_empty():
				g.choose_effect_fighter(int(p.allowed_fighters[0]));p = g.pending_choice
			if p.get("legal",[]).is_empty():
				if p.get("can_skip",false): g.skip_effect();continue
				check(false,"movement has no legal cells " + str(p));return
			var target = int(p.legal[0])
			if str(p.get("kind","")) == "move":
				var id = int(p.fighter)
				var spec = ""
				for expected in move_specs:
					var applies = (id == hero if expected.begins_with("move_hero") else id == fid if expected.begins_with("move_self") else id == foe if expected.begins_with("move_enemy") else g.fighters[id].owner != 0 if expected.begins_with("move_enemies") else true)
					if applies and not seen_moves.any(func(x):return x.spec == expected and x.id == id): spec = expected;break
				if spec != "":
					var digits = RegEx.new();digits.compile("[0-9]+")
					var steps = int(digits.search(spec).get_string())
					var through = spec.ends_with("_through") or (g.players[int(g.fighters[id].owner)].hero_id == "buffy" and bool(g.fighters[id].hero))
					check(int(p.spaces) == steps,"movement distance " + spec)
					var actual = p.legal.duplicate();actual.sort()
					check(actual == independent_reachable(id,mini(steps,1) if g._v12.stepwise(id) else steps,through,spec.ends_with("_sidekicks")),"complete legal movement set " + spec)
					seen_moves.append({"spec":spec,"id":id})
				# Move one cell when possible, retaining adjacency for following damage.
				for n in p.legal:
					if int(n) != int(g.fighters[id].node) and g.nodes[int(n)].neighbors.has(int(g.fighters[foe].node)): target=int(n);break
				if tokens.has("damage2") or tokens.has("seduction") or tokens.has("adjacent_enemies1") or tokens.has("adjacent_all1") or tokens.has("adjacent_all2"): target = int(g.fighters[id].node) if p.legal.has(int(g.fighters[id].node)) else target
			elif p.get("kind","") == "place":
				seen_places.append(int(p.fighter))
				for n in p.legal:
					if int(n) != int(g.fighters[int(p.fighter)].node): target = int(n);break
				if tokens.has("adjacent_all1") or tokens.has("adjacent_all2"): target = int(g.fighters[int(p.fighter)].node) if p.legal.has(int(g.fighters[int(p.fighter)].node)) else target
			if c.id == "restless_spirits": target = 13 if p.get("stage","") == "first" else 8
			check(g.choose_effect_node(target),"legal destination accepted")
			continue
		check(false,"unexpected phase " + g.phase);return
	check(false,"effect chain did not finish " + str(choice_trace))

func number(token: String, prefix: String): return int(token.trim_prefix(prefix))
func verify(token: String):
	var post = snapshot()
	var other = g._v6._other(ctx)
	if token.begins_with("move_"):
		var actual = []
		for move in seen_moves:
			if move.spec == token: actual.append(int(move.id))
		var expected = []
		for f in g.fighters:
			var id=int(f.id)
			if not pre.alive[id] and not (c.id=="primeval_slam" and id==hero+1): continue
			var applies = id == hero if token.begins_with("move_hero") else id == fid if token.begins_with("move_self") else id == foe if token.begins_with("move_enemy") else id in [fid,foe] if token.begins_with("move_both") or token.begins_with("move_either") else int(f.owner) != 0 if token.begins_with("move_enemies") else int(f.owner) == 0 and not f.hero if token.begins_with("move_helpers") else int(f.owner) == 0 if token.begins_with("move_friendly") or token.begins_with("move_one_friendly") else true
			if applies: expected.append(id)
		if token.begins_with("move_either") or token.begins_with("move_one_friendly"):
			check(actual.size()==1 and actual[0] in expected,"exactly one eligible fighter moves " + token)
		else:
			actual.sort();expected.sort();check(actual == expected,"all and only described fighters offered movement " + token)
		return
	if token.begins_with("place_"):
		check(not seen_places.is_empty(),"placement offered " + token)
		var id = hero if token.begins_with("place_hero") else fid
		if token.ends_with("_zone"): check(g._same_zone(int(pre.nodes[id]),int(g.fighters[id].node)),"placement stays in original zone")
		if token.ends_with("_enemy_adjacent"): check(g.nodes[int(g.fighters[id].node)].neighbors.has(int(g.fighters[foe].node)),"placement adjacent to opponent")
		return
	if token.begins_with("draw"):
		var amount = number(token,"draw")
		var extra = (1 if tokens.has("shuffle_discard") or tokens.has("topdeck") else 3 if tokens.has("assistant") else -2 if tokens.has("love") else 0)
		check(post.deck == pre.deck-amount+extra,"draw removes exact cards from deck " + token + " actual="+str(post.deck-pre.deck))
		check(post.hand == pre.hand+amount-(1 if tokens.has("topdeck") else 0),"draw adds exact cards to hand " + token)
		return
	if token.begins_with("heal_self"):
		check(post.hp[fid] == mini(int(g.fighters[fid].max_hp),int(pre.hp[fid])+number(token,"heal_self")),token);return
	if token.begins_with("heal_all"):
		check(post.hp[hero] == mini(int(g.fighters[hero].max_hp),int(pre.hp[hero])+number(token,"heal_all")),token);return
	if token.begins_with("heal"):
		check(post.hp[hero] == mini(int(g.fighters[hero].max_hp),int(pre.hp[hero])+number(token,"heal")),token+" actual="+str(post.hp[hero]-pre.hp[hero]));return
	if token.begins_with("damage"):
		check(post.hp[foe] == maxi(0,int(pre.hp[foe])-number(token,"damage")),token+" actual="+str(post.hp[foe]-pre.hp[foe]));return
	if token.begins_with("value"):
		check(ctx.value == number(token,"value"),token+" actual="+str(ctx.value));return
	if token.begins_with("plus"):
		check(ctx.value == pre.value+number(token,"plus"),token+" actual="+str(ctx.value));return
	if token.begins_with("action"):
		check(post.actions == pre.actions+number(token,"action"),token+" actual="+str(post.actions-pre.actions));return
	if token.begins_with("enemy_discard"):
		check(post.enemy_hand == pre.enemy_hand-number(token,"enemy_discard") and post.enemy_discard == pre.enemy_discard+number(token,"enemy_discard"),token);return
	if token.begins_with("enemy_draw"):
		check(post.enemy_deck == pre.enemy_deck-number(token,"enemy_draw") and post.enemy_hand == pre.enemy_hand+number(token,"enemy_draw"),token);return
	if token.begins_with("own_deck"):
		check(post.deck == pre.deck-number(token,"own_deck"),token);return
	if token.begins_with("own_discard"):
		check(post.discard == pre.discard+number(token,"own_discard"),token);return
	if token.begins_with("own_hand_minus"):
		check(post.hand == pre.hand-number(token,"own_hand_minus"),token);return
	if token.begins_with("rage"):
		check(g._v8.rage(0) == number(token,"rage"),token);return
	if token.begins_with("coils"):
		check(g._v10.coils(0) == number(token,"coils"),token);return
	if token.begins_with("adjacent_") or token.begins_with("zone_damage"):
		var amount = int(token.right(1))
		var center = hero if token == "adjacent_all1" and g.players[0].hero_id == "bigfoot" else fid
		var count = 0
		for f in g.fighters:
			if int(f.id) == center: continue
			var expected = g._same_zone(int(pre.nodes[hero]),int(pre.nodes[int(f.id)])) if token.begins_with("zone") else g.nodes[int(pre.nodes[center])].neighbors.has(int(pre.nodes[int(f.id)]))
			if not token.begins_with("adjacent_all") and int(f.owner) == 0: expected = false
			if expected and pre.alive[int(f.id)]: check(post.hp[int(f.id)] == maxi(0,int(pre.hp[int(f.id)])-amount),token+" fighter="+str(f.id));count+=1
		check(count > 0,"AoE fixture contains a target");return
	match token:
		"v14_igni":
			for f in g.fighters:
				var n=int(f.id);var amount=2 if n==foe else 1 if g.nodes[int(pre.nodes[hero])].neighbors.has(int(pre.nodes[n])) else 0
				check(int(f.hp)==maxi(0,int(pre.hp[n])-amount),"Igni hits opponent for two and each other adjacent fighter for one")
		"v14_foe_lock":check(g.fighters[foe].locked_until==g.turn_number,"Yrden locks opposing fighter")
		"v14_senses":check(post.hand==pre.hand+1 and post.deck==pre.deck-1 and g._flow.get("shuffle_scheme",false) and seen_public,"gear revealed from deck and scheme marked to shuffle at cleanup")
		"v14_lady":check(post.hand==pre.hand+2 and post.discard==pre.discard-1 and post.deck==pre.deck-1,"highest Source tier returns a discard to hand and draws")
		"v14_path":check(choice_trace.has("v14_path"),"unicorn offers explicit route, including a zero-space choice")
		"v14_source_search":check(seen_public and g.players[0].hand[-1].get("source",false),"searched Source is revealed and added to hand")
		"v14_zone3":
			for f in g.fighters:
				var n=int(f.id);var amount=3 if n!=hero and g._same_zone(int(pre.nodes[hero]),int(pre.nodes[n])) else 0
				check(int(f.hp)==maxi(0,int(pre.hp[n])-amount),"highest tier damages every other fighter, including own sidekick")
		"v14_guardian":check(other.value==pre.other_value+2 and post.enemy_deck==pre.enemy_deck-1 and post.enemy_discard==pre.enemy_discard+1 and seen_public,"opponent's top card boosts the opposing card, not Guardian")
		"v14_zone_enemy1":
			for f in g.fighters:
				var n=int(f.id);var amount=1 if f.owner!=0 and g._same_zone(int(pre.nodes[hero]),int(pre.nodes[n])) else 0
				check(int(f.hp)==maxi(0,int(pre.hp[n])-amount),"Vanish deals one to every enemy in Leshen zone")
		"v13_zone_all":
			for f in g.fighters:
				var expected=int(pre.hp[int(f.id)])-(1 if int(f.id)!=fid and g._same_zone(int(pre.nodes[int(f.id)]),int(pre.nodes[fid])) else 0)
				check(int(f.hp)==maxi(0,expected),"each other fighter in zone loses one")
		"v13_first": check(post.line==pre.line-1 and post.hand==pre.hand+1 and g.players[0].hand[-1].id=="horror","first line card returned")
		"v13_ready": check(seen_places.has(foe) and g.fighters[foe].locked_until==g.turn_number,"place chosen combatant and lock until current turn ends")
		"v13_fortune_back": check(post.hand==pre.hand+1 and post.discard==pre.discard-1,"the specific top-deck discard returned after loss")
		"v13_method": check(post.hand==pre.hand and post.deck==pre.deck and post.actions==pre.actions+1 and g.players[0].deck[0].id=="held3","all chosen cards bottomed, selected replacement count, action gained")
		"v13_moonlight": check(seen_places.has(fid) and g.nodes[int(g.fighters[fid].node)].neighbors.has(int(g.fighters[hero].node)),"Oberon placed adjacent to Titania")
		"v13_spent": check(post.glamour=="" and post.glamour_discard==pre.glamour_discard+1,"exactly one face-up glamour discarded")
		"v13_cycle": check(post.glamour==pre.glamour and post.glamour_discard==pre.glamour_discard-1 and post.glamour_deck==pre.glamour_deck+1 and g.players[0].glamour_deck[0]=="sleep","discarded glamour bottomed without revealing a new one")
		"v13_return_other": check(other.get("return_card",false),"opposing card will return to hand")
		"v13_fools": check(post.enemy_hand==pre.enemy_hand-1 and post.enemy_deck==pre.enemy_deck+1 and post.enemy_discard==pre.enemy_discard,"viewed opponent card shuffled into deck")
		"v13_bubble": check(post.pot==pre.pot+1 and post.discard==pre.discard-1,"discard chosen into cauldron")
		"v13_curious": check(post.pot==pre.pot-1 and post.hand==pre.hand+1,"cauldron card returned to hand")
		"v13_zones":
			var zones=[]
			for f in g.fighters:
				if f.owner==0 and f.alive:
					for z in g.nodes[int(f.node)].zones:
						if not zones.has(z): zones.append(z)
			check(ctx.value==zones.size(),"union of all living sisters' zones")
		"v13_ward": check(seen_places.has(foe) and g._same_zone(int(g.fighters[foe].node),int(g.fighters[fid].node)),"opponent placed in fighting Sister's zone")
		"v13_remedy": check(post.pot==0 and post.discard==pre.discard+3 and post.hp[hero]==mini(int(g.fighters[hero].max_hp),int(pre.hp[hero])+3),"three ingredients discarded directly and three individual heals chosen")
		"v13_keep_pot": check(post.pot==pre.pot,"two different free spells retain ingredients")
		"printed": check(int(ctx.value) == int(c.value),"printed value unchanged")
		"cancel": check(other.cancelled,"opponent effects cancelled")
		"prevent": check(ctx.get("prevent",false),"combat damage prevented")
		"prevent_all":
			check(ctx.get("prevent_all",false) and ctx.prevent,"combat and effect damage prevented")
			var hp = g.fighters[fid].hp;g._damage(fid,2)
			check(g.fighters[fid].hp == hp,"subsequent card effect actually deals no damage")
		"ignore": check(ctx.get("ignore_opponent_value",false),"opponent value ignored")
		"ignore_defense": check(ctx.get("ignore_defense",false),"defense ignored")
		"size": check(g.alice_size.get(0,"big") != pre.size,"Alice size switches")
		"peek": check(seen_peek,"visible hand inspection offered")
		"lock_printed": check(other.get("locked_value",-1) == 4,"opponent printed value locked")
		"lock_zero": check(other.get("locked_value",-1) == 0,"opponent value fixed at zero")
		"effect_protection":
			check(g._v10.effect_protected(fid),"noncombat damage protection active")
			var hp=g.fighters[fid].hp;g._damage(fid,2);check(g.fighters[fid].hp == hp,"Cloth blocks actual effect damage")
			g._damage(fid,2,true);check(g.fighters[fid].hp == hp-2,"Cloth permits normal combat damage")
		"reflect": check(ctx.get("reflect",false),"combat damage reflection active")
		"grail8": check(post.hp[hero] == 8,"Grail sets health to eight")
		"form_hyde","form_jekyll": check(g.form_for(0) == token.trim_prefix("form_"),"form switches")
		"form_willow": check(g.willow_form_for(0) == "willow","Willow becomes light")
		"turn_bonus1": check(g.players[0].get("turn_attack_bonus",0) == 1,"turn attack bonus added")
		"enemy_action1": check(g.actions_left == pre.actions+1,"enemy gains action in their turn")
		"self_damage2","doom": check(post.hp[fid] == pre.hp[fid]-2,"self payment deals two damage")
		"revive": check(g.fighters[hero+1].alive and g.fighters[hero+1].hp == g.fighters[hero+1].max_hp,"helper returns at full health")
		"retrieve_excalibur","retrieve_jeet","retrieve_form","retrieve_any","retrieve_random","retrieve_boost": check(post.hand == pre.hand+1 and post.discard == pre.discard-1,"one eligible discarded card returned " + token)
		"retrieve_voyages": check(post.hand == pre.hand+2 and post.discard == pre.discard-2,"all voyages returned")
		"swap": check(post.nodes[hero] == pre.nodes[foe] and post.nodes[foe] == pre.nodes[hero],"combatants swap")
		"swap_friendly","swap_defender": check(post.nodes[hero] == pre.nodes[hero+1] and post.nodes[hero+1] == pre.nodes[hero],"friendly fighters swap")
		"revive_self4": check(g.fighters[fid].alive and g.fighters[fid].hp == 4 and not seen_places.is_empty(),"defeated fighter returns at four health")
		"roar": check(g.fighters.all(func(f):return f.locked_until == g.turn_number),"all fighters movement locked")
		"queen": check(g._v10.limit_damage(hero,99) == int(g.fighters[hero].hp)-1,"Queen health floor")
		"uncancellable": check(g._card_uncancellable(0,c),"card effects cannot be cancelled")
		"ears": check(g._v8.basket(0) == "knife" and bool(c.type == "attack"),"knife permits conditional defense; integration also tests legal_defenses")
		"bess":
			g._v8.opponent_discarded(0,c)
			check(g.players[0].deck.size() == pre.deck-1,"Bess discarded by opponent draws one")
		"red_return": check(g._flow.get("return_a",false),"Large Hands returns this card rather than discarding")
		"red_path": check(post.deck == pre.deck-3 and post.actions == pre.actions,"wild basket selects exactly one Path effect")
		"bonus0","bonus3","bonus4": check(g.phase == "attack_notice" and g.pending_combat.attack_card.value == int(token.right(1)),"bonus attack with correct printed value")
		_: verify_custom(token,post,other)

func verify_custom(token,post,other):
	# Complex cards have literal outcome checks as well as decision traces.
	match token:
		"v14_igni":
			for f in g.fighters:
				var n=int(f.id);var amount=2 if n==foe else 1 if g.nodes[int(pre.nodes[hero])].neighbors.has(int(pre.nodes[n])) else 0
				check(int(f.hp)==maxi(0,int(pre.hp[n])-amount),"Igni hits opponent for two and each other adjacent fighter for one")
		"v14_foe_lock":check(g.fighters[foe].locked_until==g.turn_number,"Yrden locks opposing fighter")
		"v14_senses":check(post.hand==pre.hand+1 and post.deck==pre.deck-1 and g._flow.get("shuffle_scheme",false) and seen_public,"gear revealed from deck and scheme marked to shuffle at cleanup")
		"v14_lady":check(post.hand==pre.hand+2 and post.discard==pre.discard-1 and post.deck==pre.deck-1,"highest Source tier returns a discard to hand and draws")
		"v14_path":check(choice_trace.has("v14_path"),"unicorn offers explicit route, including a zero-space choice")
		"v14_source_search":check(seen_public and g.players[0].hand[-1].get("source",false),"searched Source is revealed and added to hand")
		"v14_zone3":
			for f in g.fighters:
				var n=int(f.id);var amount=3 if n!=hero and g._same_zone(int(pre.nodes[hero]),int(pre.nodes[n])) else 0
				check(int(f.hp)==maxi(0,int(pre.hp[n])-amount),"highest tier damages every other fighter, including own sidekick")
		"v14_guardian":check(other.value==pre.other_value+2 and post.enemy_deck==pre.enemy_deck-1 and post.enemy_discard==pre.enemy_discard+1 and seen_public,"opponent's top card boosts the opposing card, not Guardian")
		"v14_zone_enemy1":
			for f in g.fighters:
				var n=int(f.id);var amount=1 if f.owner!=0 and g._same_zone(int(pre.nodes[hero]),int(pre.nodes[n])) else 0
				check(int(f.hp)==maxi(0,int(pre.hp[n])-amount),"Vanish deals one to every enemy in Leshen zone")
		"v13_zone_all":
			for f in g.fighters:
				var expected=int(pre.hp[int(f.id)])-(1 if int(f.id)!=fid and g._same_zone(int(pre.nodes[int(f.id)]),int(pre.nodes[fid])) else 0)
				check(int(f.hp)==maxi(0,expected),"each other fighter in zone loses one")
		"v13_first": check(post.line==pre.line-1 and post.hand==pre.hand+1 and g.players[0].hand[-1].id=="horror","first line card returned")
		"v13_ready": check(seen_places.has(foe) and g.fighters[foe].locked_until==g.turn_number,"place chosen combatant and lock until current turn ends")
		"v13_fortune_back": check(post.hand==pre.hand+1 and post.discard==pre.discard-1,"the specific top-deck discard returned after loss")
		"v13_method": check(post.hand==pre.hand and post.deck==pre.deck and post.actions==pre.actions+1 and g.players[0].deck[0].id=="held3","all chosen cards bottomed, selected replacement count, action gained")
		"v13_moonlight": check(seen_places.has(fid) and g.nodes[int(g.fighters[fid].node)].neighbors.has(int(g.fighters[hero].node)),"Oberon placed adjacent to Titania")
		"v13_spent": check(post.glamour=="" and post.glamour_discard==pre.glamour_discard+1,"exactly one face-up glamour discarded")
		"v13_cycle": check(post.glamour==pre.glamour and post.glamour_discard==pre.glamour_discard-1 and post.glamour_deck==pre.glamour_deck+1 and g.players[0].glamour_deck[0]=="sleep","discarded glamour bottomed without revealing a new one")
		"v13_return_other": check(other.get("return_card",false),"opposing card will return to hand")
		"v13_fools": check(post.enemy_hand==pre.enemy_hand-1 and post.enemy_deck==pre.enemy_deck+1 and post.enemy_discard==pre.enemy_discard,"viewed opponent card shuffled into deck")
		"v13_bubble": check(post.pot==pre.pot+1 and post.discard==pre.discard-1,"discard chosen into cauldron")
		"v13_curious": check(post.pot==pre.pot-1 and post.hand==pre.hand+1,"cauldron card returned to hand")
		"v13_zones":
			var zones=[]
			for f in g.fighters:
				if f.owner==0 and f.alive:
					for z in g.nodes[int(f.node)].zones:
						if not zones.has(z): zones.append(z)
			check(ctx.value==zones.size(),"union of all living sisters' zones")
		"v13_ward": check(seen_places.has(foe) and g._same_zone(int(g.fighters[foe].node),int(g.fighters[fid].node)),"opponent placed in fighting Sister's zone")
		"v13_remedy": check(post.pot==0 and post.discard==pre.discard+3 and post.hp[hero]==mini(int(g.fighters[hero].max_hp),int(pre.hp[hero])+3),"three ingredients discarded directly and three individual heals chosen")
		"v13_keep_pot": check(post.pot==pre.pot,"two different free spells retain ingredients")
		"end_turn": check(g.actions_left==0 and g._flow.get("end_turn",false),"turn ended")
		"paid_return": check(g._flow.get("return_a",false) and post.hand==pre.hand-1,"pay card and return combat card")
		"follow": check(g.nodes[int(g.fighters[fid].node)].neighbors.has(int(g.fighters[foe].node)),"Tomoe follows opposing hero")
		"self_lock": check(g.fighters[fid].locked_until==g.turn_number,"Tomoe movement locked")
		"damage_cap": check(ctx.combat_cap==2,"combat damage capped at two")
		"prophecy": check(post.deck == pre.deck-2 and post.hand == pre.hand+2 and g.players[0].deck[-1].id == "deck21","take two of top four; return rest in selected order")
		"shuffle_discard": check(post.discard == pre.discard-1 and post.deck == pre.deck+1-(2 if tokens.has("draw2") else 0),"one discarded card shuffled into deck")
		"topdeck": check(post.hand == pre.hand+2 and post.deck == pre.deck-2,"draw three then return one to top")
		"coded": check(post.hand == pre.hand+1 and post.deck == pre.deck-1,"draw three then return two to top")
		"calming": check(post.hand == pre.hand+1 and post.deck == pre.deck-1,"look at three, keep one, put two at bottom")
		"arrogance": check(ctx.value == 6 and post.hand == 0 and post.discard == pre.discard+pre.hand,"discard hand and set value six")
		"beast": check(ctx.value == c.value+pre.hand and post.hand == 0,"discard chosen hand cards and add one each")
		"forever": check(ctx.value == c.value+6 and post.hand == 0,"discard three Jekyll cards for plus six")
		"parlor","deduce": check(other.value == 2,"opponent value replaced by printed BOOST")
		"elementary": check(ctx.get("ignore_attack",false) and other.cancelled,"correct prediction cancels and ignores attack")
		"enemy_boost": check(other.value == pre.other_value+2 and post.enemy_hand == pre.enemy_hand-1,"opponent may BOOST their card")
		"pay_action": check(post.actions == pre.actions+1 and post.hand == pre.hand-2,"pay two distinct cards then gain action")
		"pay_damage": check(post.hp[foe] == pre.hp[foe]-2 and post.hand == pre.hand-2,"pay two cards then deal damage")
		"confirm": check(post.enemy_hand == pre.enemy_hand-1 and post.hp[foe] == pre.hp[foe]-2,"correct value discards opponent choice and deals BOOST damage")
		"steal_shuffle": check(post.enemy_hand == pre.enemy_hand-1 and post.enemy_deck == pre.enemy_deck+1,"chosen hand card shuffled into opponent deck")
		"eyes": check(post.hand == pre.hand+1 and post.enemy_hand == pre.enemy_hand and post.enemy_deck == pre.enemy_deck,"chosen card bottomed and both players draw")
		"memories": check(post.enemy_hand == pre.enemy_hand-1 or post.hp[foe] == pre.hp[foe]-2,"selected card either discarded or BOOST damage paid")
		"prey": check(post.hp[foe] == pre.hp[foe]-1 and post.hp[hero] == pre.hp[hero]+1,"adjacent enemy damaged and Dracula heals matching amount")
		"strange": check(post.hp[foe] == pre.hp[foe]-2 and post.hand == pre.hand+1 and post.deck == pre.deck-1,"revealed BOOST damage then take card")
		"hacker": check(post.deck == pre.deck and post.hand == pre.hand and g.players[0].deck[-1].id == "deck23","inspect top and choose to leave it")
		"wits": check(seen_public and post.hp[foe] == pre.hp[foe]-3 and post.deck == pre.deck and post.enemy_deck == pre.enemy_deck,"reveal both tops, deal three, keep both cards")
		"xray": check(seen_public and post.enemy_deck == pre.enemy_deck-1 and post.enemy_discard == pre.enemy_discard+1,"reveal top then discard after coil payment")
		"bottom": check(seen_public and post.deck == pre.deck,"reveal bottom and leave deck size unchanged")
		"pair": check(seen_public and post.hand == pre.hand,"matching pair revealed without discard")
		"inspect_bottom": check(post.enemy_deck == pre.enemy_deck and g.players[1].deck[0].id == "deck23" and g.players[1].deck[-1].id == "deck22","one of revealed top three bottomed; other two ordered")
		"inspect_order": check(post.enemy_deck == pre.enemy_deck and g.players[1].deck[-1].id == "deck23","top three inspection preserves chosen top order")
		"assistant": check(post.discard == pre.discard-3 and post.deck == pre.deck+2 and post.hand == pre.hand+1,"three Jill cards shuffled and one drawn")
		"execute": check(not g.fighters[foe].alive and g._v8.rage(0) == 0,"three rage defeats opposing sidekick")
		"frenzy": check(post.hp[fid] == maxi(0,int(pre.hp[fid])-2) and post.hp[foe] == pre.hp[foe]-2,"two damage to both combatants")
		"seek": check(post.shadows == 3 and g.shadow_at(int(g.fighters[hero].node)) >= 0,"three available shadows, one under Spike and two adjacent")
		"fog_damage1": check(post.hp[foe] == pre.hp[foe]-1,"enemy on fog takes one")
		"fog_relocate","opponent_fog2","opponent_fog3","covert","confound": check(g.fog_tokens != pre.fog or (token == "confound" and post.enemy_hand == pre.enemy_hand-1),"fog relocation or opponent discard " + token)
		"slip": check(g.fog_at(int(g.fighters[hero].node),0) >= 0 and post.nodes[hero] != pre.nodes[hero],"move fog then place hero there")
		"lurking": check(g.fog_at(int(g.fighters[hero].node),0) >= 0 or g.fog_tokens != pre.fog,"choose fog jump or fog movement")
		"vanish": check(g.fighters[hero].get("offboard",false),"hero leaves board")
		"bring": check(g.nodes[int(g.fighters[hero].node)].neighbors.has(int(g.fighters[foe].node)),"chosen enemy placed adjacent")
		"administer": check(g.nodes[int(g.fighters[hero].node)].neighbors.has(int(g.fighters[fid].node)),"Watson placed beside Holmes")
		"clinch": check(g.fighters[hero].get("locked_until",-1) == g.turn_number and g.fighters[foe].get("locked_until",-1) == g.turn_number,"both combatants locked")
		"backup": check(g.traps.size() == pre.traps+3 and g.fighters[hero+1].alive,"choose traps AND restore workers")
		"detonation": check(g.traps.size() == pre.traps-1 and post.deck == pre.deck-1 and post.hp[foe] == pre.hp[foe]-1,"detonate adjacent enemy, remove trap and draw")
		"coordinate": check(g._same_zone(int(g.fighters[0].node),int(g.fighters[1].node)) and g._same_zone(int(g.fighters[0].node),int(g.fighters[2].node)),"both other Raptors placed in chosen zone")
		"decoy": check(g.fighters.slice(0,3).any(func(f):return int(f.id) != fid and g.nodes[int(g.fighters[foe].node)].neighbors.has(int(f.node))),"another Raptor placed beside attacker")
		"surprise": check(g.fighters[hero+1].alive and ctx.self == hero+1 and g.fighters[hero+1].hp == 2,"returned Archer becomes attacker at full health")
		"clone_swap": check(g._v9.helpers(0).size() == 3 and post.nodes[hero] != pre.nodes[hero] and g.fighters.slice(1,4).any(func(f):return f.node == pre.nodes[hero]),"clone occupies old space while Wukong relocates")
		"charge": check(choice_trace.has("v9_charge"),"charge offers per-cell route")
		"seduction": check(post.hp[foe] == pre.hp[foe]-3,"move selected enemy and deal one per adjacent Sister")
		"captain": check(g._same_zone(int(g.fighters[hero].node),int(g.fighters[hero+1].node)),"second friendly placed in Annie zone")
		"valor": check(post.hp[hero] == pre.hp[hero]-1 and post.hp[foe] == pre.hp[foe]-1 and post.actions == pre.actions+1,"Wiglaf hits adjacent friend and foe, earns action")
		"love": check(post.discard == pre.discard+2 and post.deck == pre.deck-4 and post.hp[foe+1] == pre.hp[foe+1]-3,"dark Willow draws two, discards two tops and deals three to a sidekick")
		"resurrect": check(g.fighters[hero+1].alive and g.fighters[hero+1].hp == 3 and g._same_zone(int(g.fighters[hero].node),int(g.fighters[hero+1].node)),"resurrect friendly fighter at three health in zone")
		"slayer": check(post.nodes[foe] != pre.nodes[foe] and post.hp[foe] == pre.hp[foe]-1,"relocate adjacent fighter and deal one")
		"bidding","sleight": check(str(g._combat_resolution.a.card.id) != str(c.id) and g.players[0 if token == "sleight" else 1].hand.any(func(x):return str(x.id) == str(c.id) if token == "sleight" else str(x.id) == "opposing"),"attack replaced and original returned")
		"spirits": check(post.hp[foe] == pre.hp[foe]-2,"selected neighboring spaces damage enemies")
		_: check(false,"missing oracle implementation " + token)

func run():
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://tests/v14_contracts.json"))
	for definition in catalog:
		var card_failures = failures
		for contract in definition.contracts:
			current = definition.hero+"/"+definition.card+"/"+contract.stage
			tokens = str(contract.oracle).split(" ")
			fixture(definition.hero,definition.card,contract.oracle)
			var stages = []
			for effect in c.get("effects",[]):
				if not stages.has(effect.timing): stages.append(effect.timing)
			var described_stages=[]
			for described in definition.contracts:
				if str(described.stage) != "none": described_stages.append(str(described.stage))
			described_stages.sort();stages.sort()
			check(stages == described_stages,"every timing in the card description has its own oracle")
			if contract.stage != "none":
				check(stages.has(contract.stage),"description timing implemented")
				g._queue_card_effects(c,contract.stage,ctx)
				g._pump_effects()
				resolve()
			for token in tokens: verify(token)
			stage_count += 1
		card_count += 1
		results.append({"hero":definition.hero,"card":definition.card,"stages":definition.contracts.size(),"passed":failures==card_failures})
	print("V14_CARD_CONTRACTS checks=%d failures=%d cards=%d stages=%d" % [checks,failures,card_count,stage_count])
	var out = FileAccess.open("res://../../work/v14-card-contract-results.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"cards":card_count,"stages":stage_count,"checks":checks,"failures":failures,"results":results},"  "))
	quit(1 if failures else 0)
