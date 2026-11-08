extends RefCounted
## Set rules and card decisions for Ali and Cobble & Fog. All mutable state is
## kept in BattleEngine, so suspended choices survive JSON save/load.
var _engine_ref
var e:
	get: return _engine_ref.get_ref()

func _init(engine): _engine_ref = weakref(engine)

func setup_tokens(manual: bool):
	for owner in range(e.players.size()):
		e.ali_stance[owner] = "butterfly"
		e.jekyll_form[owner] = "jekyll"
		if e._is_hero(owner, "invisible_man") and not (manual and owner == 0):
			for n in range(3):
				var legal = e.legal_fog_nodes(owner)
				if not legal.is_empty(): e.fog_tokens.append({"id": e.fog_tokens.size(), "owner": owner, "node": int(legal[0])})

func start_turn() -> bool:
	var owner = e.active
	var fid = e.hero_fighter(owner)
	if fid < 0 or not e.fighters[fid].alive: return false
	if bool(e.fighters[fid].get("offboard", false)):
		e.fighters[fid].offboard = false
		e._start_ability(owner, "Возвращение из невидимости", [{"kind":"place", "target":"hero"}], "start_turn")
		return true
	if e._is_hero(owner, "jekyll_hyde"):
		e._start_ability(owner, "Сыворотка: выбрать облик", [{"kind":"choose_form"}], "start_turn")
		return true
	if e._is_hero(owner, "dracula"):
		e._start_ability(owner, "Кровожадность Дракулы", [{"kind":"dracula_bite"}], "start_turn")
		return true
	return false

func condition(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner = int(ctx.owner)
	if effect.has("if_stance") and e.stance_for(owner) != str(effect.if_stance): return false
	if effect.has("if_form") and e.form_for(owner) != str(effect.if_form): return false
	if bool(effect.get("if_won_turn", false)) and not bool(e.players[owner].get("won_combat_turn", false)): return false
	if bool(effect.get("if_lose", false)) and bool(ctx.get("won", false)): return false
	return true

func _human(owner: int) -> bool:
	return e.interactive and owner >= 0 and owner < e.players.size() and not e.players[owner].bot

func _options(action: String, labels: Array, ctx: Dictionary, extra: Dictionary = {}, can_skip = false):
	e.pending_choice = {"kind":"options", "action":"v6_" + action, "title": str(ctx.card.get("name", "Способность")), "prompt":"Выберите вариант", "options":labels, "legal":[], "allowed_fighters":[], "fighter":-1, "can_skip":can_skip, "_ctx":ctx}
	e.pending_choice.merge(extra, true)
	e.phase = "effect_choice"

func _cards(action: String, owner: int, source: String, indices: Array, ctx: Dictionary, extra: Dictionary = {}, can_skip = false):
	var cards = []
	for index in indices: cards.append(e.players[owner][source][int(index)].duplicate(true))
	_options(action, [], ctx, {"kind":"cards", "cards":cards, "indices":indices, "victim":owner, "owner":int(ctx.owner), "viewer":int(ctx.owner), "source":source}, can_skip)
	e.pending_choice.merge(extra, true)
	e._refresh_card_options()

func _resume():
	e.pending_choice.clear()
	e._pump_effects()
	e.changed.emit()

func _set_form(owner: int, form: String):
	e.jekyll_form[owner] = form
	e._log("Облик: %s." % ("мистер Хайд" if form == "hyde" else "доктор Джекилл"))

func _other(ctx: Dictionary) -> Dictionary:
	return e._combat_resolution.get("d" if str(ctx.get("_combat_slot", "a")) == "a" else "a", {})

func _cancel(ctx: Dictionary):
	var other = _other(ctx)
	if other.is_empty(): return
	if not e._card_uncancellable(int(other.owner), other.card): other.cancelled = true
	else: e._log("Эффекты этой карты нельзя отменить.")

func _guess(owner: int) -> int:
	# Only the public deck list and public discard pile inform this prediction.
	var counts = {}
	for card in e.heroes[e.players[owner].hero_id].get("cards", []):
		if e._attack_type(card):
			var value = int(card.get("value", 0))
			counts[value] = int(counts.get(value, 0)) + int(card.get("count", 1))
	for card in e.players[owner].discard:
		var value = int(card.get("value", 0))
		if e._attack_type(card): counts[value] = maxi(0, int(counts.get(value, 0)) - 1)
	var best = 3
	for value in counts:
		if int(counts[value]) > int(counts.get(best, 0)): best = int(value)
	return best

func prepare_defense(index: int) -> bool:
	var owner = int(e.pending_combat.defender_owner)
	if index < 0 or index >= e.players[owner].hand.size(): return false
	if not e._has_kind(e.players[owner].hand[index], "elementary") or e.pending_combat.has("prediction"): return false
	if _human(owner):
		var labels = []
		for n in range(11): labels.append("Значение атаки: %d" % n)
		_options("elementary_guess", labels, {"owner":owner, "card":e.players[owner].hand[index]}, {"defense_index":index,"prompt":"Элементарно: предскажите напечатанное значение закрытой атаки"})
		return true
	e.pending_combat.prediction = e.rng.randi_range(1, 5) if e.difficulty == 0 else _guess(int(e.pending_combat.attack_owner))
	if e.interactive and not e.players[0].bot:
		_options("elementary_reveal",["Продолжить"],{"owner":owner,"card":e.players[owner].hand[index]},{"defense_index":index,"victim":owner,"cards":[e.players[owner].hand[index].duplicate(true)],"viewer":0,"prompt":"Открыта защита «Элементарно». Предсказание: %d. Карта атаки ещё закрыта." % int(e.pending_combat.prediction)})
		return true
	return false

func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var kind = str(effect.get("kind", ""))
	var owner = int(ctx.owner)
	var fid = int(ctx.get("self", e.hero_fighter(owner)))
	var opponent = int(ctx.get("opponent", -1))
	var enemy = int(ctx.get("opponent_owner", -1))
	match kind:
		"choose_form":
			if _human(owner): _options("form", ["Доктор Джекилл", "Мистер Хайд"], ctx, {"prompt":"В начале хода можно выбрать любой облик"})
			else:
				var hyde_cards = 0
				for card in e.players[owner].hand:
					if str(card.get("fighter", "")) == "hyde": hyde_cards += 1
				_set_form(owner, "hyde" if hyde_cards > 0 and e._public_target(fid) >= 0 and e._distance(int(e.fighters[fid].node), int(e.fighters[e._public_target(fid)].node)) <= 2 else "jekyll")
		"change_form": _set_form(owner, str(effect.get("form", "jekyll")))
		"dracula_bite":
			var ids = e._damage_candidates({"target":"any_adjacent_to_self"}, ctx)
			if _human(owner) and not ids.is_empty():
				var labels = []
				for id in ids: labels.append("%s: 1 урон, затем взять карту" % e.fighters[int(id)].name)
				_options("bite", labels, ctx, {"ids":ids,"allowed_fighters":ids,"prompt":"Можно нанести 1 урон соседнему бойцу и взять карту"}, true)
			else:
				var targets = []
				for id in ids:
					if e.is_enemy(owner, int(e.fighters[int(id)].owner)): targets.append(int(id))
				if not targets.is_empty(): _bite(e._best_public_target(targets), owner)
		"setup_fog": _begin_setup_fog(ctx)
		"flip_stance":
			e.ali_stance[owner] = "bee" if e.stance_for(owner) == "butterfly" else "butterfly"
			e._log("Стойка Али: %s." % ("порхай как бабочка" if e.stance_for(owner) == "butterfly" else "жаль как пчела"))
		"feeding_frenzy":
			if e._valid_fighter(opponent):
				for f in e.fighters:
					if f.alive and int(f.owner) == owner and not f.hero and e._same_zone(int(f.node), int(e.fighters[opponent].node)): ctx.value += 1
		"beastform", "forever_hyde": _discard_power(ctx, kind)
		"opponent_boost_value": ctx.value += int(_other(ctx).get("card", {}).get("boost", 0))
		"do_my_bidding": _do_bidding(ctx)
		"bidding_select": _select_bidding(ctx)
		"prey_upon":
			var ids = e._damage_candidates({"target":"opponent_adjacent_to_self"},ctx)
			e._heal(fid,e._damage_many(ids,1))
		"thirst_for_sustenance":
			if e._valid_fighter(opponent): _queue({"kind":"place","target":"hero","adjacent_to":opponent}, ctx)
		"ravening_seduction":
			var ids = []
			for f in e.fighters:
				if e._valid_fighter(int(f.id)): ids.append(int(f.id))
			if _human(owner):
				var labels = []
				for id in ids: labels.append(str(e.fighters[int(id)].name))
				_options("seduction_target", labels, ctx, {"ids":ids,"allowed_fighters":ids,"prompt":"Выберите любого бойца для перемещения"})
			elif not ids.is_empty():
				var target = e._effect_damage_target({"target":"any"}, ctx)
				if target >= 0:
					e._auto_move(target, 2, false, false, owner)
					_seduction_damage(target, owner)
		"seduction_damage": _seduction_damage(int(effect.get("fighter_id", fid)), owner)
		"education_never_ends": e._draw(enemy, 1) if bool(ctx.won) and enemy >= 0 else e._draw(owner, 2)
		"deduce_strategy":
			if _human(owner): _options("deduce", ["Заменить значение на BOOST", "Оставить значение"], ctx)
			else:
				var other = _other(ctx)
				if not other.is_empty() and int(other.card.get("boost", 0)) < int(other.value): other.value = int(other.card.get("boost", 0))
		"counterpunch":
			if e._valid_fighter(fid) and e._valid_fighter(opponent) and e.fighters_adjacent(fid,opponent): e._damage(opponent, 2)
		"fixed_point":
			var hero = e.hero_fighter(owner)
			if e._valid_fighter(fid) and e._valid_fighter(hero) and e.fighters_adjacent(fid,hero):
				e._heal(fid, 1)
				e._heal(hero, 1)
		"elementary":
			var other = _other(ctx)
			if not other.is_empty() and int(e._combat_resolution.ctx.get("prediction", -99)) == int(other.card.get("value", 0)):
				_cancel(ctx)
				ctx.ignore_attack = true
				e._log("Элементарно: значение угадано; сила атаки игнорируется.")
			else: e._log("Элементарно: предсказание %d, напечатанная атака %d — промах." % [int(e._combat_resolution.ctx.get("prediction",-1)),int(other.get("card",{}).get("value",0))])
		"confirm_suspicion", "eliminate_impossible", "master_of_disguise": _opponent_effect(kind, ctx)
		"administer_aid":
			_queue({"kind":"draw","amount":1}, ctx)
			_queue({"kind":"heal","target":"hero","amount":1}, ctx)
			_queue({"kind":"place","fixed_fighter":fid,"adjacent_to":e.hero_fighter(owner)}, ctx)
		"duality_of_man":
			if (e.form_for(owner) == "hyde" and str(ctx.get("_combat_slot", "")) == "a") or (e.form_for(owner) == "jekyll" and str(ctx.get("_combat_slot", "")) == "d"): ctx.value = 6
		"scientific_method": e._draw(owner, int(ctx.get("damage_taken", 0)))
		"calming_research":
			e._heal(fid, 2)
			if _human(owner): _options("research_count", ["Не брать карты", "Взять 1", "Взять 2", "Взять 3"], ctx, {"prompt":"Возьмите до трёх карт; одну оставьте, остальные вниз колоды"})
			else: _research(ctx, mini(3, e.players[owner].deck.size()))
		"strange_case":
			if not e.players[owner].deck.is_empty():
				var top = e.players[owner].deck.pop_back()
				e._log("Странное дело: открыта карта «%s», BOOST %d." % [top.name, int(top.get("boost", 0))])
				_queue({"kind":"damage","target":"any_adjacent_to_self","amount":int(top.get("boost", 0))}, ctx)
				e.players[owner].hand.append(top)
		"impossible_to_see", "lock_opponent_value", "lock_opponent_printed_value":
			var other = _other(ctx)
			if not other.is_empty():
				other.value = 0 if kind == "impossible_to_see" else int(other.card.get("value", 0))
				other.locked_value = int(other.value)
		"emerge_from_mist":
			if bool(e.players[owner].get("started_on_fog", false)): ctx.value = 5
		"dreaming_of_revenge":
			if e._valid_fighter(fid) and e.fog_at(int(e.fighters[fid].node), owner) >= 0:
				var ids = []
				for f in e.fighters:
					if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)) and e.fog_at(int(f.node), owner) >= 0: ids.append(int(f.id))
				e._damage_many(ids,1)
		"reign_of_terror":
			if e._valid_fighter(fid) and e.fog_at(int(e.fighters[fid].node), owner) >= 0: _queue({"kind":"damage","target":"enemy_any","amount":2}, ctx)
		"step_lightly":
			_queue({"kind":"opponent_move_fog","spaces":2}, ctx)
			_queue({"kind":"damage","target":"any_adjacent_to_self","amount":3 if e._valid_fighter(fid) and e.fog_at(int(e.fighters[fid].node), owner) >= 0 else 1}, ctx)
		"damage_all_adjacent":
			if e._valid_fighter(fid):
				var ids = []
				for f in e.fighters:
					if e._valid_fighter(int(f.id)) and e.fighters_adjacent(fid,int(f.id)) and (bool(effect.get("any_fighter",false)) or e.is_enemy(owner,int(f.owner))): ids.append(int(f.id))
				e._damage_many(ids,int(effect.get("amount",2)))
		"covert_preparation":
			e._draw(owner, 1)
			_queue({"kind":"opponent_move_fog","spaces":2,"different":true}, ctx)
			_queue({"kind":"move_fog","spaces":2,"remember":true}, ctx)
		"move_fog", "opponent_move_fog", "surprise_fog", "slip_away": _fog_effect(effect, ctx)
		"move_specific_fog": _fog_effect({"kind":"move_fog","fixed_index":int(effect.index),"anywhere":true,"other_space":true},ctx)
		"lurking":
			e._draw(owner, 1)
			if _human(owner): _options("lurking", ["Перейти на клетку с туманом", "Передвинуть туман до 3 клеток"], ctx)
			else: _queue({"kind":"move_fog","spaces":3}, ctx)
		"place_on_fog": _place_on_fog(ctx)
		"confound": _confound(ctx)
		"coded_notes":
			e._draw(owner, 3)
			_return_top(ctx, 2)
		"vanish":
			e._heal(fid, 1)
			e._v12.departed(fid,int(e.fighters[fid].node),-1)
			e.fighters[fid].offboard = true
			e.actions_left = 0
			e._log("Человек-невидимка исчезает с поля до начала своего следующего хода.")
		"shuffle_discard": _shuffle_discard(effect, ctx)
		"all_opponents_random_discard":
			for p in range(e.players.size()):
				if e.is_enemy(owner, p) and e.players[p].alive: e._force_discard(p, int(effect.get("amount", 1)), true)
		"close_and_clinch":
			if e._valid_fighter(fid) and e._valid_fighter(opponent):
				_queue({"kind":"lock_combatants"},ctx)
				_queue({"kind":"place","fixed_fighter":fid,"adjacent_to":opponent},ctx)
		"lock_combatants":
			if e._valid_fighter(fid): e.fighters[fid].locked_until = e.turn_number
			if e._valid_fighter(opponent): e.fighters[opponent].locked_until = e.turn_number
			e._log("Клинч: оба бойца остаются на своих клетках до конца хода.")
		"fancy_footwork", "ignore_if_no_shared_zone":
			if e._valid_fighter(fid) and e._valid_fighter(opponent) and not e._same_zone(int(e.fighters[fid].node),int(e.fighters[opponent].node)): ctx.ignore_opponent_value = true
		"stronger_than_skill", "stronger_than_the_skill":
			if enemy >= 0 and not e.is_dormant(enemy):
				if not bool(ctx.won) or e.players[enemy].hand.is_empty(): e._reveal_hand(owner,enemy,ctx)
				elif _human(owner): _cards("stronger_shuffle",enemy,"hand",range(e.players[enemy].hand.size()),ctx,{"prompt":"Посмотрите руку и выберите карту для замешивания в колоду противника"})
				elif bool(ctx.won) and not e.players[enemy].hand.is_empty():
					e.players[enemy].deck.append(e.players[enemy].hand.pop_at(e._lowest_card(enemy,true)))
					e._shuffle(e.players[enemy].deck)
		"the_greatest":
			if int(e.players[owner].get("combat_damage_turn",0)) >= 6 and e.active == owner:
				if e.gain_actions(owner,2): e._log("Величайший: за 6 урона в боях этого хода получены 2 действия.")
		_:
			return false
	return true

func _queue(effect: Dictionary, ctx: Dictionary): e._effect_queue.push_front({"effect":effect, "ctx":ctx.duplicate(true)})

func _bite(fid: int, owner: int):
	e._damage(fid, 1)
	e._log("Кровожадность: %s получает 1 урон; Дракула берёт карту." % e.fighters[fid].name)
	if not e._check_winner(): e._draw(owner, 1)

func _discard_power(ctx: Dictionary, kind: String):
	var owner = int(ctx.owner)
	var indices = []
	for i in range(e.players[owner].hand.size()):
		if kind == "beastform" or str(e.players[owner].hand[i].get("fighter", "")) == "jekyll": indices.append(i)
	if indices.is_empty(): return
	if _human(owner): _cards("power",owner,"hand",indices,ctx,{"power_kind":kind,"prompt":"Можно сбрасывать карты по одной или закончить усиление"},true)
	else:
		for n in range(indices.size() - 1, -1, -1):
			var i = int(indices[n])
			if e.difficulty == 0 and e.rng.randf() < 0.4: continue
			if kind == "beastform" and e._card_quality(e.players[owner].hand[i]) > 4.5 and e.players[owner].hand.size() < 4: continue
			e._discard(owner,e.players[owner].hand.pop_at(i))
			ctx.value += 1 if kind == "beastform" else 2

func _do_bidding(ctx: Dictionary):
	var other = _other(ctx)
	if other.is_empty(): return
	var owner = int(other.owner)
	e.players[owner].hand.append(other.card)
	if _human(int(ctx.owner)):
		_queue({"kind":"bidding_select"},ctx)
		e._reveal_hand(int(ctx.owner),owner,ctx)
	else: _select_bidding(ctx)

func _select_bidding(ctx: Dictionary):
	var other = _other(ctx)
	if other.is_empty(): return
	var owner = int(other.owner)
	var indices = []
	for i in range(e.players[owner].hand.size()):
		if e._attack_type(e.players[owner].hand[i]) and e._card_usable(e.players[owner].hand[i],int(other.self)): indices.append(i)
	if _human(int(ctx.owner)): _cards("bidding",owner,"hand",indices,ctx,{"prompt":"Выберите атаку, которую сыграет противник"})
	else:
		var best = int(indices[0])
		for i in indices:
			if e._card_quality(e.players[owner].hand[int(i)]) < e._card_quality(e.players[owner].hand[best]): best = int(i)
		_replace_attack(owner,best)

func _replace_attack(owner: int, index: int):
	var card = e.players[owner].hand.pop_at(index)
	var a = e._combat_resolution.a
	a.card = card
	a.value = int(card.get("value",0))
	a.cancelled = false
	e._combat_resolution.ctx.attack_card = card
	var keep = []
	for job in e._effect_queue:
		if str(job.ctx.get("_combat_slot","")) != "a" or bool(job.effect.get("intrinsic",false)): keep.append(job)
	e._effect_queue = keep
	var immediate = []
	for effect in card.get("effects",[]):
		if str(effect.get("timing","")) == "immediately": immediate.append({"effect":effect.duplicate(true),"ctx":a.duplicate(true)})
	for n in range(immediate.size()-1,-1,-1): e._effect_queue.push_front(immediate[n])
	e._queue_card_effects(card,"during",a)
	e._log("Моя воля: новая атака — «%s»." % card.name)

func _seduction_damage(fid: int, owner: int):
	if not e._valid_fighter(fid): return
	var amount = 0
	for f in e.fighters:
		if f.alive and not f.hero and int(f.owner) == owner and e.fighters_adjacent(int(f.id),fid): amount += 1
	e._damage(fid,amount)
	e._log("Голодное искушение: %s получает %d урона от соседних сестёр." % [e.fighters[fid].name,amount])

func _opponent_effect(kind: String, ctx: Dictionary):
	var owner = int(ctx.owner)
	var enemies = []
	for p in range(e.players.size()):
		if not e.is_dormant(p) and e.is_enemy(owner,p): enemies.append(p)
	if enemies.is_empty(): return
	if _human(owner) and enemies.size() > 1:
		var labels = []
		for p in enemies: labels.append(e._player_name(int(p)))
		_options("opponent",labels,ctx,{"opponents":enemies,"effect_kind":kind,"prompt":"Выберите противника"})
	else: _opponent_selected(kind,ctx,int(ctx.get("opponent_owner",enemies[0])) if enemies.has(int(ctx.get("opponent_owner",-1))) else int(enemies[0]))

func _opponent_selected(kind: String, ctx: Dictionary, victim: int):
	ctx.opponent_owner = victim
	ctx._peek_target_chosen = true
	if kind == "eliminate_impossible" and e._v8.guard_effect({"kind":kind},ctx): return
	if kind == "eliminate_impossible":
		if e.players[victim].hand.is_empty(): e._reveal_hand(int(ctx.owner),victim,ctx)
		elif _human(int(ctx.owner)): _cards("eliminate",victim,"hand",range(e.players[victim].hand.size()),ctx,{"prompt":"Посмотрите руку противника и выберите карту для сброса"})
		else: e._force_discard(victim,1,false,true)
	elif kind == "confirm_suspicion":
		if _human(int(ctx.owner)):
			var labels = []
			for n in range(11): labels.append("Назвать значение %d" % n)
			_options("suspicion_value",labels,ctx,{"prompt":"Назовите напечатанное значение атаки или защиты (схемы не считаются)"})
		else: _suspicion(ctx,_guess(victim))
	else:
		var ids = e._living_heroes(victim)
		var available = []
		for id in ids:
			if e._valid_fighter(int(id)): available.append(id)
		if available.is_empty(): return
		if _human(victim) and available.size() > 1:
			var labels = []
			for id in available: labels.append(str(e.fighters[int(id)].name))
			_options("disguise",labels,ctx,{"ids":available,"prompt":"Выберите героя, который поменяется местами с Холмсом"})
		else: _disguise(ctx,int(available[0]))

func _disguise(ctx: Dictionary, fid: int):
	var hero = e.hero_fighter(int(ctx.owner))
	if e._valid_fighter(hero) and e._valid_fighter(fid):
		if e._swap_combatants(hero,fid): e._damage(fid,1)

func _suspicion(ctx: Dictionary, value: int):
	var victim = int(ctx.opponent_owner)
	var indices = []
	for i in range(e.players[victim].hand.size()):
		var card = e.players[victim].hand[i]
		if str(card.get("type","")) != "scheme" and int(card.get("value",0)) == value: indices.append(i)
	e._log("Подтвердить подозрение: названо значение %d." % value)
	if indices.is_empty():
		e._reveal_hand(int(ctx.owner),victim,ctx)
	elif _human(victim): _cards("suspicion_discard",victim,"hand",indices,ctx,{"prompt":"Выберите совпавшую карту: её BOOST станет уроном вашему герою"})
	else:
		var best = int(indices[0])
		for i in indices:
			if int(e.players[victim].hand[int(i)].get("boost",0)) < int(e.players[victim].hand[best].get("boost",0)): best = int(i)
		_suspicion_discard(ctx,best)

func _suspicion_discard(ctx: Dictionary, index: int):
	var victim = int(ctx.opponent_owner)
	var card = e.players[victim].hand.pop_at(index)
	if not e._discard_from_opponent(victim,card):
		e._v14._reveal(card,victim,ctx);return
	var amount = int(card.get("boost",0))
	var ids = e._living_heroes(victim)
	if _human(victim) and ids.size() > 1:
		var labels = []
		for id in ids: labels.append(str(e.fighters[int(id)].name))
		_options("hero_damage",labels,ctx,{"ids":ids,"amount":amount,"prompt":"Выберите одного героя для урона"})
	elif not ids.is_empty(): e._damage(int(ids[0]),amount)

func _research(ctx: Dictionary, count: int):
	var owner = int(ctx.owner)
	var drawn = []
	for n in range(count):
		var before = e.players[owner].hand.size()
		e._draw(owner,1)
		if e.players[owner].hand.size() > before: drawn.append(e.players[owner].hand.pop_back())
	if drawn.is_empty(): return
	if _human(owner):
		_options("research_keep",[],ctx,{"kind":"cards","cards":drawn,"prompt":"Оставьте одну из взятых карт"})
		e._refresh_card_options()
	else:
		drawn.sort_custom(func(a,b): return e._card_quality(a) > e._card_quality(b))
		e.players[owner].hand.append(drawn.pop_front())
		for card in drawn: e.players[owner].deck.push_front(card)

func _return_top(ctx: Dictionary, count: int):
	var owner = int(ctx.owner)
	if e.players[owner].hand.is_empty(): return
	if _human(owner): _cards("return_top",owner,"hand",range(e.players[owner].hand.size()),ctx,{"remaining_count":mini(count,e.players[owner].hand.size()),"prompt":"Выберите карту на верх колоды; выбранная последней будет верхней"})
	else:
		for n in range(mini(count,e.players[owner].hand.size())): e.players[owner].deck.append(e.players[owner].hand.pop_at(e._lowest_card(owner)))

func _begin_setup_fog(ctx: Dictionary):
	e.pending_choice = {"kind":"spaces","action":"v6_setup_fog","title":"Расстановка тумана","prompt":"Разместите три жетона тумана на отдельных свободных клетках в зоне героя","legal":e.legal_fog_nodes(int(ctx.owner)),"allowed_fighters":[],"fighter":-1,"remaining_count":3,"can_skip":false,"_ctx":ctx}
	e.phase = "effect_move"

func _fog_indices(owner: int, effect: Dictionary) -> Array:
	var indices = []
	for i in range(e.fog_tokens.size()):
		if effect.has("fixed_index") and i != int(effect.fixed_index): continue
		if int(e.fog_tokens[i].owner) != owner: continue
		if bool(effect.get("different",false)) and int(e.fog_tokens[i].id) == int(e._flow.get("last_moved_fog",-1)): continue
		if str(effect.get("kind","")) == "surprise_fog" and int(e.fog_tokens[i].node) != int(e.fighters[e.hero_fighter(owner)].node): continue
		indices.append(i)
	return indices

func _fog_effect(effect: Dictionary, ctx: Dictionary):
	var owner = int(ctx.owner)
	var chooser = int(ctx.get("opponent_owner",-1)) if str(effect.kind) == "opponent_move_fog" else owner
	if chooser < 0:
		for p in range(e.players.size()):
			if not e.is_dormant(p) and e.is_enemy(owner,p):
				chooser = p
				break
	var indices = _fog_indices(owner,effect)
	if indices.is_empty(): return
	if _human(chooser):
		var labels = []
		for i in indices: labels.append("Туман %d · клетка %d" % [int(e.fog_tokens[int(i)].id)+1,int(e.fog_tokens[int(i)].node)+1])
		_options("fog_token",labels,ctx,{"indices":indices,"_effect":effect,"prompt":"Выберите жетон тумана для перемещения"},str(effect.kind) not in ["surprise_fog","slip_away"])
	else:
		var best = int(indices[0])
		var best_node = -1
		var score = -INF
		for index in indices:
			for node in _fog_legal(int(index),effect):
				var current = _fog_score(owner,int(node),chooser != owner)
				if current > score:
					score = current
					best = int(index)
					best_node = int(node)
		if best_node >= 0: _move_fog(best,best_node,effect,ctx)

func _fog_legal(index: int, effect: Dictionary) -> Array:
	var legal = []
	var origin = int(e.fog_tokens[index].node)
	var any_space = bool(effect.get("anywhere",false)) or str(effect.kind) in ["surprise_fog","slip_away"] or not effect.has("spaces")
	var queue = [[origin,0]]
	var seen = {origin:true}
	while not queue.is_empty():
		var entry = queue.pop_front()
		var node = int(entry[0])
		var fog = e.fog_at(node)
		if (fog < 0 or fog == index) and not ((bool(effect.get("other_space",false)) or str(effect.kind) in ["surprise_fog","slip_away"]) and node == origin):
			if str(effect.kind) != "slip_away" or e._occupant(node) < 0: legal.append(node)
		if not any_space and int(entry[1]) >= int(effect.get("spaces",0)): continue
		for next in e.nodes[node].get("move_neighbors",e.nodes[node].neighbors):
			if not seen.has(int(next)):
				seen[int(next)] = true
				queue.append([int(next),int(entry[1])+1])
	return legal

func _fog_score(owner: int, node: int, hostile: bool) -> float:
	var hero = e.hero_fighter(owner)
	var score = 0.0
	if e._valid_fighter(hero):
		var distance = e._distance(int(e.fighters[hero].node),node)
		score = 5.0 if distance == 0 else 2.0 / maxf(1.0,float(distance))
	for f in e.fighters:
		if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)):
			score += 1.2 if e._distance(int(f.node),node) == 1 else 0.0
	return -score if hostile else score

func _move_fog(index: int, node: int, effect: Dictionary, ctx: Dictionary):
	e.fog_tokens[index].node = node
	if bool(effect.get("remember",false)): e._flow.last_moved_fog = int(e.fog_tokens[index].id)
	if str(effect.kind) == "slip_away": e._enter_node(e.hero_fighter(int(ctx.owner)),node)
	e._log("Туман %d перемещён на клетку %d." % [int(e.fog_tokens[index].id)+1,node+1])

func _place_on_fog(ctx: Dictionary):
	var owner = int(ctx.owner)
	var legal = []
	for fog in e.fog_tokens:
		if int(fog.owner) == owner and e._occupant(int(fog.node)) in [-1,e.hero_fighter(owner)]: legal.append(int(fog.node))
	if legal.is_empty(): return
	if _human(owner):
		e.pending_choice = {"kind":"spaces","action":"v6_place_fog","title":str(ctx.card.name),"prompt":"Выберите свободную клетку с туманом","legal":legal,"fighter":e.hero_fighter(owner),"allowed_fighters":[],"can_skip":false,"_ctx":ctx}
		e.phase = "effect_move"
	else: e._enter_node(e.hero_fighter(owner),int(legal[0]))

func _confound(ctx: Dictionary):
	var victim = int(ctx.opponent_owner)
	if victim < 0: return
	if _human(victim) and not e.players[victim].hand.is_empty(): _options("confound",["Сбросить 1 карту", "Позволить переместить все жетоны тумана"],ctx)
	elif not e.players[victim].hand.is_empty() and e._card_quality(e.players[victim].hand[e._lowest_card(victim)]) < 3.0: e._force_discard(victim,1,false)
	else: _queue_fog_all(ctx)

func _queue_fog_all(ctx: Dictionary):
	# Each token is selected once; later tokens cannot repeat an earlier token.
	for i in range(e.fog_tokens.size()-1,-1,-1):
		if int(e.fog_tokens[i].owner) == int(ctx.owner): _queue({"kind":"move_specific_fog","index":i},ctx)

func _shuffle_discard(effect: Dictionary, ctx: Dictionary):
	var owner = int(ctx.owner)
	var indices = []
	for i in range(e.players[owner].discard.size()):
		if not bool(effect.get("exclude_scheme",true)) or str(e.players[owner].discard[i].get("type","")) != "scheme": indices.append(i)
	if indices.is_empty(): return
	if _human(owner): _cards("shuffle_discard",owner,"discard",indices,ctx,{"prompt":"Выберите карту сброса для замешивания в колоду"})
	else:
		e.players[owner].deck.append(e.players[owner].discard.pop_at(int(indices[0])))
		e._shuffle(e.players[owner].deck)

func choose_option(index: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if not str(p.get("action","")).begins_with("v6_"): return false
	if index < 0 or index >= p.get("options",[]).size(): return false
	var action = str(p.action).trim_prefix("v6_")
	var ctx = p._ctx
	var owner = int(ctx.owner)
	e.pending_choice.clear()
	match action:
		"elementary_guess":
			e.pending_combat.prediction = index
			e._resolve_combat(int(p.defense_index))
			e.changed.emit()
			return true
		"elementary_reveal":
			e._resolve_combat(int(p.defense_index))
			e.changed.emit()
			return true
		"form": _set_form(owner,"jekyll" if index == 0 else "hyde")
		"bite": _bite(int(p.ids[index]),owner)
		"deduce":
			if index == 0:
				var other = _other(ctx)
				if not other.is_empty(): other.value = int(other.card.get("boost",0))
		"power":
			var card = e.players[owner].hand.pop_at(int(p.indices[index]))
			e._discard(owner,card)
			ctx.value += 1 if str(p.power_kind) == "beastform" else 2
			if ctx.has("_combat_slot"): e._combat_resolution[str(ctx._combat_slot)] = ctx
			_discard_power(ctx,str(p.power_kind))
		"bidding": _replace_attack(int(p.victim),int(p.indices[index]))
		"opponent": _opponent_selected(str(p.effect_kind),ctx,int(p.opponents[index]))
		"suspicion_value": _suspicion(ctx,index)
		"suspicion_discard": _suspicion_discard(ctx,int(p.indices[index]))
		"eliminate": e._discard_from_opponent(int(p.victim),e.players[int(p.victim)].hand.pop_at(int(p.indices[index])))
		"view": pass
		"disguise": _disguise(ctx,int(p.ids[index]))
		"hero_damage": e._damage(int(p.ids[index]),int(p.amount))
		"research_count": _research(ctx,index)
		"research_keep":
			var card = p.cards.pop_at(index)
			e.players[owner].hand.append(card)
			if not p.cards.is_empty():
				_options("research_bottom",[],ctx,{"kind":"cards","cards":p.cards,"prompt":"Выберите следующую карту для низа колоды"})
				e._refresh_card_options()
		"research_bottom":
			e.players[owner].deck.push_front(p.cards.pop_at(index))
			if not p.cards.is_empty():
				_options("research_bottom",[],ctx,{"kind":"cards","cards":p.cards,"prompt":"Выберите следующую карту для низа колоды"})
				e._refresh_card_options()
		"return_top":
			e.players[owner].deck.append(e.players[owner].hand.pop_at(int(p.indices[index])))
			if int(p.remaining_count) > 1: _return_top(ctx,int(p.remaining_count)-1)
		"seduction_target":
			var target = int(p.ids[index])
			_queue({"kind":"seduction_damage","fighter_id":target},ctx)
			var move_ctx = ctx.duplicate(true)
			move_ctx.self = target
			_queue({"kind":"move","target":"self","spaces":2},move_ctx)
		"fog_token":
			var fog_index = int(p.indices[index])
			e.pending_choice = {"kind":"spaces","action":"v6_move_fog","title":p.title,"prompt":"Выберите клетку для жетона тумана","legal":_fog_legal(fog_index,p._effect),"fighter":-1,"allowed_fighters":[],"can_skip":true,"fog_index":fog_index,"_effect":p._effect,"_ctx":ctx}
			e.phase = "effect_move"
		"lurking": _queue({"kind":"place_on_fog"} if index == 0 else {"kind":"move_fog","spaces":3},ctx)
		"confound":
			if index == 0: _cards("confound_discard",int(ctx.opponent_owner),"hand",range(e.players[int(ctx.opponent_owner)].hand.size()),ctx)
			else: _queue_fog_all(ctx)
		"confound_discard": e._discard_from_opponent(int(p.victim),e.players[int(p.victim)].hand.pop_at(int(p.indices[index])))
		"shuffle_discard":
			e.players[owner].deck.append(e.players[owner].discard.pop_at(int(p.indices[index])))
			e._shuffle(e.players[owner].deck)
		"stronger_shuffle":
			var victim = int(p.victim)
			e.players[victim].deck.append(e.players[victim].hand.pop_at(int(p.indices[index])))
			e._shuffle(e.players[victim].deck)
		_: return false
	if e.phase in ["effect_choice","effect_move"] and not e.pending_choice.is_empty():
		e.changed.emit()
	else: _resume()
	return true

func choose_node(node: int) -> bool:
	var p = e.pending_choice
	var action = str(p.get("action",""))
	if not action.begins_with("v6_") or not p.get("legal",[]).has(node): return false
	var owner = int(p._ctx.owner)
	match action:
		"v6_setup_fog":
			e.fog_tokens.append({"id":e.fog_tokens.size(),"owner":owner,"node":node})
			p.remaining_count = int(p.remaining_count)-1
			p.legal = e.legal_fog_nodes(owner)
			if int(p.remaining_count) > 0 and not p.legal.is_empty():
				e.changed.emit()
				return true
		"v6_move_fog": _move_fog(int(p.fog_index),node,p._effect,p._ctx)
		"v6_place_fog": e._enter_node(e.hero_fighter(owner),node)
		_: return false
	_resume()
	return true
