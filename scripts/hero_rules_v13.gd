extends "res://scripts/hero_rules_v8.gd"
## Slings and Arrows. All piles, choices and continuation state live in the save.
func _init(engine): super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra = {}, optional = false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v13_"+action
func setup():
	for p in e.players:
		if p.hero_id=="william_shakespeare": p.line=[]
		if p.hero_id=="the_wayward_sisters": p.cauldron=[]
		if p.hero_id=="hamlet": p.question="be"
		if p.hero_id=="titania":
			p.glamour="";p.glamour_discard=[];p.glamour_deck=["greed","invisibility","jealousy","love","rhyme","sleep"];e._shuffle(p.glamour_deck)
func glamour(owner: int) -> String: return str(e.players[owner].get("glamour","")) if owner>=0 and owner<e.players.size() else ""
func special_cards() -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string("res://data/special_cards.json"))
func glamour_name(id: String) -> String: return str(special_cards().glamours.get(id,{}).get("name","Нет открытых чар"))
func syllables(owner: int) -> int:
	var n=0
	for c in e.players[owner].get("line",[]): n+=int(c.get("syllables",0))
	return n
func ingredients(owner: int) -> Array:
	var found=[]
	for c in e.players[owner].get("cauldron",[]):
		var symbol=str(c.get("ingredient",""))
		if not symbol.is_empty() and not found.has(symbol): found.append(symbol)
	return found
func summary(owner: int) -> String:
	if e._is_hero(owner,"william_shakespeare"): return "Строка: %d/10 слогов · карт %d" % [syllables(owner),e.players[owner].get("line",[]).size()]
	if e._is_hero(owner,"hamlet"): return "Быть: манёвр +1 карта" if e.players[owner].get("question","be")=="be" else "Не быть: атаки Гамлета +2"
	if e._is_hero(owner,"titania"):
		return "%s · сброшено чар: %d · осталось: %d" % [glamour_name(glamour(owner)),e.players[owner].get("glamour_discard",[]).size(),e.players[owner].get("glamour_deck",[]).size()]
	if e._is_hero(owner,"the_wayward_sisters"):
		var n={"snake":0,"bat":0,"lizard":0}
		for c in e.players[owner].get("cauldron",[]):
			if n.has(str(c.get("ingredient",""))): n[str(c.ingredient)]+=1
		return "Котёл: змея %d · мышь %d · ящерица %d" % [n.snake,n.bat,n.lizard]
	return ""
func start_turn() -> bool:
	var owner=e.active
	if e._is_hero(owner,"hamlet"):
		e._start_ability(owner,"Быть или не быть",[{"kind":"v13_question"}],"start_turn");return true
	if e._is_hero(owner,"titania") and glamour(owner).is_empty() and not e.players[owner].glamour_deck.is_empty():
		e.players[owner].glamour=e.players[owner].glamour_deck.pop_back();e._log("Открыты чары: %s." % glamour_name(glamour(owner)))
	return false
func end_turn() -> bool:
	if glamour(e.active)!="greed": return false
	e._start_ability(e.active,"Чары жадности",[{"kind":"v13_greed"}],"end_turn");return true
func maneuver() -> bool:
	if glamour(e.active)!="love": return false
	e._start_ability(e.active,"Чары любви",[{"kind":"v13_move_any","remaining":1,"spaces":1,"enemies":true,"optional":true}],"maneuver");return true
func attack_bonus(fid: int) -> int:
	return 2 if e.fighters[fid].hero and e._is_hero(int(e.fighters[fid].owner),"hamlet") and e.players[int(e.fighters[fid].owner)].get("question","be")=="not_be" else 0
func estimate(card: Dictionary, fid: int, target: int, value: float) -> float:
	# Uses only own cards/piles and public board state, never the facedown attack.
	var owner=int(e.fighters[fid].owner)
	if e._has_kind(card,"v13_ingredients"): value+=ingredients(owner).size()
	if e._has_kind(card,"v13_horror"):
		for c in e.players[owner].get("line",[]):
			if c.id=="horror": value+=1
	if e._has_kind(card,"v13_queen"): value+=e.players[owner].get("glamour_discard",[]).size()
	if e._has_kind(card,"v13_fairy_song") and not glamour(owner).is_empty(): value=5
	if e._has_kind(card,"v13_hand_value"): value=maxi(0,e.players[owner].hand.size()-1)
	if e._has_kind(card,"v13_stars"):
		var zones=[]
		for id in _living(owner):
			for zone in e.nodes[int(e.fighters[int(id)].node)].zones:
				if not zones.has(zone): zones.append(zone)
		value=zones.size()
	if e._has_kind(card,"v13_brute") and e._valid_fighter(target):
		for id in _living(owner):
			if e.fighters_adjacent(int(id),target): value+=1
	if e._has_kind(card,"v13_but_dream"): value+=5
	return value
func effect_protected(fid: int) -> bool: return glamour(int(e.fighters[fid].owner))=="sleep"
func _sequence(effects: Array, ctx: Dictionary):
	for i in range(effects.size()-1,-1,-1): _queue(effects[i],ctx)
func _ctx(owner: int) -> Dictionary:
	return {"owner":owner,"self":e.hero_fighter(owner),"opponent":-1,"opponent_owner":-1,"card":{"name":"Способность героя"},"won":false}
func prepare_defense() -> bool:
	if e.pending_combat.get("glamour_checked",false): return false
	e.pending_combat.glamour_checked=true
	var owner=int(e.pending_combat.defender_owner)
	if glamour(owner)!="jealousy": return false
	var target=int(e.pending_combat.target);var other=-1
	for f in e.fighters:
		if int(f.owner)==owner and int(f.id)!=target and e._valid_fighter(int(f.id)): other=int(f.id)
	if other<0 or not can_relocate(target) or not can_relocate(other): return false
	if human(owner):
		_options("jealousy",["Поменять защитника","Оставить защитника"],_ctx(owner),{"target":target,"other":other});return true
	if e.fighters[target].hero and e.fighters[other].hp>=2: _jealousy_swap(target,other)
	return false
func _jealousy_swap(target: int, other: int):
	if e._swap_combatants(target,other):
		e.pending_combat.target=other;e._log("Чары ревности: другой боец становится защитником.")
func _line_discard(owner: int):
	for card in e.players[owner].line: e._discard(owner,card)
	e.players[owner].line.clear()
func collect_combat():
	var ended=bool(e._flow.get("end_turn",false))
	for slot in ["d","a"]:
		var owner=int(e._flow.defender_owner if slot=="d" else e._flow.attack_owner)
		var card: Dictionary=e._flow.defense_card if slot=="d" else e._flow.attack_card
		if card.is_empty() or card.get("virtual",false): continue
		var receiver=int(e._flow.attack_owner if slot=="d"else e._flow.defender_owner)
		if e._v33.collect(owner,card):continue
		if e._v32.collect(owner,card,receiver):continue
		if e._flow.get("pact_collected_"+slot,false):continue
		if e._flow.get("bottom_"+slot,false):e.players[owner].deck.push_front(card);continue
		if e._flow.get("return_"+slot,false): e.players[owner].hand.append(card);continue
		if e._flow.get("shuffle_"+slot,false):e.players[owner].deck.append(card);e._shuffle(e.players[owner].deck);continue
		if e._is_hero(owner,"william_shakespeare") and not ended:
			e.players[owner].line.append(card)
			var n=syllables(owner)
			e._log("Строка Шекспира: %d/10 слогов." % n)
			if n==10:
				var ctx=e._combat_resolution.get(slot,_ctx(owner)).duplicate(true);ctx.line_count=e.players[owner].line.size()
				for effect in card.get("line_effects",[]): e._effect_queue.append({"effect":effect.duplicate(true),"ctx":ctx.duplicate(true)})
				e._effect_queue.append({"effect":{"kind":"v13_line_cleanup"},"ctx":ctx})
			elif n>10: _line_discard(owner)
		else: e._discard(owner,card,"played")
	if not ended and e._is_hero(int(e._flow.attack_owner),"the_wayward_sisters"):
		e._effect_queue.append({"effect":{"kind":"v13_cast","regular":true,"remaining":1,"used":[]},"ctx":e._combat_resolution.a.duplicate(true)})
func scheme_complete(owner: int):
	if glamour(owner)=="rhyme" and owner==e.active and e.gain_actions(owner,1): e._log("Чары рифмы: +1 действие.")
func _discard_glamour(owner: int) -> bool:
	if glamour(owner).is_empty(): return false
	e.players[owner].glamour_discard.append(glamour(owner));e.players[owner].glamour="";return true
func _living(owner=-1, enemy_owner=-1, exclude=[]) -> Array:
	var ids=[]
	for f in e.fighters:
		if not e._valid_fighter(int(f.id)) or exclude.has(int(f.id)): continue
		if owner>=0 and int(f.owner)!=owner: continue
		if enemy_owner>=0 and not e.is_enemy(enemy_owner,int(f.owner)): continue
		ids.append(int(f.id))
	return ids
func _fighter_choice(effect: Dictionary, ctx: Dictionary, ids: Array, optional=false):
	if ids.is_empty(): return
	var owner=int(ctx.owner)
	if human(owner):
		var labels=[]
		for id in ids: labels.append("%s · %d ОЗ" % [e.fighters[int(id)].name,int(e.fighters[int(id)].hp)])
		_options("fighter",labels,ctx,{"kind":"fighters","ids":ids,"allowed_fighters":ids,"operation":effect},optional)
	else:
		var chosen=int(ids[0]);var kind=str(effect.kind)
		if kind=="v13_heal_fighter":
			var best=-999
			for id in ids:
				var f=e.fighters[int(id)];var score=(int(f.max_hp)-int(f.hp))*(1 if e.are_allies(owner,int(f.owner)) else -1)
				if score>best: best=score;chosen=int(id)
		elif kind in ["v13_spell_damage","v13_move_any"]:
			for id in ids:
				if e.is_enemy(owner,int(e.fighters[int(id)].owner)): chosen=int(id);break
		_apply_fighter(effect,ctx,chosen)
func _apply_fighter(effect: Dictionary, ctx: Dictionary, fid: int):
	var owner=int(ctx.owner);var next=ctx.duplicate(true);next.self=fid;next.erase("_combat_slot")
	match str(effect.kind):
		"v13_pay_question": e._damage(fid,2)
		"v13_heal_fighter": e._heal(fid,int(effect.get("amount",1)))
		"v13_spell_damage": e._damage(fid,1)
		"v13_readiness": _sequence([{"kind":"place","target":"self"},{"kind":"v13_lock_target"}],next)
		"v13_move_any":
			var used=effect.get("used",[]).duplicate();used.append(fid)
			_queue({"kind":"v13_move_any","remaining":int(effect.get("remaining",1))-1,"spaces":int(effect.get("spaces",2)),"used":used,"enemies":bool(effect.get("enemies",false))},ctx)
			_queue({"kind":"move","target":"self","spaces":int(effect.get("spaces",2))},next)
func _place(ctx: Dictionary, fid: int, legal: Array):
	if legal.is_empty(): return
	if human(int(ctx.owner)):
		e.pending_choice={"kind":"place","title":str(ctx.card.name),"prompt":"Выберите клетку для размещения","legal":legal,"fighter":fid,"allowed_fighters":[fid],"mode":"one","can_skip":false,"_effect":{},"_ctx":ctx.duplicate(true)};e.phase="effect_move"
	else: e._enter_node(fid,int(legal[0]))
func _glamour_cost(action: String, ctx: Dictionary):
	if glamour(int(ctx.owner)).is_empty():
		if action=="wise": e._draw(int(ctx.owner))
		return
	if human(int(ctx.owner)): _options("glamour_cost",["Сбросить открытые чары","Сохранить чары"],ctx,{"mode":action})
	else: _paid_glamour(action,ctx,action!="woods" or int(e._v6._other(ctx).value)>=3)
func _paid_glamour(action: String, ctx: Dictionary, yes: bool):
	ctx=_live(ctx);var owner=int(ctx.owner)
	var paid=yes and _discard_glamour(owner)
	match action:
		"wise": e._draw(owner,2 if paid else 1)
		"whisk":
			if paid: _queue({"kind":"place","target":"self"},ctx)
		"fairy_song":
			if paid: ctx.value=5
		"woods":
			if paid: e._v6._cancel(ctx)
func available_spells(owner: int, free=false, used=[]) -> Array:
	var symbols=ingredients(owner);var needs=[["snake","bat"],["snake","lizard"],["lizard","bat"],["snake","lizard","bat"]];var result=[]
	for i in range(4):
		if used.has(i): continue
		var legal=true
		for symbol in needs[i]:
			if not symbols.has(symbol): legal=false
		if free or legal: result.append(i)
	return result
func spell_labels() -> Array:
	return ["Змея + мышь: взять 1 карту и вылечить своего бойца на 1","Змея + ящерица: передвинуть любого бойца на 0–3 клетки","Ящерица + мышь: 1 урон бойцу в зоне любой сестры","Три ингредиента: получить 1 действие"]
func _cast(effect: Dictionary, ctx: Dictionary):
	if int(effect.get("remaining",1))<=0: return
	var choices=available_spells(int(ctx.owner),not bool(effect.get("regular",false)),effect.get("used",[]))
	if choices.is_empty(): return
	if human(int(ctx.owner)):
		var labels=[]
		for id in choices: labels.append(spell_labels()[int(id)])
		_options("spell",labels,ctx,{"ids":choices,"operation":effect},bool(effect.get("regular",false)))
	else:
		var id=3 if choices.has(3) else 2 if choices.has(2) else 0 if choices.has(0) else int(choices[0]);_spell(id,effect,ctx)
func _spell(id: int, effect: Dictionary, ctx: Dictionary):
	var used=effect.get("used",[]).duplicate();used.append(id)
	var effects=[]
	match id:
		0: effects=[{"kind":"draw","amount":1},{"kind":"v13_heal_fighter","own":true,"amount":1}]
		1: effects=[{"kind":"v13_move_any","remaining":1,"spaces":3}]
		2: effects=[{"kind":"v13_spell_damage"}]
		3: effects=[{"kind":"gain_action","amount":1}]
	if bool(effect.get("regular",false)): effects.append({"kind":"v13_clear_cauldron"})
	elif int(effect.get("remaining",1))>1: effects.append({"kind":"v13_cast","regular":false,"remaining":int(effect.remaining)-1,"used":used})
	e._log("Заклинание сестёр: %s." % spell_labels()[id]);_sequence(effects,ctx)
func _method(ctx: Dictionary, count: int):
	var owner=int(ctx.owner)
	if human(owner) and not e.players[owner].hand.is_empty():
		_cards("method",owner,"hand",range(e.players[owner].hand.size()),ctx,{"count":count},true)
	else:
		if not human(owner):
			for i in range(mini(2,e.players[owner].hand.size())): e.players[owner].deck.push_front(e.players[owner].hand.pop_at(e._lowest_card(owner)));count+=1
		_method_draw(ctx,count)
func _method_draw(ctx: Dictionary, count: int):
	if human(int(ctx.owner)) and count>0:
		var labels=[]
		for i in range(count+1): labels.append("Взять карт: %d" % i)
		_options("method_draw",labels,ctx)
	else:
		e._draw(int(ctx.owner),count)
		if int(ctx.owner)==e.active: e.gain_actions(int(ctx.owner),1)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1))
	match str(effect.kind):
		"v13_question":
			if human(owner): _options("question",["Быть: манёвр +1 карта","Не быть: 2 урона своему бойцу, атаки Гамлета +2"],ctx)
			else:
				e.players[owner].question="not_be" if e.fighters[e.hero_fighter(owner)].hp>5 and e.players[owner].hand.size()>3 else "be"
				if e.players[owner].question=="not_be": _fighter_choice({"kind":"v13_pay_question"},ctx,_living(owner))
		"v13_greed":
			if human(owner): _options("greed",["Взять 1 карту","Пропустить"],ctx)
			else: e._draw(owner)
		"v13_pay_question": _fighter_choice(effect,ctx,_living(owner))
		"v13_horror":
			for c in e.players[owner].get("line",[]):
				if c.id=="horror": ctx.value+=1
		"v13_line_horror": e._damage(foe,maxi(0,int(ctx.get("line_count",0))-1))
		"v13_line_cleanup": _line_discard(owner)
		"v13_line_return":
			if not e.players[owner].line.is_empty(): e.players[owner].hand.append(e.players[owner].line.pop_back())
		"v13_zone_damage":
			if e._valid_fighter(fid):
				var ids=[]
				for f in e.fighters:
					if int(f.id)!=fid and e._valid_fighter(int(f.id)) and e._same_zone(int(f.node),int(e.fighters[fid].node)): ids.append(int(f.id))
				e._damage_many(ids,1)
		"v13_places":
			var hero=e.hero_fighter(owner);var legal=[]
			if e._valid_fighter(hero):
				for n in e.nodes:
					if e._occupant(int(n.id)) not in [-1,hero] or (not can_relocate(hero) and int(n.id)!=int(e.fighters[hero].node)): continue
					var actors=false
					for f in e.fighters:
						if int(f.owner)==owner and not f.hero and e._valid_fighter(int(f.id)) and e._same_zone(int(n.id),int(f.node)): actors=true
					if not actors: legal.append(int(n.id))
				_place(ctx,hero,legal)
		"v13_brute":
			if e._valid_fighter(foe):
				for f in e.fighters:
					if e._valid_fighter(int(f.id),owner) and e.fighters_adjacent(int(f.id),foe): ctx.value+=1
		"v13_revise": e._draw(owner,2 if bool(ctx.won) else 1)
		"v13_again":
			if not e.players[owner].get("line",[]).is_empty():
				if human(owner): _options("again",["Вернуть первую карту строки","Оставить строку"],ctx,{"cards":[e.players[owner].line[0]]})
				else: e.players[owner].hand.append(e.players[owner].line.pop_front())
		"v13_versatile_ignore":
			if str(e._v6._other(ctx).card.get("type",""))=="versatile": ctx.ignore_opponent_value=true
		"v13_hand_value": ctx.value=e.players[owner].hand.size()
		"v13_sleep_dream":
			if bool(ctx.won): _queue({"kind":"move","target":"opposing_combatant","spaces":int(ctx.get("damage_dealt",0))},ctx)
			else: e._heal(e.hero_fighter(owner),1)
		"v13_readiness": _fighter_choice(effect,ctx,[fid,foe].filter(func(id):return e._valid_fighter(int(id))))
		"v13_lock_target":
			if e._valid_fighter(fid): e.fighters[fid].locked_until=e.turn_number
		"v13_play_thing":
			var enemy=int(ctx.opponent_owner)
			if enemy>=0 and not e.players[enemy].hand.is_empty() and not e._v14.owl_protected(enemy):
				var c=e.players[enemy].hand.pop_at(e.rng.randi_range(0,e.players[enemy].hand.size()-1));e._discard_from_opponent(enemy,c)
				if bool(ctx.won): e._heal(e.hero_fighter(owner),int(c.get("boost",0)))
		"v13_blood":
			if int(e.fighters[e.hero_fighter(owner)].get("damaged_turn",-1))==e.turn_number: e._damage(foe,1)
		"v13_fortune":
			if not e.players[owner].deck.is_empty():
				var c=e.players[owner].deck.pop_back();ctx.fortune_card=c.duplicate(true);e._discard(owner,c,"deck");ctx.value+=int(c.get("boost",0))
		"v13_fortune_return":
			if not bool(ctx.won) and ctx.has("fortune_card"):
				var index=e.players[owner].discard.find(ctx.fortune_card)
				if index>=0: e.players[owner].hand.append(e.players[owner].discard.pop_at(index))
		"v13_versatile_damage":
			if str(e._v6._other(ctx).card.get("type",""))=="versatile": e._damage(foe,2)
		"v13_method": _method(ctx,0)
		"v13_ghost":
			if human(owner): _options("ghost",["Восстановить 2 здоровья","Разместить Гамлета в его зоне и получить действие"],ctx)
			else: e._heal(e.hero_fighter(owner),2)
		"v13_queen": ctx.value+=e.players[owner].get("glamour_discard",[]).size()
		"v13_moonlight": _queue({"kind":"place","target":"self","adjacent_to":e.hero_fighter(owner)},ctx)
		"v13_wise": _glamour_cost("wise",ctx)
		"v13_whisk": _glamour_cost("whisk",ctx)
		"v13_fairy_song": _glamour_cost("fairy_song",ctx)
		"v13_woods": _glamour_cost("woods",ctx)
		"v13_moon":
			if not e.players[owner].get("glamour_discard",[]).is_empty():
				if human(owner):
					var labels=[]
					for id in e.players[owner].glamour_discard: labels.append(glamour_name(str(id)))
					_options("moon",labels,ctx)
				else: e.players[owner].glamour_deck.push_front(e.players[owner].glamour_discard.pop_back())
		"v13_parting":
			if human(owner): _options("parting",["Нанести обоим по 2 урона","Пропустить"],ctx)
			else: e._damage_many([fid,foe],2)
		"v13_but_dream": e._v6._cancel(ctx);ctx.ignore_opponent_value=true;e._v6._other(ctx).return_card=true
		"v13_fair_gift":
			var options=[{"kind":"v13_heal_fighter","amount":2},{"kind":"draw","amount":2},{"kind":"v13_move_any","spaces":2,"remaining":2}]
			if human(owner):
				e._begin_manual_effect({"kind":"choose_two","options":options},ctx);e.pending_choice.options=["Вылечить любого бойца на 2","Взять 2 карты","Передвинуть двух бойцов на 0–2 клетки"]
			else: _sequence([options[0],options[1]],ctx)
		"v13_heal_fighter": _fighter_choice(effect,ctx,_living(owner if effect.get("own",false) else -1))
		"v13_move_any":
			if int(effect.get("remaining",1))>0: _fighter_choice(effect,ctx,_living(-1,owner if effect.get("enemies",false) else -1,effect.get("used",[])),bool(effect.get("optional",false)))
		"v13_fools":
			var enemies=[];var labels=[]
			for i in range(e.players.size()):
				if e.is_enemy(owner,i) and not e.players[i].hand.is_empty(): enemies.append(i);labels.append(str(e.players[i].name))
			if not enemies.is_empty():
				if human(owner) and enemies.size()>1: _options("fools_target",labels,ctx,{"ids":enemies})
				else: _fools_hand(ctx,int(enemies[0]))
		"v13_ingredients": ctx.value+=ingredients(owner).size()
		"v13_stars":
			var zones=[]
			for id in _living(owner):
				for zone in e.nodes[int(e.fighters[int(id)].node)].zones:
					if not zones.has(zone): zones.append(zone)
			ctx.value=zones.size()
		"v13_bubble":
			if not e.players[owner].discard.is_empty():
				if human(owner): _cards("bubble",owner,"discard",range(e.players[owner].discard.size()),ctx)
				else: e.players[owner].cauldron.append(e.players[owner].discard.pop_back())
		"v13_curious":
			if not e.players[owner].get("cauldron",[]).is_empty():
				if human(owner): _cards("curious",owner,"cauldron",range(e.players[owner].cauldron.size()),ctx)
				else: e.players[owner].hand.append(e.players[owner].cauldron.pop_back())
		"v13_familiar":
			if not e.players[owner].deck.is_empty():
				if human(owner): _options("familiar",["Положить в руку","Положить в котёл"],ctx,{"cards":[e.players[owner].deck[-1]]})
				else: e.players[owner].hand.append(e.players[owner].deck.pop_back())
		"v13_hurly":
			if not e.players[owner].deck.is_empty():
				var top=e.players[owner].deck.pop_back();var other=int(ctx.opponent_owner)
				if human(other): _options("hurly",["Положить в руку соперника","В котёл соперника и усилить его карту"],ctx,{"top":top,"cards":[top],"owner":other,"viewer":other})
				else:
					_hurly(ctx,top,0 if int(top.get("boost",0))>1 else 1)
					if e.interactive and not e.players[0].bot: _options("reveal",["Продолжить"],ctx,{"top":top,"cards":[top],"viewer":0,"prompt":"Раскрыта верхняя карта колоды. Выбор соперника отражён в журнале."})
		"v13_ward":
			var next=ctx.duplicate(true);next.self=foe;next.erase("_combat_slot");_queue({"kind":"place","target":"self","zone_anchor":fid},next)
		"v13_pricking": e._damage(foe,int(ctx.get("damage_taken",0)))
		"v13_remedy":
			if int(effect.get("remaining",3))>0 and not e.players[owner].get("cauldron",[]).is_empty():
				if human(owner): _cards("remedy",owner,"cauldron",range(e.players[owner].cauldron.size()),ctx,{"remaining":int(effect.get("remaining",3))},true)
				else:
					e.players[owner].discard.append(e.players[owner].cauldron.pop_back());_sequence([{"kind":"v13_heal_fighter","amount":1},{"kind":"v13_remedy","remaining":int(effect.get("remaining",3))-1}],ctx)
		"v13_cast": _cast(effect,ctx)
		"v13_spell_damage":
			var ids=[]
			for id in _living():
				for sister in _living(owner):
					if e._same_zone(int(e.fighters[int(id)].node),int(e.fighters[int(sister)].node)) and not ids.has(id): ids.append(id)
			_fighter_choice(effect,ctx,ids)
		"v13_clear_cauldron":
			e.players[owner].discard.append_array(e.players[owner].cauldron);e.players[owner].cauldron.clear()
		_: return false
	return true
func _hurly(ctx: Dictionary, top: Dictionary, index: int):
	ctx=_live(ctx);var owner=int(ctx.owner)
	if index==0: e.players[owner].hand.append(top)
	else: e.players[owner].cauldron.append(top);ctx.value+=int(top.get("boost",0))
	e._log("Суматоха: %s → %s." % [str(top.name),"рука" if index==0 else "котёл и усиление"])
func _fools_hand(ctx: Dictionary, victim: int):
	if human(int(ctx.owner)): _cards("fools",victim,"hand",range(e.players[victim].hand.size()),ctx,{"viewer":int(ctx.owner),"owner":int(ctx.owner)})
	else:
		var index=e._lowest_card(victim,true);e.players[victim].deck.append(e.players[victim].hand.pop_at(index));e._shuffle(e.players[victim].deck)
func skip() -> bool:
	if not e.pending_choice.get("can_skip",false): return false
	var p=e.pending_choice.duplicate(true);e.pending_choice.clear()
	if p.action=="v13_method":
		_method_draw(p._ctx,int(p.count))
		if e.phase=="effect_choice" and not e.pending_choice.is_empty(): e.changed.emit();return true
	_resume();return true
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.get("options",[]).size(): return false
	e.pending_choice.clear();var ctx=_live(p._ctx);var owner=int(ctx.owner)
	match str(p.action).trim_prefix("v13_"):
		"jealousy":
			if index==0: _jealousy_swap(int(p.target),int(p.other))
			e._begin_defense();e.changed.emit();return true
		"question":
			e.players[owner].question="be" if index==0 else "not_be"
			if index==1: _queue({"kind":"v13_pay_question"},ctx)
		"fighter": _apply_fighter(p.operation,ctx,int(p.ids[index]))
		"greed":
			if index==0: e._draw(owner)
		"again":
			if index==0 and not e.players[owner].line.is_empty(): e.players[owner].hand.append(e.players[owner].line.pop_front())
		"glamour_cost": _paid_glamour(str(p.mode),ctx,index==0)
		"moon": e.players[owner].glamour_deck.push_front(e.players[owner].glamour_discard.pop_at(index))
		"parting":
			if index==0: e._damage_many([int(ctx.self),int(ctx.opponent)],2)
		"fools_target":
			_fools_hand(ctx,int(p.ids[index]))
			if not e.pending_choice.is_empty(): e.changed.emit();return true
		"fools":
			var victim=int(p.victim);e.players[victim].deck.append(e.players[victim].hand.pop_at(int(p.indices[index])));e._shuffle(e.players[victim].deck)
		"bubble": e.players[owner].cauldron.append(e.players[owner].discard.pop_at(int(p.indices[index])))
		"curious": e.players[owner].hand.append(e.players[owner].cauldron.pop_at(int(p.indices[index])))
		"familiar":
			if index==0: e.players[owner].hand.append(e.players[owner].deck.pop_back())
			else: e.players[owner].cauldron.append(e.players[owner].deck.pop_back())
		"hurly": _hurly(ctx,p.top,index)
		"reveal": pass
		"remedy":
			e.players[owner].discard.append(e.players[owner].cauldron.pop_at(int(p.indices[index])));_sequence([{"kind":"v13_heal_fighter","amount":1},{"kind":"v13_remedy","remaining":int(p.remaining)-1}],ctx)
		"spell": _spell(int(p.ids[index]),p.operation,ctx)
		"method":
			e.players[owner].deck.push_front(e.players[owner].hand.pop_at(int(p.indices[index])));_method(ctx,int(p.count)+1)
			if not e.pending_choice.is_empty(): e.changed.emit();return true
		"method_draw":
			e._draw(owner,index)
			if owner==e.active: e.gain_actions(owner,1)
		"ghost":
			if index==0: e._heal(e.hero_fighter(owner),2)
			else:
				var next=ctx.duplicate(true);next.self=e.hero_fighter(owner);_sequence([{"kind":"place","target":"self","same_zone":true},{"kind":"gain_action","amount":1}],next)
		_: return false
	_resume();return true

func can_relocate(fid: int) -> bool:
	if e._v35.block_move(fid):return false
	return e._valid_fighter(fid) and int(e.fighters[fid].get("locked_until",-1))!=e.turn_number
