extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v22_"+action
func start_turn() -> bool:
 if not e._is_hero(e.active,"she_hulk"):return false
 if not human(e.active) and not e.fighters.any(func(f):return e._valid_fighter(int(f.id)) and e.is_enemy(e.active,int(f.owner)) and e._same_zone(int(f.node),int(e.fighters[e.hero_fighter(e.active)].node))):return false
 e._start_ability(e.active,"Бросить предмет",[{"kind":"v22_throw"}],"start_turn");return true
func before_collect() -> bool:
 if e._flow.get("kind","")!="combat" or e._flow.get("v22_checked",false):return false
 e._flow.v22_checked=true;var added=false
 for slot in ["d","a"]:
  var ctx=e._combat_resolution.get(slot,{})
  if ctx.is_empty():continue
  if e._is_hero(int(ctx.owner),"doctor_strange") and e.fighters[int(ctx.self)].hero and not ctx.card.is_empty() and e._valid_fighter(int(ctx.self)):_queue({"kind":"v22_pact"},ctx);added=true
  if slot=="a" and e._is_hero(int(ctx.owner),"cloak_and_dagger") and int(ctx.get("damage_dealt",0))>=2:
   if e.fighters[int(ctx.self)].name=="Плащ":_queue({"kind":"opponent_discard","amount":1},ctx)
   else:e.gain_actions(int(ctx.owner),1)
 return added
func _own(p: int) -> Array:return e.fighters.filter(func(f):return int(f.owner)==p and e._valid_fighter(int(f.id))).map(func(f):return int(f.id))
func _start_place(ctx: Dictionary, fid: int, exclude=-1):
 if not e._valid_fighter(fid) or not e._v13.can_relocate(fid):return
 var legal=e.board_data.get("starts",[0,4,20,24]).map(func(n):return int(n)).filter(func(n):return n!=exclude and e._occupant(n)in[-1,fid])
 if legal.is_empty():return
 if human(int(ctx.owner)):_options("start",legal.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":legal,"fid":fid})
 else:e._enter_node(fid,int(legal[0]))
func _mists(ctx: Dictionary):
 var other=e._v6._other(ctx);var victim=int(other.owner);e._discard(victim,other.card,"played");other.card={};other.item={};other.value=0;var revealed=[]
 while not e.players[victim].deck.is_empty():
  var c=e.players[victim].deck.pop_back()
  if e._attack_type(c) and e._card_usable(c,int(other.self)):other.card=c;other.value=int(c.value);break
  revealed.append(c)
 e._shuffle(revealed)
 for c in revealed:e.players[victim].deck.push_front(c)
 e._effect_queue=e._effect_queue.filter(func(job):return job.ctx.get("_combat_slot","")!=other.get("_combat_slot","") or job.effect.get("intrinsic",false))
 var effects=[]
 for timing in ["immediately","during"]:
  for fx in other.card.get("effects",[]):
   if fx.timing==timing:effects.append(fx)
 for i in range(effects.size()-1,-1,-1):_queue(effects[i],other)
func _option(ctx: Dictionary, mode: String, labels: Array, extra={}, optional=false):
 if human(int(ctx.owner)):_options(mode,labels,ctx,extra,optional)
 else:
  var index=0
  if mode=="pact" and int(e.fighters[int(ctx.self)].hp)<=1:index=1
  if mode=="fate_target" and extra.ids.size()>1 and e.fighters[int(extra.ids[1])].hp>e.fighters[int(extra.ids[0])].hp:index=1
  if mode=="fate_amount" and int(extra.ids[1])>=0:index=mini(mini(4,int(e.fighters[int(extra.ids[0])].hp)-1),int(e.fighters[int(extra.ids[1])].max_hp)-int(e.fighters[int(extra.ids[1])].hp))
  _apply(mode,maxi(0,index),ctx,extra)
func _apply(mode: String, index: int, ctx: Dictionary, extra: Dictionary):
 var p=int(ctx.owner);var fid=int(ctx.self)
 match mode:
  "sensational":
   if index==0:e._v18._recycle(ctx,"deck",1)
  "savage":
   if index==0 and p==e.active and e.actions_left>0:e.actions_left-=1;ctx.value=9
  "legalese":
   for owner in [p,int(ctx.opponent_owner)]:
    if index==0:e._draw(owner,1)
    else:_queue({"kind":"opponent_discard","amount":1},_victim(ctx,owner))
  "pact":
   if index==0:
    e._damage(fid,1);e.players[p].deck.push_front(ctx.card);e._flow["pact_collected_"+str(ctx.get("_combat_slot","a"))]=true;e._draw(p,1)
  "move_combatant":_queue({"kind":"move","fixed_fighter":int(extra.ids[index]),"spaces":int(extra.get("spaces",3))},ctx)
  "doctor":
   var c=e.players[p].hand.pop_at(int(extra.indices[index]));e.players[p].deck.append(c);e._log("Раскрыта карта: %s · BOOST %d"%[c.name,int(c.boost)]);ctx.heal_amount=int(c.boost);var ids=[e.hero_fighter(p)]+e._v14._adjacent(e.hero_fighter(p)).filter(func(n):return not e.is_enemy(p,int(e.fighters[int(n)].owner)))
   _option(ctx,"heal_target",ids.map(func(n):return e.fighters[int(n)].name),{"ids":ids})
  "heal_target":e._heal(int(extra.ids[index]),int(ctx.heal_amount))
  "fate_target":
   var ids=extra.ids;var victim=int(ids[index]);var other=int(ids[1-index]) if ids.size()>1 else -1;_option(ctx,"fate_amount",range(5).map(func(n):return "Урон: %d"%n),{"ids":[victim,other]})
  "fate_amount":
   var ids=extra.ids
   if ids.size()==2:e._damage(int(ids[0]),index);e._heal(int(ids[1]),index)
   e._draw(p,2)
func _victim(ctx: Dictionary, victim: int) -> Dictionary:
 var c=ctx.duplicate(true);c.opponent_owner=victim;return c
func run(fx: Dictionary, ctx: Dictionary) -> bool:
 var p=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1));var other=e._v6._other(ctx) if ctx.has("_combat_slot") else {};var id=str(ctx.card.get("id",""))
 if fx.kind=="v22_throw":
  if human(p):_cards("throw",p,"hand",range(e.players[p].hand.size()),ctx,{},true)
  elif not e.players[p].hand.is_empty():
   var c=e.players[p].hand.pop_at(e._lowest_card(p));e._discard(p,c);_queue({"kind":"damage","target":"any_in_hero_zone","amount":int(c.boost)},ctx)
  return true
 if fx.kind=="v22_pact":_option(ctx,"pact",["Получить 1 урон: карта вниз колоды и добор","Пропустить"]);return true
 if fx.kind=="v22_leap":
  if e._v14._adjacent(fid).any(func(n):return e.is_enemy(p,int(e.fighters[int(n)].owner))):e.gain_actions(p,1)
  return true
 if fx.kind!="v22_card":return false
 match id:
  "lady_justice":
   var victim=int(ctx.opponent_owner)
   if not e.players[victim].deck.is_empty():var c=e.players[victim].deck.pop_back();e._discard(victim,c,"deck");ctx.value+=2*int(c.boost)
  "the_defense_rests":e._draw(p,int(ctx.get("damage_taken",0)))
  "cease_and_desist":
   if fx.stage=="immediately":e._v6._cancel(ctx)
   elif ctx._combat_slot=="a":ctx.value=4
  "legalese":
   var chooser=int(ctx.opponent_owner)if ctx.won else p;var c=ctx.duplicate(true);c.owner=chooser;c.opponent_owner=p if chooser!=p else int(ctx.opponent_owner);_option(c,"legalese",["Оба берут карту","Оба сбрасывают карту"])
  "nerve_cluster_strike":
   if e._v14._adjacent(fid).has(foe):e.fighters[foe].locked_until=e.turn_number
  "the_savage_she_hulk":_option(ctx,"savage",["Потратить действие: сила 9","Пропустить"])
  "green_energy":
   if ctx.won:e._damage_many(e._v14._adjacent(fid),1)
  "sensational":
   if ctx.won:_option(ctx,"sensational",["Вернуть карту сброса в колоду","Пропустить"])
  "omega_level_threat":
   if int(ctx.get("damage_dealt",0))>=2:e._force_discard(int(ctx.opponent_owner),2,true)
  "double_jeopardy":e._draw(p,2);e._heal(fid,2)
  "jennifer_walters_esq":_queue({"kind":"draw","amount":1},ctx);_queue({"kind":"gain_action","amount":1},ctx);_start_place(ctx,fid)
  "leap_toward":_queue({"kind":"v22_leap"},ctx);_queue({"kind":"move","spaces":4,"through_enemies":true},ctx)
  "friendly_neighborhood_spider_man":e._heal(fid,3);_queue({"kind":"place","same_zone":true},ctx)
  "counter_attack":
   if int(other.get("value",other.card.get("value",0)))>=4:e._damage(foe,2)
  "disarming_shot":e._draw(p,int(ctx.get("damage_dealt",0)))
  "momentous_shift":
   if int(e.fighters[fid].node)!=int(e.turn_start_nodes[fid]):ctx.value=5
  "web_shooters":ctx.combat_cap=2
  "right_in_the_face":e.players[int(ctx.opponent_owner)].no_draw_turn=e.turn_number
  "spider_sense_tingling":
   if int(other.get("value",other.card.get("value",0)))>=4:e._draw(p,2)
  "swinging_kick":_queue({"kind":"move","fixed_fighter":foe,"spaces":int(ctx.get("damage_dealt",0))},ctx)
  "thwip","wall_crawler":
   if id=="wall_crawler" or ctx.won:_queue({"kind":"place","same_zone":true},ctx)
  "with_great_power":e.players[p].turn_attack_bonus=int(e.players[p].get("turn_attack_bonus",0))+1;e._draw(p,1);e.gain_actions(p,1)
  "snark":
   if e._v14._adjacent(fid).has(foe):e._draw(p,1)
  "channel_the_dark":
   if e.fighters[fid].name=="Плащ":
    var dagger=_own(p).filter(func(n):return e.fighters[int(n)].name=="Кинжал")
    if not dagger.is_empty():_queue({"kind":"place","fixed_fighter":foe,"adjacent_to":int(dagger[0])},ctx);e.gain_actions(p,1)
  "chosen_fate":
   var ids=_own(p)
   if not ids.is_empty():_option(ctx,"fate_target",ids.map(func(n):return e.fighters[int(n)].name),{"ids":ids})
   else:e._draw(p,2)
  "darkforce_dimension":_queue({"kind":"opponent_discard","amount":1},ctx);_queue({"kind":"place","fixed_fighter":foe},ctx)
  "into_darkness":
   var ids=[fid,foe].filter(func(n):return e._valid_fighter(int(n)));_option(ctx,"move_combatant",ids.map(func(n):return e.fighters[int(n)].name),{"ids":ids})
  "into_the_void":_queue({"kind":"optional_boost"},ctx)
  "lightforce_barrage":
   if fx.stage=="after" and ctx.won:e._damage(fid,int(ctx.get("damage_dealt",0)))
  "living_shadow":
   if e.fighters[fid].name=="Кинжал":
    var ids=_own(p).filter(func(n):return e.fighters[int(n)].name=="Плащ")
    if not ids.is_empty():
     e._v15._apply("portal",int(ids[0]),ctx,{})
     if int(ctx.self)==int(ids[0]):ctx.value=4
  "perfect_balance":
   if _own(p).size()==2 and _own(p).all(func(n):return e._v14._adjacent(int(n)).has(foe)):ctx.value=6
  "the_living_light":
   if (e.fighters[fid].name=="Плащ" and ctx._combat_slot=="d")or(e.fighters[fid].name=="Кинжал" and ctx._combat_slot=="a"):
    for n in _own(p):
     if int(n)!=fid:e._heal(int(n),2)
  "traverse_the_darkforce":_queue({"kind":"move","target":"all_friendly","spaces":2},ctx)
  "commanding_impact":e._draw(p,1)
  "cloak_of_levitation":
   if e._v14._adjacent(fid).has(foe):ctx.ignore_opponent_value=true
  "steadfast_disciple":
   if e._v14._adjacent(fid).has(foe):e._damage(foe,1);e._draw(p,1)
  "master_of_kamar_taj":
   if _own(p).size()==2 and e._v14._adjacent(int(_own(p)[0])).has(int(_own(p)[1])):ctx.value=4
  "bolts_of_balthakk":
   if fx.stage=="during":_blind_offer(ctx)
   elif ctx.won:e.gain_actions(p,1)
  "seven_suns_of_cinnibus":
   if fx.stage=="during":_queue({"kind":"v22_suns_finish"},ctx);_queue({"kind":"v22_blind"},ctx);_queue({"kind":"v22_blind"},ctx)
  "the_mists_of_munnopor":_mists(ctx)
  "the_rings_of_raggadorr":
   if ctx.won:
    for n in [fid]+e._v14._adjacent(fid):
     if not e.is_enemy(p,int(e.fighters[int(n)].owner)):e._heal(int(n),int(ctx.get("damage_dealt",0)))
  "the_winds_of_watoomb":
   for player in e.players:e._shuffle(player.deck)
   _queue({"kind":"v22_winds_second","strange":e.hero_fighter(p)},ctx)
   var c=ctx.duplicate(true);c.owner=int(ctx.opponent_owner);_start_place(c,e.hero_fighter(p))
  "eye_of_agamotto":e.players[p].deck.append_array(e.players[p].hand);e.players[p].hand.clear();e._shuffle(e.players[p].deck);e._draw(p,5);e.gain_actions(p,1)
  "no_really_im_a_doctor":
   if human(p):_cards("doctor",p,"hand",range(e.players[p].hand.size()),ctx)
   elif not e.players[p].hand.is_empty():_apply("doctor",0,ctx,{"indices":[0]})
  "feint":e._v6._cancel(ctx)
  _:push_error("Unhandled v22 "+id)
 return true
func _blind_offer(ctx: Dictionary):
 if human(int(ctx.owner)):_options("blind",["Слепое усиление","Пропустить"],ctx)
 else:_blind(ctx)
func extras(fx: Dictionary, ctx: Dictionary) -> bool:
 if fx.kind=="v22_winds_second":_start_place(ctx,int(ctx.opponent),int(e.fighters[int(fx.strange)].node));return true
 if fx.kind=="v22_blind":_blind_offer(ctx);return true
 if fx.kind=="v22_suns_finish":
  pass # The conditional value is evaluated after all card/item modifiers.
  return true
 return false
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true
func choose_option(index: int) -> bool:
 var p=e.pending_choice.duplicate(true)
 if index<0 or index>=p.options.size():return false
 e.pending_choice.clear();var ctx=_live(p._ctx);var mode=str(p.action).trim_prefix("v22_")
 if mode=="throw":
  var c=e.players[int(ctx.owner)].hand.pop_at(int(p.indices[index]));e._discard(int(ctx.owner),c);_queue({"kind":"damage","target":"any_in_hero_zone","amount":int(c.boost)},ctx)
 elif mode=="start":e._enter_node(int(p.fid),int(p.nodes[index]))
 elif mode=="blind":
  if index==0:_blind(ctx)
 else:_apply(mode,index,ctx,p)
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true

func _blind(ctx: Dictionary):
 var p=int(ctx.owner)
 if e.players[p].deck.is_empty():return
 var c=e.players[p].deck.pop_back();e._discard(p,c,"deck");ctx.value+=int(c.boost);e._log("Слепое усиление: "+str(c.name))
