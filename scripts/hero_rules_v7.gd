extends RefCounted
## Buffy rules. Every choice and token lives in the engine save state.
var _engine_ref
var e:
	get: return _engine_ref.get_ref()
func _init(engine): _engine_ref = weakref(engine)
func _human(owner: int) -> bool:
	return e.interactive and owner >= 0 and owner < e.players.size() and not e.players[owner].bot
func condition(effect: Dictionary, ctx: Dictionary) -> bool:
	return not bool(effect.get("if_dark",false)) or e.willow_form_for(int(ctx.owner)) == "dark"
func _queue(effect: Dictionary, ctx: Dictionary):
	e._effect_queue.push_front({"effect":effect,"ctx":ctx.duplicate(true)})
func _resume():
	e.pending_choice.clear()
	e._pump_effects()
	e.changed.emit()
func _options(action: String, labels: Array, ctx: Dictionary, extra = {}, optional = false):
	e.pending_choice = {"kind":"options","action":"v7_"+action,"title":str(ctx.card.get("name","Способность")),"prompt":"Выберите вариант","options":labels,"owner":int(ctx.owner),"viewer":int(ctx.owner),"legal":[],"fighter":-1,"allowed_fighters":[],"can_skip":optional,"_ctx":ctx.duplicate(true)}
	e.pending_choice.merge(extra,true)
	e.phase = "effect_choice"
func _spaces(action: String, legal: Array, ctx: Dictionary, extra = {}, optional = false):
	e.pending_choice = {"kind":"spaces","action":"v7_"+action,"title":str(ctx.card.get("name","Способность")),"prompt":"Выберите клетку","legal":legal,"fighter":-1,"allowed_fighters":[],"can_skip":optional,"_ctx":ctx.duplicate(true)}
	e.pending_choice.merge(extra,true)
	e.phase = "effect_move"
func _cards(action: String, owner: int, source: String, ctx: Dictionary, extra = {}):
	_options(action,[],ctx,{"kind":"cards","victim":owner,"source":source,"cards":e.players[owner][source].duplicate(true)})
	e.pending_choice.merge(extra,true)
	e._refresh_card_options()
func start_turn() -> bool:
	if not e._is_hero(e.active,"spike") or e.is_dormant(e.active): return false
	e._start_ability(e.active,"Тени Спайка",[{"kind":"shadow_start"}],"start_turn")
	return true
func end_turn():
	var owner = e.active
	if not e._is_hero(owner,"willow") or e.willow_form_for(owner) != "dark": return
	var hero = e.hero_fighter(owner)
	if not e._valid_fighter(hero): return
	for f in e.fighters:
		if int(f.owner) == owner and not f.hero and e._valid_fighter(int(f.id)) and e.fighters_adjacent(int(f.id),hero):
			e.willow_form[owner] = "willow"
			return
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var kind = str(effect.get("kind",""))
	var owner = int(ctx.owner)
	var fid = int(ctx.get("self",-1))
	var opponent = int(ctx.get("opponent",-1))
	match kind:
		"daring_strike":
			if bool(ctx.won): e._draw(owner,2)
			else: e._damage(fid,1)
		"right_hand_man":
			var hero = e.hero_fighter(owner)
			if e._valid_fighter(fid) and e._valid_fighter(hero) and e.fighters_adjacent(hero,fid): ctx.value = 6
		"cartwheel_kick":
			_queue({"kind":"adjacent_damage","amount":1},ctx)
			_queue({"kind":"move","target":"hero","spaces":3},ctx)
		"slayer_s_strength": _slayer_strength(ctx)
		"slayer_move": _slayer_move(int(effect.fighter),ctx)
		"slayer_damage":
			e._damage_many(e._flow.get("slayer_moved",[]),1)
		"insight", "the_sight": _opponent_choice(kind,ctx)
		"shadow_start", "seek_shadow_one": _shadow_place(effect,ctx)
		"seek_the_shadows":
			e._draw(owner,2)
			e._flow.seek_shadow_ids = []
			e._flow.seek_shadow_nodes = []
			for n in range(2,-1,-1): _queue({"kind":"seek_shadow_one","step":n},ctx)
		"the_rush":
			if _combat_shadow(ctx): ctx.value = 5
		"empathy": e._draw(owner,3 if e._valid_fighter(opponent) and e.shadow_at(int(e.fighters[opponent].node)) >= 0 else 1)
		"always_surprising": _blind_boost(ctx,2 if e._valid_fighter(fid) and e.shadow_at(int(e.fighters[fid].node)) >= 0 else 1)
		"blind_boost": _blind_boost(ctx)
		"arrogance":
			if _human(owner): _options("arrogance",["Сбросить всю руку: сила 6","Оставить руку"],ctx)
			elif e.players[owner].hand.size() <= (3 if e.difficulty == 0 else 2): _arrogance(ctx)
		"bloody_hell":
			if e._valid_fighter(opponent):
				var spaces = []
				for token in e.shadow_tokens:
					if e.node_adjacent_to_fighter(int(token.node),opponent) and not spaces.has(int(token.node)): spaces.append(int(token.node))
				e._damage(opponent,1)
				e._damage(opponent,spaces.size())
		"let_s_dance":
			if _combat_shadow(ctx):
				if _human(owner): e._begin_manual_effect({"kind":"optional_boost"},ctx)
				else: e._run_effects({"effects":[{"timing":"queued","kind":"optional_boost"}]},"queued",ctx)
		"love_and_loss":
			e._draw(owner,2)
			if e.willow_form_for(owner) == "dark":
				_discard_top(owner,2)
				var ids = []
				var hero = e.hero_fighter(owner)
				if e._valid_fighter(hero):
					for f in e.fighters:
						if not f.hero and e._valid_fighter(int(f.id)) and e._same_zone(int(f.node),int(e.fighters[hero].node)): ids.append(int(f.id))
				if not ids.is_empty():
					if _human(owner): _fighter_options("love_damage",ids,ctx,"Выберите помощника в зоне Уиллоу: 3 урона")
					else:
						var enemies = []
						for id in ids:
							if e.is_enemy(owner,int(e.fighters[int(id)].owner)): enemies.append(id)
						e._damage(int(enemies[0] if not enemies.is_empty() else ids[0]),3)
		"meditation": e.willow_form[owner] = "willow"
		"hacker":
			if not e.players[owner].deck.is_empty():
				if _human(owner): _options("hacker",["Оставить сверху","Положить вниз"],ctx,{"cards":[e.players[owner].deck[-1].duplicate(true)],"prompt":"Посмотрите верхнюю карту и выберите её положение"})
				elif e._card_quality(e.players[owner].deck[-1]) < 3.0: e.players[owner].deck.push_front(e.players[owner].deck.pop_back())
		"when_good_magic_fails":
			_queue({"kind":"discard_top","amount":1},ctx)
			_queue({"kind":"place","target":"hero","same_zone":true},ctx)
		"discard_top": _discard_top(owner,int(effect.get("amount",1)))
		"knowledge_of_the_craft":
			if not e.players[owner].discard.is_empty():
				if _human(owner): _cards("retrieve",owner,"discard",ctx,{"prompt":"Выберите карту сброса для возвращения в руку"})
				else:
					var best = 0
					for i in range(e.players[owner].discard.size()):
						if e._card_quality(e.players[owner].discard[i]) > e._card_quality(e.players[owner].discard[best]): best = i
					e.players[owner].hand.append(e.players[owner].discard.pop_at(best))
		"resurrect": _resurrect(ctx)
		_: return false
	return true
func _fighter_options(action: String, ids: Array, ctx: Dictionary, prompt: String):
	var labels = []
	for id in ids: labels.append(str(e.fighters[int(id)].name))
	_options(action,labels,ctx,{"ids":ids,"prompt":prompt})
func _blind_boost(ctx: Dictionary, multiplier = 1):
	var owner = int(ctx.owner)
	if e.players[owner].deck.is_empty(): return
	var card = e.players[owner].deck.pop_back()
	e._discard(owner,card)
	ctx.value += int(card.get("boost",0)) * multiplier
	e._log("Слепое усиление: «%s», +%d." % [card.name,int(card.get("boost",0))*multiplier])
func _discard_top(owner: int, count: int):
	for n in range(mini(count,e.players[owner].deck.size())): e._discard(owner,e.players[owner].deck.pop_back(),"deck")
func _combat_shadow(ctx: Dictionary) -> bool:
	for id in [int(ctx.get("self",-1)),int(ctx.get("opponent",-1))]:
		if e._valid_fighter(id) and e.shadow_at(int(e.fighters[id].node)) >= 0: return true
	return false
func _arrogance(ctx: Dictionary):
	var owner = int(ctx.owner)
	while not e.players[owner].hand.is_empty(): e._discard(owner,e.players[owner].hand.pop_back())
	ctx.value = 6
	if ctx.has("_combat_slot"): e._combat_resolution[str(ctx._combat_slot)] = ctx
func _opponent_choice(kind: String, ctx: Dictionary):
	var enemies = []
	var labels = []
	for owner in range(e.players.size()):
		if e.is_enemy(int(ctx.owner),owner) and not e.is_dormant(owner):
			enemies.append(owner)
			labels.append(str(e.players[owner].name))
	if enemies.is_empty(): return
	if _human(int(ctx.owner)) and enemies.size() > 1: _options("opponent",labels,ctx,{"opponents":enemies,"effect_kind":kind,"prompt":"Выберите противника"})
	else: _opponent_selected(kind,ctx,int(ctx.get("opponent_owner",-1)) if enemies.has(int(ctx.get("opponent_owner",-1))) else int(enemies[0]))
func _opponent_selected(kind: String, ctx: Dictionary, victim: int):
	ctx.opponent_owner = victim
	ctx._peek_target_chosen = true
	if e._v8.guard_effect({"kind":kind},ctx): return
	var amount = 1
	if kind == "the_sight":
		for f in e.fighters:
			if int(f.owner) == victim and e._valid_fighter(int(f.id)) and e.shadow_at(int(f.node)) >= 0: amount = 2
	if e.players[victim].hand.is_empty(): e._reveal_hand(int(ctx.owner),victim,ctx)
	elif _human(int(ctx.owner)): _cards("hand_discard",victim,"hand",ctx,{"remaining_count":mini(amount,e.players[victim].hand.size()),"prompt":"Посмотрите руку и выберите карту для сброса"})
	else: e._force_discard(victim,amount,false,true)
func _slayer_strength(ctx: Dictionary):
	var hero = e.hero_fighter(int(ctx.owner))
	if not e._valid_fighter(hero): return
	var ids = []
	for f in e.fighters:
		if e._valid_fighter(int(f.id)) and e.fighters_adjacent(hero,int(f.id)): ids.append(int(f.id))
	if ids.is_empty(): return
	# "May move all fighters" is one decision, not a separate opt-in per fighter.
	if _human(int(ctx.owner)):
		_options("slayer_strength",["Переместить всех соседних бойцов","Не перемещать бойцов"],ctx,{"ids":ids})
	else: _queue_slayer_moves(ids,ctx)
func _queue_slayer_moves(ids: Array, ctx: Dictionary):
	e._flow.slayer_moved = []
	_queue({"kind":"slayer_damage"},ctx)
	for n in range(ids.size()-1,-1,-1): _queue({"kind":"slayer_move","fighter":ids[n]},ctx)
func _slayer_move(fid: int, ctx: Dictionary):
	if not e._valid_fighter(fid): return
	if int(e.fighters[fid].get("locked_until",-1)) == e.turn_number: return
	var legal = []
	for node in e.nodes:
		if e._occupant(int(node.id)) < 0 and e._same_zone(int(e.fighters[fid].node),int(node.id)): legal.append(int(node.id))
	if legal.is_empty(): return
	if _human(int(ctx.owner)): _spaces("slayer_move",legal,ctx,{"fighter":fid,"prompt":"%s: выберите другую клетку в его зоне" % e.fighters[fid].name})
	else:
		e._enter_node(fid,int(legal[-1]))
		e._flow.slayer_moved.append(fid)
func _shadow_legal(effect: Dictionary, ctx: Dictionary) -> Array:
	var legal = []
	var owner = int(ctx.owner)
	if str(effect.kind) == "seek_shadow_one":
		var hero = e.hero_fighter(owner)
		if not e._valid_fighter(hero): return legal
		if int(effect.step) == 0: return [int(e.fighters[hero].node)]
		for node in e.nodes[int(e.fighters[hero].node)].neighbors:
			if not _contains_int(e._flow.get("seek_shadow_nodes",[]),int(node)): legal.append(int(node))
	else:
		for f in e.fighters:
			if int(f.owner) == owner and e._valid_fighter(int(f.id)):
				for node in e.nodes[int(f.node)].neighbors:
					if not legal.has(int(node)): legal.append(int(node))
	return legal
func _contains_int(values: Array, value: int) -> bool:
	# JSON restores numbers as floats; Array.has distinguishes their Variant types.
	for item in values:
		if int(item) == value: return true
	return false
func _shadow_place(effect: Dictionary, ctx: Dictionary):
	var owner = int(ctx.owner)
	var legal = _shadow_legal(effect,ctx)
	if legal.is_empty(): return
	var indices = []
	var used_ids = []
	for i in range(e.shadow_tokens.size()):
		if int(e.shadow_tokens[i].owner) == owner:
			used_ids.append(int(e.shadow_tokens[i].id))
			if not (str(effect.kind) == "seek_shadow_one" and _contains_int(e._flow.get("seek_shadow_ids",[]),int(e.shadow_tokens[i].id))): indices.append(i)
	var free_id = -1
	for id in range(3):
		if not used_ids.has(id): free_id = id; break
	if free_id >= 0:
		if _human(owner): _spaces("shadow_place",legal,ctx,{"token_index":-1,"token_id":free_id,"_effect":effect,"prompt":"Разместите жетон тени"},str(effect.kind) == "shadow_start")
		else: _put_shadow(-1,free_id,_best_shadow_node(owner,legal),effect,ctx)
	elif not indices.is_empty():
		if _human(owner):
			var labels = []
			for i in indices: labels.append("Тень %d · клетка %d" % [int(e.shadow_tokens[int(i)].id)+1,int(e.shadow_tokens[int(i)].node)+1])
			_options("shadow_token",labels,ctx,{"indices":indices,"_effect":effect,"prompt":"Выберите тень для перемещения"},str(effect.kind) == "shadow_start")
		else:
			var index = int(indices[0])
			_put_shadow(index,int(e.shadow_tokens[index].id),_best_shadow_node(owner,legal),effect,ctx)
func _best_shadow_node(owner: int, legal: Array) -> int:
	var best = int(legal[0])
	var score = -INF
	for node in legal:
		var value = 0.0
		for f in e.fighters:
			if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)): value += 3.0 if int(f.node) == int(node) else (1.0 if e.nodes[int(f.node)].neighbors.has(int(node)) else 0.0)
		if value > score: score = value; best = int(node)
	return best
func _put_shadow(index: int, id: int, node: int, effect: Dictionary, ctx: Dictionary):
	if index < 0: e.shadow_tokens.append({"id":id,"owner":int(ctx.owner),"node":node})
	else: e.shadow_tokens[index].node = node
	if str(effect.kind) == "seek_shadow_one":
		e._flow.seek_shadow_ids.append(id)
		e._flow.seek_shadow_nodes.append(node)
	e._log("Тень %d: клетка %d." % [id+1,node+1])
func _resurrect(ctx: Dictionary):
	var ids = []
	for f in e.fighters:
		if not f.alive and not bool(f.get("reserve",false)) and e.are_allies(int(ctx.owner),int(f.owner)): ids.append(int(f.id))
	if ids.is_empty(): return
	if _human(int(ctx.owner)): _fighter_options("resurrect",ids,ctx,"Выберите поверженного дружественного бойца")
	else:
		var best = int(ids[0])
		for id in ids:
			if e.fighters[int(id)].hero: best = int(id); break
		_resurrect_space(best,ctx)
func _resurrect_space(fid: int, ctx: Dictionary):
	var hero = e.hero_fighter(int(ctx.owner))
	if not e._valid_fighter(hero): return
	var legal = []
	for node in e.nodes:
		if e._occupant(int(node.id)) < 0 and e._same_zone(int(node.id),int(e.fighters[hero].node)): legal.append(int(node.id))
	if legal.is_empty(): return
	if _human(int(ctx.owner)): _spaces("resurrect",legal,ctx,{"revive_fighter":fid,"prompt":"Поместите бойца в зону Уиллоу: здоровье 3"})
	else: _revive(fid,int(legal[0]))
func _revive(fid: int, node: int):
	e.fighters[fid].alive = true
	e.fighters[fid].offboard = false
	e.fighters[fid].hp = 3
	e.fighters[fid].max_hp = maxi(3,int(e.fighters[fid].max_hp))
	e.players[int(e.fighters[fid].owner)].alive = true
	e._enter_node(fid,node)
	e._log("%s возвращается с 3 здоровья." % e.fighters[fid].name)
func choose_option(index: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if index < 0 or index >= p.get("options",[]).size(): return false
	var ctx = p._ctx
	var action = str(p.action).trim_prefix("v7_")
	e.pending_choice.clear()
	match action:
		"slayer_strength":
			if index == 0: _queue_slayer_moves(p.ids,ctx)
		"arrogance":
			if index == 0: _arrogance(ctx)
		"hacker":
			if index == 1 and not e.players[int(ctx.owner)].deck.is_empty(): e.players[int(ctx.owner)].deck.push_front(e.players[int(ctx.owner)].deck.pop_back())
		"retrieve": e.players[int(ctx.owner)].hand.append(e.players[int(ctx.owner)].discard.pop_at(index))
		"opponent": _opponent_selected(str(p.effect_kind),ctx,int(p.opponents[index]))
		"hand_discard":
			e._discard_from_opponent(int(p.victim),e.players[int(p.victim)].hand.pop_at(index))
			if int(p.remaining_count) > 1 and not e.players[int(p.victim)].hand.is_empty(): _cards("hand_discard",int(p.victim),"hand",ctx,{"remaining_count":int(p.remaining_count)-1,"prompt":p.prompt})
		"love_damage": e._damage(int(p.ids[index]),3)
		"resurrect": _resurrect_space(int(p.ids[index]),ctx)
		"shadow_token":
			var token_index = int(p.indices[index])
			_spaces("shadow_place",_shadow_legal(p._effect,ctx),ctx,{"token_index":token_index,"token_id":int(e.shadow_tokens[token_index].id),"_effect":p._effect,"prompt":"Выберите новую клетку тени"},str(p._effect.kind) == "shadow_start")
		_: return false
	if not e.pending_choice.is_empty(): e.changed.emit()
	else: _resume()
	return true
func choose_node(node: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if not p.get("legal",[]).has(node): return false
	match str(p.action):
		"v7_shadow_place": _put_shadow(int(p.token_index),int(p.token_id),node,p._effect,p._ctx)
		"v7_slayer_move":
			e._enter_node(int(p.fighter),node)
			e._flow.slayer_moved.append(int(p.fighter))
		"v7_resurrect": _revive(int(p.revive_fighter),node)
		_: return false
	_resume()
	return true
