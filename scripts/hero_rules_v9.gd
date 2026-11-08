extends "res://scripts/hero_rules_v8.gd"
## Battle of Legends 2. Interruptions and nested bonus combats are serializable.
func _init(engine): super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra = {}, optional = false):
	super._options(action,labels,ctx,extra,optional)
	e.pending_choice.action = "v9_"+action
func condition(effect: Dictionary, ctx: Dictionary) -> bool:
	return not bool(effect.get("third_action",false)) or (int(ctx.owner) == e.active and int(e.players[int(ctx.owner)].get("actions_taken",0)) == 3)
func helpers(owner: int, alive = true) -> Array:
	var ids = []
	for f in e.fighters:
		if int(f.owner) == owner and not f.hero and bool(f.alive) == alive: ids.append(int(f.id))
	return ids
func enraged(owner: int) -> bool:
	return e._is_hero(owner,"achilles") and helpers(owner).is_empty()
func setup():
	for f in e.fighters:
		if not f.hero and e._is_hero(int(f.owner),"sun_wukong"): f.alive = false; f.hp = 0; f.reserve = true
func start_turn() -> bool:
	var owner = e.active
	if e._is_hero(owner,"bloody_mary") and e.players[owner].hand.size() == 3:
		if e.gain_actions(owner,1): e._log("Кровавая Мэри: ровно 3 карты — дополнительное действие.")
	if e._is_hero(owner,"sun_wukong"):
		e._start_ability(owner,"Призыв клона",[{"kind":"v9_clone_start"}],"start_turn")
		return true
	return false
func defeated(fid: int):
	var f = e.fighters[fid]
	if not f.hero and e._is_hero(int(f.owner),"achilles"):
		e._force_discard(int(f.owner),2,true)
		e._log("Патрокл повержен: Ахиллес сбрасывает 2 случайные карты и впадает в гнев.")
func protected(fid: int) -> bool:
	for slot in ["a","d"]:
		var ctx = e._combat_resolution.get(slot,{})
		if int(ctx.get("self",-1)) == fid and bool(ctx.get("prevent_all",false)) and not bool(ctx.get("cancelled",false)): return true
	return false
func archers(fid: int) -> Array:
	var ids = []
	if not e._valid_fighter(fid) or not e.fighters[fid].hero or not e._is_hero(int(e.fighters[fid].owner),"yennenga"): return ids
	for id in helpers(int(e.fighters[fid].owner)):
		if e._same_zone(int(e.fighters[fid].node),int(e.fighters[id].node)): ids.append(id)
	return ids
func intercept_damage(fid: int, amount: int) -> bool:
	var ids = archers(fid)
	if ids.is_empty() or amount <= 0: return false
	if human(int(e.fighters[fid].owner)):
		var job = {"effect":{"kind":"v9_damage","fighter":fid,"amount":amount},"ctx":{"owner":int(e.fighters[fid].owner),"self":fid,"opponent":-1,"opponent_owner":-1,"card":{"name":"Защита лучников"},"won":false}}
		if e._flow.is_empty(): e._deferred_damage.append(job)
		else: e._effect_queue.push_front(job)
	else:
		for id in ids:
			var assigned = mini(amount,int(e.fighters[id].hp))
			e._damage_raw(id,assigned)
			amount -= assigned
		e._damage_raw(fid,amount)
	return true
func flush_damage():
	if e._deferred_damage.is_empty(): return
	e._flow = {"kind":"ability","stage":"effects","completion":"maneuver","effect_logs":[]}
	e.combat_report = {"kind":"ability","title":"Защита лучников"}
	e._effect_queue = e._deferred_damage.duplicate(true)
	e._deferred_damage.clear()
	e._pump_effects()
func combat_damage(fid: int, amount: int) -> bool:
	if not human(int(e.fighters[fid].owner)) or archers(fid).is_empty() or amount <= 0: return false
	_damage_choice(fid,amount,true)
	return true
func _damage_choice(fid: int, amount: int, combat: bool):
	var ids = archers(fid)
	if ids.is_empty():
		e._damage_raw(fid,amount)
		if combat: e._finish_combat_damage()
		return
	var labels = ["Оставшийся урон Йенненге: %d" % amount]
	var all_archers = []
	for f in e.fighters:
		if int(f.owner) == int(e.fighters[fid].owner) and not f.hero: all_archers.append(int(f.id))
	for id in ids: labels.append("Передать 1 урон лучнику №%d · %d ОЗ" % [all_archers.find(id)+1,int(e.fighters[id].hp)])
	_options("damage",labels,{"owner":int(e.fighters[fid].owner),"self":fid,"card":{"name":"Защита лучников"}},{"ids":ids,"allowed_fighters":[fid]+ids,"amount":amount,"combat":combat,"prompt":"Распределите урон по одному очку или оставьте остаток Йенненге"})
func fighter_high_ground(a: int,b: int) -> int:
	for origin in e._v19.spaces(a):
		for target in e._v19.spaces(b):
			if high_ground(int(origin),int(target))>0:return 1
	return 0
func high_ground(a: int, b: int) -> int:
	for edge in e.board_data.get("high_ground",[]):
		if int(edge[0]) == a and int(edge[1]) == b: return 1
	return 0
func bonus(effect: Dictionary, ctx: Dictionary):
	var fid = int(ctx.self)
	var target = int(ctx.opponent)
	if not e._valid_fighter(fid) or not e._valid_fighter(target): return
	var defense = e._combat_resolution.get("d",{}).get("card",{})
	if bool(effect.get("requires_defense",false)) and defense.is_empty(): return
	var card = {"id":"bonus_attack","name":str(effect.name),"type":"attack","fighter":"any","boost":int(ctx.card.get("boost",0)),"value":int(effect.value),"text":"Бонусная атака","effects":[],"effect":"none","virtual":true}
	if bool(effect.get("reprise",false)) and not defense.is_empty(): card.effects = [{"kind":"v9_set_value","timing":"during","value":int(defense.get("value",0))}]; card.effect = "bonus"
	if effect.has("bonus_card"):card=effect.bonus_card.duplicate(true)
	ctx.bonus_started = true
	e._combat_stack.append({"flow":e._flow.duplicate(true),"queue":e._effect_queue.duplicate(true),"resolution":e._combat_resolution.duplicate(true),"pending":e.pending_combat.duplicate(true),"report":e.combat_report.duplicate(true)})
	e._effect_queue.clear()
	e.pending_combat = {"attacker":fid,"target":target,"attack_owner":int(ctx.owner),"defender_owner":int(e.fighters[target].owner),"attack_card":card,"boost":0,"boosted":false}
	e._flow = {"kind":"bonus_pending","effect_logs":[]}
	if e.interactive: e.phase = "attack_notice"
	else: e._begin_defense()
func resume_parent() -> bool:
	if e._combat_stack.is_empty(): return false
	var state = e._combat_stack.pop_back()
	e._flow = state.flow
	e._effect_queue = state.queue
	e._combat_resolution = state.resolution
	e.pending_combat = state.pending
	e.combat_report = state.report
	e._pump_effects()
	return true
func _spaces(action: String, legal: Array, ctx: Dictionary, extra = {}, optional = false):
	e.pending_choice = {"kind":"spaces","action":"v9_"+action,"title":str(ctx.card.get("name","Эффект")),"prompt":"Выберите свободную клетку","legal":legal,"allowed_fighters":[],"fighter":-1,"can_skip":optional,"_ctx":ctx.duplicate(true)}
	e.pending_choice.merge(extra,true)
	e.phase = "effect_move"
func _free(zone = -1, adjacent = -1) -> Array:
	var legal = []
	for node in e.nodes:
		if e._occupant(int(node.id)) >= 0: continue
		if zone >= 0 and not e._same_zone(zone,int(node.id)): continue
		if adjacent >= 0 and not e.nodes[adjacent].neighbors.has(int(node.id)): continue
		legal.append(int(node.id))
	return legal
func _clone(ctx: Dictionary, sly: bool):
	var owner = int(ctx.owner)
	var hero = e.hero_fighter(owner)
	if not e._valid_fighter(hero): return
	if sly and int(e.fighters[hero].get("locked_until",-1)) == e.turn_number: return
	var legal = _free(int(e.fighters[hero].node) if sly else -1,-1 if sly else int(e.fighters[hero].node))
	if legal.is_empty(): return
	var ids = helpers(owner,false)
	if ids.is_empty(): ids = helpers(owner)
	if ids.is_empty(): return
	if human(owner) and ids.size() > 1: _fighters("clone_token",ids,ctx); e.pending_choice.sly = sly
	else: _clone_space(ctx,int(ids[0]),sly)
func _clone_space(ctx: Dictionary, id: int, sly: bool):
	var hero = e.hero_fighter(int(ctx.owner))
	var origin = int(e.fighters[hero].node)
	var legal = _free(origin if sly else -1,-1 if sly else origin)
	if human(int(ctx.owner)): _spaces("clone",legal,ctx,{"token":id,"sly":sly,"origin":origin})
	elif not legal.is_empty(): _put_clone(ctx,id,int(legal[0]),sly,origin)
func _put_clone(ctx: Dictionary, id: int, node: int, sly: bool, origin: int):
	if sly: e._enter_node(e.hero_fighter(int(ctx.owner)),node); node = origin
	else: e._damage_raw(e.hero_fighter(int(ctx.owner)),1)
	if not e.players[int(ctx.owner)].alive: return
	e.fighters[id].alive = true
	e.fighters[id].reserve = false
	e.fighters[id].hp = 1
	e._enter_node(id,node)
func _revive_archer(ctx: Dictionary, surprise: bool):
	var owner = int(ctx.owner)
	var center = int(ctx.opponent) if surprise else e.hero_fighter(owner)
	if not e._valid_fighter(center):
		if surprise and owner == e.active: e.gain_actions(owner,1)
		return
	var ids = helpers(owner,false)
	var legal = _free(int(e.fighters[center].node))
	if ids.is_empty() or legal.is_empty():
		if surprise and owner == e.active: e.gain_actions(owner,1)
		return
	if human(owner): _spaces("archer",legal,ctx,{"token":int(ids[0]),"surprise":surprise},surprise)
	else: _put_archer(ctx,int(ids[0]),int(legal[0]),surprise)
func _put_archer(ctx: Dictionary, fid: int, node: int, surprise: bool):
	e.fighters[fid].alive = true
	e.fighters[fid].hp = 2
	e._enter_node(fid,node)
	if surprise:
		ctx = _live(ctx)
		ctx.self = fid
		e._v6._other(ctx).opponent = fid
		e._combat_resolution.ctx.attacker = fid
func _opponent(kind: String, ctx: Dictionary):
	var ids = []
	var labels = []
	for p in range(e.players.size()):
		if e.is_enemy(int(ctx.owner),p) and not e.is_dormant(p): ids.append(p); labels.append(e._player_name(p))
	if ids.is_empty(): return
	if human(int(ctx.owner)) and ids.size() > 1: _options("opponent",labels,ctx,{"ids":ids,"effect_kind":kind})
	else: _peek(kind,ctx,int(ids[0]))
func _peek(kind: String, ctx: Dictionary, victim: int):
	ctx.opponent_owner = victim
	ctx._peek_target_chosen = true
	if e._v8.guard_effect({"kind":"v9_"+kind},ctx): return
	if e.players[victim].hand.is_empty():
		if kind == "eyes": e._draw(int(ctx.owner),1); e._draw(victim,1)
		return
	if human(int(ctx.owner)): _cards(kind,victim,"hand",range(e.players[victim].hand.size()),ctx)
	else: _peek_selected(kind,ctx,victim,e._lowest_card(victim,true))
func _peek_selected(kind: String, ctx: Dictionary, victim: int, index: int):
	if kind == "eyes":
		e.players[victim].deck.push_front(e.players[victim].hand.pop_at(index))
		e._draw(int(ctx.owner),1)
		e._draw(victim,1)
	else:
		if human(victim): _options("memory_response",["Сбросить выбранную карту","Получить урон по BOOST"],_with_owner(ctx,victim),{"victim":victim,"index":index,"original_ctx":ctx,"cards":[e.players[victim].hand[index].duplicate(true)]})
		else: _memory_response(ctx,victim,index,e._card_quality(e.players[victim].hand[index]) <= 4.0)
func _memory_response(ctx: Dictionary, victim: int, index: int, discard: bool):
	if discard: e._discard_from_opponent(victim,e.players[victim].hand.pop_at(index),false)
	else: e._damage(e.hero_fighter(victim),int(e.players[victim].hand[index].boost))
func _offer_discard(kind: String, ctx: Dictionary):
	var victim = int(ctx.opponent_owner)
	if human(victim) and not e.players[victim].hand.is_empty():
		var copy = ctx.duplicate(true)
		copy.owner = victim
		_cards("offer_discard",victim,"hand",range(e.players[victim].hand.size()),copy,{"original_ctx":ctx.duplicate(true),"effect_kind":kind},true)
	else:
		if not e.players[victim].hand.is_empty(): e._force_discard(victim,1,false,false,false)
		else: _decline_discard(kind,ctx)
func _decline_discard(kind: String, ctx: Dictionary):
	if kind == "taunt": _live(ctx).ignore_opponent_value = true
	else: _revive_archer(ctx,false)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner = int(ctx.owner)
	var fid = int(ctx.get("self",-1))
	var opponent = int(ctx.get("opponent",-1))
	match str(effect.kind):
		"v9_bonus": bonus(effect,ctx)
		"v9_damage": _damage_choice(int(effect.fighter),int(effect.amount),false)
		"v9_frenzy": e._damage(opponent,2); e._damage(fid,2)
		"v9_doom":
			if not e._valid_fighter(fid): return true
			if human(owner): _options("doom",["Нанести Патроклу 2 урона: сила 5","Не наносить урон"],ctx)
			else: ctx.value = 5; e._damage(fid,2)
		"v9_brothers":
			if not helpers(owner).is_empty() and owner == e.active: e.gain_actions(owner,1)
		"v9_helm":
			if not helpers(owner).is_empty():
				if human(owner): _options("helm",["Поменяться с Патроклом","Остаться"],ctx)
				else: e._v8._swap(ctx,true)
		"v9_enemy_action":
			if int(ctx.opponent_owner) == e.active: e.gain_actions(int(ctx.opponent_owner),1)
		"v9_set_value": ctx.value = int(effect.value)
		"v9_glass":
			if human(owner): _options("glass",["Оставить силу","Сила −1","Сила +1"],ctx)
			else:
				var other = e._v6._other(ctx)
				ctx.value = int(ctx.value)+(clampi(int(other.value)-int(ctx.value),-1,1) if abs(int(other.value)-int(ctx.value)) <= 1 else 1)
		"v9_glass_after":
			var other = e._v6._other(ctx)
			if int(ctx.value) == int(other.get("value",-1)): e._draw(owner,1); e._damage(opponent,2)
		"v9_jump":
			if e._valid_fighter(fid) and fid < e.turn_start_nodes.size() and not e._same_zone(int(e.fighters[fid].node),int(e.turn_start_nodes[fid])): ctx.value = 6
		"v9_mirror": ctx.value = int(e._v6._other(ctx).get("card",{}).get("value",0))
		"v9_memories", "v9_eyes":
			var kind = str(effect.kind).trim_prefix("v9_")
			if bool(ctx.get("_peek_target_chosen",false)): _peek(kind,ctx,int(ctx.opponent_owner))
			else: _opponent(kind,ctx)
		"v9_clone_start":
			if not _free(-1,int(e.fighters[fid].node)).is_empty():
				if human(owner): _options("clone_start",["Получить 1 урон и призвать клона","Пропустить"],ctx)
				elif int(e.fighters[fid].hp) > 2: _clone(ctx,false)
		"v9_infinite":
			if e._valid_fighter(opponent):
				for f in e.fighters:
					if int(f.id) != fid and e._valid_fighter(int(f.id),owner) and e.fighters_adjacent(opponent,int(f.id)): ctx.value += 1
		"v9_taunt": _offer_discard("taunt",ctx)
		"v9_shield": _offer_discard("shield",ctx)
		"v9_forms":
			var ids = []
			for i in range(e.players[owner].discard.size()):
				if str(e.players[owner].discard[i].id) in ["ox_form","tortoise_form","phoenix_form"]: ids.append(i)
			if not ids.is_empty():
				if human(owner): _cards("form",owner,"discard",ids,ctx)
				else: e.players[owner].hand.append(e.players[owner].discard.pop_at(int(ids[0])))
		"v9_sly":
			if e.fighters[fid].hero: _clone(ctx,true)
		"v9_prevent_all": ctx.prevent = true; ctx.prevent_all = true
		"v9_reflect": ctx.reflect = true
		"v9_phoenix": e._heal(e.hero_fighter(owner),helpers(owner).size())
		"v9_surprise": _revive_archer(ctx,true)
		"v9_divide":
			var hero = e.hero_fighter(owner)
			if e._valid_fighter(hero) and not e._same_zone(int(e.fighters[fid].node),int(e.fighters[hero].node)): ctx.value = 4
		"v9_point_blank":
			var hero = e.hero_fighter(owner)
			if e._valid_fighter(hero) and e._valid_fighter(opponent) and e.fighters_adjacent(hero,opponent): e._damage(opponent,2)
		"v9_jaws":
			if e._valid_fighter(opponent): ctx.value += e.nodes[int(e.fighters[opponent].node)].zones.size()
		"v9_heal_all":
			for f in e.fighters:
				if int(f.owner) == owner: e._heal(int(f.id),1)
		"v9_charge": _charge(ctx)
		_: return false
	return true
func _charge(ctx: Dictionary):
	var fid = e.hero_fighter(int(ctx.owner))
	if not e._valid_fighter(fid) or int(e.fighters[fid].get("locked_until",-1)) == e.turn_number: return
	var state = {"fighter":fid,"position":int(e.fighters[fid].node),"steps":5,"passed":[],"origin":int(e.fighters[fid].node),"visited":[int(e.fighters[fid].node)]}
	if human(int(ctx.owner)): _charge_step(state,ctx)
	else:
		var queue = [[state.position,[],[state.position]]]
		var best = queue[0]
		var best_score = -1.0
		while not queue.is_empty():
			var path = queue.pop_front()
			var node = int(path[0])
			if e._occupant(node) in [-1,fid]:
				var score = path[1].size()*5+e._position_score(fid,node)*0.01
				if score > best_score: best_score = score; best = path
			if path[2].size() > 5: continue
			if node != state.origin and e._enemy_trap_at(node,int(ctx.owner)) >= 0: continue
			for next in e.nodes[node].get("move_neighbors",e.nodes[node].neighbors):
				if path[2].has(int(next)): continue
				var hits = path[1].duplicate()
				var occupant = e._occupant(int(next))
				if occupant >= 0 and e.is_enemy(int(ctx.owner),int(e.fighters[occupant].owner)) and not hits.has(occupant): hits.append(occupant)
				queue.append([int(next),hits,path[2]+[int(next)]])
		state.position = int(best[0]); state.passed = best[1];state.visited=best[2]; _charge_finish(state,ctx)
func _charge_step(state: Dictionary, ctx: Dictionary):
	var legal = []
	for n in e.nodes[int(state.position)].get("move_neighbors",e.nodes[int(state.position)].neighbors):
		if e._enemy_trap_at(int(n),int(ctx.owner)) >= 0 and e._occupant(int(n)) >= 0: continue
		if int(state.steps) > 1 or e._occupant(int(n)) in [-1,int(state.fighter)]: legal.append(int(n))
	var can_end = e._occupant(int(state.position)) in [-1,int(state.fighter)]
	if int(state.steps) <= 0 or legal.is_empty() or (int(state.position) != int(state.origin) and e._enemy_trap_at(int(state.position),int(ctx.owner)) >= 0):
		_charge_finish(state,ctx)
		return
	_spaces("charge",legal,ctx,{"route":state,"prompt":"Маршрут: выберите следующую клетку. Осталось шагов: %d" % int(state.steps)},can_end)
func _charge_finish(state: Dictionary, ctx: Dictionary):
	if e._v12.stepwise(int(state.fighter)):
		var reached=[]
		for node in state.get("visited",[int(state.origin),int(state.position)]).slice(1):
			if not e._valid_fighter(int(state.fighter)): break
			var target=e._occupant(int(node))
			var trapped=e._enemy_trap_at(int(node),int(ctx.owner))>=0
			if target>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[target].owner)) and not reached.has(target): reached.append(target)
			e._enter_node(int(state.fighter),int(node))
			if trapped: break
		state.passed=reached
	else: e._enter_node(int(state.fighter),int(state.position))
	e._damage_many(state.passed,1)
func choose_node(node: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if not p.get("legal",[]).has(node): return false
	e.pending_choice.clear()
	match str(p.action):
		"v9_clone": _put_clone(p._ctx,int(p.token),node,bool(p.sly),int(p.origin))
		"v9_archer": _put_archer(p._ctx,int(p.token),node,bool(p.surprise))
		"v9_charge":
			p.route.position = node
			if not p.route.has("visited"): p.route.visited=[int(p.route.origin)]
			p.route.visited.append(node)
			p.route.steps = int(p.route.steps)-1
			var occupant = e._occupant(node)
			if occupant >= 0 and e.is_enemy(int(p._ctx.owner),int(e.fighters[occupant].owner)) and not p.route.passed.has(occupant): p.route.passed.append(occupant)
			_charge_step(p.route,p._ctx)
		_: return false
	if e.pending_choice.is_empty(): _resume()
	else: e.changed.emit()
	return true
func skip() -> bool:
	var p = e.pending_choice.duplicate(true)
	if not bool(p.get("can_skip",false)): return false
	e.pending_choice.clear()
	match str(p.action):
		"v9_charge": _charge_finish(p.route,p._ctx)
		"v9_archer":
			if bool(p.surprise) and int(p._ctx.owner) == e.active: e.gain_actions(int(p._ctx.owner),1)
		"v9_offer_discard": _decline_discard(str(p.effect_kind),p.original_ctx)
	if e.pending_choice.is_empty(): _resume()
	else: e.changed.emit()
	return true
func choose_option(index: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if index < 0 or index >= p.get("options",[]).size(): return false
	var ctx = _live(p._ctx)
	e.pending_choice.clear()
	match str(p.action).trim_prefix("v9_"):
		"damage":
			var remaining = int(p.amount)
			if index > 0:
				e._damage_raw(int(p.ids[index-1]),1)
				remaining -= 1
				if remaining > 0 and not archers(int(ctx.self)).is_empty(): _damage_choice(int(ctx.self),remaining,bool(p.combat)); e.changed.emit(); return true
			e._damage_raw(int(ctx.self),remaining)
			if bool(p.combat): e._finish_combat_damage(); e.changed.emit(); return true
		"doom":
			if index == 0 and e._valid_fighter(int(ctx.self)): ctx.value = 5; e._damage(int(ctx.self),2)
		"helm":
			if index == 0: e._v8._swap(ctx,true)
		"glass": ctx.value += [0,-1,1][index]
		"opponent": _peek(str(p.effect_kind),ctx,int(p.ids[index]))
		"eyes", "memories": _peek_selected(str(p.action).trim_prefix("v9_"),ctx,int(p.victim),int(p.indices[index]))
		"memory_response": _memory_response(p.original_ctx,int(p.victim),int(p.index),index == 0)
		"clone_start":
			if index == 0: _clone(ctx,false)
		"clone_token": _clone_space(ctx,int(p.ids[index]),bool(p.sly))
		"form": e.players[int(ctx.owner)].hand.append(e.players[int(ctx.owner)].discard.pop_at(int(p.indices[index])))
		"offer_discard": e._discard_from_opponent(int(p.victim),e.players[int(p.victim)].hand.pop_at(int(p.indices[index])),false)
		_: return false
	if e.pending_choice.is_empty(): _resume()
	else: e.changed.emit()
	return true
