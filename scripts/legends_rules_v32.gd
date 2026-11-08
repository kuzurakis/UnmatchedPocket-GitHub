extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v32_"+action
func setup():
 for p in range(e.players.size()):
  e.players[p].trick_returns=[]
  if e._is_hero(p,"blackbeard"):e.players[p].doubloons=2
  if e._is_hero(p,"pandora"):
   e.players[p].box=["hope","pain","misfortune","woe","toil","greed","confusion"];e._shuffle(e.players[p].box);e.players[p].miseries=[];e.players[p].box_peek=false
   for f in e.fighters:
    if int(f.owner)==p and not f.hero:f.alive=false;f.reserve=true;f.node=-1
  if e._is_hero(p,"loki"):
   for pile in ["hand","deck"]:
    for c in e.players[p][pile]:
     if c.get("trick",false):c.trick_owner=p
func origin(card: Dictionary) -> int:
 if not card.get("trick",false):return -1
 if card.has("trick_owner"):return int(card.trick_owner)
 for p in range(e.players.size()):
  if e._is_hero(p,"loki"):return p
 return -1
func move_bonus(p: int) -> int:
 if not e._is_hero(p,"loki"):return 0
 var n=0
 for other in range(e.players.size()):
  if e.is_enemy(p,other):n+=e.players[other].hand.filter(func(c):return origin(c)==p).size()
 return n
func attack_bonus(fid: int) -> int:
 var p=int(e.fighters[fid].owner)
 return e.players[p].get("miseries",[]).count("toil")if e._is_hero(p,"pandora") and e.fighters[fid].hero else 0
func estimate(c: Dictionary,fid: int,foe: int,value: float,defending=false) -> float:
 if not c.has("bol3_number"):return value
 var p=int(e.fighters[fid].owner);var other=int(e.fighters[foe].owner);var n=int(c.bol3_number)
 match n:
  655:value+=e.players[other].hand.size()
  657:value+=3*e.players[other].hand.filter(func(card):return card.get("trick",false)).size()
  659:value=maxf(value,4.0)
  660:value+=1.5
  662:
   if e.players[other].hand.size()>e.players[p].hand.size()-1:value=6
  665:value+=e.players[p].get("miseries",[]).size()
  666:value+=float(e.players[p].get("miseries",[]).size())*0.5
  668:value=maxf(value,6.0)
  669:value+=1.5 if e.players[p].hand.size()>1 else 0.0
  670:value+=2
  676:value=8
  678:
   if e.players[p].get("won_combat_turn",false)and e.players[p].hand.size()>1:value+=2
  682:
   if int(e.fighters[e.hero_fighter(p)].hp)<=7:value=5
  687:
   if e.fighters.any(func(f):return int(f.id)!=fid and e.are_allies(p,int(f.owner))and e.fighters_adjacent(int(f.id),foe)):value=5
  689:value=maxf(1.0,value-2*(3-coins(p)))
  692:value+=1.5 if e.players[p].hand.size()>1 else 0.0
 if not defending:value+=attack_bonus(fid)
 return value
func collect(p: int,c: Dictionary,receiver: int) -> bool:
 var owner=origin(c)
 if owner<0:return false
 if p==owner and receiver>=0 and receiver<e.players.size() and e.players[receiver].alive:e.players[receiver].hand.append(c);e._log("Уловка Локи передана: "+e._player_name(receiver))
 else:e.players[owner].discard.append(c)
 return true
func discarded(p: int,c: Dictionary,source: String) -> bool:
 var owner=origin(c)
 if owner<0 or owner==p:return false
 if source=="hand" and e.players[owner].alive:
  if not e._flow.is_empty():
   e._effect_queue.push_front({"effect":{"kind":"v32_return","card":c,"intrinsic":true},"ctx":{"owner":owner,"self":e.hero_fighter(owner),"opponent":-1,"opponent_owner":-1,"card":{"name":"Возвращение уловки"},"value":0,"won":false}})
  else:
   if not e.players[owner].has("trick_returns"):e.players[owner].trick_returns=[]
   e.players[owner].trick_returns.append(c)
 else:e.players[owner].discard.append(c)
 return true
func pending_returns() -> Array:
 var jobs=[]
 for p in range(e.players.size()):
  for c in e.players[p].get("trick_returns",[]):jobs.append({"effect":{"kind":"v32_return","card":c,"intrinsic":true},"ctx":{"owner":p,"self":e.hero_fighter(p),"opponent":-1,"opponent_owner":-1,"card":{"name":"Возвращение уловки"},"value":0,"won":false}})
  e.players[p].trick_returns=[]
 return jobs
func before_collect() -> bool:
 var jobs=pending_returns()
 if jobs.is_empty():return false
 e._effect_queue.append_array(jobs);return true
func flush_returns(completion: String) -> bool:
 var jobs=pending_returns()
 if jobs.is_empty():return false
 e.combat_report={"kind":"ability","title":"Возвращение уловки","effect_logs":[]}
 e._flow={"kind":"ability","stage":"effects","completion":completion,"effect_logs":[]};e._effect_queue=jobs;e._pump_effects();return true
func summary(p: int) -> String:
 if p<0 or p>=e.players.size():return ""
 if e._is_hero(p,"blackbeard"):return "Дублоны: %d · казна: %d"%[coins(p),3-coins(p)]
 if e._is_hero(p,"loki"):return "Уловок у соперников: %d · движение: %d"%[move_bonus(p),2+move_bonus(p)]
 if e._is_hero(p,"pandora"):return "Бед раскрыто: %d · перья: %d · %s"%[e.players[p].get("miseries",[]).size(),feathers(p),", ".join(e.players[p].get("miseries",[]).map(func(id):return misery_name(str(id))))]
 if e._is_hero(p,"chupacabra"):return "Голод: после атаки можно взять карту · порог: 7 здоровья"
 return ""
func coins(p: int) -> int:return int(e.players[p].get("doubloons",0))
func pay(p: int,amount: int):e.players[p].doubloons=maxi(0,coins(p)-amount)
func combat_damaged(fid: int,amount: int):
 if amount>0 and e._is_hero(int(e.fighters[fid].owner),"blackbeard") and e.fighters[fid].hero:pay(int(e.fighters[fid].owner),1)
func start_turn() -> bool:
 var p=e.active
 if e._is_hero(p,"blackbeard") and coins(p)>0:
  e._start_ability(p,"Дополнительное действие за дублон",[{"kind":"v32_start_coin"}],"start_turn");return true
 if e._is_hero(p,"pandora"):
  e.players[p].box_peek=false;e._start_ability(p,"Ящик Пандоры",[{"kind":"v32_box_draw"}],"start_turn");return true
 return false
func feathers(p: int) -> int:
 var n=0
 for id in e.players[p].get("miseries",[]):n+=2 if id=="misfortune"else 1 if id in["pain","toil","greed"]else 0
 return n
func misery_name(id: String) -> String:
 return {"hope":"Надежда","pain":"Боль","misfortune":"Несчастье","woe":"Горе","toil":"Тяжкий труд","greed":"Жадность","confusion":"Смятение"}.get(id,id)
func _box_draw(ctx: Dictionary):
 var p=int(ctx.owner)
 if e.players[p].box.is_empty():return
 var id=str(e.players[p].box.pop_back());e.players[p].miseries.append(id);e.players[p].box_peek=id=="hope";e._log("Ящик Пандоры: "+misery_name(id))
 _queue({"kind":"v32_box_decide"},ctx)
 match id:
  "greed":e._draw(p,1)
  "pain":e._damage_many(e._v14._adjacent(e.hero_fighter(p)).filter(func(fid):return e.is_enemy(p,int(e.fighters[int(fid)].owner))),1)
  "confusion":e._v31._move(ctx,e.hero_fighter(p),1)
  "woe":_queue({"kind":"v32_summon","where":"zone"},ctx)
func _box_decide(ctx: Dictionary):
 var p=int(ctx.owner);var n=e.players[p].miseries.size()
 if feathers(p)>=3:e._log("Ящик Пандоры: три пера — урон %d."%n);e._damage(e.hero_fighter(p),n);return
 if e.players[p].box.is_empty():return
 var peek=str(e.players[p].box[-1])if e.players[p].box_peek else""
 if human(p):
  _options("box",["Раскрыть следующую беду","Остановиться"],ctx)
  e.pending_choice.prompt="Раскрыто: %d · перья: %d"%[n,feathers(p)]
  if not peek.is_empty():e.pending_choice.prompt+="\nНадежда: следующая беда — "+misery_name(peek)
 else:
  var threshold=3 if e.difficulty==0 else 2
  var safe=peek.is_empty()or feathers(p)+(2 if peek=="misfortune"else 1 if peek in["greed","pain","toil"]else 0)<3
  if n<threshold and int(e.fighters[e.hero_fighter(p)].hp)>n+2 and safe:_queue({"kind":"v32_box_draw"},ctx)
func reset_box(p: int):
 if not e._is_hero(p,"pandora"):return
 e.players[p].box.append_array(e.players[p].miseries);e.players[p].miseries=[];e.players[p].box_peek=false;e._shuffle(e.players[p].box)
func _enemy_ids(p: int) -> Array:return range(e.players.size()).filter(func(n):return e.is_enemy(p,n)and not e.is_dormant(n))
func ransom(fx: Dictionary,ctx: Dictionary):
 var p=int(ctx.owner);var ids=fx.get("payers",_enemy_ids(p)).duplicate();var cost=int(fx.ransom)
 if ids.is_empty() or 3-coins(p)<(1 if cost<0 else cost):
  if cost>=0:var next=fx.duplicate(true);next.decided=true;_queue(next,ctx)
  return
 var payer=int(ids.pop_front());var count=3-coins(p)
 if cost>=0:count=cost
 if human(payer):
  var labels=["Оплатить %d дублонов: отменить эффект"%cost,"Не платить"]if cost>=0 else range(count+1).map(func(n):return "Оплатить %d: сила карты −%d"%[n,2*n])
  _options("ransom",labels,ctx,{"fx":fx,"payers":ids,"payer":payer});e.pending_choice.owner=payer;e.pending_choice.viewer=payer
  var descriptions={685:["Соперник сбрасывает случайную карту","Каждый враг в зоне Чёрной Бороды получает 1 урон"],686:["Выбранный враг в зоне Чёрной Бороды получает 3 урона"],687:["Чёрная Борода получает дополнительное действие"],689:["Сила карты уменьшается на 2 за каждый оплаченный дублон"],690:["Чёрная Борода смотрит руку и выбирает карту для сброса"],691:["Все эффекты карты противника отменяются"],695:["Чёрная Борода восстанавливает 2 здоровья","Призвать морского волка в любую клетку","Чёрная Борода получает дополнительное действие"]}
  var parts=descriptions.get(int(fx.number),["Эффект карты"]);e.pending_choice.prompt=str(parts[mini(int(fx.get("part",0)),parts.size()-1)])+"\nВ казне: %d дублонов"%(3-coins(p))
 else:_ransom_paid(ctx,fx,ids,(cost if cost>=0 else count))
func _ransom_paid(ctx: Dictionary,fx: Dictionary,rest: Array,amount: int):
 var p=int(ctx.owner);var cost=int(fx.ransom)
 if cost>=0 and amount==cost:e.players[p].doubloons=mini(3,coins(p)+cost);e._log("Выкуп оплачен: эффект отменён.");return
 if cost<0:
  e.players[p].doubloons=mini(3,coins(p)+amount);ctx=_live(ctx);ctx.value=maxi(0,int(ctx.value)-2*amount)
 var next=fx.duplicate(true);next.payers=rest;ransom(next,ctx)
func _summon(ctx: Dictionary,fx: Dictionary):
 var p=int(ctx.owner);var hero=e.hero_fighter(p)
 if not e._valid_fighter(hero):return
 var own=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero);var reserve=own.filter(func(f):return not e._valid_fighter(int(f.id)));var ids=(reserve if not reserve.is_empty()else own).map(func(f):return int(f.id))
 if ids.is_empty():return
 if reserve.is_empty()and human(p)and not fx.has("fid"):_options("summon_source",ids.map(func(fid):return str(e.fighters[int(fid)].name)+" · клетка %d"%(int(e.fighters[int(fid)].node)+1)),ctx,{"ids":ids,"fx":fx});return
 var fid=int(fx.get("fid",ids[0]));var legal=e.nodes.filter(func(n):return e._v31.can_end(fid,int(n.id))and(fx.get("where","")!="zone"or e._same_zone(int(n.id),int(e.fighters[hero].node)))).map(func(n):return int(n.id))
 if legal.is_empty():return
 if human(p):_options("summon",legal.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":legal,"fid":fid})
 else:
  var best=int(legal[0]);var score=-INF
  for n in legal:
   var value=e._position_score(hero,int(n))
   if value>score:score=value;best=int(n)
  _summoned(fid,best)
func _summoned(fid: int,node: int):
 e.fighters[fid].node=node;e.fighters[fid].hp=1;e.fighters[fid].alive=true;e.fighters[fid].reserve=false;e.fighters[fid].placed=true
func _hidden(ctx: Dictionary,victim: int,mode: String):
 if victim<0 or e.players[victim].hand.is_empty():return
 var labels=e.players[victim].hand.map(func(c):return "Рубашка: УЛОВКА"if c.get("trick",false)else"Рубашка: обычная карта")
 if human(int(ctx.owner)):_options("hidden",range(labels.size()).map(func(i):return "%d · %s"%[i+1,labels[i]]),ctx,{"victim":victim,"mode":mode})
 else:
  var index=e.players[victim].hand.find_custom(func(c):return c.get("trick",false));_hidden_selected(ctx,victim,maxi(0,index),mode)
func _hidden_selected(ctx: Dictionary,victim: int,index: int,mode: String):
 var c=e.players[victim].hand[index];e._log("Раскрытая карта: "+str(c.name))
 if mode=="levateinn":
  ctx=_live(ctx);ctx.value+=int(c.get("boost",0))
  if c.get("trick",false):e.players[victim].hand.remove_at(index);e.players[int(ctx.owner)].hand.append(c)
 else:e._discard_from_opponent(victim,e.players[victim].hand.pop_at(index))
 if human(int(ctx.owner)):_options("revealed",["Продолжить"],ctx,{"kind":"hand_view","cards":[c.duplicate(true)],"victim":victim})
func _trouble(ctx: Dictionary):
 var other=e._v6._other(ctx);var victim=int(other.owner);var fid=int(other.self);var slot=str(other._combat_slot)
 var legal=range(e.players[victim].hand.size()).filter(func(i):var c=e.players[victim].hand[i];return (e._attack_type(c)if slot=="a"else e._defense_type(c))and e._card_usable(c,fid))
 if human(int(ctx.owner)):_options("trouble_view",["Выбрать карту для розыгрыша"if not legal.is_empty()else"Нет подходящих карт — продолжить"],ctx,{"kind":"hand_view","cards":e.players[victim].hand.duplicate(true),"victim":victim,"indices":legal,"slot":slot})
 elif not legal.is_empty():
  var best=int(legal[0])
  for i in legal:
   if int(e.players[victim].hand[int(i)].value)<int(e.players[victim].hand[best].value):best=int(i)
  _trouble_play(ctx,best)
func _trouble_play(ctx: Dictionary,index: int):
 var other=e._v6._other(ctx);var victim=int(other.owner);var c=e.players[victim].hand.pop_at(index);var slot=str(other._combat_slot)
 other.card=c;other.value=int(c.value);other.cancelled=false
 e._combat_resolution.ctx["attack_card"if slot=="a"else"defense_card"]=c
 var effects=c.get("effects",[]).filter(func(fx):return fx.get("timing","")=="during")
 for i in range(effects.size()-1,-1,-1):_queue(effects[i],other)
func _tooth(ctx: Dictionary,remaining=2,used=[]):
 used=used.map(func(n):return int(n))
 var p=int(ctx.owner);var hero=e.hero_fighter(p);var ids=e._v14._adjacent(hero).filter(func(fid):return not used.has(int(fid)))
 if remaining<=0 or ids.is_empty():return
 if human(p):_options("tooth",ids.map(func(fid):return str(e.fighters[int(fid)].name)+" · клетка %d"%(int(e.fighters[int(fid)].node)+1)),ctx,{"ids":ids,"tooth_left":remaining,"used":used},true)
 else:
  var enemies=ids.filter(func(fid):return e.is_enemy(p,int(e.fighters[int(fid)].owner)))
  if not enemies.is_empty():_tooth_hit(ctx,int(enemies[0]),remaining,used)
func _tooth_hit(ctx: Dictionary,fid: int,remaining: int,used: Array):
 var before=e.fighters.map(func(f):return int(f.hp));used=used.duplicate();used.append(fid)
 _queue({"kind":"v32_tooth_finish","before":before,"remaining":remaining-1,"used":used},ctx);e._damage(fid,1)
func _unsettle(ctx: Dictionary,victim=-1):
 var p=int(ctx.owner);var hero=e.hero_fighter(p);var ids=_enemy_ids(p).filter(func(other):return e.fighters.any(func(f):return int(f.owner)==other and e._valid_fighter(int(f.id))and e._same_zone(int(f.node),int(e.fighters[hero].node))))
 if ids.is_empty():return
 if victim<0:
  if human(p)and ids.size()>1:_options("unsettle_enemy",ids.map(func(n):return e._player_name(n)),ctx,{"ids":ids});return
  victim=int(ids[0])
 ctx=ctx.duplicate(true);ctx.opponent_owner=victim
 if human(p):_options("unsettle",["Противник сбрасывает 1 карту","Получить 2 урона: противник сбрасывает 2 карты"],ctx)
 else:_queue({"kind":"opponent_discard","amount":1},ctx)
func _choose_enemy_fighter(ctx: Dictionary,mode: String):
 var p=int(ctx.owner);var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))).map(func(f):return int(f.id))
 if ids.is_empty():return
 if human(p):_options("enemy_fighter",ids.map(func(fid):return e._player_name(int(e.fighters[int(fid)].owner))+" · "+str(e.fighters[int(fid)].name)+" · клетка %d"%(int(e.fighters[int(fid)].node)+1)),ctx,{"ids":ids,"mode":mode})
 else:_enemy_fighter(ctx,e._best_public_target(ids),mode)
func _enemy_fighter(ctx: Dictionary,fid: int,mode: String):
 var p=int(ctx.owner);ctx=ctx.duplicate(true);ctx.opponent=fid;ctx.opponent_owner=int(e.fighters[fid].owner)
 if mode=="lure":
  e._flow.trick_receiver=int(ctx.opponent_owner);_queue({"kind":"place","fixed_fighter":fid,"adjacent_to":e.hero_fighter(p)},ctx)
 elif mode=="zeus":e._v31._move(ctx,fid,1)
 elif mode=="pistols":e._damage(fid,3)
func _pistols(ctx: Dictionary):
 var p=int(ctx.owner);var hero=e.hero_fighter(p);var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and e._same_zone(int(f.node),int(e.fighters[hero].node))).map(func(f):return int(f.id))
 if ids.is_empty():return
 if human(p):_options("enemy_fighter",ids.map(func(fid):return str(e.fighters[int(fid)].name)+" · клетка %d"%(int(e.fighters[int(fid)].node)+1)),ctx,{"ids":ids,"mode":"pistols"})
 else:e._damage(e._best_public_target(ids),3)
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var kind=str(fx.kind);var p=int(ctx.owner);var fid=int(ctx.get("self",-1));var foe=int(ctx.get("opponent",-1))
 match kind:
  "v32_return":
   var c=fx.card
   if human(p):_options("return",["Вернуть в руку","Положить наверх колоды"],ctx,{"returned":c})
   else:e.players[p].hand.append(c)
   return true
  "v32_hunger":
   if human(p):_options("hunger",["Взять 1 карту","Не брать карту"],ctx)
   elif not e.players[p].deck.is_empty():e._draw(p,1)
   return true
  "v32_start_coin":
   if human(p):_options("coin",["Оплатить 1 дублон: +1 действие","Не платить"],ctx)
   else:pay(p,1);e.gain_actions(p,1)
   return true
  "v32_steal":e.players[p].doubloons=mini(3,coins(p)+1);return true
  "v32_box_draw":_box_draw(ctx);return true
  "v32_box_decide":_box_decide(ctx);return true
  "v32_summon":_summon(ctx,fx);return true
  "v32_tooth":_tooth(ctx,int(fx.remaining),fx.used);return true
  "v32_tooth_finish":
   var count=0
   for i in range(e.fighters.size()):
    if int(e.fighters[i].hp)<int(fx.before[i]):count+=1
   e._heal(e.hero_fighter(p),count);_tooth(ctx,int(fx.remaining),fx.used);return true
  "v32_trouble":_trouble(ctx);return true
  "v32_sindri":
   var victim=int(ctx.opponent_owner)
   if human(victim)and not e.players[victim].hand.is_empty():
    _cards("sindri",victim,"hand",range(e.players[victim].hand.size()),ctx,{},true);e.pending_choice.owner=victim;e.pending_choice.viewer=victim
   else:
    var other=e._v6._other(ctx)
    if int(other.value)>3 and not e.players[victim].hand.is_empty():e._discard(victim,e.players[victim].hand.pop_at(e._lowest_card(victim)))
    else:other.value=maxi(0,int(other.value)-3)
   return true
  "v32_conveyor":_conveyor(ctx);return true
  "v32_conveyor_commit":_conveyor_commit();return true
  "v32_bin":_bin(ctx,int(fx.fid));return true
  "v32_adjacent_damage":e._damage_many(e._v14._adjacent(fid),1);return true
 if kind!="v32_card":return false
 var number=int(fx.number);var stage=str(fx.stage)
 if int(fx.get("ransom",0))!=0 and not fx.get("decided",false):ransom(fx,ctx);return true
 match number:
  2:e._v31._cancel(ctx)
  9:
   var victim=int(ctx.opponent_owner)
   if not e.players[victim].hand.is_empty():var c=e.players[victim].hand.pop_at(e.rng.randi_range(0,e.players[victim].hand.size()-1));e._discard_from_opponent(victim,c);ctx.value+=int(c.get("boost",0))
  685:
   if stage=="immediately":
    var victim=int(ctx.opponent_owner)
    if not e.players[victim].hand.is_empty():e._discard_from_opponent(victim,e.players[victim].hand.pop_at(e.rng.randi_range(0,e.players[victim].hand.size()-1)))
   else:
    var hero=e.hero_fighter(p);e._damage_many(e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and e._same_zone(int(f.node),int(e.fighters[hero].node))).map(func(f):return int(f.id)),1)
  686:_pistols(ctx)
  687:
   if stage=="after":e.gain_actions(p,1)
   elif e.fighters.any(func(f):return int(f.id)!=fid and e.are_allies(p,int(f.owner))and e.fighters_adjacent(int(f.id),foe)):ctx.value=5
  688:
   var hero=e.hero_fighter(p)
   if e._v14._adjacent(hero).any(func(n):return e.is_enemy(p,int(e.fighters[int(n)].owner))):e._heal(hero,2)
  689:pass
  690:_queue({"kind":"reveal_choose_discard","amount":1},ctx)
  691:e._v31._cancel(ctx)
  692:
   if stage=="during":e._v31.offer_boost(ctx)
   elif ctx.won:e._draw(p,1)
  693:_queue({"kind":"v32_summon","where":"zone"},ctx)
  694:_queue({"kind":"v32_steal"},ctx);e._v31._move_own(ctx,3,true)
  695:
   match int(fx.part):
    0:e._heal(e.hero_fighter(p),2)
    1:_queue({"kind":"v32_summon","where":"any"},ctx)
    2:e.gain_actions(p,1)
  696:_queue({"kind":"v32_adjacent_damage"},ctx);e._v31._move(ctx,fid,2)
  654:
   if p==origin(ctx.card):e._draw(p,1)
   else:e._damage(e.hero_fighter(p),2)
  655:
   if human(p):_options("shapeshift",["Прибавить размер руки соперника","Получить 1 действие"],ctx)
   else:ctx.value+=e.players[int(ctx.opponent_owner)].hand.size()
  656:
   var other=e._v6._other(ctx)
   if not other.card.is_empty():
    e.players[int(other.owner)].hand.append(other.card);other.card={};other.value=0;var slot=str(other._combat_slot)
    e._effect_queue=e._effect_queue.filter(func(job):return job.ctx.get("_combat_slot","")!=slot or job.effect.get("intrinsic",false));_queue({"kind":"v32_trouble"},ctx)
  657:ctx.value+=3*e.players[int(ctx.opponent_owner)].hand.filter(func(c):return c.get("trick",false)).size()
  658:
   if p==origin(ctx.card):
    if stage=="during":_queue({"kind":"v32_sindri"},ctx)
   elif stage=="after":
    var loki=origin(ctx.card)
    if loki>=0 and not e.players[loki].discard.is_empty():e.players[loki].hand.append(e.players[loki].discard.pop_back())
  659:
   if p==origin(ctx.card):
    if stage=="during":var other=e._v6._other(ctx);var value=ctx.value;ctx.value=other.value;other.value=value
   elif stage=="after":e._heal(e.hero_fighter(origin(ctx.card)),3)
  660:
   if e._v6._other(ctx).card.get("trick",false):ctx.ignore_opponent_value=true
   else:e._v31._cancel(ctx)
  661:_hidden(ctx,int(ctx.opponent_owner),"levateinn")
  662:
   if e.players[int(ctx.opponent_owner)].hand.size()>e.players[p].hand.size():ctx.value=6
  663:e._draw(p,2 if e._v6._other(ctx).card.get("trick",false)else 1)
  664:
   var loki=origin(ctx.card)
   if p==loki:_choose_enemy_fighter(ctx,"lure")
   elif loki>=0:var next=ctx.duplicate(true);next.owner=loki;_hidden(next,p,"discard")
  676:ctx.value=2*int(e._v6._other(ctx).card.get("value",0))
  677:
   if int(e.fighters[e.hero_fighter(p)].hp)<=7:e.gain_actions(p,1);e._heal(e.hero_fighter(p),1)
  678:
   if e.players[p].get("won_combat_turn",false):e._v31.offer_boost(ctx)
  679:
   if not ctx.won:e._flow["return_"+str(ctx._combat_slot)]=true
  680:e._heal(e.hero_fighter(p),2 if ctx.won else 1)
  681:_tooth(ctx)
  682:
   if int(e.fighters[e.hero_fighter(p)].hp)<=7:ctx.value=5
  683:e.gain_actions(p,1);e._v31._move(ctx,fid,4,true)
  684:_unsettle(ctx)
  665:
   if stage=="during":ctx.value+=e.players[p].miseries.size()
   else:_queue({"kind":"reveal_hand"},ctx)
  666:
   if stage=="immediately":e._v31._cancel(ctx)
   else:e._heal(e.hero_fighter(p),e.players[p].miseries.size())
  667:
   if ctx.won:
    if human(p):_cards("hindsight",p,"discard",range(e.players[p].discard.size()),ctx)
    elif not e.players[p].discard.is_empty():e.players[p].deck.append(e.players[p].discard.pop_back())
  668:ctx.ignore_opponent_value=true
  669:
   if stage=="during":e._v31.offer_boost(ctx)
   elif ctx.won:e._damage(foe,2)
  670:
   if stage=="during":
    if not e.players[p].deck.is_empty():var c=e.players[p].deck.pop_back();e._discard(p,c,"deck");ctx.value+=int(c.get("boost",0))
   elif ctx.won:e._heal(e.hero_fighter(p),2)
  671:e._v31._move(ctx,e.hero_fighter(p),5)
  672:e._draw(p,e.players[p].miseries.size());e.gain_actions(p,1);_choose_enemy_fighter(ctx,"zeus")
  673:e.gain_actions(p,1);_queue({"kind":"place","fixed_fighter":fid},ctx)
  674:e._damage_many(e._v14._adjacent(fid),1)
  675:_queue({"kind":"opponent_discard","amount":1},ctx)
 return true
func conveyor_plan() -> Dictionary:
 var belt=e._int_array(e.board_data.get("conveyor",[]));var plan={}
 if belt.is_empty():return plan
 var bins=e.nodes.filter(func(n):return n.zones.has(int(e.board_data.gift_zone))and e._v31.occupants(int(n.id)).is_empty()).size()
 for f in e.fighters:
  var fid=int(f.id);var i=belt.find(int(f.node))
  if not e._valid_fighter(fid)or e._v19.large(fid)or not e._v13.can_relocate(fid)or i<0:continue
  if i==belt.size()-1:
   if bins>0:plan[fid]=-1;bins-=1
   continue
  plan[fid]=int(belt[i+1])
 var changed=true
 while changed:
  changed=false
  for fid in plan.keys():
   var to=int(plan[fid]);var blockers=e._v31.occupants(to).filter(func(id):return not e._v31.small(int(id))and int(id)!=int(fid)and not plan.has(int(id)))
   if to<0:continue
   if not e._v31.small(int(fid))and not blockers.is_empty():plan.erase(fid);changed=true;continue
   if e._v31.small(int(fid)):
    var count=0
    for f in e.fighters:
     if e._valid_fighter(int(f.id))and e._v31.small(int(f.id))and int(plan.get(int(f.id),int(f.node)))==to:count+=1
    if count>4:plan.erase(fid);changed=true
 return plan
func end_board() -> bool:
 var p=e.active
 if int(e.players[p].get("v32_end_turn",-1))==e.turn_number:return false
 e.players[p].v32_end_turn=e.turn_number;reset_box(p)
 if not e.board_data.has("conveyor"):return false
 e._start_ability(p,"Конвейер мастерской Санты",[{"kind":"v32_conveyor"}],"end_turn");return true
func _conveyor(ctx: Dictionary):
 var plan=conveyor_plan();var ends=[]
 e._flow.conveyor_plan=plan;e._flow.conveyor_choices={}
 for fid in plan:
  if int(plan[fid])<0:ends.append(int(fid))
 _queue({"kind":"v32_conveyor_commit"},ctx)
 for i in range(ends.size()-1,-1,-1):_queue({"kind":"v32_bin","fid":int(ends[i])},ctx)
func _conveyor_commit():
 var plan=e._flow.get("conveyor_plan",{});var old={};var placed=[]
 for key in plan:
  var fid=int(key);old[fid]=int(e.fighters[fid].node)
  if int(plan[key])<0:
   var node=e._flow.get("conveyor_choices",{}).get(str(fid),-1)
   if int(node)<0:continue
   plan[key]=int(node);placed.append(fid)
  e.fighters[fid].node=int(plan[key])
 for key in plan:
  var fid=int(key)
  if int(plan[key])<0:continue
  e.fighters[fid].left_space_turn=e.turn_number;e._v12.departed(fid,int(old[fid]),int(plan[key]),{"old_cells":[int(old[fid])]});e._trigger_trap(fid);e._v19.moved(fid,int(old[fid]),placed.has(fid))
func _bin(ctx: Dictionary,fid: int):
 if not e._valid_fighter(fid):return
 var claimed=e._flow.get("conveyor_choices",{}).values().map(func(n):return int(n))
 var legal=e.nodes.filter(func(n):return n.zones.has(int(e.board_data.gift_zone))and e._v31.occupants(int(n.id)).is_empty()and not claimed.has(int(n.id))).map(func(n):return int(n.id))
 if legal.is_empty():return
 var p=int(e.fighters[fid].owner)
 if human(p):_options("bin",legal.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":legal,"fid":fid});e.pending_choice.owner=p;e.pending_choice.viewer=p
 else:e._flow.conveyor_choices[str(fid)]=int(legal[0])
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 e.pending_choice.clear();var ctx=_live(q._ctx);var p=int(ctx.owner);var mode=str(q.action).trim_prefix("v32_")
 match mode:
  "hunger":
   if index==0:e._draw(p,1)
  "coin":
   if index==0 and coins(p)>0:pay(p,1);e.gain_actions(p,1)
  "box":
   if index==0:_queue({"kind":"v32_box_draw"},ctx)
  "ransom":_ransom_paid(ctx,q.fx,q.payers,(int(q.fx.ransom)if index==0 else 0)if int(q.fx.ransom)>=0 else index)
  "return":
   if index==0:e.players[p].hand.append(q.returned)
   else:e.players[p].deck.append(q.returned)
  "summon_source":var next=q.fx.duplicate(true);next.fid=int(q.ids[index]);_summon(ctx,next)
  "summon":_summoned(int(q.fid),int(q.nodes[index]))
  "hidden":_hidden_selected(ctx,int(q.victim),index,str(q.mode))
  "revealed":pass
  "trouble_view":
   if not q.indices.is_empty():_cards("trouble",int(q.victim),"hand",q.indices,ctx)
  "trouble":_trouble_play(ctx,int(q.indices[index]))
  "sindri":var victim=int(ctx.opponent_owner);e._discard(victim,e.players[victim].hand.pop_at(int(q.indices[index])))
  "shapeshift":
   if index==0:ctx.value+=e.players[int(ctx.opponent_owner)].hand.size()
   else:e.gain_actions(p,1)
  "tooth":_tooth_hit(ctx,int(q.ids[index]),int(q.tooth_left),q.used)
  "unsettle_enemy":_unsettle(ctx,int(q.ids[index]))
  "unsettle":
   if index==1:e._damage(e.hero_fighter(p),2)
   _queue({"kind":"opponent_discard","amount":index+1},ctx)
  "enemy_fighter":_enemy_fighter(ctx,int(q.ids[index]),str(q.mode))
  "hindsight":e.players[p].deck.append(e.players[p].discard.pop_at(int(q.indices[index])))
  "bin":e._flow.conveyor_choices[str(int(q.fid))]=int(q.nodes[index])
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 var q=e.pending_choice.duplicate(true)
 if str(q.action)=="v32_sindri":var other=e._v6._other(_live(q._ctx));other.value=maxi(0,int(other.value)-3)
 e.pending_choice.clear();_resume();return true
