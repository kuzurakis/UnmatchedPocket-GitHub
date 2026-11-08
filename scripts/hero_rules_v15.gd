extends "res://scripts/hero_rules_v8.gd"
## Realms Fall: Eredin. Decisions and combat substitutions survive JSON saves.
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
	super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v15_"+action
func enraged(owner: int) -> bool:
	if not e._is_hero(owner,"eredin"):return false
	for f in e.fighters:
		if int(f.owner)==owner and not f.hero and f.alive:return false
	return true
func bonus(owner: int) -> int:return 1 if enraged(owner) else 0
func protected(fid: int) -> bool:
	return e.fighters[fid].hero and e._v14.ongoing(int(e.fighters[fid].owner))=="might_of_the_aen_elle"
func summary(owner: int) -> String:
	if not e._is_hero(owner,"eredin"):return ""
	return "Ярость: атака и защита +1 · движение 3" if enraged(owner) else "Всадники на поле: %d/4 · движение 2" % riders(owner).size()
func riders(owner: int, alive=true) -> Array:
	var ids=[]
	for f in e.fighters:
		if int(f.owner)==owner and not f.hero and bool(f.alive)==alive:ids.append(int(f.id))
	return ids
func global_attack(card: Dictionary, owner: int) -> bool:return str(card.get("id",""))=="foul_purpose" and enraged(owner)
func _fighter(action: String, ids: Array, ctx: Dictionary, optional=false, extra={}):
	if ids.is_empty():return
	if human(int(ctx.owner)):
		var labels=[]
		for id in ids:labels.append("%s · клетка %d" % [e.fighters[int(id)].name,int(e.fighters[int(id)].node)+1])
		_options(action,labels,ctx,{"ids":ids,"extra":extra,"kind":"fighters","allowed_fighters":ids},optional)
	else:_apply(action,int(ids[0]),ctx,extra)
func _apply(action: String, fid: int, ctx: Dictionary, extra: Dictionary):
	match action:
		"sacrifice":
			# Defeating is not damage; the combatant itself may be paid.
			e.fighters[fid].hp=0;e.fighters[fid].alive=false;e._v9.defeated(fid)
			e._log("Всадник принесён в жертву.")
			if str(extra.mode)=="ignore":ctx.ignore_opponent_value=true
			else:e._flow["return_"+str(ctx.get("_combat_slot","a"))]=true
		"revive":
			if human(int(ctx.owner)):
				var legal=[]
				for n in e.nodes:
					if e._occupant(int(n.id))<0:legal.append(int(n.id))
				if legal.is_empty():return
				e.pending_choice={"kind":"revive_sidekick","title":str(ctx.card.name),"prompt":"Разместите Всадника на свободной клетке","legal":legal,"fighter":fid,"allowed_fighters":[fid],"mode":"one","can_skip":false,"_effect":{},"_ctx":ctx.duplicate(true)};e.phase="effect_move"
			else:
				for n in e.nodes:
					if e._occupant(int(n.id))<0:e.fighters[fid].alive=true;e.fighters[fid].hp=1;e._enter_node(fid,int(n.id));break
		"portal":
			var old=int(ctx.self)
			if not e._swap_combatants(old,fid):return
			ctx.self=fid;e._combat_resolution.ctx.target=fid
			e._combat_resolution.a.opponent=fid;e._combat_resolution.a.opponent_owner=int(e.fighters[fid].owner)
			e.pending_combat.target=fid
			e._log("Портал: новый защитник — %s." % str(e.fighters[fid].name))
func run(effect: Dictionary, ctx: Dictionary) -> bool:
	var owner=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1))
	match str(effect.kind):
		"v15_brutal":
			for fx in e._v6._other(ctx).card.get("effects",[]):
				if str(fx.get("timing",""))=="immediately":ctx.ignore_opponent_value=true;break
		"v15_backhand":
			var victim=int(ctx.opponent_owner)
			if victim>=0 and not e.players[victim].hand.is_empty():
				if enraged(owner):e._force_discard(victim,1,true)
				else:e.players[victim].deck.append(e.players[victim].hand.pop_at(e.rng.randi_range(0,e.players[victim].hand.size()-1)))
		"v15_sacrifice":_fighter("sacrifice",riders(owner),ctx,true,{"mode":str(effect.mode)})
		"v15_revive":_fighter("revive",riders(owner,false),ctx)
		"v15_hordes":
			for f in e.fighters:
				if int(f.id)!=fid and e._valid_fighter(int(f.id)) and not e.is_enemy(owner,int(f.owner)) and e._valid_fighter(foe) and e.fighters_adjacent(int(f.id),foe):ctx.value+=1
		"v15_hunt":
			var ids=[]
			for f in e.fighters:
				if not e._valid_fighter(int(f.id)) or not e.is_enemy(owner,int(f.owner)):continue
				for own in e.fighters:
					if int(own.owner)==owner and e._valid_fighter(int(own.id)) and e.fighters_adjacent(int(own.id),int(f.id)):ids.append(int(f.id));break
			e._damage_many(ids,2 if enraged(owner) else 1)
		"v15_icy":
			if enraged(owner):e._v6._cancel(ctx)
		"v15_portal":
			var ids=[]
			for f in e.fighters:
				if int(f.id)!=fid and e._valid_fighter(int(f.id)) and not e.is_enemy(owner,int(f.owner)) and e.fighters_adjacent(int(f.id),fid) and e._v13.can_relocate(fid) and e._v13.can_relocate(int(f.id)):ids.append(int(f.id))
			_fighter("portal",ids,ctx)
		"v15_portal_draw":
			if enraged(owner):e._draw(owner,2)
		_:return false
	return true
func skip() -> bool:
	if not e.pending_choice.get("can_skip",false):return false
	_resume();return true
func choose_option(index: int) -> bool:
	var p=e.pending_choice.duplicate(true)
	if index<0 or index>=p.options.size():return false
	e.pending_choice.clear();_apply(str(p.action).trim_prefix("v15_"),int(p.ids[index]),_live(p._ctx),p.extra)
	if e.pending_choice.is_empty():e._pump_effects()
	e.changed.emit();return true
