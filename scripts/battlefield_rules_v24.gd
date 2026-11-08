extends "res://scripts/hero_rules_v8.gd"
## Battlefield objects are independent from cards; mutable state is held by BattleEngine.
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/battlefield_items.json"))
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v24_"+action
func setup():
 e.battlefield_items.clear()
 for type in ["scheme","versatile"]:
  var ids=[]
  for key in definitions:
   if definitions[key].map==e.map_id and definitions[key].type==type:ids.append(int(key))
  e._shuffle(ids)
  var cells=e.board_data.get("item_slots",{}).get(type,[])
  for i in range(mini(ids.size(),cells.size())):e.battlefield_items.append({"id":ids[i],"node":int(cells[i]),"used":false})
func definition(token: Dictionary) -> Dictionary:return definitions.get(str(int(token.id)),{})
func at(fid: int, type: String) -> Array:
 if not e._valid_fighter(fid):return []
 var cells=e._v19.spaces(fid);var result=[]
 for i in range(e.battlefield_items.size()):
  var token=e.battlefield_items[i]
  if not token.used and cells.has(int(token.node)) and definition(token).type==type:result.append(i)
 return result
func global_attack(owner: int) -> bool:return int(e.players[owner].get("map_attack_turn",-1))==e.turn_number and e.players[owner].get("map_attack_ready",false)
func used_attack(owner: int):e.players[owner].map_attack_ready=false
func _take(index: int) -> Dictionary:
 var token=e.battlefield_items[index];token.used=true;var d=definition(token).duplicate(true)
 e._log("Предмет использован: %s · клетка %d."%[d.name,int(token.node)+1]);return d
func use(fid: int, index: int) -> bool:
 if e.actions_left<=0 or not e._can_act() or not e._valid_fighter(fid,e.active) or not at(fid,"scheme").has(index):return false
 e._v34.clear_free(e.active)
 var d=_take(index);var p=e.active;e.actions_left-=1;e.players[p].actions_taken=int(e.players[p].get("actions_taken",0))+1
 var foe=e._public_target(fid);var ctx={"owner":p,"self":fid,"opponent":foe,"opponent_owner":int(e.fighters[foe].owner)if foe>=0 else -1,"card":d,"value":0,"won":false,"item_effect":true}
 e._flow={"kind":"battlefield_item","stage":"effects","owner":p,"fighter":fid,"card":d,"effect_logs":[]}
 e.combat_report={"kind":"ability","stage":"effects","title":d.name,"card":d,"effect_logs":[]};e._effect_queue=[{"effect":{"kind":"v24_item","id":int(d.id)},"ctx":ctx}];e._pump_effects();e.changed.emit();return true
func offer(slot: String, defense_index=-1) -> bool:
 if e.pending_combat.get("item_checked_"+slot,false):return false
 e.pending_combat["item_checked_"+slot]=true
 var fid=int(e.pending_combat.attacker if slot=="a" else e.pending_combat.target);var p=int(e.fighters[fid].owner);var ids=at(fid,"versatile")
 if ids.is_empty() or (slot=="d" and defense_index<0):return false
 if human(p):
  var labels=ids.map(func(i):var d=definition(e.battlefield_items[int(i)]);return "%s · +%d"%[d.name,int(d.value)])
  labels.append("Пропустить");_options("combat_item",labels,{"owner":p,"self":fid,"card":{"name":"Боевой предмет"}},{"ids":ids,"slot":slot,"defense_index":defense_index});e.changed.emit();return true
 e.pending_combat["item_"+slot]=_take(int(ids[0]));return false
func queue_during(ctx: Dictionary):
 var groups=[]
 if ctx.card.get("effects",[]).any(func(fx):return fx.get("timing","")=="during"):groups.append("card")
 groups.append("item")
 if e._is_hero(int(ctx.owner),"daredevil") and e.fighters[int(ctx.self)].hero:groups.append("ability")
 e._effect_queue.append({"effect":{"kind":"v24_order","groups":groups,"intrinsic":true},"ctx":ctx.duplicate(true)})
func _order(ctx: Dictionary, groups: Array):
 var choices=groups.filter(func(g):return g=="ability" or not ctx.get("cancelled",false))
 if choices.is_empty():return
 if human(int(ctx.owner)) and choices.size()>1:
  var labels=choices.map(func(g):return {"card":"Эффект карты","item":"Бонус предмета","ability":"Способность героя"}[g]);_options("order",labels,ctx,{"groups":choices})
 else:_ordered(ctx,choices,0)
func _ordered(ctx: Dictionary, groups: Array, index: int):
 var rest=groups.duplicate();var group=rest.pop_at(index)
 if not rest.is_empty():_queue({"kind":"v24_order","groups":rest,"intrinsic":true},ctx)
 if group=="item":_queue({"kind":"v24_combat_bonus"},ctx)
 elif group=="ability":_queue({"kind":"v18_blind","ability":true,"intrinsic":true},ctx)
 else:
  var effects=ctx.card.get("effects",[]).filter(func(fx):return fx.get("timing","")=="during")
  for i in range(effects.size()-1,-1,-1):_queue(effects[i],ctx)
func _pick(action: String, ids: Array, labels: Array, ctx: Dictionary, extra={}):
 if ids.is_empty():return
 if human(int(ctx.owner)):_options(action,labels,ctx,{"ids":ids});e.pending_choice.merge(extra,true)
 else:_apply(action,0,ctx,{"ids":ids}.merged(extra,true))
func _discard_choice(victim: int, count: int, ctx: Dictionary, self_cost=false):
 if count<=0 or e.players[victim].hand.is_empty() or (not self_cost and e._v14.owl_protected(victim)):return
 if human(victim):
  var c=ctx.duplicate(true);c.owner=victim;_cards("discard",victim,"hand",range(e.players[victim].hand.size()),c,{"remaining_count":count,"self_cost":self_cost})
 else:e._force_discard(victim,count,false,false,not self_cost)
func _top(ctx: Dictionary, victim: int):
 var count=mini(3,e.players[victim].deck.size());var ids=range(e.players[victim].deck.size()-count,e.players[victim].deck.size())
 if human(int(ctx.owner)):_cards("top",victim,"deck",ids,ctx,{"ordered":[],"remaining":ids})
 # A bot may leave the legal current order, without exposing cards to the human.
func _apply(mode: String, index: int, ctx: Dictionary, extra: Dictionary):
 var p=int(ctx.owner);var fid=int(ctx.self)
 match mode:
  "retrieve":e.players[p].hand.append(e.players[p].discard.pop_at(int(extra.indices[index])))
  "bottom":e.players[p].deck.push_front(e.players[p].hand.pop_at(int(extra.indices[index])))
  "brazier":
   e._flow.deck_scheme=e.players[p].deck.pop_at(int(extra.indices[index]));e._shuffle(e.players[p].deck)
  "damage":e._damage(int(extra.ids[index]),2)
  "camera":
   var c=ctx.duplicate(true);c.opponent_owner=int(extra.ids[index]);_queue({"kind":"draw","amount":1},ctx);_queue({"kind":"reveal_hand"},c)
  "deck":_top(ctx,int(extra.ids[index]))
  "discard":
   var victim=int(extra.victim);var c=e.players[victim].hand.pop_at(int(extra.indices[index]))
   if extra.self_cost:e._discard(victim,c)
   else:e._discard_from_opponent(victim,c)
   _discard_choice(victim,int(extra.remaining_count)-1,ctx,bool(extra.self_cost))
  "top":
   var ordered=extra.ordered.duplicate();var selected=int(extra.indices[index]);ordered.append(selected);var left=extra.remaining.map(func(v):return int(v));left.erase(selected)
   if left.is_empty():
    var victim=int(extra.victim);var cards=ordered.map(func(i):return e.players[victim].deck[int(i)])
    for i in range(cards.size()):e.players[victim].deck.pop_back()
    for i in range(cards.size()-1,-1,-1):e.players[victim].deck.append(cards[i])
   else:_cards("top",int(extra.victim),"deck",left,ctx,{"ordered":ordered,"remaining":left})
func run(fx: Dictionary, ctx: Dictionary) -> bool:
 var p=int(ctx.owner);var fid=int(ctx.self)
 match str(fx.kind):
  "v24_order":_order(ctx,fx.groups)
  "v24_combat_bonus":
   if not ctx.get("cancelled",false):ctx.value+=int(ctx.get("item",{}).get("value",0));e._log("Бонус боевого предмета: +%d."%int(ctx.get("item",{}).get("value",0)))
  "v24_discard":_discard_choice(int(fx.victim),int(fx.amount),ctx,bool(fx.get("self_cost",false)))
  "v24_item":
   match int(fx.id):
    1:_queue({"kind":"move","target":"all_fighters","spaces":1},ctx)
    4:
     var ids=[]
     for i in range(e.players[p].deck.size()):
      var c=e.players[p].deck[i]
      if c.type=="scheme" and e._card_usable(c,fid):ids.append(i)
     if human(p):_cards("brazier",p,"deck",ids,ctx)
     elif not ids.is_empty():_apply("brazier",0,ctx,{"indices":ids})
     if ids.is_empty():
      var held=e.players[p].hand.filter(func(c):return c.type=="scheme" and e._card_usable(c,fid))
      e._log("В колоде нет подходящего приёма.")
      if not held.is_empty() and e.interactive and p!=0:_options("public",["Продолжить"],ctx,{"cards":held,"viewer":0,"prompt":"Подходящие приёмы находятся в руке."})
    5:
     e._draw(p,3)
     if human(p):_cards("bottom",p,"hand",range(e.players[p].hand.size()),ctx)
     elif not e.players[p].hand.is_empty():_apply("bottom",0,ctx,{"indices":[e._lowest_card(p)]})
    7:
     var ids=[]
     for f in e.fighters:
      if e._valid_fighter(int(f.id)) and e._same_zone(int(e.fighters[fid].node),int(f.node)):ids.append(int(f.id))
     e._damage_many(ids,1)
    9:
     for victim in range(e.players.size()):
      if e.players[victim].alive:_queue({"kind":"v24_discard","victim":victim,"amount":2,"self_cost":victim==p},ctx)
    11:e._heal(fid,2);e._draw(p,1)
    15:_queue({"kind":"gain_action","amount":1},ctx);_queue({"kind":"move","fixed_fighter":fid,"spaces":2},ctx)
    17:
     var ids=[]
     for f in e.fighters:
      if e._valid_fighter(int(f.id)) and e._same_zone(int(e.fighters[fid].node),int(f.node)):ids.append(int(f.id))
     if not human(p):ids.sort_custom(func(a,b):return int(e.is_enemy(p,int(e.fighters[int(a)].owner)))>int(e.is_enemy(p,int(e.fighters[int(b)].owner))))
     _pick("damage",ids,ids.map(func(n):return str(e.fighters[int(n)].name)),ctx)
    20:e.players[p].map_attack_ready=true;e.players[p].map_attack_turn=e.turn_number
    22:
     var ids=range(e.players[p].discard.size())
     if human(p):_cards("retrieve",p,"discard",ids,ctx)
     elif not ids.is_empty():_apply("retrieve",0,ctx,{"indices":ids})
    24:_queue({"kind":"place","fixed_fighter":fid},ctx)
    25:
     var held=e.players[p].hand.duplicate();e.players[p].hand.clear()
     for c in held:e._discard(p,c)
     e._draw(p,3)
    26:
     var ids=range(e.players.size()).filter(func(v):return e.players[int(v)].alive and e.is_enemy(p,int(v)))
     _pick("camera",ids,ids.map(func(v):return str(e.players[int(v)].name)),ctx)
    29:e._heal(fid,3)
    30:
     var ids=range(e.players.size()).filter(func(v):return e.players[int(v)].alive and not e.players[int(v)].deck.is_empty())
     _pick("deck",ids,ids.map(func(v):return str(e.players[int(v)].name)),ctx)
  _:return false
 return true
func choose_option(index: int) -> bool:
 var choice=e.pending_choice.duplicate(true)
 if index<0 or index>=choice.options.size():return false
 e.pending_choice.clear();var ctx=_live(choice._ctx);var mode=str(choice.action).trim_prefix("v24_")
 if mode=="combat_item":
  if index<choice.ids.size():e.pending_combat["item_"+str(choice.slot)]=_take(int(choice.ids[index]))
  if choice.slot=="a":
   if e.interactive:e.phase="attack_notice"
   else:e._begin_defense()
  else:e._resolve_combat(int(choice.defense_index))
  e.changed.emit();return true
 elif mode=="order":_ordered(ctx,choice.groups,index)
 elif mode!="public":_apply(mode,index,ctx,choice)
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:return false
func bot_score(fid: int, index: int) -> float:
 var d=definition(e.battlefield_items[index]);var p=int(e.fighters[fid].owner)
 match int(d.id):
  11,29:return float(mini(int(e.fighters[fid].max_hp)-int(e.fighters[fid].hp),3))*1.8+(1.0 if d.id==11 else 0.0)
  22:return 3.0 if not e.players[p].discard.is_empty() else -1.0
  17:return 4.0 if e.fighters.any(func(f):return e._valid_fighter(int(f.id)) and e.is_enemy(p,int(f.owner)) and e._same_zone(int(f.node),int(e.fighters[fid].node)))else -1.0
  7:return 2.0 if e.fighters.any(func(f):return e._valid_fighter(int(f.id)) and e.is_enemy(p,int(f.owner)) and e._same_zone(int(f.node),int(e.fighters[fid].node)))and int(e.fighters[fid].hp)>1 else -1.0
  25:return 4.0 if e.players[p].hand.size()<3 else -1.0
  20:return 1.0 if e.players[p].hand.any(func(c):return e._attack_type(c)) else -1.0
 return 2.0
