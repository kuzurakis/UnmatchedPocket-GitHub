extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v16_"+action
func end_turn() -> bool:
	if e._v14.ongoing(e.active)=="polymorphy":
		var near=false;var hero=e.hero_fighter(e.active)
		for f in e.fighters:
			if e._valid_fighter(int(f.id)) and e.is_enemy(e.active,int(f.owner)) and e._same_zone(int(e.fighters[hero].node),int(f.node)):near=true
		if not near:e._v14._discard_ongoing(e.active)
	if e._is_hero(e.active,"philippa") and e.players[e.active].hand.size()<4:
		e._start_ability(e.active,"На два шага впереди",[{"kind":"v16_end_draw"}],"end_turn");return true
	return false
func _offer(ctx: Dictionary, mode: String):
	var victim=int(ctx.opponent_owner)
	if victim<0:return
	if e.players[victim].hand.is_empty():_declined(ctx,mode);return
	if human(victim):
		_cards("pay",victim,"hand",range(e.players[victim].hand.size()),_with_owner(ctx,victim),{"original":ctx.duplicate(true),"mode":mode},true)
	else:e._discard(victim,e.players[victim].hand.pop_at(e._lowest_card(victim)))
func _declined(ctx: Dictionary, mode: String):
	if mode=="ignore":_live(ctx).ignore_opponent_value=true
	else:e._damage(int(ctx.opponent),2)
func _zone_damage(ctx: Dictionary, zones: Array):
	var ids=[]
	for f in e.fighters:
		if not e._valid_fighter(int(f.id)) or not e.is_enemy(int(ctx.owner),int(f.owner)):continue
		for z in zones:
			if e.nodes[int(f.node)].zones.has(int(z)):ids.append(int(f.id));break
	e._damage_many(ids,1)
func _owl(ctx: Dictionary):
	var owner=int(ctx.owner)
	if human(owner):_cards("owl",owner,"hand",range(e.players[owner].hand.size()),ctx,{},true)
	else:
		while not e.players[owner].hand.is_empty():e._discard(owner,e.players[owner].hand.pop_back());ctx.value+=1
func _spy(ctx: Dictionary):
	var victim=int(ctx.opponent_owner);var count=mini(4,e.players[victim].hand.size())
	if human(victim) and count<e.players[victim].hand.size():_cards("reveal_four",victim,"hand",range(e.players[victim].hand.size()),_with_owner(ctx,victim),{"original":ctx.duplicate(true),"chosen":[],"count":count})
	else:
		var ids=range(e.players[victim].hand.size());ids.sort_custom(func(a,b):return e._card_quality(e.players[victim].hand[int(a)])<e._card_quality(e.players[victim].hand[int(b)]));_spy_choose(ctx,ids.slice(0,count),mini(2,count))
func _spy_choose(ctx: Dictionary, indices: Array, remaining: int):
	var victim=int(ctx.opponent_owner)
	if remaining<=0 or indices.is_empty():e._draw(victim,2);return
	if not ctx.get("_v16_revealed",false):
		ctx._v16_revealed=true
		if e.interactive and not e.players[0].bot and int(ctx.owner)!=0 and victim!=0:
			var cards=[];var owners=[]
			for i in indices:cards.append(e.players[victim].hand[int(i)].duplicate(true));owners.append(victim)
			_options("spy_public",["Продолжить"],ctx,{"kind":"hand_view","viewer":0,"cards":cards,"card_owners":owners,"indices":indices,"remaining_count":remaining,"victim":victim});return
	if human(int(ctx.owner)):_cards("spy_discard",victim,"hand",indices,ctx,{"remaining_count":remaining})
	else:
		indices.sort_custom(func(a,b):return e._card_quality(e.players[victim].hand[int(a)])>e._card_quality(e.players[victim].hand[int(b)]));_spy_discard(ctx,indices,remaining,0)
func _spy_discard(ctx: Dictionary, indices: Array, remaining: int, index: int):
	var victim=int(ctx.opponent_owner);var selected=int(indices[index]);indices.remove_at(index)
	if not e._v14.owl_protected(victim):
		var c=e.players[victim].hand.pop_at(selected);e._discard_from_opponent(victim,c)
		for i in range(indices.size()):
			if int(indices[i])>selected:indices[i]=int(indices[i])-1
	_spy_choose(ctx,indices,remaining-1)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var hero=e.hero_fighter(owner)
	match str(effect.kind):
		"v16_end_draw":
			if human(owner):_options("end_draw",["Добрать до 4 карт","Пропустить"],ctx)
			else:e._draw(owner,maxi(0,4-e.players[owner].hand.size()))
		"v16_backup":
			if human(owner):_options("backup",["Установить здоровье равным 5","Взять 3 карты"],ctx)
			elif e.fighters[hero].hp<5:e.fighters[hero].hp=5
			else:e._draw(owner,3)
		"v16_fetters":e._v6._other(ctx).frozen_printed=true
		"v16_owl":_owl(ctx)
		"v16_offer":_offer(ctx,str(effect.mode))
		"v16_dust":
			if human(owner):_cards("dust",owner,"hand",range(e.players[owner].hand.size()),ctx,{},true)
			elif not e.players[owner].hand.is_empty():
				var c=e.players[owner].hand.pop_at(e._best_boost(owner));e._discard(owner,c);e._damage(int(ctx.opponent),int(c.boost))
		"v16_chain":
			if not e._valid_fighter(hero):return true
			var zones=e.nodes[int(e.fighters[hero].node)].zones
			if human(owner):
				var labels=[]
				for z in zones:labels.append("Зона %d" % (int(z)+1))
				_options("zone",labels,ctx,{"zones":zones})
			else:_zone_damage(ctx,[zones[0]])
		"v16_bolt":
			if e._valid_fighter(hero) and int(e.players[owner].get("maneuvered_turn",-1))!=e.turn_number:_zone_damage(ctx,e.nodes[int(e.fighters[hero].node)].zones)
		"v16_spy_target":
			var ids=[];var labels=[]
			for p in range(e.players.size()):
				if e.is_enemy(owner,p) and e.players[p].alive:ids.append(p);labels.append(e._player_name(p))
			if human(owner) and ids.size()>1:_options("target",labels,ctx,{"ids":ids})
			elif not ids.is_empty():ctx.opponent_owner=int(ids[0]);_queue({"kind":"v16_spy"},ctx)
		"v16_spy":_spy(ctx)
		_:return false
	return true
func skip() -> bool:
	var p=e.pending_choice.duplicate(true)
	if not p.get("can_skip",false):return false
	e.pending_choice.clear()
	if p.action=="v16_pay":_declined(p.original,p.mode)
	_resume();return true
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.options.size():return false
	e.pending_choice.clear();var ctx=_live(p._ctx);var owner=int(p.get("victim",ctx.owner))
	match str(p.action).trim_prefix("v16_"):
		"end_draw":
			if index==0:e._draw(owner,maxi(0,4-e.players[owner].hand.size()))
		"backup":
			if index==0:e.fighters[e.hero_fighter(owner)].hp=5
			else:e._draw(owner,3)
		"pay":e._discard(owner,e.players[owner].hand.pop_at(int(p.indices[index])))
		"owl":e._discard(owner,e.players[owner].hand.pop_at(int(p.indices[index])));ctx.value+=1;_owl(ctx)
		"dust":
			var c=e.players[owner].hand.pop_at(int(p.indices[index]));e._discard(owner,c);e._damage(int(ctx.opponent),int(c.boost))
		"zone":_zone_damage(ctx,[int(p.zones[index])])
		"target":ctx.opponent_owner=int(p.ids[index]);_queue({"kind":"v16_spy"},ctx)
		"reveal_four":
			var chosen=p.chosen;chosen.append(int(p.indices[index]));var ids=[]
			for i in range(e.players[owner].hand.size()):
				if not chosen.map(func(v):return int(v)).has(i):ids.append(i)
			if chosen.size()<int(p.count):_cards("reveal_four",owner,"hand",ids,ctx,{"original":p.original,"chosen":chosen,"count":int(p.count)})
			else:_spy_choose(p.original,chosen,mini(2,chosen.size()))
		"spy_public":_spy_choose(ctx,p.indices,int(p.remaining_count))
		"spy_discard":_spy_discard(ctx,p.indices,int(p.remaining_count),index)
		_:return false
	if not e.pending_choice.is_empty():e.changed.emit();return true
	_resume();return true
