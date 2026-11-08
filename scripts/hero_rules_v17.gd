extends "res://scripts/hero_rules_v8.gd"
const ID="yennefer_triss"
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v17_"+action
func definition(main: String) -> Dictionary:
	var h=e.heroes[ID].duplicate(true);h.name="Трисс" if main=="triss" else "Йеннифэр";h.sidekick.name="Йеннифэр" if main=="triss" else "Трисс";return h
func main_for(owner: int) -> String:return str(e.players[owner].get("sorceress","yennefer"))
func summary(owner: int) -> String:
	if not e._is_hero(owner,ID):return ""
	return "Главная героиня: Трисс · после её приёма 2 урона соседу" if main_for(owner)=="triss" else "Главная героиня: Йеннифэр · усиление атаки на этапе «Сразу»"
func refresh_boosts(owner: int):
	if owner<0 or owner>=e.players.size() or not e._is_hero(owner,ID):return
	var cards=[];var bonus=1 if e._v14.ongoing(owner)=="advisor_to_the_king" else 0
	for pile in ["hand","deck","discard"]:cards.append_array(e.players[owner][pile])
	if not e.players[owner].get("ongoing",{}).is_empty():cards.append(e.players[owner].ongoing)
	if int(e._flow.get("owner",-1))==owner and e._flow.has("card"):cards.append(e._flow.card)
	for slot in ["a","d"]:
		if int(e._combat_resolution.get(slot,{}).get("owner",-1))==owner:cards.append(e._combat_resolution[slot].card)
	if int(e.pending_combat.get("attack_owner",-1))==owner:cards.append(e.pending_combat.attack_card)
	for c in cards:
		if c.is_empty():continue
		if not c.has("printed_boost"):c.printed_boost=int(c.get("boost",0))
		c.boost=int(c.printed_boost)+bonus
func queue_immediate(ctx: Dictionary):
	if e._is_hero(int(ctx.owner),ID) and main_for(int(ctx.owner))=="yennefer" and e.fighters[int(ctx.self)].hero:
		e._effect_queue.append({"effect":{"kind":"v17_order","intrinsic":true},"ctx":ctx.duplicate(true)})
	else:e._queue_card_effects(ctx.card,"immediately",ctx)
func _immediates(ctx: Dictionary, first: bool):
	var effects=[];var boost={"kind":"optional_boost","intrinsic":true}
	if first:effects.append(boost)
	for fx in ctx.card.get("effects",[]):
		if fx.get("timing","")=="immediately":effects.append(fx)
	if not first:effects.append(boost)
	for i in range(effects.size()-1,-1,-1):_queue(effects[i],ctx)
func after_scheme() -> bool:
	if e._flow.get("kind","")!="scheme" or e._flow.get("triss_checked",false):return false
	e._flow.triss_checked=true;var owner=int(e._flow.owner);var fid=int(e._flow.get("fighter",-1))
	if not e._is_hero(owner,ID) or main_for(owner)!="triss" or fid!=e.hero_fighter(owner) or not e._valid_fighter(fid):return false
	var ctx={"owner":owner,"self":fid,"opponent":-1,"opponent_owner":-1,"card":{"name":"Способность Трисс"},"won":false}
	_queue({"kind":"damage","target":"any_adjacent_to_self","amount":2},ctx);return true
func _offer_cost(ctx: Dictionary, mode: String, count: int):
	var victim=int(ctx.opponent_owner)
	if e.players[victim].hand.size()<count:
		if mode=="telepathy":e._v6._cancel(ctx)
		return
	if human(victim):_cards("pay",victim,"hand",range(e.players[victim].hand.size()),_with_owner(ctx,victim),{"original":ctx.duplicate(true),"mode":mode,"left":count,"total":count},true)
	else:
		for i in range(count):e._discard(victim,e.players[victim].hand.pop_at(e._lowest_card(victim)))
		if mode=="incinerate":e._v6._other(ctx).ignore_opponent_value=true
func _hail(ctx: Dictionary, index: int):
	var victim=int(ctx.opponent_owner)
	if index==0:_queue({"kind":"opponent_discard","amount":2},ctx)
	elif index==1:e._damage(e.hero_fighter(victim),3)
	else:
		for i in range(mini(4,e.players[victim].deck.size())):e._discard_from_opponent(victim,e.players[victim].deck.pop_back(),false)
func _lodge(ctx: Dictionary):
	var state={"cards":[],"owners":[]}
	for p in range(e.players.size()):
		if not e.players[p].alive or e.players[p].hand.is_empty():continue
		if human(p):continue
		state.cards.append(e.players[p].hand[e._lowest_card(p)].duplicate(true));state.owners.append(p)
	if human(0) and e.players[0].alive and not e.players[0].hand.is_empty():_cards("lodge_pick",0,"hand",range(e.players[0].hand.size()),_with_owner(ctx,0),{"state":state})
	else:_lodge_reveal(ctx,state)
func _lodge_reveal(ctx: Dictionary, state: Dictionary):
	if e.interactive and not e.players[0].bot and not state.cards.is_empty():_options("lodge_reveal",["Продолжить"],ctx,{"kind":"hand_view","viewer":0,"cards":state.cards,"card_owners":state.owners,"state":state})
	else:_lodge_resolve(state)
func _lodge_resolve(state: Dictionary):
	var counts=[];var maximum=0
	for i in range(state.cards.size()):
		var owner=int(state.owners[i]);var before=e.players[owner].deck.size();e._draw(owner,int(state.cards[i].boost));var count=before-e.players[owner].deck.size();counts.append(count);maximum=maxi(maximum,count)
	var ids=[]
	for i in range(counts.size()):
		if counts[i]==maximum:ids.append(e.hero_fighter(int(state.owners[i])))
	e._damage_many(ids,maximum)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var fid=int(ctx.self)
	match str(effect.kind):
		"v17_order":
			var immediate=ctx.card.get("effects",[]).any(func(fx):return fx.get("timing","")=="immediately")
			if human(owner) and immediate:_options("order",["Сначала усилить атаку","Сначала эффект карты"],ctx)
			else:_immediates(ctx,true)
		"v17_pay":_offer_cost(ctx,str(effect.mode),int(effect.count))
		"v17_hail":
			var victim=int(ctx.opponent_owner)
			if human(victim):_options("hail",["Сбросить 2 карты из руки","Получить 3 урона герою","Сбросить верхние 4 карты колоды"],_with_owner(ctx,victim),{"original":ctx.duplicate(true)})
			else:_hail(ctx,2 if e.players[victim].deck.size()>=4 else 1 if e.fighters[e.hero_fighter(victim)].hp>3 else 0)
		"v17_portal":
			var ids=[fid,int(ctx.opponent)].filter(func(id):return e._valid_fighter(int(id)))
			if human(owner):
				var labels=[]
				for id in ids:labels.append(e.fighters[int(id)].name)
				if not ids.is_empty():_options("portal",labels,ctx,{"ids":ids})
			elif not ids.is_empty():e._auto_place(int(ids[0]))
		"v17_return":e._flow["return_"+str(ctx.get("_combat_slot","a"))]=true
		"v17_ball":
			_queue({"kind":"opponent_discard","amount":1},ctx)
			if not ctx.won:_queue({"kind":"v17_self_discard"},ctx)
		"v17_self_discard":
			if human(owner):_cards("forced",owner,"hand",range(e.players[owner].hand.size()),ctx)
			else:e._force_discard(owner,1,false)
		"v17_heal_all":
			for f in e.fighters:
				if int(f.owner)==owner:e._heal(int(f.id),1)
		"v17_lodge":_lodge(ctx)
		_:return false
	return true
func skip() -> bool:
	var p=e.pending_choice.duplicate(true)
	if not p.get("can_skip",false):return false
	e.pending_choice.clear()
	if p.action=="v17_pay" and p.mode=="telepathy":e._v6._cancel(_live(p.original))
	_resume();return true
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.options.size():return false
	e.pending_choice.clear();var ctx=_live(p._ctx)
	match str(p.action).trim_prefix("v17_"):
		"order":_immediates(ctx,index==0)
		"hail":_hail(p.original,index)
		"portal":
			var fx={"kind":"place","fixed_fighter":int(p.ids[index])}
			if not e._begin_manual_effect(fx,ctx):pass
		"forced":e._discard(int(p.victim),e.players[int(p.victim)].hand.pop_at(int(p.indices[index])))
		"pay":
			var victim=int(p.victim);e._discard(victim,e.players[victim].hand.pop_at(int(p.indices[index])));var original=_live(p.original)
			if int(p.left)>1:_cards("pay",victim,"hand",range(e.players[victim].hand.size()),_with_owner(original,victim),{"original":original.duplicate(true),"mode":p.mode,"left":int(p.left)-1,"total":p.total},false)
			elif p.mode=="incinerate":e._v6._other(original).ignore_opponent_value=true
		"lodge_pick":p.state.cards.append(e.players[int(p.victim)].hand[int(p.indices[index])].duplicate(true));p.state.owners.append(int(p.victim));_lodge_reveal(ctx,p.state)
		"lodge_reveal":_lodge_resolve(p.state)
		_:return false
	if not e.pending_choice.is_empty():e.changed.emit();return true
	_resume();return true
