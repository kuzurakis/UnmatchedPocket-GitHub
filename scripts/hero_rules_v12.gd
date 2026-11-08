extends "res://scripts/hero_rules_v8.gd"
func _init(engine): super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra = {}, optional = false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v12_"+action
func flanked(owner: int, fid: int) -> bool:
	if not e._valid_fighter(fid): return false
	var count=0
	for f in e.fighters:
		if e._valid_fighter(int(f.id),owner) and e.fighters_adjacent(int(f.id),fid): count+=1
	return count>=2
func inspire(fid: int) -> int:
	if not e._valid_fighter(fid): return 0
	var bonus=0
	for p in range(e.players.size()):
		if not e._is_hero(p,"oda_nobunaga") or not e.are_allies(p,int(e.fighters[fid].owner)): continue
		var h=e.hero_fighter(p)
		if h!=fid and e._valid_fighter(h) and e._same_zone(int(e.fighters[h].node),int(e.fighters[fid].node)): bonus+=1
	return bonus
func stepwise(fid: int) -> bool:
	if e._v36.stepwise(fid):return true
	if not e._valid_fighter(fid) or not e.fighters[fid].hero: return false
	for p in range(e.players.size()):
		if e._is_hero(p,"tomoe_gozen") and e.is_enemy(p,int(e.fighters[fid].owner)) and e._valid_fighter(e.hero_fighter(p)): return true
	return false
func departed(fid: int, old: int, destination: int, snapshots = {}):
	if not e.fighters[fid].hero: return
	for p in range(e.players.size()):
		if not e._is_hero(p,"tomoe_gozen") or not e.is_enemy(p,int(e.fighters[fid].owner)): continue
		var h=e.hero_fighter(p)
		if not e._valid_fighter(h): continue
		var anchor=int(snapshots.get(h,e.fighters[h].node))
		var was_in_zone=false
		for cell in snapshots.get("old_cells",[old]):
			for zone in e.nodes[anchor].zones:
				if e.nodes[int(cell)].zones.has(zone) and e._v8.zone_path_open(anchor,int(cell)):was_in_zone=true
		if was_in_zone and (destination<0 or not e._same_zone(anchor,destination)):
			e._log("Томоэ: герой покинул её зону — 1 урон.");e._damage(fid,1)
func adjacent(ctx: Dictionary) -> bool:
	return e._valid_fighter(int(ctx.self)) and e._valid_fighter(int(ctx.opponent)) and e.fighters_adjacent(int(ctx.self),int(ctx.opponent))
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.opponent)
	match str(effect.kind):
		"v12_flank_value":
			if flanked(owner,foe): ctx.value=5
		"v12_flank_cancel":
			if flanked(owner,foe): e._v6._cancel(ctx)
		"v12_flank_ignore":
			if flanked(owner,foe): ctx.ignore_opponent_value=true
		"v12_flank_heal":
			if flanked(owner,foe): e._heal(fid,2)
		"v12_reinforce":
			var options=[{"kind":"v12_heal_friends"},{"kind":"draw","amount":2},{"kind":"gain_action","amount":1}]
			if human(owner):
				e._begin_manual_effect({"kind":"choose_two","options":options},ctx);e.pending_choice.options=["Лечение всех дружественных бойцов","Взять 2 карты","Получить 1 действие"]
			else: _queue(options[1],ctx);_queue(options[0],ctx)
		"v12_heal_friends":
			for f in e.fighters:
				if e.are_allies(owner,int(f.owner)): e._heal(int(f.id),1)
		"v12_demon":
			var ids=[]
			for f in e.fighters:
				if e.is_enemy(owner,int(f.owner)) and flanked(owner,int(f.id)): ids.append(int(f.id))
			e._damage_many(ids,2)
		"v12_guard_swap","v12_adjacent_swap":
			var ids=[]
			if e._valid_fighter(fid):
				for f in e.fighters:
					if e._valid_fighter(int(f.id)) and e.fighters_adjacent(fid,int(f.id)) and (str(effect.kind)=="v12_adjacent_swap" or e.are_allies(owner,int(f.owner))): ids.append(int(f.id))
			if not ids.is_empty():
				if human(owner): _options("swap",ids.map(func(id):return str(e.fighters[id].name)),ctx,{"ids":ids,"guard":str(effect.kind)=="v12_guard_swap"},true)
				else: _swap_to(ctx,int(ids[0]),str(effect.kind)=="v12_guard_swap")
		"v12_hero_cancel":
			if foe>=0 and e.fighters[foe].hero: e._v6._cancel(ctx)
		"v12_adjacent_damage":
			if adjacent(ctx): e._damage(foe,1)
		"v12_adjacent_discard":
			if adjacent(ctx): _queue({"kind":"opponent_discard","amount":1},ctx)
		"v12_lock": e.fighters[fid].locked_until=e.turn_number
		"v12_damage_cap": ctx.combat_cap=2
		"v12_follow":
			if e._valid_fighter(foe) and e.fighters[foe].hero: _queue({"kind":"place","target":"self","adjacent_to":foe},ctx)
		"v12_return":
			if adjacent(ctx) and not e.players[owner].hand.is_empty():
				if human(owner): _cards("return",owner,"hand",range(e.players[owner].hand.size()),ctx,{},true)
				else: _pay_return(ctx,e._lowest_card(owner))
		"v12_end_turn": e._flow.end_turn=true;e.actions_left=0;e._effect_queue.clear()
		"v12_kiso":
			if human(owner): _options("kiso",["Восстановить 2 здоровья","Получить 1 действие"],ctx)
			else: e._heal(fid,2)
		_: return false
	return true
func _swap_to(ctx: Dictionary, other: int, guard: bool):
	ctx=_live(ctx)
	if not e._swap_combatants(int(ctx.self),other): return
	if guard:
		ctx.self=other;e._v6._other(ctx).opponent=other;e._combat_resolution.ctx.target=other
func _pay_return(ctx: Dictionary, index: int):
	e._discard(int(ctx.owner),e.players[int(ctx.owner)].hand.pop_at(index));e._flow["return_"+str(ctx.get("_combat_slot","a"))]=true
func skip() -> bool:
	if not e.pending_choice.get("can_skip",false): return false
	_resume();return true
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.get("options",[]).size(): return false
	e.pending_choice.clear();var ctx=_live(p._ctx)
	match str(p.action):
		"v12_swap": _swap_to(ctx,int(p.ids[index]),bool(p.guard))
		"v12_return": _pay_return(ctx,int(p.indices[index]))
		"v12_kiso":
			if index==0: e._heal(int(ctx.self),2)
			elif int(ctx.owner)==e.active: e.gain_actions(int(ctx.owner),1)
		_: return false
	_resume();return true
