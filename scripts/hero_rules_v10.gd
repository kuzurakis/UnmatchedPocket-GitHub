extends "res://scripts/hero_rules_v8.gd"
## Tales to Amaze heroes in competitive play. All choices belong to saved state.
func _init(engine): super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra = {}, optional = false):
	super._options(action,labels,ctx,extra,optional)
	e.pending_choice.action = "v10_"+action
func coils(owner: int) -> int: return int(e.players[owner].get("coils",1))
func gadget(owner: int) -> String: return str(e.players[owner].get("gadget","hypno"))
func charge(owner: int, amount: int):
	e.players[owner].coils = clampi(coils(owner)+amount,0,2)
	e._log("Катушки Теслы: %d/2." % coils(owner))
func start_turn() -> bool:
	var owner = e.active
	if e._is_hero(owner,"dr_jill_trent"):
		e._start_ability(owner,"Гаджеты Джилл",[{"kind":"v10_gadget_choice"}],"start_turn")
		return true
	if e._is_hero(owner,"nikola_tesla") and coils(owner) == 2:
		e._start_ability(owner,"Электрическое переполнение",[{"kind":"v10_overflow"}],"start_turn")
		return true
	return false
func end_turn() -> bool:
	if not e._is_hero(e.active,"nikola_tesla") or coils(e.active) >= 2 or not e._valid_fighter(e.hero_fighter(e.active)): return false
	e._start_ability(e.active,"Зарядка катушки",[{"kind":"v10_end_charge"}],"end_turn")
	return true
func attack_bonus(fid: int, defender: int) -> int:
	if not e.fighters[fid].hero: return 0
	var owner = int(e.fighters[fid].owner)
	if e._is_hero(owner,"annie_christmas") and int(e.fighters[fid].hp) < int(e.fighters[defender].hp): return 2
	if e._is_hero(owner,"golden_bat") and int(e.players[owner].get("maneuvered_turn",-1)) != e.turn_number: return 2
	return 0
func limit_damage(fid: int, amount: int) -> int:
	if fid >= 0 and int(e.fighters[fid].get("queen_until",-1)) == e.turn_number: return mini(amount,maxi(0,int(e.fighters[fid].hp)-1))
	return amount
func effect_protected(fid: int) -> bool:
	for slot in ["a","d"]:
		var ctx = e._combat_resolution.get(slot,{})
		if int(ctx.get("self",-1)) == fid and bool(ctx.get("no_effect_damage",false)): return true
	return false
func gadget_eligible(ctx: Dictionary) -> bool:
	var owner = int(ctx.owner)
	if not e._is_hero(owner,"dr_jill_trent") or str(ctx.get("_combat_slot","")) != "a": return false
	if e.fighters[int(ctx.self)].hero: return true
	var hero = e.hero_fighter(owner)
	return str(ctx.card.get("id","")) == "sisters_in_arms" and e._valid_fighter(hero) and e._valid_fighter(int(ctx.self)) and e.fighters_adjacent(hero,int(ctx.self))
func queue_gadget(ctx: Dictionary, timing: String):
	if not e._is_hero(int(ctx.owner),"dr_jill_trent"): return
	e._effect_queue.append({"effect":{"kind":"v10_gadget_during" if timing == "during" else "v10_gadget_after","intrinsic":true},"ctx":ctx.duplicate(true)})
func _top(owner: int) -> Dictionary:
	return {} if owner < 0 or e.players[owner].deck.is_empty() else e.players[owner].deck[-1]
func _reveal(ctx: Dictionary, cards: Array, owners: Array):
	if cards.is_empty() or not e.interactive or e.players[0].bot: return
	_options("reveal",["Продолжить"],ctx,{"kind":"hand_view","deck_view":true,"cards":cards.duplicate(true),"card_owners":owners,"victim":int(owners[0]),"viewer":0,"prompt":"Раскрытые карты колод. Они остаются на прежних местах, если эффект не говорит иначе."})
func _coil_choice(mode: String, ctx: Dictionary, extra = {}):
	var owner = int(ctx.owner)
	if human(owner):
		var labels = ["Не разряжать катушки"]
		for amount in range(1,coils(owner)+1): labels.append("Разрядить катушек: %d" % amount)
		_options("coils",labels,ctx,{"mode":mode,"extra":extra})
	else: _discharge(mode,coils(owner),ctx,extra)
func _discharge(mode: String, amount: int, ctx: Dictionary, extra = {}):
	ctx = _live(ctx)
	var owner = int(ctx.owner)
	amount = clampi(amount,0,coils(owner))
	charge(owner,-amount)
	match mode:
		"hertz":
			if amount >= 1 and owner == e.active: e.gain_actions(owner,1)
			if amount == 2: e._draw(owner,1)
		"death":
			if amount > 0: ctx.value = 5 if amount == 1 else 7
		"experimentation":
			e._draw(owner,amount+1)
			if amount == 2: e._heal(e.hero_fighter(owner),1)
		"storm":
			if amount > 0: _zone_damage(ctx,amount)
		"polyphase":
			if amount > 0: e._v6._cancel(ctx)
			if amount == 2: ctx.ignore_opponent_value = true
		"repulsion":
			if amount == 2: _queue({"kind":"random_discard","amount":1},ctx)
			if amount > 0: _queue({"kind":"move","target":"hero","spaces":2},ctx)
		"xray":
			var victim = int(ctx.opponent_owner)
			if amount > 0 and not e.players[victim].deck.is_empty():
				var card = e.players[victim].deck.pop_back()
				e._discard_from_opponent(victim,card,false)
				if amount == 2: ctx.value += int(card.get("boost",0))
func _zone_damage(ctx: Dictionary, amount: int):
	var hero = e.hero_fighter(int(ctx.owner))
	if not e._valid_fighter(hero): return
	var ids = []
	for f in e.fighters:
		if e._valid_fighter(int(f.id)) and e.is_enemy(int(ctx.owner),int(f.owner)) and e._same_zone(int(e.fighters[hero].node),int(f.node)): ids.append(int(f.id))
	e._damage_many(ids,amount)
func _inspect(ctx: Dictionary, bottom: bool):
	var victim = int(ctx.opponent_owner)
	if victim < 0: return
	var cards = []
	for i in range(mini(3,e.players[victim].deck.size())): cards.append(e.players[victim].deck.pop_back())
	if cards.is_empty(): return
	if human(int(ctx.owner)):
		_options("inspect",[],ctx,{"kind":"cards","cards":cards,"victim":victim,"ordered":[],"bottom":bottom,"stage":"bottom" if bottom else "order","prompt":"Выберите карту для низа колоды" if bottom else "Выберите порядок сверху: первая выбранная карта будет верхней"})
		e._refresh_card_options()
	else:
		if bottom:
			var owners = []
			for card in cards: owners.append(victim)
			_reveal(ctx,cards,owners)
		cards.sort_custom(func(a,b): return e._card_quality(a) < e._card_quality(b))
		if bottom: e.players[victim].deck.push_front(cards.pop_back())
		for i in range(cards.size()-1,-1,-1): e.players[victim].deck.append(cards[i])
func _shuffle_selected(owner: int, indices: Array):
	indices.sort()
	indices.reverse()
	for i in indices: e.players[owner].deck.append(e.players[owner].discard.pop_at(int(i)))
	if not indices.is_empty(): e._shuffle(e.players[owner].deck)
func _assistant(ctx: Dictionary):
	var owner = int(ctx.owner)
	var indices = []
	for i in range(e.players[owner].discard.size()):
		if str(e.players[owner].discard[i].get("fighter","any")) == "hero": indices.append(i)
	if indices.is_empty(): return
	if human(owner): _cards("assistant",owner,"discard",indices,ctx,{"chosen":[],"remaining_count":3,"prompt":"Выберите до 3 карт Джилл Трент или завершите выбор"},true)
	else:
		indices.resize(mini(3,indices.size()))
		_shuffle_selected(owner,indices)
func _show_pair(ctx: Dictionary, name: String):
	var cards = []
	for card in e.players[int(ctx.owner)].hand:
		if str(card.name) == name and cards.size() < 2: cards.append(card)
	e._v6._cancel(ctx)
	e._log("Раскрыта пара карт: %s." % name)
	_reveal(ctx,cards,[int(ctx.owner),int(ctx.owner)])
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner = int(ctx.owner)
	var fid = int(ctx.get("self",-1))
	var opponent = int(ctx.get("opponent",-1))
	match str(effect.kind):
		"v10_gadget_choice":
			if human(owner): _options("gadget",["Гипнолучевой бластер","Ультрабиотический тоник"],ctx)
			else: e.players[owner].gadget = "tonic" if int(e.fighters[fid].hp) < 10 else "hypno"
		"v10_gadget_during":
			if gadget_eligible(ctx) and gadget(owner) == "hypno":
				var other = e._v6._other(ctx)
				if int(ctx.card.get("value",0)) < int(other.get("card",{}).get("value",0)):
					var card = _top(int(ctx.opponent_owner))
					ctx.gadget_bonus = int(ctx.get("gadget_bonus",0))+int(card.get("boost",0))
					if not card.is_empty(): _reveal(ctx,[card],[int(ctx.opponent_owner)])
		"v10_gadget_after":
			if gadget_eligible(ctx) and gadget(owner) == "tonic" and int(ctx.card.get("value",0)) > int(e._v6._other(ctx).get("card",{}).get("value",0)): e._heal(e.hero_fighter(owner),1)
		"v10_end_charge":
			if human(owner): _options("end_charge",["Зарядить 1 катушку","Пропустить"],ctx)
			else: charge(owner,1)
		"v10_overflow":
			var ids = []
			for f in e.fighters:
				if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)) and e.fighters_adjacent(fid,int(f.id)): ids.append(int(f.id))
			e._damage_many(ids,1)
			for i in range(ids.size()-1,-1,-1): _queue({"kind":"move","target":"self","spaces":1},_with_self(ctx,int(ids[i])))
		"v10_coils": _coil_choice(str(effect.mode),ctx)
		"v10_charge": charge(owner,int(effect.get("win_amount",effect.amount)) if bool(ctx.won) else int(effect.amount))
		"v10_alternating":
			if human(owner): _options("alternating",["Зарядить обе катушки"]+(["Разрядить обе: восстановить 2 здоровья"] if coils(owner) == 2 else []),ctx)
			elif coils(owner) == 2 and int(e.fighters[fid].hp) <= 10: charge(owner,-2); e._heal(fid,2)
			else: charge(owner,2)
		"v10_xray":
			var card = _top(int(ctx.opponent_owner))
			_queue({"kind":"v10_coils","mode":"xray"},ctx)
			if not card.is_empty(): _reveal(ctx,[card],[int(ctx.opponent_owner)])
		"v10_hypnotist":
			if gadget(owner) == "hypno": e._v6._cancel(ctx)
		"v10_stasis":
			var other = e._v6._other(ctx)
			if not other.is_empty(): other.locked_value = int(other.get("card",{}).get("value",0)); other.value = int(other.locked_value)
		"v10_cloth": ctx.no_effect_damage = true
		"v10_wits":
			var own = _top(owner)
			var enemy = _top(int(ctx.opponent_owner))
			if int(own.get("boost",0)) > int(enemy.get("boost",0)): _queue({"kind":"damage","target":"opposing_combatant","amount":3},ctx)
			var cards = []
			var owners = []
			for pair in [[own,owner],[enemy,int(ctx.opponent_owner)]]:
				if not pair[0].is_empty(): cards.append(pair[0]); owners.append(pair[1])
			_reveal(ctx,cards,owners)
		"v10_belt":
			if human(owner): _options("belt",["Восстановить Джилл 1 здоровье","Передвинуть Джилл на 0–1 клетку","Взять 1 карту"],ctx)
			else: e._heal(e.hero_fighter(owner),1) if int(e.fighters[e.hero_fighter(owner)].hp) < 12 else e._draw(owner,1)
		"v10_inspect": _inspect(ctx,bool(effect.bottom))
		"v10_assistant": _assistant(ctx)
		"v10_captain":
			var ids = []
			for f in e.fighters:
				if e._valid_fighter(int(f.id)) and e.are_allies(owner,int(f.owner)) and int(f.id) != e.hero_fighter(owner): ids.append(int(f.id))
			if not ids.is_empty():
				if human(owner): _fighters("captain",ids,ctx)
				else: _queue({"kind":"place","fixed_fighter":int(ids[0]),"zone_anchor":e.hero_fighter(owner)},ctx)
		"v10_lagniappe":
			var limit = mini(2,int(e.fighters[fid].hp)-(1 if int(e.fighters[fid].get("queen_until",-1)) == e.turn_number else 0))
			if human(owner):
				var labels = []
				for n in range(limit+1): labels.append("Нанести себе урон и взять карт: %d" % n)
				_options("lagniappe",labels,ctx)
			else:
				var amount = mini(limit,maxi(0,int(e.fighters[fid].hp)-1))
				e._damage(fid,amount)
				e._draw(owner,amount)
		"v10_queen": e.fighters[e.hero_fighter(owner)].queen_until = e.turn_number
		"v10_together":
			if e._valid_fighter(fid):
				var ids = []
				for f in e.fighters:
					if int(f.id) != fid and e._valid_fighter(int(f.id)) and e.are_allies(owner,int(f.owner)) and e.fighters_adjacent(fid,int(f.id)): ids.append(int(f.id))
				if not ids.is_empty():
					e._heal(fid,1)
					for id in ids: e._heal(id,1)
		"v10_long_shot":
			if e._valid_fighter(fid) and e._valid_fighter(opponent) and not e.fighters_adjacent(fid,opponent): ctx.value = 5
		"v10_pair":
			var pairs = []
			var labels = []
			for card in e.players[owner].hand:
				var count = 0
				for other in e.players[owner].hand:
					if str(other.name) == str(card.name): count += 1
				if count >= 2 and not pairs.has(str(card.name)): pairs.append(str(card.name)); labels.append(str(card.name))
			if not pairs.is_empty():
				if human(owner): _options("pair",labels+["Не раскрывать карты"],ctx,{"pairs":pairs})
				else: _show_pair(ctx,str(pairs[0]))
		"v10_swap":
			if _own_pair(owner).size() == 2:
				if human(owner): _options("swap",["Поменяться местами","Остаться"],ctx)
				else: e._v8._swap(ctx,true)
		"v10_bottom":
			if not e.players[owner].deck.is_empty():
				var card = e.players[owner].deck[0]
				ctx.value += int(card.get("boost",0))
				_queue({"kind":"v10_bottom_choice","card":card.duplicate(true)},ctx)
				_reveal(ctx,[card],[owner])
		"v10_bottom_choice":
			if human(owner): _options("bottom",["Оставить внизу","Положить наверх"],ctx,{"cards":[effect.card.duplicate(true)],"victim":owner})
			elif not e.players[owner].deck.is_empty() and e._card_quality(effect.card) >= 3: e.players[owner].deck.append(e.players[owner].deck.pop_front())
		"v10_zone_damage": _zone_damage(ctx,int(effect.get("win_amount",effect.amount)) if bool(ctx.won) else int(effect.amount))
		"v10_fortress":
			if not e.players[owner].discard.is_empty():
				if human(owner): _cards("fortress",owner,"discard",range(e.players[owner].discard.size()),ctx)
				else: _shuffle_selected(owner,[0])
		"v10_random_retrieve":
			if not e.players[owner].discard.is_empty(): e.players[owner].hand.append(e.players[owner].discard.pop_at(e.rng.randi_range(0,e.players[owner].discard.size()-1)))
		"v10_no_shared":
			if e._valid_fighter(fid) and fid < e.turn_start_nodes.size() and not e._same_zone(int(e.fighters[fid].node),int(e.turn_start_nodes[fid])): ctx.value = int(effect.value)
		"v10_roar":
			for f in e.fighters:
				if f.alive: f.locked_until = e.turn_number
			e._log("Ужасающий рёв: все бойцы неподвижны до конца текущего хода.")
		_: return false
	return true
func _finish_assistant(p: Dictionary): _shuffle_selected(int(p._ctx.owner),p.get("chosen",[]))
func skip() -> bool:
	var p = e.pending_choice.duplicate(true)
	if not bool(p.get("can_skip",false)): return false
	if str(p.action) == "v10_assistant": _finish_assistant(p)
	_resume()
	return true
func choose_option(index: int) -> bool:
	var p = e.pending_choice.duplicate(true)
	if index < 0 or index >= p.get("options",[]).size(): return false
	var ctx = _live(p._ctx)
	var owner = int(ctx.owner)
	e.pending_choice.clear()
	match str(p.action).trim_prefix("v10_"):
		"reveal": pass
		"gadget": e.players[owner].gadget = "hypno" if index == 0 else "tonic"
		"end_charge":
			if index == 0: charge(owner,1)
		"coils": _discharge(str(p.mode),index,ctx,p.extra)
		"alternating":
			if index == 0: charge(owner,2)
			else: charge(owner,-2); e._heal(e.hero_fighter(owner),2)
		"belt":
			if index == 0: e._heal(e.hero_fighter(owner),1)
			elif index == 1: _queue({"kind":"move","target":"hero","spaces":1},ctx)
			else: e._draw(owner,1)
		"captain": _queue({"kind":"place","fixed_fighter":int(p.ids[index]),"zone_anchor":e.hero_fighter(owner)},ctx)
		"lagniappe": e._damage(int(ctx.self),index); e._draw(owner,index)
		"swap":
			if index == 0: e._v8._swap(ctx,true)
		"pair":
			if index < p.pairs.size(): _show_pair(ctx,str(p.pairs[index]))
		"bottom":
			if index == 1 and not e.players[owner].deck.is_empty(): e.players[owner].deck.append(e.players[owner].deck.pop_front())
		"fortress": _shuffle_selected(owner,[int(p.indices[index])])
		"assistant":
			p.chosen.append(int(p.indices[index]))
			p.cards.remove_at(index)
			p.indices.remove_at(index)
			p.remaining_count = int(p.remaining_count)-1
			if int(p.remaining_count) > 0 and not p.cards.is_empty():
				e.pending_choice = p
				e._refresh_card_options()
				e.phase = "effect_choice"
			else: _finish_assistant(p)
		"inspect":
			var card = p.cards.pop_at(index)
			if str(p.stage) == "bottom": e.players[int(p.victim)].deck.push_front(card); p.stage = "order"
			else: p.ordered.append(card)
			if p.cards.is_empty():
				for i in range(p.ordered.size()-1,-1,-1): e.players[int(p.victim)].deck.append(p.ordered[i])
			else:
				p.prompt = "Выберите порядок сверху: первая выбранная карта будет верхней"
				e.pending_choice = p
				e._refresh_card_options()
				e.phase = "effect_choice"
		_: return false
	if e.pending_choice.is_empty(): _resume()
	else: e.changed.emit()
	return true
