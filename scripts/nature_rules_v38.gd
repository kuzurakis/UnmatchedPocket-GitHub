extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v38_"+action
func hid(p: int) -> String:return e._hero_id(p)
func own(p: int,alive=true) -> Array:return e.fighters.filter(func(f):return int(f.owner)==p and bool(f.alive)==alive).map(func(f):return int(f.id))
func charge(p: int) -> Array:return e.players[p].get("charge",[])
func setup():
 for p in range(e.players.size()):
  if hid(p)=="godzilla":e.players[p].charge=[]
  if hid(p)=="birds":
   var placed=[]
   for fid in own(p):
    if placed.is_empty():placed.append(fid);continue
    for node in e.nodes:
     if e._occupant(int(node.id))>=0:continue
     if placed.any(func(other):return e.node_adjacent_to_fighter(int(node.id),int(other))):e.fighters[fid].node=int(node.id);break
    placed.append(fid)
  if hid(p)=="kraken":
   for fid in own(p):
    if not e.fighters[fid].hero:e.fighters[fid].hp=0;e.fighters[fid].alive=false;e.fighters[fid].reserve=true
func same(a: int,b: int) -> bool:
 for x in e._v19.spaces(a):
  for y in e._v19.spaces(b):
   if e._same_zone(int(x),int(y)):return true
 return false
func zones(fid: int) -> Array:
 var result=[]
 for n in e._v19.spaces(fid):
  for z in e.nodes[int(n)].zones:
   if not result.has(int(z)):result.append(int(z))
 return result
func friends_adj(ctx: Dictionary) -> Array:return e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.are_allies(int(ctx.owner),int(f.owner))and int(f.id)!=int(ctx.self)and e.fighters_adjacent(int(f.id),int(ctx.opponent))).map(func(f):return int(f.id))
func tail_adj(fid: int,foe: int) -> bool:return int(e.fighters[fid].get("tail",-1))>=0 and e.node_adjacent_to_fighter(int(e.fighters[fid].tail),foe)
func bonus(fid: int,foe: int) -> int:
 var p=int(e.fighters[fid].owner)
 if hid(p)=="godzilla":return charge(p).reduce(func(total,c):return total+int(c.get("boost",0)),0)
 if hid(p)=="moose"and e.node_adjacent_to_fighter(int(e.fighters[fid].node),foe):return 2
 return 0
func in_range(a: int,b: int) -> bool:
 var p=int(e.fighters[a].owner)
 return hid(p)=="kraken"and e.fighters[a].hero and own(p).any(func(fid):return not e.fighters[fid].hero and e.fighters_adjacent(fid,b))
func ranged(c: Dictionary,a: int,b: int) -> bool:return c.get("nature_hero","")in["moose","godzilla"]and int(c.get("nature_number",0))in([6]if c.get("nature_hero","")=="moose"else[2])and same(a,b)
func damaged(fid: int):
 var p=int(e.fighters[fid].owner)
 if hid(p)=="godzilla"and not charge(p).is_empty():release_charge(p,1)
func release_charge(p: int,amount: int):
 for i in range(mini(amount,charge(p).size())):
  var entry=e.players[p].charge.pop_back();e._discard(int(entry.get("charge_owner",p)),entry,"played")
func add_charge(p: int,source: int,amount: int):
 for i in range(mini(amount,e.players[source].discard.size())):
  var c=e.players[source].discard.pop_back();c.charge_owner=source;e.players[p].charge.append(c)
func collect(p: int,c: Dictionary) -> bool:
 if hid(p)!="godzilla":return false
 c.charge_owner=p;e.players[p].charge.append(c);return true
func start_turn() -> bool:
 e.players[e.active].nature_attacks=0
 if hid(e.active)!="moose":return false
 var p=e.active;var ids=[]
 for i in range(e.players[p].hand.size()):
  if e.players[p].hand[i].get("nature_hero","")=="moose"and int(e.players[p].hand[i].get("nature_number",0))==1:ids.append(i)
 if ids.is_empty():return false
 e._start_ability(p,"Начало хода Лося",[{"kind":"v38_alert","indices":ids}],"start_turn");return true
func move(ctx: Dictionary,fid: int,distance: int,through=false):_queue({"kind":"move","fixed_fighter":fid,"spaces":distance,"through_enemies":through},ctx)
func place(ctx: Dictionary,fx: Dictionary):
 var fid=int(fx.fid);var ids=[]
 if not e._valid_fighter(fid)or not e._v13.can_relocate(fid):return
 for node in e.nodes:
  var n=int(node.id)
  if e._occupant(n)not in[-1,fid]:continue
  var tails=e._v19.orientations(fid,n)if e._v19.large(fid)else[-1]
  for tail in tails:
   var cells=[n]+([int(tail)]if int(tail)>=0 else[])
   if fx.get("zone",false)and not cells.any(func(cell):return zones(fid).any(func(z):return e.nodes[cell].zones.has(z))):continue
   if fx.has("adjacent")and not cells.any(func(cell):return e.node_adjacent_to_fighter(cell,int(fx.adjacent))):continue
   if fx.has("apart")and cells.any(func(cell):return e._v19.spaces(int(fx.apart)).any(func(x):return e._same_zone(int(x),cell))):continue
   ids.append({"head":n,"tail":int(tail)})
 if ids.is_empty():return
 if human(int(ctx.owner)):_options("place",ids.map(func(s):return "Клетка %d"%(int(s.head)+1)if int(s.tail)<0 else"Голова: %d · хвост: %d"%[int(s.head)+1,int(s.tail)+1]),ctx,{"states":ids,"fx":fx})
 else:
  ids.sort_custom(func(a,b):return e._position_score(fid,int(a.head))>e._position_score(fid,int(b.head)));placed(ctx,fx,ids[0])
func placed(ctx: Dictionary,fx: Dictionary,s: Dictionary):
 var fid=int(fx.fid);var old=int(e.fighters[fid].node)
 if e._v19.large(fid):e.fighters[fid].chosen_tail=int(s.tail)
 e._enter_node(fid,int(s.head));e._v19.moved(fid,old,true)
 if fx.get("deep",false)and e.fighters.any(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(int(ctx.owner),int(f.owner))and e.fighters_adjacent(fid,int(f.id)))and human(int(ctx.owner)):_options("deep",["Завершить","Повторить перемещение"],ctx,{"fid":fid})
func summon(ctx: Dictionary,bird: bool):
 var p=int(ctx.owner);var ids=own(p,false).filter(func(fid):return bird or not e.fighters[fid].hero);var states=[]
 for fid in ids:
  for node in e.nodes:
   if e._occupant(int(node.id))>=0:continue
   if own(p).any(func(anchor):return (bird or e.fighters[anchor].hero)and e._same_zone(int(e.fighters[anchor].node),int(node.id))):states.append({"fid":fid,"node":int(node.id)})
 if states.is_empty():return
 if human(p):_options("summon",states.map(func(s):return "%s · клетка %d"%[str(e.fighters[int(s.fid)].name),int(s.node)+1]),ctx,{"states":states})
 else:summoned(states[0])
func summoned(s: Dictionary):
 var f=e.fighters[int(s.fid)];f.hp=f.max_hp;f.alive=true;f.offboard=false;f.node=int(s.node);f.reserve=false
func targets(ctx: Dictionary,ids: Array,action: String,amount=0):
 if ids.is_empty():return
 if human(int(ctx.owner))and ids.size()>1:_options(action,ids.map(func(fid):return str(e.fighters[fid].name)),ctx,{"ids":ids,"amount":amount})
 else:selected_target(ctx,action,int(ids[0]),amount)
func selected_target(ctx: Dictionary,action: String,fid: int,amount: int):
 match action:
  "bird_place":place(ctx,{"fid":fid})
  "sightless":e._damage(fid,amount)
  "wave":
   var birds=own(int(ctx.owner));birds.sort_custom(func(a,b):return e.fighters_distance(a,fid)<e.fighters_distance(b,fid))
   if not birds.is_empty():
    var nearest=birds.filter(func(b):return e.fighters_distance(b,fid)==e.fighters_distance(int(birds[0]),fid));var c=ctx.duplicate(true);c.opponent=fid;c.opponent_owner=int(e.fighters[fid].owner)
    if human(int(ctx.owner))and nearest.size()>1:_options("swarm_actor",nearest.map(func(b):return str(e.fighters[b].name)),c,{"ids":nearest})
    else:c.self=int(nearest[0]);swarm(c)
func swarm(ctx: Dictionary):
 var c={"id":"nature_swarm","name":"Рой","type":"attack","fighter":"any","boost":0,"value":0,"text":"Рой","effects":[{"kind":"v38_swarm_value","timing":"during"}],"virtual":true}
 _queue({"kind":"v9_bonus","name":"Рой","value":0,"bonus_card":c},ctx)
func after_queue(a: Dictionary):
 if a.get("nature_king_action",false)and not a.cancelled:e._effect_queue.append({"effect":{"kind":"gain_action","amount":1},"ctx":a.duplicate(true)})
 if hid(int(a.owner))=="birds"and not a.card.get("virtual",false):e._effect_queue.append({"effect":{"kind":"v38_swarm_offer","intrinsic":true},"ctx":a.duplicate(true)})
func roost(fid: int,amount: int) -> bool:
 var ctx=e._combat_resolution.get("d",{})
 if int(ctx.get("self",-1))!=fid or not ctx.get("roost",false)or ctx.get("cancelled",false)or amount<int(e.fighters[fid].hp):return false
 var ids=own(int(ctx.owner))
 if human(int(ctx.owner)):_options("roost",ids.map(func(other):return str(e.fighters[other].name)),ctx,{"ids":ids})
 else:
  var victim=int(ids[0])
  for id in ids:
   if id!=fid:victim=id;break
  e._damage_raw(victim,int(e.fighters[victim].hp));e._finish_combat_damage()
 return true
func roost_effect(fid: int,amount: int) -> bool:
 if e._flow.get("kind","")!="combat":return false
 var ctx=e._combat_resolution.get("d",{})
 if int(ctx.get("self",-1))!=fid or not ctx.get("roost",false)or ctx.get("cancelled",false)or amount<int(e.fighters[fid].hp):return false
 var ids=own(int(ctx.owner))
 if human(int(ctx.owner)):_options("roost_after",ids.map(func(other):return str(e.fighters[other].name)),ctx,{"ids":ids})
 else:
  var victim=int(ids[0])
  for id in ids:
   if id!=fid:victim=id;break
  e._damage_raw(victim,int(e.fighters[victim].hp))
 return true
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var k=str(fx.kind);var p=int(ctx.owner);var fid=int(ctx.get("self",-1));var foe=int(ctx.get("opponent",-1));var n=int(fx.get("number",0));var stage=str(fx.get("stage",""))
 match k:
  "v38_place":place(ctx,fx);return true
  "v38_summon":summon(ctx,bool(fx.bird));return true
  "v38_zone_draw":e._draw(p,zones(fid).size());return true
  "v38_alert":
   if human(p):_options("alert",["Оставить направление","Сбросить карту: развернуть Лося"],ctx,{"index":int(fx.indices[0])})
   elif e._v19.spaces(fid).size()>1 and e._v14._adjacent(fid).any(func(f):return tail_adj(fid,int(f))):turn_moose(p,int(fx.indices[0]))
   return true
  "v38_swarm_value":e._draw(p,1);ctx.value=own(p).filter(func(f):return e.fighters_adjacent(f,foe)).size();return true
  "v38_swarm_offer":
   if not e.players[p].hand.is_empty()and e._valid_fighter(fid)and e._valid_fighter(foe):
    if human(p):_cards("swarm_pay",p,"hand",range(e.players[p].hand.size()),ctx,{},true)
    else:e._discard(p,e.players[p].hand.pop_at(e._lowest_card(p)),"voluntary");swarm(ctx)
   return true
  "v38_wave_gain":
   if e.players[p].get("won_combat_turn",false):e.gain_actions(p,1)
   return true
  "v38_group_move":
   var ids=e._int_array(fx.ids).filter(func(id):return e._valid_fighter(id))
   if human(p)and ids.size()>1:_options("group",["Завершить"]+ids.map(func(id):return str(e.fighters[id].name)),ctx,{"ids":ids,"fx":fx})
   else:
    for id in ids:move(ctx,id,int(fx.spaces),bool(fx.get("through",false)))
   return true
  "v38_god_group":
   _queue({"kind":"v38_group_move","spaces":2,"ids":e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and same(fid,int(f.id))).map(func(f):return int(f.id))},ctx)
   return true
  "v38_dread":offer_discard(ctx,"dread");return true
  "v38_heal_discard":
   var pile=e.players[int(ctx.opponent_owner)].discard
   if not pile.is_empty():e._heal(fid,int(pile[-1].get("boost",0)))
   return true
  "v38_alki":alki(ctx,int(fx.get("at",0)));return true
  "v38_alki_damage":
   e._damage_many(e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and f.hero and e.is_enemy(p,int(f.owner))and not e.fighters_adjacent(fid,int(f.id))).map(func(f):return int(f.id)),2);return true
  "v38_road":road(ctx);return true
  "v38_card":pass
  _:return false
 match str(fx.hero):
  "birds":
   match n:
    1:e._v9.run({"kind":"v9_glass"if stage=="during"else"v9_glass_after"},ctx)
    2:
     if stage=="immediately":e.fighters[foe].locked_until=e.turn_number
     elif e.players[p].get("won_combat_turn",false)and not e.players[p].discard.is_empty():e.players[p].hand.append(e.players[p].discard.pop_back())
    3:_queue({"kind":"opponent_discard","amount":1},ctx)
    4:_queue({"kind":"v38_summon","bird":true},ctx);_queue({"kind":"v38_group_move","ids":own(p),"spaces":3,"through":true},ctx)
    5:
     _queue({"kind":"draw","amount":1},ctx);_queue({"kind":"v38_group_move","ids":own(p).filter(func(f):return same(fid,f)),"spaces":2,"through":true},ctx)
    6:targets(ctx,own(p),"bird_place")
    7:ctx.value=e.fighters.filter(func(f):return not f.alive and not f.get("reserve",false)).size()
    8:_queue({"kind":"v38_zone_draw"},ctx);place(ctx,{"fid":fid,"zone":true})
    9:e._v6._cancel(ctx);ctx.roost=true
    10:
     var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and own(p).any(func(b):return b!=fid and e.fighters_adjacent(b,int(f.id)))).map(func(f):return int(f.id))
     targets(ctx,ids,"sightless",int(e._v6._other(ctx).get("card",{}).get("boost",0)))
    11:_queue({"kind":"v38_wave_gain"},ctx);targets(ctx,e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))).map(func(f):return int(f.id)),"wave")
    12:ctx.value+=own(p).filter(func(f):return e.fighters_adjacent(f,foe)).size()
  "moose":
   match n:
    1:e._v6._cancel(ctx)
    2:e._draw(p,1);alki(ctx,0)
    3:move(ctx,fid,5,true)
    4:
     if not ctx.won:_queue({"kind":"opponent_discard","amount":1},ctx)
     else:e._damage(foe,1)
    5:
     var old=[int(e.turn_start_nodes[fid]),int(e.turn_start_tails[fid])];var shared=false
     for x in old:
      if x>=0 and e._v19.spaces(fid).any(func(y):return e._same_zone(x,int(y))):shared=true
     if not shared:ctx.value=6
    6:place(ctx,{"fid":fid,"adjacent":foe})
    7:e._draw(p,2 if ctx.won else 1)
    8:e._draw(p,1);road(ctx)
    9:
     if stage=="immediately":
      for id in e.fighters:
       if e._valid_fighter(int(id.id))and e.is_enemy(p,int(id.owner))and not e._v35.shielded(int(id.owner)):id.locked_until=e.turn_number
     elif ctx.won:e._draw(p,2)
    10:
     if ctx.won:
      if human(p):_options("skirmish",[str(e.fighters[fid].name),str(e.fighters[foe].name)],ctx,{"ids":[fid,foe]})
      else:move(ctx,fid,2)
    11:
     if stage=="immediately":
      if tail_adj(fid,foe):e.gain_actions(p,1)
     else:move(ctx,fid,4)
    12:
     ctx.ignore_opponent_value=true
     if tail_adj(fid,foe):e._v6._cancel(ctx)
  "kraken":
   var hero=e.hero_fighter(p)
   match n:
    1:
     if not e.fighters.any(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and same(hero,int(f.id))):_queue({"kind":"draw","amount":2},ctx)
     summon(ctx,false)
    2:
     if stage=="during":ctx.nature_halve="up"
     elif int(ctx.get("damage_taken",0))<=2:end_turn_effect()
    3:_queue({"kind":"v38_group_move","ids":e.fighters.filter(func(f):return e._valid_fighter(int(f.id))).map(func(f):return int(f.id)),"spaces":1},ctx)
    4:
     if not friends_adj(ctx).is_empty():optional_boost(ctx)
    5:e._draw(p,2 if not friends_adj(ctx).is_empty()else 1)
    6:
     var all=[]
     for id in own(p):
      for z in zones(id):
       if not all.has(z):all.append(z)
     ctx.value=all.size()
    7:
     var ids=e._v14._adjacent(hero).filter(func(f):return e.is_enemy(p,int(e.fighters[f].owner)))
     if e._damage_many(ids,1)==0:_queue({"kind":"opponent_discard","amount":1},ctx)
    8:
     if not same(hero,foe):ctx.value=5
    9:offer_discard(ctx,"dread")
    10:place(ctx,{"fid":fid,"zone":true,"deep":true})
    11:
     if ctx.won:place(ctx,{"fid":foe,"apart":fid})
    12:ctx.value-=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and int(f.id)!=hero and same(hero,int(f.id))).size()
  "godzilla":
   match n:
    1:
     if ctx.won:e._damage(foe,2)
    2:release_charge(p,charge(p).size())
    3:
     if stage=="during":optional_boost(ctx)
     else:e._damage_many(e._v14._adjacent(fid).filter(func(f):return e.is_enemy(p,int(e.fighters[f].owner))),1)
    4:_queue({"kind":"gain_action","amount":1},ctx);_queue({"kind":"draw","amount":1},ctx);move(ctx,fid,1)
    5:
     e._draw(p,1)
     if int(e.players[p].get("nature_attacks",0))>0:_queue({"kind":"opponent_discard","amount":1},ctx)
    6:
     var ids=range(e.players.size()).filter(func(other):return e.is_enemy(p,other)and e.players[other].alive)
     if human(p)and ids.size()>1:_options("forgotten_target",ids.map(func(other):return e._player_name(other)),ctx,{"ids":ids})
     elif not ids.is_empty():ctx.opponent_owner=int(ids[0]);offer_discard(ctx,"forgotten")
    7:
     var victim=int(ctx.opponent_owner)
     if human(victim):_options("king",["Отменить эффекты моей карты","Дать Годзилле действие после боя"],ctx,{"owner":victim,"viewer":victim})
     elif e._v6._other(ctx).get("card",{}).get("effects",[]).is_empty():e._v6._cancel(ctx)
     else:ctx.nature_king_action=true
    8:end_turn_effect()
    9:e._draw(p,2);place(ctx,{"fid":fid,"zone":true})
    10:
     e._damage_many(e._v14._adjacent(fid).filter(func(f):return e.is_enemy(p,int(e.fighters[f].owner))),1)
     search(ctx,"deck",false)
    11:add_charge(p,p,2 if ctx.won else 1)
    12:add_charge(p,int(ctx.opponent_owner),1)
    13:
     if stage=="during":ctx.nature_halve="down"
     elif not ctx.won and not e.players[p].discard.is_empty():e.players[p].deck.append(e.players[p].discard.pop_back());e._shuffle(e.players[p].deck)
    14:_queue({"kind":"v38_god_group"},ctx);move(ctx,fid,2)
    15:
     if ctx.won:search(ctx,"discard",true)
 return true
func optional_boost(ctx: Dictionary):
 if human(int(ctx.owner)):e._begin_manual_effect({"kind":"optional_boost"},ctx)
 else:
  var at=e._best_boost(int(ctx.owner))
  if at>=0:e._v8.combat_boost(ctx,at)
func end_turn_effect():e.actions_left=0;e._v34.clear_free(e.active);e._flow.completion="end_turn"
func turn_moose(p: int,index: int):
 var fid=e.hero_fighter(p);var tail=int(e.fighters[fid].get("tail",-1))
 if tail<0:return
 e._discard(p,e.players[p].hand.pop_at(index),"voluntary");var head=int(e.fighters[fid].node);e.fighters[fid].node=tail;e.fighters[fid].tail=head
func alki(ctx: Dictionary,at: int):
 var opponents=range(e.players.size()).filter(func(p):return e.is_enemy(int(ctx.owner),p)and e.players[p].alive)
 if at>=opponents.size():_queue({"kind":"v38_alki_damage"},ctx);return
 var victim=int(opponents[at]);var fid=e.hero_fighter(victim)
 _queue({"kind":"v38_alki","at":at+1},ctx)
 if human(victim):_options("alki",["Остаться на месте","Разместить героя рядом с Лосем"],ctx,{"owner":victim,"viewer":victim,"fid":fid})
 elif not e.fighters_adjacent(fid,int(ctx.self)):var other=ctx.duplicate(true);other.owner=victim;place(other,{"fid":fid,"adjacent":int(ctx.self)})
func road(ctx: Dictionary):
 var fid=int(ctx.self);var states=e._v19.paths(fid,1).filter(func(s):return int(s.head)!=int(e.fighters[fid].node))if e._v13.can_relocate(fid)else[]
 if states.is_empty():optional_boost(ctx);return
 var victim=int(ctx.opponent_owner)
 if human(victim):_options("road",states.map(func(s):return "Голова: %d · хвост: %d"%[int(s.head)+1,int(s.tail)+1]),ctx,{"states":states,"owner":victim,"viewer":victim})
 else:placed(ctx,{"fid":fid},states[0])
func offer_discard(ctx: Dictionary,mode: String):
 var victim=int(ctx.opponent_owner)
 if human(victim)and not e.players[victim].hand.is_empty():_options("offer",["Сбросить карту","Не сбрасывать"],ctx,{"owner":victim,"viewer":victim,"mode":mode})
 else:
  var pay=not e.players[victim].hand.is_empty()and e._card_quality(e.players[victim].hand[e._lowest_card(victim)])<4.0
  if pay:e._force_discard(victim,1,false,false,false)
  offer_done(ctx,mode,pay)
func offer_done(ctx: Dictionary,mode: String,paid: bool):
 if mode=="forgotten":_queue({"kind":"v38_heal_discard"},ctx)
 elif not paid:place(ctx,{"fid":e.hero_fighter(int(ctx.owner))})
func search(ctx: Dictionary,pile: String,scheme: bool):
 var p=int(ctx.owner);var ids=range(e.players[p][pile].size()).filter(func(i):return not scheme or e.players[p][pile][i].type=="scheme")
 if ids.is_empty():return
 if human(p):_cards("search",p,pile,ids,ctx,{"pile":pile})
 else:
  ids.sort_custom(func(a,b):return e._card_quality(e.players[p][pile][a])>e._card_quality(e.players[p][pile][b]));e.players[p].hand.append(e.players[p][pile].pop_at(int(ids[0])))
  if pile=="deck":e._shuffle(e.players[p].deck)
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 var ctx=q._ctx;var p=int(ctx.owner);e.pending_choice.clear()
 match str(q.action):
  "v38_place":placed(ctx,q.fx,q.states[index])
  "v38_group":
   if index>0:
    var ids=e._int_array(q.ids);var fid=int(ids.pop_at(index-1));var fx=q.fx;fx.ids=ids
    if not ids.is_empty():_queue(fx,ctx)
    move(ctx,fid,int(fx.spaces),bool(fx.get("through",false)))
  "v38_summon":summoned(q.states[index])
  "v38_swarm_actor":ctx.self=int(q.ids[index]);swarm(ctx)
  "v38_forgotten_target":ctx.opponent_owner=int(q.ids[index]);offer_discard(ctx,"forgotten")
  "v38_alert":
   if index==1:turn_moose(p,int(q.index))
  "v38_bird_place","v38_sightless","v38_wave":selected_target(ctx,str(q.action).trim_prefix("v38_"),int(q.ids[index]),int(q.amount))
  "v38_swarm_pay":e._discard(p,e.players[p].hand.pop_at(int(q.indices[index])),"voluntary");swarm(ctx)
  "v38_roost":e._damage_raw(int(q.ids[index]),int(e.fighters[int(q.ids[index])].hp));e._finish_combat_damage();return true
  "v38_roost_after":e._damage_raw(int(q.ids[index]),int(e.fighters[int(q.ids[index])].hp))
  "v38_deep":
   if index==1:place(ctx,{"fid":int(q.fid),"zone":true,"deep":true})
  "v38_skirmish":move(ctx,int(q.ids[index]),2)
  "v38_road":placed(ctx,{"fid":int(ctx.self)},q.states[index])
  "v38_alki":
   if index==1:
    var other=ctx.duplicate(true);other.owner=int(q.owner);place(other,{"fid":int(q.fid),"adjacent":int(ctx.self)})
  "v38_offer":
   if index==0:
    var victim=int(ctx.opponent_owner);_cards("offer_pay",victim,"hand",range(e.players[victim].hand.size()),ctx,{"owner":victim,"viewer":victim,"mode":q.mode})
   else:offer_done(ctx,q.mode,false)
  "v38_offer_pay":e._discard_from_opponent(int(ctx.opponent_owner),e.players[int(ctx.opponent_owner)].hand.pop_at(int(q.indices[index])),false);offer_done(ctx,q.mode,true)
  "v38_search":
   e.players[p].hand.append(e.players[p][q.pile].pop_at(int(q.indices[index])))
   if q.pile=="deck":e._shuffle(e.players[p].deck)
  "v38_king":
   if index==0:e._v6._cancel(_live(ctx))
   else:_live(ctx).nature_king_action=true
 if e.pending_choice.is_empty():_resume()
 else:e.changed.emit()
 return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true
func estimate(c: Dictionary,fid: int,foe: int,value: float,defending=false) -> float:
 var hero=str(c.get("nature_hero",""));var n=int(c.get("nature_number",0));var p=int(e.fighters[fid].owner)
 if hero=="birds":
  if n==1:value+=1
  if n==7:value=e.fighters.filter(func(f):return not f.alive and not f.get("reserve",false)).size()
  if n==12:value+=own(p).filter(func(f):return e.fighters_adjacent(f,foe)).size()
  if n==9 and defending and own(p).size()>1:value+=5
 if hero=="kraken":
  if n==2 and defending:value+=2.5
  if n==8 and not same(e.hero_fighter(p),foe):value=5
  if n==12:value-=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and int(f.id)!=fid and same(fid,int(f.id))).size()
 if hero=="godzilla"and n==13 and defending:value+=2.5
 return value
