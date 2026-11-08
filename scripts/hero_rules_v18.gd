extends "res://scripts/hero_rules_v8.gd"
## Marvel: decisions, routes and resurrection state live in the saved model.
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v18_"+action
func resurrected(owner: int) -> bool:return bool(e.players[owner].get("elektra_resurrected",false))
func waiting(owner: int) -> bool:return bool(e.players[owner].get("elektra_waiting",false))
func protects(fid: int) -> bool:return e.fighters[fid].hero and waiting(int(e.fighters[fid].owner))
func first_defeat(fid: int) -> bool:
	var owner=int(e.fighters[fid].owner)
	if not e.fighters[fid].hero or not e._is_hero(owner,"elektra") or resurrected(owner) or waiting(owner):return false
	e.players[owner].elektra_waiting=true;e.players[owner].alive=true
	for f in e.fighters:
		if int(f.owner)==owner:f.alive=false
	e._log("Электра вернётся в начале своего следующего хода.");return true
func start_turn() -> bool:
	var owner=e.active
	if not waiting(owner):return false
	e.players[owner].elektra_resurrected=true
	e.players[owner].deck.append_array(e.players[owner].discard);e.players[owner].discard.clear();e._shuffle(e.players[owner].deck)
	var ids=[]
	for f in e.fighters:
		if int(f.owner)==owner:
			ids.append(int(f.id));f.alive=false
			if f.hero:f.max_hp=9
	e._start_ability(owner,"Воскрешение Электры",[{"kind":"v18_resurrect","ids":ids,"used":[]}],"start_turn");return true
func summary(owner: int) -> String:
	if e._is_hero(owner,"elektra"):return "Ожидает воскрешения" if waiting(owner) else "Воскрешена: дополнительные эффекты активны" if resurrected(owner) else "До воскрешения · первое поражение не выводит из игры"
	if e._is_hero(owner,"daredevil"):return "Слепое усиление доступно при 0–2 картах в руке"
	if e._is_hero(owner,"bullseye"):return "Дальность: общая зона или до 5 линий"
	if e._is_hero(owner,"luke_cage"):return "Люк: боевой урон −2 · Мисти без снижения"
	return ""
func reduce_damage(fid: int, amount: int) -> int:
	return maxi(0,amount-2) if e.fighters[fid].hero and e._is_hero(int(e.fighters[fid].owner),"luke_cage") else amount
func estimate(card: Dictionary, fid: int, target: int, value: float) -> float:
	var owner=int(e.fighters[fid].owner);var id=str(card.get("id",""))
	if e._is_hero(owner,"daredevil"):
		var deck=e.players[owner].deck;var avg=0.0
		for c in deck:avg+=float(c.boost)
		if not deck.is_empty():avg/=deck.size()
		var ability=e.players[owner].hand.size()<=3
		if id=="devil_of_hell_s_kitchen" and (deck.is_empty() or (ability and deck.size()==1)):return 8.0
		return value+avg*mini(deck.size(),int(ability)+int(id=="man_without_fear"))
	if e._is_hero(owner,"bullseye"):
		if id=="i_planned_to_be_here" and int(e.fighters[fid].node)==int(e.turn_start_nodes[fid]):value=5
		if e.players[owner].get("won_combat_turn",false):
			if id=="i_m_better_and_ill_prove_it":value=6
			if id=="world_s_greatest_assassin":value+=3
	if e._is_hero(owner,"elektra") and resurrected(owner) and id=="intercept" and e.players[owner].hand.any(func(c):return c.id=="sai"):value=5
	if e._is_hero(owner,"luke_cage") and id=="daughter_of_the_dragon" and e._valid_fighter(target) and e.fighters_adjacent(fid,target):value=6
	return value
func queue_during(ctx: Dictionary):
	if not ctx.get("item",{}).is_empty():e._v24.queue_during(ctx);return
	if e._is_hero(int(ctx.owner),"daredevil") and e.fighters[int(ctx.self)].hero:
		e._effect_queue.append({"effect":{"kind":"v18_order","intrinsic":true},"ctx":ctx.duplicate(true)})
	else:e._queue_card_effects(ctx.card,"during",ctx)
func _ordered(ctx: Dictionary, first: bool):
	var effects=[];var ability={"kind":"v18_blind","intrinsic":true,"ability":true}
	if first:effects.append(ability)
	for fx in ctx.card.get("effects",[]):
		if fx.get("timing","")=="during":effects.append(fx)
	if not first:effects.append(ability)
	for i in range(effects.size()-1,-1,-1):_queue(effects[i],ctx)
func _blind(ctx: Dictionary):
	var owner=int(ctx.owner)
	if e.players[owner].deck.is_empty():return
	var c=e.players[owner].deck.pop_back();e._discard(owner,c,"deck");ctx.value+=int(c.boost)
	e._log("Слепое усиление: %s · +%d." % [str(c.name),int(c.boost)])
	if not e._flow.has("boosts"):e._flow.boosts=[]
	e._flow.boosts.append({"owner":owner,"card":c.duplicate(true)})
func _pick_fighter(action: String, ids: Array, ctx: Dictionary, optional=false):
	if ids.is_empty():return
	if human(int(ctx.owner)):
		var labels=[]
		for id in ids:labels.append("%s · клетка %d" % [e.fighters[int(id)].name,int(e.fighters[int(id)].node)+1])
		_options(action,labels,ctx,{"ids":ids,"kind":"fighters","allowed_fighters":ids},optional)
	else:_fighter_selected(action,int(ids[0]),ctx)
func _fighter_selected(action: String, fid: int, ctx: Dictionary):
	if action=="hit":e._damage(fid,int(ctx.hit_amount))
	elif action=="swap":
		if not e._swap_combatants(int(ctx.self),fid):return
		ctx.self=fid;e._combat_resolution.ctx.target=fid;e.pending_combat.target=fid
		e._combat_resolution.a.opponent=fid;e._combat_resolution.a.opponent_owner=int(e.fighters[fid].owner)
		e._log("Новый защитник: %s." % e.fighters[fid].name)
func _recycle(ctx: Dictionary, mode: String, count: int):
	var owner=int(ctx.owner);var ids=[]
	for i in range(e.players[owner].discard.size()):
		if mode!="hand" or e.players[owner].discard[i].type in ["attack","defense","versatile"]:ids.append(i)
	if ids.is_empty():return
	if human(owner):_cards("recycle",owner,"discard",ids,ctx,{"mode":mode,"left":count})
	else:
		for i in range(mini(count,ids.size())-1,-1,-1):_recycled(owner,int(ids[i]),mode)
		if mode=="deck":e._shuffle(e.players[owner].deck)
func _recycled(owner: int, index: int, mode: String):
	var c=e.players[owner].discard.pop_at(index)
	if mode=="hand":e.players[owner].hand.append(c)
	else:e.players[owner].deck.append(c)
func _node_choice(action: String, legal: Array, ctx: Dictionary, extra={}):
	if legal.is_empty():return
	var labels=[]
	for n in legal:labels.append("Клетка %d" % (int(n)+1))
	_options(action,labels,ctx,{"legal":legal,"choices":legal,"kind":"spaces"});e.pending_choice.merge(extra,true)
func _zone_mask(zones: Array) -> int:
	var mask=0
	for z in zones:mask |= 1 << int(z)
	return mask
func _res_capacity(used: int, masks: Array, memo: Dictionary) -> int:
	if memo.has(used):return int(memo[used])
	var best=0
	for mask in masks:
		if (used & int(mask))==0:best=maxi(best,1+_res_capacity(used | int(mask),masks,memo))
	memo[used]=best;return best
func _resurrection(effect: Dictionary, ctx: Dictionary):
	if effect.ids.is_empty():
		e.players[int(ctx.owner)].elektra_waiting=false;return
	var used=effect.used.map(func(v):return int(v));var legal=[]
	for n in e.nodes:
		if e._occupant(int(n.id))>=0:continue
		if n.zones.any(func(z):return used.has(int(z))):continue
		legal.append(int(n.id))
	# Do not offer an early placement that would unnecessarily strand a Hand.
	var masks=[];var memo={};var best=0;var kept=[];var used_mask=_zone_mask(used)
	for n in legal:
		var mask=_zone_mask(e.nodes[int(n)].zones)
		if not masks.has(mask) and mask!=0:masks.append(mask)
	for n in legal:
		var score=mini(effect.ids.size(),1+_res_capacity(used_mask | _zone_mask(e.nodes[int(n)].zones),masks,memo))
		if score>best:best=score;kept.clear()
		if score==best:kept.append(n)
	legal=kept
	if legal.is_empty():
		# A battlefield can have fewer disjoint zones than fighters. Leave those
		# helpers defeated rather than breaking the different-zone requirement.
		e.players[int(ctx.owner)].elektra_waiting=false;e._log("Нет свободной клетки в отдельной зоне для оставшихся ниндзя.");return
	if human(int(ctx.owner)):_node_choice("resurrect",legal,ctx,{"resurrection":effect,"prompt":"Разместите бойца: %s" % e.fighters[int(effect.ids[0])].name})
	else:_resurrect_at(effect,int(legal[0]),ctx)
func _resurrect_at(effect: Dictionary, node: int, ctx: Dictionary):
	var ids=effect.ids.duplicate();var fid=int(ids.pop_front());e.fighters[fid].alive=true;e.fighters[fid].hp=int(e.fighters[fid].max_hp);e._enter_node(fid,node)
	var used=effect.used.duplicate();used.append_array(e.nodes[node].zones)
	_queue({"kind":"v18_resurrect","ids":ids,"used":used},ctx)
func _path_can_end(state: Dictionary, route: Array) -> bool:
	var fid=int(state.fighter);var current=int(route[-1]);var occ=e._occupant(current)
	return occ in [-1,fid] and (state.mode!="exact" or route.size()==int(state.spaces)+1 or (route.size()>1 and e._enemy_trap_at(current,int(e.fighters[fid].owner))>=0))
func _routes(state: Dictionary, route: Array, out: Array):
	var fid=int(state.fighter);var current=int(route[-1]);var max_steps=int(state.spaces)
	if _path_can_end(state,route):out.append(route)
	if route.size()>max_steps or int(e.fighters[fid].get("locked_until",-1))==e.turn_number or (route.size()>1 and e._enemy_trap_at(current,int(e.fighters[fid].owner))>=0):return
	for n in (e.nodes[current].neighbors if e._v19.large(fid) else e.nodes[current].get("move_neighbors",e.nodes[current].neighbors)):
		var occ=e._occupant(int(n))
		if occ>=0 and occ!=fid and state.mode=="power" and not e.is_enemy(int(state.owner),int(e.fighters[occ].owner)):continue
		if occ>=0 and occ!=fid and e._enemy_trap_at(int(n),int(e.fighters[fid].owner))>=0:continue
		_routes(state,route+[int(n)],out)
func _path(ctx: Dictionary, spaces: int, mode: String):
	var fid=int(ctx.opponent if mode=="power" else ctx.self)
	if not e._valid_fighter(fid):return
	var state={"fighter":fid,"spaces":spaces,"mode":mode,"owner":int(ctx.owner),"route":[int(e.fighters[fid].node)]};var routes=[];_routes(state,state.route,routes)
	if routes.is_empty():return
	if human(int(ctx.owner)):_path_options(state,routes,ctx)
	else:
		var best=routes[0];var score=-INF
		for route in routes:
			var hits=[]
			for n in route:
				var occ=e._occupant(int(n))
				if occ>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[occ].owner)) and not hits.has(occ):hits.append(occ)
			var value=e._position_score(fid,int(route[-1]))*( -1 if mode=="power" else 1)+(hits.size()*5 if mode!="exact" else 0)
			if value>score:score=value;best=route
		_path_finish(state,best,ctx)
func _path_options(state: Dictionary, routes: Array, ctx: Dictionary):
	var choices=[];var labels=[];var depth=state.route.size()
	for route in routes:
		var n=-1 if route.size()==depth else int(route[depth])
		if choices.has(n):continue
		choices.append(n);labels.append("Завершить маршрут" if n<0 else "Шаг на клетку %d" % (n+1))
	_options("path",labels,ctx,{"state":state,"routes":routes,"choices":choices,"prompt":"Маршрут: %s" % str(state.route.map(func(n):return int(n)+1))})
func _path_finish(state: Dictionary, route: Array, ctx: Dictionary):
	var fid=int(state.fighter);var hit=[]
	if state.mode=="power":hit.append(fid)
	for i in range(1,route.size()):
		var n=int(route[i]);var occ=e._occupant(n)
		if occ>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[occ].owner)) and not hit.has(occ):hit.append(occ)
		e._enter_node(fid,n)
		if not e._valid_fighter(fid) or e._enemy_trap_at(n,int(e.fighters[fid].owner))>=0:break
	if state.mode!="exact":e._damage_many(hit,1)
func _mesmerize(ctx: Dictionary):
	var ids=[];var labels=[]
	for p in range(e.players.size()):
		if e.is_enemy(int(ctx.owner),p) and not e.is_dormant(p):ids.append(p);labels.append(e._player_name(p))
	if ids.is_empty():return
	if human(int(ctx.owner)) and ids.size()>1:_options("mesmerize",labels,ctx,{"ids":ids})
	else:_mesmerize_target(ctx,int(ids[0]))
func _mesmerize_target(ctx: Dictionary, victim: int):
	ctx.opponent_owner=victim
	if resurrected(int(ctx.owner)):_queue({"kind":"reveal_choose_discard","amount":1},ctx)
	else:_queue({"kind":"reveal_hand"},ctx)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1));var kind=str(effect.kind)
	match kind:
		"v18_order":
			var has_effect=ctx.card.get("effects",[]).any(func(fx):return fx.get("timing","")=="during") and not ctx.get("cancelled",false)
			if human(owner) and has_effect:_options("order",["Сначала способность","Сначала эффект карты"],ctx)
			else:_ordered(ctx,true)
		"v18_blind":
			if effect.get("ability",false) and e.players[owner].hand.size()>2:return true
			if not e.players[owner].deck.is_empty():
				if human(owner):_options("blind",["Слепое усиление","Пропустить"],ctx)
				else:_blind(ctx)
		"v18_empty":
			if e.players[owner].deck.is_empty():ctx.value=8
		"v18_devil":
			for i in range(mini(4,e.players[owner].discard.size())):e.players[owner].deck.append(e.players[owner].discard.pop_back())
			e._flow["shuffle_"+str(ctx.get("_combat_slot","a"))]=true
		"v18_knee":
			if not e.players[owner].deck.is_empty():
				var c=e.players[owner].deck.pop_back();e._discard(owner,c,"deck");e._heal(fid,int(c.boost))
		"v18_boxer":
			if not ctx.won:ctx.hit_amount=2;_pick_fighter("hit",e._damage_candidates({"target":"any_adjacent_to_self"},ctx),ctx)
		"v18_recycle":_recycle(ctx,str(effect.mode),int(effect.count))
		"v18_path":_path(ctx,int(effect.spaces),str(effect.mode))
		"v18_planned":
			if e._valid_fighter(fid) and int(e.turn_start_nodes[fid])==int(e.fighters[fid].node):ctx.value=5
		"v18_never":
			var ids=[]
			for i in range(e.players[owner].hand.size()):
				if e.can_boost_card(e.players[owner].hand[i]):ids.append(i)
			if ids.is_empty():e._draw(owner)
			elif human(owner):_cards("never_boost",owner,"hand",ids,ctx,{},true)
			else:e._v8.combat_boost(ctx,int(ids[0]))
		"v18_retreat":
			if not e._valid_fighter(fid) or not e._v13.can_relocate(fid):return true
			var legal=[]
			for n in e.nodes:
				if e._occupant(int(n.id))<0 and not n.zones.any(func(z):return e.nodes[int(e.fighters[fid].node)].zones.has(z)):legal.append(int(n.id))
			if human(owner):_node_choice("retreat",legal,ctx)
			elif not legal.is_empty():e._enter_node(fid,int(legal[0]))
		"v18_won":ctx.won=true;e.players[owner].won_combat_turn=true
		"v18_between":
			if e.players[owner].get("won_combat_turn",false):_queue({"kind":"opponent_discard","amount":1},ctx)
		"v18_better":
			if e.players[owner].get("won_combat_turn",false):ctx.value=6
		"v18_assassin":
			if e.players[owner].get("won_combat_turn",false):ctx.ignore_opponent_value=true
		"v18_study":
			if e.players[owner].get("won_combat_turn",false):e._draw(owner);e.gain_actions(owner,1)
		"v18_ricochet":
			if e._valid_fighter(foe):ctx.hit_amount=1;_pick_fighter("hit",e.fighters.filter(func(f):return e._valid_fighter(int(f.id)) and e._same_zone(int(f.node),int(e.fighters[foe].node))).map(func(f):return int(f.id)),ctx)
		"v18_mystic":
			if not resurrected(owner):e._damage(fid,3)
		"v18_fist":
			if e._valid_fighter(fid):
				if human(owner):_options("fist",["Нанести 1 урон своему ниндзя","Пропустить"],ctx)
				else:_fist(ctx)
		"v18_intercept":
			if resurrected(owner) and e.players[owner].hand.any(func(c):return c.id=="sai"):
				if human(owner):_options("intercept",["Раскрыть Сай","Пропустить"],ctx)
				else:ctx.value=5;e._log("Электра раскрывает Сай.")
		"v18_swap":
			var ids=[]
			for f in e.fighters:
				if int(f.owner)==owner and e._valid_fighter(int(f.id)) and int(f.id)!=fid and (not f.hero if effect.mode=="hand" else f.hero) and e._v13.can_relocate(fid) and e._v13.can_relocate(int(f.id)):ids.append(int(f.id))
			_pick_fighter("swap",ids,ctx,true)
		"v18_whirlwind":
			if resurrected(owner):e._damage_many(e._v14._adjacent(fid).filter(func(id):return e.is_enemy(owner,int(e.fighters[int(id)].owner))),1)
		"v18_shadow":
			if resurrected(owner):_queue({"kind":"move","target":"hero","spaces":3},ctx)
		"v18_mesmerize":_mesmerize(ctx)
		"v18_resurrect":_resurrection(effect,ctx)
		"v18_titanium":
			if not ctx.won:e._damage(foe,int(ctx.get("damage_taken",0)))
		"v18_end":e._flow.end_turn=true;e.actions_left=0;e._effect_queue.clear()
		"v18_dragon":
			if e._valid_fighter(fid) and e._valid_fighter(foe) and e.fighters_adjacent(fid,foe):ctx.value=6
		"v18_money":
			if not e._valid_fighter(fid) or not e._v13.can_relocate(fid):return true
			var nearest=999;var enemies=[];var legal=[]
			for f in e.fighters:
				if not e._valid_fighter(int(f.id)) or not e.is_enemy(owner,int(f.owner)):continue
				var dist=e._v14.board_distance(int(e.fighters[fid].node),int(f.node))
				if dist<nearest:nearest=dist;enemies.clear()
				if dist==nearest:enemies.append(int(f.id))
			for id in enemies:
				for n in e.nodes[int(e.fighters[int(id)].node)].neighbors:
					if e._occupant(int(n)) in [-1,fid] and not legal.has(int(n)):legal.append(int(n))
			if human(owner):_node_choice("retreat",legal,ctx)
			elif not legal.is_empty():e._enter_node(fid,int(legal[0]))
		_:return false
	return true
func _fist(ctx: Dictionary):
	e._damage(int(ctx.self),1);e._flow["return_"+str(ctx.get("_combat_slot","a"))]=true;e.gain_actions(int(ctx.owner),1)
func skip() -> bool:
	if not e.pending_choice.get("can_skip",false):return false
	if e.pending_choice.action=="v18_never_boost":e._draw(int(e.pending_choice._ctx.owner))
	_resume();return true
func choose_node(node: int) -> bool:
	var p=e.pending_choice
	if not p.get("legal",[]).map(func(v):return int(v)).has(node):return false
	return choose_option(p.choices.map(func(v):return int(v)).find(node))
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.options.size():return false
	e.pending_choice.clear();var ctx=_live(p._ctx);var owner=int(ctx.owner)
	match str(p.action).trim_prefix("v18_"):
		"order":_ordered(ctx,index==0)
		"blind":
			if index==0:_blind(ctx)
		"never_boost":e._v8.combat_boost(ctx,int(p.indices[index]))
		"never":
			if index==0:_queue({"kind":"optional_boost"},ctx)
			else:e._draw(owner)
		"hit","swap":_fighter_selected(str(p.action).trim_prefix("v18_"),int(p.ids[index]),ctx)
		"recycle":
			_recycled(owner,int(p.indices[index]),str(p.mode))
			if int(p.left)>1:_recycle(ctx,str(p.mode),int(p.left)-1)
			if e.pending_choice.is_empty() and p.mode=="deck":e._shuffle(e.players[owner].deck)
		"retreat":e._enter_node(int(ctx.self),int(p.choices[index]))
		"resurrect":_resurrect_at(p.resurrection,int(p.choices[index]),ctx)
		"path":
			var n=int(p.choices[index])
			if n<0:_path_finish(p.state,p.state.route,ctx)
			else:
				p.state.route.append(n);var routes=p.routes.filter(func(route):return route.size()>=p.state.route.size() and int(route[p.state.route.size()-1])==n)
				_path_options(p.state,routes,ctx)
		"mesmerize":_mesmerize_target(ctx,int(p.ids[index]))
		"fist":
			if index==0:_fist(ctx)
		"intercept":
			if index==0:ctx.value=5;e._log("Электра раскрывает Сай.")
		_:return false
	if not e.pending_choice.is_empty():e.changed.emit();return true
	_resume();return true
