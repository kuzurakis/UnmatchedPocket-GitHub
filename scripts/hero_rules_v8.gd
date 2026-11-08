extends RefCounted
## Little Red / Beowulf and Houdini / Genie. Mutable decisions stay in the save.
var _engine_ref
var e:
	get: return _engine_ref.get_ref()
func _init(engine): _engine_ref = weakref(engine)
func human(owner: int) -> bool:
	return e.interactive and owner >= 0 and owner < e.players.size() and not e.players[owner].bot
func basket(owner: int) -> String:
	if e.players[owner].discard.is_empty(): return "wild"
	var card = e.players[owner].discard[-1]
	if card.has("basket_symbol"): return str(card.basket_symbol)
	for definition in e.heroes[str(e.players[owner].hero_id)].cards:
		if str(definition.id) == str(card.get("id","")): return str(definition.get("basket_symbol","wild"))
	return "wild"
func migrate_basket_cards():
	for owner in range(e.players.size()):
		if not e._is_hero(owner,"little_red"): continue
		var copies = []
		for pile in ["deck","hand","discard"]:
			for card in e.players[owner][pile]:
				if str(card.get("id","")) == "into_the_woods": copies.append(card)
		if int(e._flow.get("owner",-1)) == owner and str(e._flow.get("card",{}).get("id","")) == "into_the_woods": copies.append(e._flow.card)
		var used = []
		for card in copies:
			if card.has("basket_copy"): used.append(int(card.basket_copy))
		for card in copies:
			if not card.has("basket_copy"):
				for id in range(3):
					if not used.has(id): card.basket_copy=id;used.append(id);break
			card.basket_copy = int(card.get("basket_copy",0))%3
			card.basket_symbol = ["pelt","knife","flower"][card.basket_copy]
func condition(effect: Dictionary, ctx: Dictionary) -> bool:
	return not effect.has("basket") or basket(int(ctx.owner)) in ["wild",str(effect.basket)]
func rage(owner: int) -> int:
	return int(e.players[owner].get("rage",1))
func add_rage(owner: int, amount: int):
	e.players[owner].rage = clampi(rage(owner)+amount,0,3)
	e._log("Ярость Беовульфа: %d/3." % rage(owner))
func _live(ctx: Dictionary) -> Dictionary:
	if str(e._flow.get("kind","")) == "combat_pre" and ctx.has("_combat_slot"): return e._combat_resolution[str(ctx._combat_slot)]
	return ctx
func _queue(effect: Dictionary, ctx: Dictionary):
	e._effect_queue.push_front({"effect":effect,"ctx":ctx.duplicate(true)})
func _options(action: String, labels: Array, ctx: Dictionary, extra = {}, optional = false):
	e.pending_choice = {"kind":"options","action":"v8_"+action,"title":str(ctx.card.get("name","Способность")),"prompt":"Выберите вариант","options":labels,"owner":int(ctx.owner),"viewer":int(ctx.owner),"legal":[],"fighter":-1,"allowed_fighters":[],"can_skip":optional,"_ctx":ctx.duplicate(true)}
	e.pending_choice.merge(extra,true)
	e.phase = "effect_choice"
func _cards(action: String, owner: int, source: String, indices: Array, ctx: Dictionary, extra = {}, optional = false):
	var cards = []
	for i in indices: cards.append(e.players[owner][source][int(i)].duplicate(true))
	if cards.is_empty(): return
	_options(action,[],ctx,{"kind":"cards","cards":cards,"indices":indices,"source":source,"victim":owner},optional)
	e.pending_choice.merge(extra,true)
	e._refresh_card_options()
func _resume():
	e.pending_choice.clear()
	e._pump_effects()
	e.changed.emit()
func start_turn() -> bool:
	if not e._is_hero(e.active,"genie"): return false
	e.players[e.active].fixed_four = false
	e._start_ability(e.active,"Безграничная сила",[{"kind":"v8_genie_start"}],"start_turn")
	return true
func _spend(ctx: Dictionary, action: String, costs: Array, labels: Array):
	var valid = []
	var opts = []
	for i in range(costs.size()):
		if action == "heirloom" and int(costs[i]) in [1,3] and e._best_boost(int(ctx.owner)) < 0: continue
		if int(costs[i]) <= rage(int(ctx.owner)):
			valid.append(int(costs[i]))
			opts.append(labels[i])
	if human(int(ctx.owner)): _options(action,opts,ctx,{"costs":valid})
	else: _spent(action,int(valid[-1]),ctx)
func _spent(action: String, cost: int, ctx: Dictionary):
	ctx = _live(ctx)
	var owner = int(ctx.owner)
	add_rage(owner,-cost)
	match action:
		"war": ctx.value = int(ctx.value)+2*cost
		"grendel":
			if cost > 0: _printed_damage(ctx)
		"execute":
			if cost > 0: e._damage(int(ctx.opponent),int(e.fighters[int(ctx.opponent)].hp))
		"heirloom":
			if cost in [2,3]: ctx.value = 5
			if cost in [1,3]: _queue({"kind":"optional_boost"},ctx)
		"horn":
			if cost <= 0: return
			var effects = [{"kind":"draw","amount":2},{"kind":"move","target":"hero","spaces":4},{"kind":"heal","target":"hero","amount":2}]
			if human(owner):
				e._begin_manual_effect({"kind":"choose_two","remaining_count":cost,"options":effects},ctx)
				e.pending_choice.options = ["Взять 2 карты","Передвинуть Беовульфа на 0–4 клетки","Восстановить 2 здоровья"]
			else:
				if int(e.fighters[e.hero_fighter(owner)].hp) < int(e.fighters[e.hero_fighter(owner)].max_hp)-1: effects.reverse()
				for i in range(cost-1,-1,-1): _queue(effects[i],ctx)
func _printed_damage(ctx: Dictionary):
	var other = e._v6._other(ctx)
	e._damage(int(ctx.opponent),int(other.get("card",{}).get("value",0)))
func _opponent(kind: String, ctx: Dictionary):
	var ids = []
	var labels = []
	for p in range(e.players.size()):
		if e.is_enemy(int(ctx.owner),p) and not e.is_dormant(p): ids.append(p); labels.append(e._player_name(p))
	if ids.is_empty(): return
	if human(int(ctx.owner)) and ids.size() > 1: _options("opponent",labels,ctx,{"ids":ids,"effect_kind":kind})
	else: _opponent_selected(kind,ctx,int(ids[0]))
func _opponent_selected(kind: String, ctx: Dictionary, victim: int):
	ctx.opponent_owner = victim
	if kind == "vigor":
		if e._v14.owl_protected(victim): return
		if e.players[victim].hand.is_empty(): return
		var card = e.players[victim].hand.pop_at(e.rng.randi_range(0,e.players[victim].hand.size()-1))
		e._discard(victim,card)
		opponent_discarded(victim,card)
		add_rage(int(ctx.owner),int(card.boost))
	else: _queue({"kind":"reveal_choose_discard","amount":1},ctx)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var kind = str(effect.get("kind",""))
	var owner = int(ctx.owner)
	var fid = int(ctx.get("self",-1))
	match kind:
		"right_hand_man_red":
			if e._valid_fighter(fid) and e._valid_fighter(int(ctx.opponent)) and e.fighters_adjacent(fid,int(ctx.opponent)): ctx.value = 6
		"v8_grimm": e._heal(e.hero_fighter(owner),4 if basket(owner) in ["wild","pelt"] else 2)
		"v8_ignore_value": ctx.ignore_opponent_value = true
		"v8_printed_damage": _printed_damage(ctx)
		"v8_red_hands":
			var symbol = basket(owner)
			var modes = []
			var labels = []
			if symbol != "flower": modes.append("self"); labels.append("Вернуть эту карту в руку")
			if symbol in ["flower","wild"] and not e.players[owner].discard.is_empty(): modes.append("basket"); labels.append("Вернуть верхнюю карту сброса")
			modes.append("leave")
			labels.append("Оставить карту")
			if human(owner): _options("red_hands",labels,ctx,{"modes":modes})
			elif modes[0] != "leave": _red_hands(ctx,modes[0] == "basket")
		"v8_red_path":
			var symbol = basket(owner)
			if symbol == "wild" and human(owner): _options("path",["Шкура: перенести и получить действие","Нож: 2 урона всем врагам в зоне","Цветок: взять 3 карты"],ctx)
			else: _red_path(symbol if symbol != "wild" else "flower",ctx)
		"v8_valor":
			if e._valid_fighter(fid):
				var hero_hit = false
				var ids = []
				for f in e.fighters:
					if e._valid_fighter(int(f.id)) and e.fighters_adjacent(fid,int(f.id)):
						ids.append(int(f.id))
						if int(f.id) == e.hero_fighter(owner): hero_hit = true
				e._damage_many(ids,1)
				if hero_hit and owner == e.active: e.gain_actions(owner,1)
		"v8_rage": add_rage(owner,int(effect.amount))
		"v8_epic": ctx.value = int(ctx.value)+rage(owner)
		"v8_war_king": _spend(ctx,"war",[0,1,2,3],["Не тратить ярость","1 ярость: сила +2","2 ярости: сила +4","3 ярости: сила +6"])
		"v8_grendel": _spend(ctx,"grendel",[0,2],["Не тратить ярость","2 ярости: нанести урон"])
		"v8_heirloom": _spend(ctx,"heirloom",[0,1,2,3],["Не тратить ярость","1 ярость: усилить карту","2 ярости: сила 5","3 ярости: сила 5 и усиление"])
		"v8_execute":
			if bool(ctx.won) and e._valid_fighter(int(ctx.opponent)) and not e.fighters[int(ctx.opponent)].hero: _spend(ctx,"execute",[0,3],["Не тратить ярость","3 ярости: победить помощника"])
		"v8_horn": _spend(ctx,"horn",[0,1,2,3],["Не тратить ярость","1 ярость: 1 эффект","2 ярости: 2 разных эффекта","3 ярости: все 3 эффекта"])
		"v8_vigor": _opponent("vigor",ctx)
		"v8_swap_wiglaf", "v8_smoke":
			if _own_pair(owner).size() == 2:
				if human(owner): _options("swap",["Поменяться местами","Остаться"],ctx,{"smoke":kind == "v8_smoke"})
				elif kind == "v8_smoke" and not e.fighters[fid].hero: _swap(ctx,true)
		"v8_fatal": e._draw(owner if bool(ctx.won) else int(ctx.opponent_owner),2)
		"v8_boost":
			if human(owner): e._begin_manual_effect({"kind":"optional_boost"},ctx)
			else:
				var index = e._best_boost(owner)
				if index >= 0: combat_boost(ctx,index)
		"v8_enemy_boost":
			var other = e._v6._other(ctx)
			if not other.get("card",{}).is_empty(): _queue({"kind":"v8_boost"},other)
		"v8_boost_discard":
			e._discard(owner,effect.boost_card)
			var held = e._flow.get("held_boosts",[])
			for i in range(held.size()):
				if held[i].card == effect.boost_card and int(held[i].owner) == owner: held.remove_at(i); break
		"v8_boost_damage":
			var ids = []
			for f in e.fighters:
				if e._valid_fighter(int(f.id)): ids.append(int(f.id))
			if human(owner): _fighters("boost_damage",ids,ctx)
			else:
				for id in ids:
					if e.is_enemy(owner,int(e.fighters[id].owner)): e._damage(id,2); break
		"v8_boost_peek": _opponent("peek",ctx)
		"v8_return_boost":
			var indices = []
			for i in range(e.players[owner].discard.size()):
				for b in e._flow.get("boosts",[]):
					if int(b.owner) == owner and b.card == e.players[owner].discard[i]: indices.append(i); break
			if not indices.is_empty():
				if human(owner): _cards("return_boost",owner,"discard",indices,ctx)
				else: e.players[owner].hand.append(e.players[owner].discard.pop_at(int(indices[0])))
		"v8_sleight":
			if e._combat_resolution.is_empty(): return true
			var indices = []
			for i in range(e.players[owner].hand.size()):
				var card = e.players[owner].hand[i]
				if card.id != ctx.card.id and e._attack_type(card) and e._card_usable(card,fid): indices.append(i)
			if not indices.is_empty():
				if human(owner): _cards("sleight",owner,"hand",indices,ctx,{},true)
				else: _sleight(ctx,int(indices[0]))
		"v8_topdeck":
			if human(owner): _cards("topdeck",owner,"hand",range(e.players[owner].hand.size()),ctx)
			elif not e.players[owner].hand.is_empty(): e.players[owner].deck.append(e.players[owner].hand.pop_at(e._lowest_card(owner)))
		"v8_show":
			if fid >= 0 and not e.fighters[fid].alive:
				e.fighters[fid].alive = true
				e.fighters[fid].hp = 4
				e.players[owner].alive = true
				_queue({"kind":"place","fixed_fighter":fid},ctx)
		"v8_next_trick":
			var ids = _own_pair(owner)
			if human(owner) and ids.size() > 1: _fighters("next_trick",ids,ctx)
			elif not ids.is_empty(): _queue({"kind":"move","fixed_fighter":int(ids[0]),"target":"self","spaces":1},_with_self(ctx,int(ids[0])))
		"v8_genie_start": _pay(ctx,1,"action")
		"v8_pay_action":
			if owner == e.active: _pay(ctx,2,"action")
		"v8_pay_damage":
			if not e._damage_candidates({"target":"opponent_adjacent_to_self"},ctx).is_empty(): _pay(ctx,2,"damage")
		"v8_more_wishes":
			e._draw(int(ctx.opponent_owner),1)
			e._draw(owner,3)
		"v8_three_wishes":
			if human(owner): _options("wish",["Взять 5 карт","Сила всех моих карт 4 до конца хода","Каждый соперник сбрасывает 2 карты"],ctx)
			else: _wish(0 if e.players[owner].hand.size() < 4 else 1,ctx)
		"v8_parlor":
			var other = e._v6._other(ctx)
			if not other.is_empty(): other.value = int(other.get("card",{}).get("boost",0))
		"v8_torment": e._draw(owner,int(ctx.get("damage_taken",0)))
		_: return false
	return true
func _own_pair(owner: int) -> Array:
	var ids = []
	for f in e.fighters:
		if int(f.owner) == owner and e._valid_fighter(int(f.id)): ids.append(int(f.id))
	return ids
func _with_self(ctx: Dictionary, fid: int) -> Dictionary:
	var copy = ctx.duplicate(true)
	copy.self = fid
	return copy
func _fighters(action: String, ids: Array, ctx: Dictionary):
	var labels = []
	for id in ids: labels.append("%s · %d ОЗ" % [e.fighters[int(id)].name,int(e.fighters[int(id)].hp)])
	if not ids.is_empty(): _options(action,labels,ctx,{"ids":ids})
func _red_hands(ctx: Dictionary, flower: bool):
	var owner = int(ctx.owner)
	if flower:
		if not e.players[owner].discard.is_empty(): e.players[owner].hand.append(e.players[owner].discard.pop_back())
	else: e._flow["return_"+str(ctx.get("_combat_slot","a"))] = true
func _red_path(symbol: String, ctx: Dictionary):
	match symbol:
		"pelt":
			_queue({"kind":"gain_action","amount":1},ctx)
			_queue({"kind":"place","target":"hero"},ctx)
		"knife":
			var hero = e.hero_fighter(int(ctx.owner))
			if not e._valid_fighter(hero): return
			var ids = []
			for f in e.fighters:
				if e._valid_fighter(int(f.id)) and e.is_enemy(int(ctx.owner),int(f.owner)) and e._same_zone(int(e.fighters[hero].node),int(f.node)): ids.append(int(f.id))
			e._damage_many(ids,2)
		"flower": e._draw(int(ctx.owner),3)
func _swap(ctx: Dictionary, smoke: bool):
	var ids = _own_pair(int(ctx.owner))
	if ids.size() != 2: return
	if not e._swap_combatants(int(ids[0]),int(ids[1])): return
	if smoke and ctx.has("_combat_slot"):
		ctx = _live(ctx)
		ctx.self = int(ids[1]) if int(ctx.self) == int(ids[0]) else int(ids[0])
		var other = e._v6._other(ctx)
		other.opponent = int(ctx.self)
		var slot = str(ctx._combat_slot)
		e._combat_resolution.ctx["attacker" if slot == "a" else "target"] = int(ctx.self)
func _sleight(ctx: Dictionary, index: int):
	ctx = _live(ctx)
	var owner = int(ctx.owner)
	e.players[owner].hand.append(ctx.card)
	e._v6._replace_attack(owner,index)
func combat_boost(ctx: Dictionary, index: int):
	ctx = _live(ctx)
	var owner = int(ctx.owner)
	var card = e.players[owner].hand.pop_at(index)
	ctx.value = int(ctx.value)+int(card.boost)
	if not e._flow.has("boosts"): e._flow.boosts = []
	e._flow.boosts.append({"owner":owner,"card":card.duplicate(true)})
	boosted(owner,card)
func boosted(owner: int, card: Dictionary, maneuver = false):
	if card.get("dice_boost",false):card.boost=0
	if e._is_hero(owner,"black_panther"):e._draw(owner,1)
	if not e._is_hero(owner,"houdini") and not card.get("_stolen_boost_effect",false):
		e._discard(owner,card)
		return
	if maneuver:
		e._flow = {"kind":"ability","stage":"effects","completion":"maneuver","effect_logs":[]}
		e.combat_report = {"kind":"ability","title":"Фокус усиления","effect_logs":[]}
	if not e._flow.has("held_boosts"): e._flow.held_boosts = []
	e._flow.held_boosts.append({"owner":owner,"card":card.duplicate(true)})
	var ctx = {"owner":owner,"self":e.hero_fighter(owner),"opponent":-1,"opponent_owner":-1,"card":card,"value":0,"won":false}
	_queue({"kind":"v8_boost_discard","boost_card":card},ctx)
	match str(card.id):
		"sleight_of_hand", "flourish": _queue({"kind":"draw","amount":1},ctx)
		"set_the_stage": _queue({"kind":"v8_boost_peek"},ctx)
		"misdirection": _queue({"kind":"v8_boost_damage"},ctx)
		"all_part_of_the_show": _queue({"kind":"heal","target":"hero","amount":2},ctx)
		"and_the_beautiful_bess":
			if owner == e.active: _queue({"kind":"gain_action","amount":1},ctx)
	if maneuver: e._pump_effects()
func _pay(ctx: Dictionary, count: int, benefit: String):
	var owner = int(ctx.owner)
	if e.players[owner].hand.size() < count: return
	if human(owner): _cards("pay",owner,"hand",range(e.players[owner].hand.size()),ctx,{"remaining_count":count,"benefit":benefit,"prompt":"Выберите карты для оплаты эффекта или пропустите"},true)
	elif e.players[owner].hand.size() >= count+1:
		for n in range(count): e._discard(owner,e.players[owner].hand.pop_at(e._lowest_card(owner)))
		_paid(ctx,benefit)
func _paid(ctx: Dictionary, benefit: String):
	if benefit == "action":
		if int(ctx.owner) == e.active: e.gain_actions(int(ctx.owner),1)
	else: _queue({"kind":"damage","target":"opponent_adjacent_to_self","amount":2},ctx)
func _wish(index: int, ctx: Dictionary):
	match index:
		0: e._draw(int(ctx.owner),5)
		1: e.players[int(ctx.owner)].fixed_four = true
		2:
			for p in range(e.players.size()-1,-1,-1):
				if e.is_enemy(int(ctx.owner),p):
					var copy = ctx.duplicate(true)
					copy.opponent_owner = p
					_queue({"kind":"opponent_discard","amount":2},copy)
func opponent_discarded(owner: int, card: Dictionary):
	if e._is_hero(owner,"houdini") and str(card.id) == "and_the_beautiful_bess": e._draw(owner,1)
func guard_effect(effect: Dictionary, ctx: Dictionary) -> bool:
	var victim = int(ctx.get("opponent_owner",-1))
	if e._card_uncancellable(int(ctx.owner),ctx.get("card",{})): return false
	if bool(effect.get("peek_allowed",false)) or bool(ctx.get("_peek_allowed",false)) or victim < 0 or not e._is_hero(victim,"houdini"): return false
	if str(effect.get("kind","")) not in ["v35_view","v34_look","v32_trouble","reveal_hand","reveal_choose_discard","stronger_than_skill","stronger_than_the_skill","eliminate_impossible","insight","the_sight","do_my_bidding","v9_eyes","v9_memories","v16_spy"]: return false
	if str(effect.kind) in ["eliminate_impossible","insight","the_sight","v9_eyes","v9_memories"] and human(int(ctx.owner)) and not bool(ctx.get("_peek_target_chosen",false)):
		var count = 0
		for p in range(e.players.size()):
			if e.is_enemy(int(ctx.owner),p) and not e.is_dormant(p): count += 1
		if count > 1: return false
	for card in e.players[victim].hand:
		if str(card.id) != "a_magician_never_reveals_his_secrets": continue
		if human(victim):
			_options("guard",["Раскрыть секрет: отменить просмотр","Разрешить просмотр"],_with_owner(ctx,victim),{"original_effect":effect.duplicate(true),"original_ctx":ctx.duplicate(true),"prompt":"Фокусник не раскрывает секретов: карта останется в вашей руке"})
		else: e._log("Гудини раскрывает «Фокусник не раскрывает секретов»: просмотр руки отменён.")
		return true
	return false
func _with_owner(ctx: Dictionary, owner: int) -> Dictionary:
	var copy = ctx.duplicate(true)
	copy.owner = owner
	return copy
func choose_option(index: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if index < 0 or index >= p.get("options",[]).size(): return false
	var ctx = _live(p._ctx)
	var owner = int(ctx.owner)
	var action = str(p.action).trim_prefix("v8_")
	e.pending_choice.clear()
	match action:
		"war", "grendel", "execute", "horn", "heirloom": _spent(action,int(p.costs[index]),ctx)
		"red_hands":
			if p.modes[index] != "leave": _red_hands(ctx,p.modes[index] == "basket")
		"path": _red_path(["pelt","knife","flower"][index],ctx)
		"opponent": _opponent_selected(str(p.effect_kind),ctx,int(p.ids[index]))
		"swap":
			if index == 0: _swap(ctx,bool(p.smoke))
		"boost_damage": e._damage(int(p.ids[index]),2)
		"next_trick": _queue({"kind":"move","target":"self","spaces":1},_with_self(ctx,int(p.ids[index])))
		"return_boost": e.players[owner].hand.append(e.players[owner].discard.pop_at(int(p.indices[index])))
		"topdeck": e.players[owner].deck.append(e.players[owner].hand.pop_at(int(p.indices[index])))
		"sleight": _sleight(ctx,int(p.indices[index]))
		"wish": _wish(index,ctx)
		"pay":
			# Reserve choices first so cancel never charges only half the price.
			var chosen = p.get("chosen",[])
			chosen.append(int(p.indices[index]))
			if int(p.remaining_count) > 1:
				p.cards.remove_at(index)
				p.indices.remove_at(index)
				p.remaining_count = int(p.remaining_count)-1
				p.chosen = chosen
				e.pending_choice = p
				e._refresh_card_options()
				e.phase = "effect_choice"
			else:
				chosen.sort()
				chosen.reverse()
				for i in chosen: e._discard(owner,e.players[owner].hand.pop_at(int(i)))
				_paid(ctx,str(p.benefit))
		"guard":
			if index == 1:
				p.original_effect.peek_allowed = true
				p.original_ctx._peek_allowed = true
				_queue(p.original_effect,p.original_ctx)
			else: e._log("Гудини раскрывает «Фокусник не раскрывает секретов»: просмотр руки отменён.")
		_: return false
	if not e.pending_choice.is_empty(): e.changed.emit()
	else: _resume()
	return true
func protects_from_defeat(fid: int) -> bool:
	for key in ["a","d"]:
		var ctx = e._combat_resolution.get(key,{})
		if int(ctx.get("self",-1)) == fid and str(ctx.get("card",{}).get("id","")) == "all_part_of_the_show": return true
	return false
func rebuild_doors():
	if not e.board_data.has("doors"): return
	for i in range(e.nodes.size()): e.nodes[i].neighbors = e._int_array(e.board_data.nodes[i].neighbors)
	for i in range(e.door_states.size()):
		if bool(e.door_states[i]):
			for edge in e.board_data.doors[i].edges:
				e.nodes[int(edge[0])].neighbors.erase(int(edge[1]))
				e.nodes[int(edge[1])].neighbors.erase(int(edge[0]))
func door_adjacent(fid: int, door: int) -> bool:
	if not e._valid_fighter(fid) or door < 0 or door >= e.door_states.size(): return false
	for edge in e.board_data.doors[door].edges:
		if e._v19.spaces(fid).any(func(n):return int(n) in [int(edge[0]),int(edge[1])]): return true
	return false
func toggle_door(fid: int, door: int) -> bool:
	if e.phase != "move" or not e._valid_fighter(fid,e.active) or not door_adjacent(fid,door): return false
	if e.fighters.any(func(f):return e._valid_fighter(int(f.id)) and f.has("friendly_transit") and int(f.id)!=fid):return false
	if e.maneuver_moved.has(fid) and int(e.door_active_fighter) != fid: return false
	if e.maneuver_moved.has(fid) and e._is_hero(e.active,"houdini") and e.fighters[fid].hero and e.maneuver_boosted:return false
	if not bool(e.door_states[door]):
		for f in e.fighters:
			if e._valid_fighter(int(f.id)) and e._v19.large(int(f.id)):
				var cells=e._v19.spaces(int(f.id))
				for edge in e.board_data.doors[door].edges:
					if cells.has(int(edge[0])) and cells.has(int(edge[1])):return false
	var spent = int(e.door_movement_spent.get(fid,0))
	if bool(e.door_states[door]) and e.fighters[fid].has("friendly_transit") and spent+1>=e._maneuver_budget(fid):return false
	if bool(e.door_states[door]) and (spent >= e._maneuver_budget(fid) or int(e.fighters[fid].get("locked_until",-1)) == e.turn_number): return false
	activate_fighter(fid)
	if bool(e.door_states[door]): e.door_movement_spent[fid] = spent+1
	e.door_states[door] = not bool(e.door_states[door])
	rebuild_doors()
	e._log("Дверь %d: %s." % [door+1,"закрыта" if bool(e.door_states[door]) else "открыта"])
	e.changed.emit()
	return true
func activate_fighter(fid: int):
	if e.door_active_fighter >= 0 and e.door_active_fighter != fid and not e.maneuver_moved.has(e.door_active_fighter): e.maneuver_moved.append(e.door_active_fighter)
	e.door_active_fighter = fid
func move_cost(fid: int, destination: int) -> int:
	for distance in range(e._maneuver_budget(fid)+1):
		if e._reachable(fid,distance).has(destination): return distance
	return e._maneuver_budget(fid)+1
func zone_path_open(a: int, b: int) -> bool:
	if not e.door_states.has(true): return true
	var original = _graph_distance(a,b,true)
	return _graph_distance(a,b,false) == original
func _graph_distance(a: int, b: int, original: bool) -> int:
	var queue = [[a,0]]
	var seen = {a:true}
	while not queue.is_empty():
		var next = queue.pop_front()
		if int(next[0]) == b: return int(next[1])
		var links = e.board_data.nodes[int(next[0])].neighbors if original else e.nodes[int(next[0])].neighbors
		for n in links:
			if not seen.has(int(n)): seen[int(n)] = true; queue.append([int(n),int(next[1])+1])
	return 999
