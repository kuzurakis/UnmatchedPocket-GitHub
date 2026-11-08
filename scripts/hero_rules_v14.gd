extends "res://scripts/hero_rules_v8.gd"
## Witcher: Steel & Silver. Gear, ongoing schemes and routes are saved data.
const GEAR={"sword":["steel","silver"],"armor":["medallion","forgotten"],"potion":["blizzard","owl"]}
func _init(engine): super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v14_"+action
func select_gear(owner: int, config: Dictionary) -> Dictionary:
	var selected=config.get("geralt_gears",{}).get(owner,config.get("geralt_gears",{}).get(str(owner),config.get("geralt_gear",{}) if owner==0 else {}));var result={}
	for slot in GEAR:
		var value=str(selected.get(slot,GEAR[slot][e.rng.randi_range(0,1)]))
		result[slot]=value if GEAR[slot].has(value) else GEAR[slot][0]
	return result
func gear_names() -> Dictionary:
	return {"steel":"Стальной меч","silver":"Серебряный меч","medallion":"Медальон Школы Волка","forgotten":"Доспех Забытой Школы Волка","blizzard":"Пурга","owl":"Неясыть"}
func setup():
	for p in e.players:
		p.ongoing={};p.owl_ignore=true
func source_count(owner: int) -> int:
	var n=0
	for c in e.players[owner].discard:
		if c.get("source",false): n+=1
	return n
func ongoing(owner: int) -> String:
	return str(e.players[owner].get("ongoing",{}).get("ongoing","")) if owner>=0 and owner<e.players.size() else ""
func owl_protected(owner: int) -> bool:
	return ongoing(owner)=="gear_tawny_owl" and bool(e.players[owner].get("owl_ignore",true))
func action_blocked(owner: int) -> bool:
	for p in range(e.players.size()):
		if e.players[p].alive and e.is_enemy(owner,p) and ongoing(p)=="gear_blizzard": return true
	return false
func summary(owner: int) -> String:
	var parts=[]
	if e._is_hero(owner,"ciri"): parts.append("Источник: %d · эффекты нельзя отменить" % source_count(owner) if source_count(owner)>=7 else "Источник: %d/7" % source_count(owner))
	if e._is_hero(owner,"ancient_leshen"):
		parts.append("Леший: шаг 1 · волки: шаг 3")
		if leshen_attacks(owner)>0: parts.append("Следующая атака Лешего: +3")
		if e.fighters[e.hero_fighter(owner)].get("offboard",false):parts.append("Леший вне поля до своего хода")
	if e._is_hero(owner,"geralt_of_rivia"):
		var names=[]
		for value in e.players[owner].get("gear",{}).values(): names.append(gear_names().get(str(value),str(value)))
		parts.append(" · ".join(names))
	if not ongoing(owner).is_empty(): parts.append("Постоянно: %s" % str(e.players[owner].ongoing.name))
	return "\n".join(parts)
func begin_scheme(owner: int, card: Dictionary):
	if not card.has("ongoing"):return
	_discard_ongoing(owner)
func _discard_ongoing(owner: int):
	if e.players[owner].get("ongoing",{}).is_empty():return
	var c=e.players[owner].ongoing;e.players[owner].ongoing={};e._discard(owner,c);e._v17.refresh_boosts(owner);e._log("Постоянный приём сброшен: %s." % str(c.name))
func collect_scheme(owner: int, card: Dictionary) -> bool:
	if card.has("ongoing"):
		e.players[owner].ongoing=card;e._v17.refresh_boosts(owner);e._log("Постоянный приём активен: %s." % str(card.name));return true
	if e._flow.get("shuffle_scheme",false):
		e.players[owner].deck.append(card);e._shuffle(e.players[owner].deck);return true
	return false
func end_turn():
	var owner=e.active;var id=ongoing(owner)
	if id in ["gear_blizzard","gear_tawny_owl","might_of_the_aen_elle","advisor_to_the_king"] and int(e.players[owner].get("attacked_turn",-1))!=e.turn_number: _discard_ongoing(owner)
	if id=="unicorn_ally" and e.players[owner].hand.size()>=5:_discard_ongoing(owner)
	if id=="strength_of_the_pack":
		var hero=e.hero_fighter(owner);var nearby=false
		for f in e.fighters:
			if int(f.owner)==owner and not f.hero and e._valid_fighter(int(f.id)) and e._valid_fighter(hero) and e._same_zone(int(f.node),int(e.fighters[hero].node)):nearby=true
		if not nearby:_discard_ongoing(owner)
func start_turn() -> bool:
	var owner=e.active;var hero=e.hero_fighter(owner)
	if not e._is_hero(owner,"ancient_leshen") or hero<0 or not e.fighters[hero].alive:return false
	var effects=[]
	if e.fighters[hero].get("offboard",false):
		e.fighters[hero].offboard=false;e.fighters[hero].returning_offboard=true
		effects.append({"kind":"place","target":"hero"});effects.append({"kind":"v14_return_done"})
	if ongoing(owner)=="strength_of_the_pack":effects.append({"kind":"heal","target":"hero","amount":1})
	if effects.is_empty():return false
	e._start_ability(owner,"Сердце леса",effects,"start_turn");return true
func leshen_attacks(owner: int) -> int:
	return int(e.players[owner].get("leshen_attacks",0)) if int(e.players[owner].get("leshen_attack_turn",-1))==e.turn_number else 0
func attack_started(fid: int):
	var owner=int(e.fighters[fid].owner);e.players[owner].attacked_turn=e.turn_number
	if e._is_hero(owner,"ancient_leshen") and e.fighters[fid].hero:
		e.players[owner].leshen_attacks=leshen_attacks(owner)+1;e.players[owner].leshen_attack_turn=e.turn_number
func attack_bonus(fid: int) -> int:
	return 3 if e._is_hero(int(e.fighters[fid].owner),"ancient_leshen") and e.fighters[fid].hero and leshen_attacks(int(e.fighters[fid].owner))>=2 else 0
func estimate(card: Dictionary, fid: int, target: int, value: float) -> float:
	var owner=int(e.fighters[fid].owner);var count=source_count(owner)
	if e._has_kind(card,"v14_lion") and count>=1:value=7 if count>=5 else 4
	if e._has_kind(card,"v14_zireael") and count>=3:value=4
	if e._has_kind(card,"v14_channel"):
		for c in e.players[owner].hand:
			if c.get("source",false):value+=2
	if e._has_kind(card,"v14_harrying"):
		for id in _adjacent(target):
			if int(e.fighters[int(id)].owner)==owner:value+=2
	if e._has_kind(card,"v14_armor"):value+=_adjacent(e.hero_fighter(owner)).size()
	if e._has_kind(card,"v14_medallion") and not _adjacent(e.hero_fighter(owner)).has(target):value+=5
	return value
func combat_complete():
	if e._flow.get("end_turn",false):return
	for slot in ["d","a"]:
		var ctx=e._combat_resolution.get(slot,{})
		if not ctx.is_empty() and ongoing(int(ctx.owner))=="unicorn_ally":e._effect_queue.append({"effect":{"kind":"draw","amount":1},"ctx":ctx.duplicate(true)})
func _sequence(effects: Array, ctx: Dictionary):
	for i in range(effects.size()-1,-1,-1):_queue(effects[i],ctx)
func _adjacent(fid: int) -> Array:
	var ids=[]
	if not e._valid_fighter(fid):return ids
	for f in e.fighters:
		if e._valid_fighter(int(f.id)) and e.fighters_adjacent(fid,int(f.id)):ids.append(int(f.id))
	return ids
func board_distance(a: int, b: int) -> int:
	var queue=[[a,0]];var seen=[a]
	while not queue.is_empty():
		var item=queue.pop_front()
		if int(item[0])==b:return int(item[1])
		for n in e.nodes[int(item[0])].neighbors:
			if not seen.has(n):seen.append(n);queue.append([n,int(item[1])+1])
	return 999
func _fighter(action: String, ids: Array, ctx: Dictionary, extra={}, optional=false):
	if ids.is_empty():return
	if human(int(ctx.owner)):
		var labels=[]
		for id in ids:labels.append("%s · %d ОЗ" % [e.fighters[int(id)].name,int(e.fighters[int(id)].hp)])
		_options(action,labels,ctx,{"ids":ids,"extra":extra,"allowed_fighters":ids,"kind":"fighters"},optional)
	else:
		var chosen=int(ids[0])
		for id in ids:
			if e.is_enemy(int(ctx.owner),int(e.fighters[int(id)].owner)):chosen=int(id);break
		_apply_fighter(action,chosen,ctx,extra)
func _apply_fighter(action: String, fid: int, ctx: Dictionary, extra: Dictionary):
	match action:
		"damage":e._damage(fid,int(extra.get("amount",1)))
		"swap":e._swap_combatants(e.hero_fighter(int(ctx.owner)),fid)
		"wolf":_place_wolf(fid,ctx)
func _place_wolf(fid: int, ctx: Dictionary):
	var hero=e.hero_fighter(int(ctx.owner));var legal=[]
	if not e._valid_fighter(hero):return
	for n in e.nodes:
		if not e._same_zone(int(e.fighters[hero].node),int(n.id)):continue
		if e._occupant(int(n.id)) not in [-1,fid]:continue
		if e.fighters[fid].alive and int(e.fighters[fid].get("locked_until",-1))==e.turn_number and int(n.id)!=int(e.fighters[fid].node):continue
		legal.append(int(n.id))
	if legal.is_empty():return
	if human(int(ctx.owner)):
		e.pending_choice={"kind":"place" if e.fighters[fid].alive else "revive_sidekick","title":str(ctx.card.name),"prompt":"Разместите призванного волка в зоне Лешего","legal":legal,"fighter":fid,"allowed_fighters":[fid],"mode":"one","can_skip":false,"_effect":{},"_ctx":ctx.duplicate(true)};e.phase="effect_move"
	else:e.fighters[fid].alive=true;e.fighters[fid].hp=e.fighters[fid].max_hp;e._enter_node(fid,int(legal[0]))
func _reveal(card: Dictionary, owner: int, ctx: Dictionary):
	e._log("Раскрыта карта: %s." % str(card.name))
	if e.interactive and not e.players[0].bot:
		_options("reveal",["Продолжить"],ctx,{"kind":"hand_view","deck_view":true,"cards":[card.duplicate(true)],"card_owners":[owner],"victim":owner,"viewer":0,"prompt":"Раскрытая карта"})
func _senses(ctx: Dictionary):
	var owner=int(ctx.owner);var choices=[];var labels=[];var cards=[]
	for source in ["deck","discard"]:
		for i in range(e.players[owner][source].size()):
			var c=e.players[owner][source][i]
			if not c.has("gear_slot"):continue
			choices.append({"source":source,"index":i});labels.append("%s · %s" % [str(c.name),"колода" if source=="deck" else "сброс"]);cards.append(c)
	if choices.is_empty():return
	if human(owner):_options("senses",labels,ctx,{"choices":choices,"cards":cards,"victim":owner})
	else:_take_gear(choices[0],ctx)
func _take_gear(choice: Dictionary, ctx: Dictionary):
	var owner=int(ctx.owner);var c=e.players[owner][str(choice.source)].pop_at(int(choice.index));e.players[owner].hand.append(c)
	if str(choice.source)=="deck":e._flow.shuffle_scheme=true;_reveal(c,owner,ctx)
func _channel(ctx: Dictionary):
	var owner=int(ctx.owner);var indices=[]
	for i in range(e.players[owner].hand.size()):
		if e.players[owner].hand[i].get("source",false):indices.append(i)
	if indices.is_empty():return
	if human(owner):_cards("channel",owner,"hand",indices,ctx,{},true)
	else:
		for n in range(indices.size()-1,-1,-1):e._discard(owner,e.players[owner].hand.pop_at(int(indices[n])));ctx.value+=2
func _lady(ctx: Dictionary):
	var owner=int(ctx.owner);var count=source_count(owner)
	if count<3 or e.players[owner].discard.is_empty():return
	if human(owner):_cards("lady",owner,"discard",range(e.players[owner].discard.size()),ctx,{"to_hand":count>=8})
	else:_lady_card(ctx,e.players[owner].discard.size()-1,count>=8)
func _lady_card(ctx: Dictionary, index: int, to_hand: bool):
	var owner=int(ctx.owner);var c=e.players[owner].discard.pop_at(index)
	if to_hand:e.players[owner].hand.append(c);e._draw(owner)
	else:e.players[owner].deck.append(c)
func _source_search(ctx: Dictionary):
	var owner=int(ctx.owner);var ids=[]
	for i in range(e.players[owner].deck.size()):
		if e.players[owner].deck[i].get("source",false):ids.append(i)
	if ids.is_empty():return
	if human(owner):_cards("source_search",owner,"deck",ids,ctx,{},true)
	else:_take_source(owner,int(ids[0]),ctx)
func _take_source(owner: int, index: int, ctx: Dictionary):
	var c=e.players[owner].deck.pop_at(index);e.players[owner].hand.append(c);e._shuffle(e.players[owner].deck);_reveal(c,owner,ctx)
func _path_options(state: Dictionary, ctx: Dictionary):
	var fid=int(state.fighter);var current=int(state.route[-1]);var choices=[];var labels=[]
	if e._occupant(current) in [-1,fid]:choices.append(-1);labels.append("Завершить маршрут на клетке %d" % (current+1))
	if state.route.size()<=4 and int(e.fighters[fid].get("locked_until",-1))!=e.turn_number and (current==int(state.route[0]) or e._enemy_trap_at(current,int(e.fighters[fid].owner))<0):
		for n in e.nodes[current].get("move_neighbors",e.nodes[current].neighbors):
			var occupant=e._occupant(int(n))
			if occupant>=0 and occupant!=fid and (state.route.size()==4 or e._enemy_trap_at(int(n),int(e.fighters[fid].owner))>=0):continue
			choices.append(int(n));labels.append("Шаг на клетку %d" % (int(n)+1))
	if choices.is_empty():return
	_options("path",labels,ctx,{"state":state,"choices":choices,"prompt":"Иггоракс: выберите путь. Пройденных врагов можно выбрать для 1 урона."})
func _path_finish(state: Dictionary, ctx: Dictionary):
	var fid=int(state.fighter);var passed=[]
	for i in range(1,state.route.size()):
		var node=int(state.route[i]);var occupant=e._occupant(node)
		if occupant>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[occupant].owner)) and not passed.has(occupant):passed.append(occupant)
		var trap=e._enemy_trap_at(node,int(ctx.owner))>=0;e._enter_node(fid,node)
		if not e._valid_fighter(fid) or trap:break
	var ids=passed.filter(func(id):return e._valid_fighter(int(id)))
	_fighter("damage",ids,ctx,{"amount":1})
func _auto_path(fid: int, ctx: Dictionary):
	var queue=[[int(e.fighters[fid].node)]];var best=queue[0];var score=-INF
	while not queue.is_empty():
		var route=queue.pop_front();var last=int(route[-1]);var occupant=e._occupant(last)
		if occupant in [-1,fid]:
			var hit=[]
			for n in route:
				var id=e._occupant(int(n))
				if id>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[id].owner)) and not hit.has(id):hit.append(id)
			var value=hit.size()*5+e._position_score(fid,last)
			if value>score:score=value;best=route
		if route.size()>=5 or (route.size()>1 and e._enemy_trap_at(last,int(ctx.owner))>=0) or int(e.fighters[fid].get("locked_until",-1))==e.turn_number:continue
		for n in e.nodes[last].get("move_neighbors",e.nodes[last].neighbors):
			if route.has(n):continue
			var occ=e._occupant(int(n))
			if occ>=0 and occ!=fid and (route.size()==4 or e._enemy_trap_at(int(n),int(ctx.owner))>=0):continue
			queue.append(route+[int(n)])
	_path_finish({"fighter":fid,"route":best},ctx)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1));var hero=e.hero_fighter(owner)
	match str(effect.kind):
		"v14_igni":
			var ids=_adjacent(hero);ids.erase(foe)
			if e._valid_fighter(foe) and not e.fighters[foe].hero:e._damage(foe,2);e._damage_many(ids,1)
			else:e._damage_many(ids,1);e._damage(foe,2)
		"v14_riposte":
			if human(owner):_options("riposte",["Нанести 1 урон соседнему бойцу","Обменяться с соседним бойцом"],ctx)
			else:_fighter("damage",_adjacent(hero),ctx)
		"v14_yrden":
			if e._valid_fighter(foe):e.fighters[foe].locked_until=e.turn_number
		"v14_duelist":
			match int(e._v6._other(ctx).card.get("value",-1)):
				2:
					if human(owner):_options("draw",["Взять 1 карту","Пропустить"],ctx)
					else:e._draw(owner)
				3:e._damage(foe,1)
				4:_queue({"kind":"opponent_discard","amount":1},ctx)
		"v14_senses":_senses(ctx)
		"v14_steel":e.gain_actions(owner,2 if foe>=0 and e.fighters[foe].hp>=8 else 1)
		"v14_silver":
			if int(e._v6._other(ctx).card.get("value",0))>=4:ctx.ignore_opponent_value=true
		"v14_medallion":
			if not _adjacent(hero).has(foe):ctx.ignore_opponent_value=true
		"v14_armor":ctx.value+=_adjacent(hero).size()
		"v14_lion":
			if source_count(owner)>=1:ctx.value=7 if source_count(owner)>=5 else 4
		"v14_channel":_channel(ctx)
		"v14_unicorn_path":
			if e._valid_fighter(fid):
				if human(owner):_path_options({"fighter":fid,"route":[int(e.fighters[fid].node)]},ctx)
				else:_auto_path(fid,ctx)
		"v14_brink":
			if source_count(owner)>=7:
				var ids=[]
				if e._valid_fighter(hero):
					for f in e.fighters:
						if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)) and board_distance(int(e.fighters[hero].node),int(f.node))<=3:ids.append(int(f.id))
				_fighter("damage",ids,ctx,{"amount":2})
			elif source_count(owner)>=2:e._damage(foe,1)
		"v14_lady":_lady(ctx)
		"v14_zireael":
			if source_count(owner)>=3:ctx.value=4
			if source_count(owner)>=5:_queue({"kind":"random_discard","amount":1},ctx)
		"v14_source_search":_source_search(ctx)
		"v14_elder_blood":
			if source_count(owner)>=4 and e._valid_fighter(hero):
				var ids=[]
				for f in e.fighters:
					if e._valid_fighter(int(f.id)) and int(f.id)!=hero and e._same_zone(int(e.fighters[hero].node),int(f.node)):ids.append(int(f.id))
				e._damage_many(ids,3 if source_count(owner)>=9 else 1)
		"v14_summon_wolf":
			var dead=[];var live=[]
			for f in e.fighters:
				if int(f.owner)==owner and not f.hero:
					if f.alive:live.append(int(f.id))
					else:dead.append(int(f.id))
			_fighter("wolf",dead if not dead.is_empty() else live,ctx)
		"v14_nature":
			var n=0
			for id in _adjacent(foe):
				if int(e.fighters[int(id)].owner)==owner:n+=1
			e._draw(owner,n)
		"v14_planted":
			if int(e.fighters[fid].get("left_space_turn",-1))!=e.turn_number:e._draw(owner)
		"v14_harrying":
			for id in _adjacent(foe):
				if int(e.fighters[int(id)].owner)==owner:ctx.value+=2
		"v14_guardian":
			var enemy=int(ctx.opponent_owner)
			if enemy>=0 and not e.players[enemy].deck.is_empty():
				var c=e.players[enemy].deck.pop_back();e._discard(enemy,c,"deck");e._v6._other(ctx).value+=int(c.get("boost",0));_reveal(c,enemy,ctx)
		"v14_leshen_zone":
			var ids=[]
			if e._valid_fighter(hero):
				for f in e.fighters:
					if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)) and e._same_zone(int(e.fighters[hero].node),int(f.node)):ids.append(int(f.id))
			e._damage_many(ids,1)
		"v14_vanish":
			if e._valid_fighter(hero) and int(e.fighters[hero].get("locked_until",-1))!=e.turn_number:
				e._v12.departed(hero,int(e.fighters[hero].node),-1);e.fighters[hero].offboard=true;e.fighters[hero].left_space_turn=e.turn_number
				if e.is_dormant(owner):e.actions_left=0
		"v14_return_done":e.fighters[hero].erase("returning_offboard")
		_:return false
	return true
func skip() -> bool:
	if not e.pending_choice.get("can_skip",false):return false
	_resume();return true
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.get("options",[]).size():return false
	e.pending_choice.clear();var ctx=_live(p._ctx);var owner=int(ctx.owner)
	match str(p.action).trim_prefix("v14_"):
		"damage","swap","wolf":
			_apply_fighter(str(p.action).trim_prefix("v14_"),int(p.ids[index]),ctx,p.extra)
			if e.phase=="effect_move" and not e.pending_choice.is_empty():e.changed.emit();return true
		"riposte":_fighter("damage" if index==0 else "swap",_adjacent(e.hero_fighter(owner)),ctx)
		"draw":
			if index==0:e._draw(owner)
		"senses":_take_gear(p.choices[index],ctx)
		"channel":
			e._discard(owner,e.players[owner].hand.pop_at(int(p.indices[index])));ctx.value+=2;_channel(ctx)
		"lady":_lady_card(ctx,int(p.indices[index]),bool(p.to_hand))
		"source_search":_take_source(owner,int(p.indices[index]),ctx)
		"reveal":pass
		"path":
			var choice=int(p.choices[index])
			if choice<0:_path_finish(p.state,ctx)
			else:p.state.route.append(choice);_path_options(p.state,ctx)
		_:return false
	if not e.pending_choice.is_empty():e.changed.emit();return true
	_resume();return true
