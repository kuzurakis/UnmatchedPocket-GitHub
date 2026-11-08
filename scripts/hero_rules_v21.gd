extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v21_"+action
func form(owner: int) -> int:return int(e.players[owner].get("moon_form",0))
func fire(owner: int) -> int:return int(e.players[owner].get("hellfire",5))
func add_fire(owner: int, amount: int):e.players[owner].hellfire=clampi(fire(owner)+amount,0,5)
func change(owner: int):e.players[owner].moon_form=(form(owner)+1)%3;e._log("Личность: "+["Лунный рыцарь","Хонсу","Мистер Найт"][form(owner)])
func protected(fid: int) -> bool:return e._is_hero(int(e.fighters[fid].owner),"moon_knight") and form(int(e.fighters[fid].owner))==1
func summary(owner: int) -> String:
 if e._is_hero(owner,"moon_knight"):return "Личность: "+["Лунный рыцарь","Хонсу","Мистер Найт"][form(owner)]
 if e._is_hero(owner,"ghost_rider"):return "Адское пламя: %d/5"%fire(owner)
 if e._is_hero(owner,"winter_soldier"):return "Красная комната отключена в этом ходу" if int(e.players[owner].get("redroom_off",-1))==e.turn_number else "Эффекты карт нельзя отменить"
 return ""
func start_turn() -> bool:
 var p=e.active;var distance=2 if e._is_hero(p,"moon_knight") and form(p)==0 else 1 if e._is_hero(p,"ms_marvel") else 0
 if distance==0:return false
 e._start_ability(p,"Начальное перемещение",[{"kind":"move","spaces":distance}],"start_turn");return true
func end_turn():
 if e._is_hero(e.active,"moon_knight"):change(e.active)
func maneuver(boost_index: int) -> bool:
 if not e._is_hero(e.active,"ghost_rider") or fire(e.active)==0:return false
 e._start_ability(e.active,"Адский мотоцикл",[{"kind":"v21_cycle","boost_index":boost_index}],"maneuver");return true
func _cost(ctx: Dictionary, mode: String, cost: int):
 if fire(int(ctx.owner))<cost:return
 if human(int(ctx.owner)):_options("cost",["Потратить пламя: %d"%cost,"Пропустить"],ctx,{"mode":mode,"cost":cost})
 else:_paid21(ctx,mode,cost)
func _paid21(ctx: Dictionary, mode: String, cost: int):
 var p=int(ctx.owner);add_fire(p,-cost)
 match mode:
  "escape":_queue({"kind":"move","spaces":2},ctx)
  "vengeance":e._draw(p,2)
  "devil":e.gain_actions(p,1)
  "penance":ctx.value+=int(e._v6._other(ctx).card.get("boost",0))
  "defense":ctx.value+=cost
  "blaze":e._damage_many(e.fighters.filter(func(f):return e._valid_fighter(int(f.id)) and e._same_zone(int(f.node),int(e.fighters[int(ctx.self)].node))).map(func(f):return int(f.id)),cost)
func _optional(ctx: Dictionary, mode: String):
 if not e.players[int(ctx.owner)].alive:return
 if human(int(ctx.owner)):_options("optional",["Применить эффект","Пропустить"],ctx,{"mode":mode})
 else:_optional_apply(ctx,mode)
func _optional_apply(ctx: Dictionary, mode: String):
 var p=int(ctx.owner)
 match mode:
  "change":change(p)
  "good":e._draw(p,2);e._damage(int(ctx.self),2)
  "sane":e._damage_many([int(ctx.self),int(ctx.opponent)],2)
  "family":
   if e.actions_left>0:e.actions_left-=1;e._draw(p,maxi(0,7-e.players[p].hand.size()))
  "red_draw":e._draw(p,maxi(0,5-e.players[p].hand.size()))
  "one_draw":e._draw(p,1)
  "top":_top(ctx)
func _foe_ctx(ctx: Dictionary, p: int) -> Dictionary:
 var c=ctx.duplicate(true);c.owner=p;c.self=e.hero_fighter(p);c.opponent_owner=int(ctx.owner);c.opponent=int(ctx.self);return c
func _top(ctx: Dictionary):
 var victim=int(ctx.opponent_owner);var ids=[]
 for i in range(maxi(0,e.players[victim].deck.size()-3),e.players[victim].deck.size()):ids.append(i)
 if ids.is_empty():return
 if human(int(ctx.owner)):_cards("top_discard",victim,"deck",ids,ctx)
 else:e._discard_from_opponent(victim,e.players[victim].deck.pop_at(int(ids[0])),false)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
 var p=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1))
 if effect.kind=="v21_cycle":
  if human(p):_options("cycle",["Потратить 1 пламя: маршрут до 4 клеток","Обычный манёвр"],ctx,{"boost_index":effect.boost_index})
  else:_cycle(ctx,true,int(effect.boost_index))
  return true
 if effect.kind!="v21_card":return false
 if ctx.card.id!="manipulation" and effect.get("redroom",false) and int(e.players[p].get("redroom_off",-1))==e.turn_number:return true
 var id=str(ctx.card.id)
 match id:
  "feint":e._v6._cancel(ctx)
  "momentous_shift":
   if int(e.fighters[fid].node)!=int(e.turn_start_nodes[fid]):ctx.value=5
  "im_not_real":_optional(ctx,"change")
  "thats_why_i_always_win":_queue({"kind":"optional_boost"},ctx)
  "were_all_in_this_together":
   if ctx.won:e._draw(p,1)
  "good_enough_for_us":_optional(ctx,"good")
  "a_totally_sane_thing_to_do":_optional(ctx,"sane")
  "thats_the_part_i_like":
   if ctx.won:_optional(ctx,"top")
  "fist_of_khonshu":
   if ctx.won:_queue({"kind":"move","fixed_fighter":foe,"spaces":4},ctx)
  "let_your_insanity_guide_you":
   if not e.players[p].deck.is_empty():
    var c=e.players[p].deck.pop_back();e._discard(p,c,"deck");e._draw(p,int(c.boost))
  "past_and_present_intermingle":
   if not e.players[p].discard.is_empty():ctx.value+=int(e.players[p].discard[-1].boost)
  "madness_will_keep_you_alive":
   e._heal(fid,2)
   if int(e.fighters[fid].node)!=int(e.turn_start_nodes[fid]):e.gain_actions(p,1)
  "travelers_of_the_night":_queue({"kind":"gain_action","amount":1},ctx);_queue({"kind":"move","spaces":4,"through_enemies":true},ctx)
  "i_finally_escaped_hell":_cost(ctx,"escape",1)
  "spirit_of_vengeance":_cost(ctx,"vengeance",1)
  "i_brought_the_devil_with_me":_cost(ctx,"devil",2)
  "blaze_of_glory","deal_with_the_devil":
   if human(p):_options("amount",range(fire(p)+1).map(func(n):return "Пламя: %d"%n),ctx,{"mode":"blaze" if id=="blaze_of_glory" else "defense"})
   else:_paid21(ctx,"blaze" if id=="blaze_of_glory" else "defense",mini(2,fire(p)))
  "stoke_the_flames":
   if not ctx.won:add_fire(p,int(ctx.get("damage_taken",0)))
  "control_the_demon":ctx.value+=fire(p)
  "penance_stare":ctx.value+=int(e._v6._other(ctx).card.get("boost",0));_cost(ctx,"penance",2)
  "the_wicked_will_burn":
   if int(e.fighters[fid].node)!=int(e.turn_start_nodes[fid]):add_fire(p,2)
  "chains_of_hellfire":e.players[p].hellfire=5
  "hell_rides_with_me":
   var ids=e._v14._adjacent(fid);_queue({"kind":"v21_hell_finish"},ctx)
   _queue({"kind":"move","spaces":4},ctx)
   if not ids.is_empty():
    if human(p):_options("hell_friend",ids.map(func(n):return e.fighters[int(n)].name),ctx,{"ids":ids},true)
    else:_queue({"kind":"move","fixed_fighter":int(ids[0]),"spaces":4},ctx)
  "big_wind_up":
   if not e._same_zone(int(e.fighters[fid].node),int(e.fighters[foe].node)):_queue({"kind":"optional_boost"},ctx)
  "easy_peasy":e._draw(p,1);_queue({"kind":"v21_easy"},ctx)
  "embiggen":
   if e._v19.zones(int(e.fighters[fid].node)).size()>e._v19.zones(int(e.fighters[foe].node)).size():ctx.value=6
  "friends_and_family":e._draw(p,2);_optional(ctx,"family")
  "gyro_and_fries":
   e._heal(fid,2)
   if e.players[p].hand.size()>=4:e.gain_actions(p,1)
  "im_not_touching_you":
   if not e._same_zone(int(e.fighters[fid].node),int(e.fighters[foe].node)):e._draw(p,2)
  "shrink_shrink_shrink":
   if not e._same_zone(int(e.fighters[fid].node),int(e.fighters[foe].node)):_shrink(ctx,2)
   elif human(p):_options("shrink",["Противник сбрасывает карту","Передвинуть противника до 3 клеток"],ctx)
   else:_shrink(ctx,0)
  "slingshot":_queue({"kind":"place","same_zone":true},ctx)
  "fangirl":ctx.value=e.players[p].hand.size()
  "a_boy_named_bucky":e.players[p].redroom_off=e.turn_number;e.gain_actions(p,1)
  "bionic_arm":
   if effect.stage=="during":
    if e.fighters_adjacent(fid,foe):ctx.value=6
   else:_queue({"kind":"move","target":"all_friendly","spaces":5},_foe_ctx(ctx,int(ctx.opponent_owner)))
  "complete_the_mission":
   if effect.stage=="during":_queue({"kind":"optional_boost"},ctx)
   else:e._damage(foe,int(ctx.get("damage_taken",0)))
  "manipulation":
   e._draw(p,maxi(0,5-e.players[p].hand.size()))
   if int(e.players[p].get("redroom_off",-1))!=e.turn_number:
    for victim in range(e.players.size()):
     if e.is_enemy(p,victim):_queue({"kind":"v21_red_draw"},_foe_ctx(ctx,victim))
  "marksman":ctx.value+=maxi(0,e.fighters_distance(fid,foe)-1)
  "programmed_to_kill":
   if ctx.won:e._damage(fid,2)
  "reflex_memories":e._force_discard(p,2,true,false,false);e._draw(p,2)
  "reprogram":e._v18._recycle(ctx,"deck",3)
  "wily_fighting":e._damage_many(e._v14._adjacent(fid).filter(func(n):return e.is_enemy(p,int(e.fighters[int(n)].owner))),1)
  "without_remorse":_queue({"kind":"v21_one_draw"},_foe_ctx(ctx,int(ctx.opponent_owner)))
  "born_in_the_barracks":
   if ctx.won:e._heal(fid,2)
  _:push_error("Unhandled v21 card: "+id)
 return true
func extras(effect: Dictionary, ctx: Dictionary) -> bool:
 match str(effect.kind):
  "v21_hell_finish":add_fire(int(ctx.owner),2);e.gain_actions(int(ctx.owner),1)
  "v21_easy":
   if e.players[int(ctx.owner)].hand.size()>=4:_queue({"kind":"damage","target":"any_adjacent_to_self","amount":1},ctx)
  "v21_red_draw":_optional(ctx,"red_draw")
  "v21_one_draw":_optional(ctx,"one_draw")
  _:return false
 return true
func _shrink(ctx: Dictionary, mode: int):
 if mode in [1,2]:_queue({"kind":"move","fixed_fighter":int(ctx.opponent),"spaces":3},ctx)
 if mode in [0,2]:_queue({"kind":"opponent_discard","amount":1},ctx)
func _cycle(ctx: Dictionary, paid: bool, boost_index: int):
 if paid:
  add_fire(int(ctx.owner),-1);e.maneuver_distance=0;e.maneuver_boosted=true;e.maneuver_moved.append(int(ctx.self));e._v18._path(ctx,4,"adversity")
 elif boost_index>=0:e._apply_maneuver_boost(boost_index)
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true
func choose_option(index: int) -> bool:
 var p=e.pending_choice.duplicate(true)
 if index<0 or index>=p.options.size():return false
 e.pending_choice.clear();var ctx=_live(p._ctx)
 match str(p.action).trim_prefix("v21_"):
  "cost":
   if index==0:_paid21(ctx,str(p.mode),int(p.cost))
  "amount":_paid21(ctx,str(p.mode),index)
  "optional":
   if index==0:_optional_apply(ctx,str(p.mode))
  "cycle":_cycle(ctx,index==0,int(p.boost_index))
  "shrink":_shrink(ctx,index)
  "hell_friend":_queue({"kind":"move","fixed_fighter":int(p.ids[index]),"spaces":4},ctx)
  "top_discard":
   var victim=int(p.victim);e._discard_from_opponent(victim,e.players[victim].deck.pop_at(int(p.indices[index])),false)
   var left=[]
   for i in p.indices:
    if int(i)!=int(p.indices[index]):left.append(int(i)-(1 if int(i)>int(p.indices[index]) else 0))
   if left.size()==2:_cards("top_order",victim,"deck",left,ctx)
  "top_order":
   var victim=int(p.victim);var chosen=e.players[victim].deck[int(p.indices[index])];var other=e.players[victim].deck[int(p.indices[1-index])]
   for i in range(2):e.players[victim].deck.pop_back()
   e.players[victim].deck.append(other);e.players[victim].deck.append(chosen)
  _:return false
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true

