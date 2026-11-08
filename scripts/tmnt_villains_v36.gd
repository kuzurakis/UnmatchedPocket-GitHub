extends "res://scripts/hero_rules_v8.gd"
## Competitive Shredder/Krang, not the cooperative villain decks.
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v36_"+action
func num(c: Dictionary) -> int:return int(c.get("tmntv_number",-1))
func setup():
 for p in range(e.players.size()):
  if e._is_hero(p,"shredder"):e.players[p].foot=[]
  if e._is_hero(p,"krang"):e.players[p].machines=1
func machines(p: int) -> int:return clampi(int(e.players[p].get("machines",0)),0,3)
func move_bonus(p: int) -> int:return machines(p)if e._is_hero(p,"krang")else 0
func activate(p: int):e.players[p].machines=mini(3,machines(p)+1)
func feet(p: int) -> Array:return e.players[p].get("foot",[])
func key(a: int,b: int) -> String:return str(mini(a,b))+":"+str(maxi(a,b))
func count(p: int,fid: int) -> int:
 if not e._valid_fighter(fid):return 0
 var cells=e._v19.spaces(fid);var n=0
 for edge in feet(p):
  if cells.has(int(edge[0]))or cells.has(int(edge[1])):n+=1
 return n
func foot_range(a: int,b: int) -> bool:
 var p=int(e.fighters[a].owner)
 return e._is_hero(p,"shredder")and count(p,b)>0
func ranged(c: Dictionary,a: int,b: int) -> bool:return num(c)==759 and e._same_zone(int(e.fighters[a].node),int(e.fighters[b].node))
func edges(p: int,anywhere: bool) -> Array:
 var used={};var result=[]
 for player in range(e.players.size()):
  for edge in feet(player):used[key(int(edge[0]),int(edge[1]))]=true
 for node in e.nodes:
  for n in node.neighbors:
   var a=int(node.id);var b=int(n)
   if a>=b or used.has(key(a,b)):continue
   if anywhere or e.fighters.any(func(f):return e._valid_fighter(int(f.id))and e.are_allies(p,int(f.owner))and (e._v19.spaces(int(f.id)).has(a)or e._v19.spaces(int(f.id)).has(b))):result.append([a,b])
 return result
func deploy(ctx: Dictionary,remaining: int,anywhere: bool):
 var p=int(ctx.owner);var ids=edges(p,anywhere)
 if remaining<=0 or feet(p).size()>=24 or ids.is_empty():return
 if human(p):_options("deploy",ids.map(func(edge):return "Фут: дорожка %d—%d"%[int(edge[0])+1,int(edge[1])+1]),ctx,{"edges":ids,"deployments_left":remaining,"anywhere":anywhere})
 else:
  ids.sort_custom(func(a,b):return edge_score(p,a)>edge_score(p,b))
  e.players[p].foot.append(ids[0]);deploy(ctx,remaining-1,anywhere)
func edge_score(p: int,edge: Array) -> float:
 var score=0.0
 for f in e.fighters:
  if not e._valid_fighter(int(f.id)):continue
  var distance=mini(e._v14.board_distance(int(edge[0]),int(f.node)),e._v14.board_distance(int(edge[1]),int(f.node)))
  score+=(8.0/(1+distance))if e.is_enemy(p,int(f.owner))else 2.0/(1+distance)
 return score
func start_turn() -> bool:
 if not e._is_hero(e.active,"shredder"):return false
 e._start_ability(e.active,"Мастер клана",[{"kind":"v36_deploy","remaining":1,"anywhere":false}],"start_turn");return true
func stepwise(fid: int) -> bool:
 if not e._valid_fighter(fid)or not e.fighters[fid].hero:return false
 return range(e.players.size()).any(func(p):return e._is_hero(p,"shredder")and e.players[p].alive and e.is_enemy(p,int(e.fighters[fid].owner)))
func crossed(fid: int,a: int,b: int,old_cells: Array=[],force=false):
 if not e.maneuver_boosted or (e.phase!="move"and not force)or not e.fighters[fid].hero or int(e.fighters[fid].owner)!=e.active:return
 if e._is_hero(e.active,"houdini"):return
 # A large base can advance from either occupied end; only that real edge counts.
 if e._v19.large(fid)and old_cells.has(int(e.fighters[fid].get("tail",-1))):a=int(e.fighters[fid].tail)
 if not e.nodes[a].neighbors.has(b):
  for cell in old_cells:
   if e.nodes[int(cell)].neighbors.has(b):a=int(cell);break
 if not e.nodes[a].neighbors.has(b):return
 var crossed_edges=e.players[e.active].get("foot_crossed",[])
 for p in range(e.players.size()):
  if not e.is_enemy(e.active,p):continue
  for edge in feet(p):
   if key(int(edge[0]),int(edge[1]))==key(a,b):
    var mark={"owner":p,"edge":edge}
    if not crossed_edges.has(mark):crossed_edges.append(mark)
 e.players[e.active].foot_crossed=crossed_edges
func finish_maneuver() -> bool:
 var marks=e.players[e.active].get("foot_crossed",[]).duplicate(true);e.players[e.active].foot_crossed=[]
 if marks.is_empty():return false
 e._start_ability(e.active,"Пройти через Фут",[{"kind":"v36_remove","marks":marks}],"maneuver");return true
func remove_offer(ctx: Dictionary,marks: Array):
 if marks.is_empty():return
 var mark=marks.pop_front();var p=int(mark.owner)
 if human(int(ctx.owner)):_options("remove",["Убрать Фут с дорожки %d—%d"%[int(mark.edge[0])+1,int(mark.edge[1])+1],"Оставить Фут"],ctx,{"mark":mark,"marks":marks})
 else:remove_mark(mark);remove_offer(ctx,marks)
func remove_mark(mark: Dictionary):e.players[int(mark.owner)].foot=feet(int(mark.owner)).filter(func(edge):return key(int(edge[0]),int(edge[1]))!=key(int(mark.edge[0]),int(mark.edge[1])))
func end_turn() -> bool:
 var p=e.active
 if int(e.players[p].get("plan_end",-1))==e.turn_number:return false
 e.players[p].plan_end=e.turn_number
 var amount=int(e.players[p].get("plan_penalty",0));e.players[p].plan_penalty=0
 if amount<=0 or int(e.players[p].get("scheme_turn",-1))==e.turn_number:return false
 e._start_ability(p,"Всё по плану",[{"kind":"v36_penalty","amount":amount,"source":int(e.players[p].get("plan_owner",p))}],"end_turn")
 return true
func summary(p: int) -> String:
 if e._is_hero(p,"shredder"):return "Фут на поле: %d/24"%feet(p).size()
 if e._is_hero(p,"krang"):return "Машины: %d/3 · движение: %d"%[machines(p),1+machines(p)]
 return ""
func roll(ctx: Dictionary,mode: String,extra={}):
 var p=int(ctx.owner);var value=e.rng.randi_range(0,5)
 e._log("Кубик Крэнга: %s."%("X"if value==0 else str(value)))
 if human(p)and machines(p)>0:_options("die",["Принять результат: %d"%value,"Отключить машину и перебросить"],ctx,{"roll":value,"mode":mode,"extra":extra,"prompt":"Активных машин: %d/3"%machines(p)})
 else:
  while value<2 and machines(p)>0 and e.difficulty>0:
   e.players[p].machines=machines(p)-1;value=e.rng.randi_range(0,5);e._log("Переброс Крэнга: %d."%value)
  rolled(ctx,mode,value,extra)
func rolled(ctx: Dictionary,mode: String,value: int,extra: Dictionary):
 var p=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1));ctx=_live(ctx)
 match mode:
  "value":ctx.value+=value
  "draw":e._draw(p,value)
  "heal":e._heal(e.hero_fighter(p),value)
  "chain":
   var other=e._v6._other(ctx)
   if other.get("card",{}).is_empty()or int(other.card.get("value",0))<value:_queue({"kind":"opponent_discard","amount":2},ctx)
  "portal_hand":
   for victim in [p,int(ctx.opponent_owner)]:
    var pile=e.players[victim]
    for i in range(mini(value,pile.hand.size())):pile.deck.push_front(pile.hand.pop_at(e.rng.randi_range(0,pile.hand.size()-1)))
   e._draw(p,2);e._draw(int(ctx.opponent_owner),2)
  "wings":wings(ctx,value,[])
  "maneuver_boost":
   var index=int(extra.index)
   if index>=0 and index<e.players[p].hand.size():
    e.maneuver_distance+=e._movement(p)-int(extra.get("base_move",e._movement(p)))
    e.players[p].hand[index].boost=value;e._apply_maneuver_boost(index)
   e.phase="move"
  "combat_boost":
   var index=int(extra.index)
   if index>=0 and index<e.players[p].hand.size():
    e.players[p].hand[index].boost=value;e._v8.combat_boost(ctx,index)
func boost_offer(index: int,ctx: Dictionary,mode: String) -> bool:
 var p=int(ctx.owner)
 if index<0 or index>=e.players[p].hand.size()or not e.players[p].hand[index].get("dice_boost",false):return false
 e.pending_choice.clear()
 roll(ctx,mode,{"index":index,"base_move":e._movement(p)});return true
func wings(ctx: Dictionary,left: int,path: Array):
 var fid=e.hero_fighter(int(ctx.owner));var origin=int(e.fighters[fid].node);var here=origin if path.is_empty()else int(path[-1]);var ids=[]
 if e._occupant(here)in[-1,fid]:ids.append(-1)
 if left>0 and e._v13.can_relocate(fid):
  for n in e._v34.links(fid,here):
   if not wings_can_finish(fid,int(n),left-1):continue
   ids.append(int(n))
 if human(int(ctx.owner))and ids.size()>1:_options("wings",ids.map(func(n):return "Завершить движение"if n<0 else "Клетка %d"%(n+1)),ctx,{"ids":ids,"left":left,"path":path});return
 var next=-1
 if left>0:
  for n in ids:
   if n>=0 and not path.has(n)and e._occupant(n)>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[e._occupant(n)].owner)):next=n;break
  if next<0 and not ids.has(-1):
   for n in ids:
    if n>=0 and not path.has(n):next=n;break
   if next<0 and not ids.is_empty():next=int(ids[0])
 if next>=0:path.append(next);wings(ctx,left-1,path);return
 wings_finish(ctx,path)
func wings_can_finish(fid: int,node: int,left: int) -> bool:
 var seen={};var queue=[[node,left]]
 while not queue.is_empty():
  var job=queue.pop_front();var here=int(job[0]);var remaining=int(job[1])
  if seen.has(here):continue
  seen[here]=true
  if e._occupant(here)in[-1,fid]:return true
  if remaining<=0 or e._enemy_trap_at(here,int(e.fighters[fid].owner))>=0:continue
  for n in e._v34.links(fid,here):queue.append([int(n),remaining-1])
 return false
func wings_finish(ctx: Dictionary,path: Array):
 var fid=e.hero_fighter(int(ctx.owner));var victims=[]
 for n in path:
  var trap=e._enemy_trap_at(int(n),int(ctx.owner))
  var occupant=e._occupant(int(n))
  if occupant>=0 and e.is_enemy(int(ctx.owner),int(e.fighters[occupant].owner))and not victims.has(occupant):victims.append(occupant)
  var old=int(e.fighters[fid].node);e._enter_node(fid,int(n));e._v19.moved(fid,old,false)
  if not e._valid_fighter(fid)or trap>=0:break
 e._damage_many(victims,1);e.gain_actions(int(ctx.owner),1)
func portal(ctx: Dictionary):
 var ids=[int(ctx.self),int(ctx.opponent)].filter(func(fid):return e._valid_fighter(fid))
 if human(int(ctx.owner)):_options("portal_fighter",ids.map(func(fid):return str(e.fighters[fid].name)),ctx,{"ids":ids})
 elif not ids.is_empty():portal_fighter(ctx,int(ids[-1]))
func portal_fighter(ctx: Dictionary,fid: int):
 _queue({"kind":"v36_lock","fid":fid},ctx)
 _queue({"kind":"place","fixed_fighter":fid},ctx)
func revive(ctx: Dictionary):
 var p=int(ctx.owner);var fid=-1
 for f in e.fighters:
  if int(f.owner)==p and not f.hero:fid=int(f.id);break
 if fid<0:return
 var hero=e.hero_fighter(p);var ids=[];var best=10000
 for node in e.nodes:
  if e._occupant(int(node.id))not in[-1,fid]:continue
  var distance=e._v14.board_distance(int(e.fighters[hero].node),int(node.id))
  if distance<best:best=distance;ids=[]
  if distance==best:ids.append(int(node.id))
 if ids.is_empty():return
 e.fighters[fid].alive=true;e.fighters[fid].hp=mini(int(e.fighters[fid].max_hp),int(e.fighters[fid].hp)+3)
 e.fighters[fid].offboard=true
 if human(p):_options("revive",ids.map(func(n):return "Клетка %d"%(n+1)),ctx,{"ids":ids,"fid":fid})
 else:e.fighters[fid].node=int(ids[0]);e.fighters[fid].offboard=false
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var kind=str(fx.get("kind",""));var p=int(ctx.owner);var fid=int(ctx.get("self",-1));var foe=int(ctx.get("opponent",-1))
 match kind:
  "v36_penalty":
   ctx.opponent_owner=p;ctx.owner=int(fx.source);_queue({"kind":"opponent_discard","amount":int(fx.amount)},ctx);return true
  "v36_deploy":deploy(ctx,int(fx.remaining),bool(fx.anywhere));return true
  "v36_remove":remove_offer(ctx,fx.marks.duplicate(true));return true
  "v36_die":roll(ctx,str(fx.mode));return true
  "v36_boost":
   if human(p):e._begin_manual_effect({"kind":"optional_boost"},ctx)
   else:
    var index=e._best_boost(p)
    if index>=0 and not boost_offer(index,ctx,"combat_boost"):e._v8.combat_boost(ctx,index)
   return true
  "v36_lock":
   if e._valid_fighter(int(fx.fid))and not e._v35.shielded(int(e.fighters[int(fx.fid)].owner)):e.fighters[int(fx.fid)].locked_until=e.turn_number
   return true
  "v36_card":pass
  _:return false
 match int(fx.number):
  486:
   if not e.fighters_adjacent(fid,foe):ctx.value=5
  763:e._draw(p,count(p,foe))
  764:
   _queue({"kind":"move","fixed_fighter":e.hero_fighter(p),"spaces":2},ctx);deploy(ctx,2,true)
  765:
   if count(p,foe)>=2:ctx.value=6
  766:revive(ctx)
  767:e._heal(e.hero_fighter(p),count(p,e.hero_fighter(p)))
  768:
   if ctx.get("won",false):e._damage_many(e._v14._adjacent(fid),1)
  769:
   e._v6._cancel(ctx)
   if feet(p).size()>=10:ctx.ignore_opponent_value=true
  770:
   var victim=int(ctx.opponent_owner);e.gain_actions(victim,1);e.players[victim].plan_penalty=int(e.players[victim].get("plan_penalty",0))+2;e.players[victim].plan_owner=p
  771:
   var other=e._v6._other(ctx)
   other.locked_value=int(other.get("card",{}).get("value",0));other.value=other.locked_value
  772:e.gain_actions(p,count(p,e.hero_fighter(p)))
  773:ctx.value+=count(p,fid)
  774:
   var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and count(p,int(f.id))>0).map(func(f):return int(f.id))
   e._damage_many(ids,1)
  753:
   var other=int(ctx.opponent_owner)
   if not e.players[p].deck.is_empty()and not e.players[other].deck.is_empty():
    var a=e.players[p].deck[-1];var b=e.players[other].deck[-1]
    e._log("Раскрыты карты: %s / %s."%[str(a.name),str(b.name)])
    if original_name(p,a).length()>original_name(other,b).length():e._draw(p,1)
  754:
   e.players[p].machines=3;_queue({"kind":"v36_die","mode":"heal"},ctx);roll(ctx,"draw")
  755:
   _queue({"kind":"v36_die","mode":"portal_hand"},ctx);portal(ctx)
  756:
   if human(p):_options("technodrome",["Отменить эффекты карты противника","Активировать машину"],ctx)
   elif machines(p)<3 and e._v6._other(ctx).get("card",{}).get("effects",[]).is_empty():activate(p)
   else:e._v6._cancel(ctx)
  757:
   if str(fx.stage)=="immediately":e._v6._other(ctx).value-=4
   else:e.actions_left=0;e._v34.clear_free(e.active);e._flow.completion="end_turn"
  758:roll(ctx,"wings")
  759:roll(ctx,"value")
  760:
   if str(fx.stage)=="during":_queue({"kind":"v36_boost"},ctx)
   else:_queue({"kind":"move","fixed_fighter":foe,"spaces":int(ctx.get("damage_dealt",0))},ctx)
  761:roll(ctx,"chain")
  762:
   if str(fx.stage)=="immediately":activate(p)
   else:roll(ctx,"value")
 return true
func original_name(p: int,c: Dictionary) -> String:
 var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/locales.json"))
 return str(catalog.get("cards",{}).get("en",{}).get(e._hero_id(p),{}).get(str(c.get("id","")),{}).get("name",c.get("name","")))
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 var ctx=q._ctx;var p=int(ctx.owner);e.pending_choice.clear()
 match str(q.action):
  "v36_deploy":e.players[p].foot.append(q.edges[index]);deploy(ctx,int(q.deployments_left)-1,bool(q.anywhere))
  "v36_remove":
   if index==0:remove_mark(q.mark)
   remove_offer(ctx,q.marks)
  "v36_die":
   if index==1 and machines(p)>0:e.players[p].machines=machines(p)-1;roll(ctx,q.mode,q.extra)
   else:rolled(ctx,q.mode,int(q.roll),q.extra)
   if q.mode=="maneuver_boost":
    if e.pending_choice.is_empty():e.phase="move"
    e.changed.emit();return true
  "v36_wings":
   var n=int(q.ids[index]);var path=q.path
   if n<0:wings_finish(ctx,path)
   else:path.append(n);wings(ctx,int(q.left)-1,path)
  "v36_portal_fighter":portal_fighter(ctx,int(q.ids[index]))
  "v36_revive":e.fighters[int(q.fid)].node=int(q.ids[index]);e.fighters[int(q.fid)].offboard=false
  "v36_technodrome":
   if index==0:e._v6._cancel(_live(ctx))
   else:activate(p)
 if e.pending_choice.is_empty():_resume()
 else:e.changed.emit()
 return true
func skip() -> bool:return false
func estimate(c: Dictionary,fid: int,foe: int,value: float) -> float:
 var p=int(e.fighters[fid].owner)
 match num(c):
  486:
   if not e.fighters_adjacent(fid,foe):return 5.0
  765:
   if count(p,foe)>=2:return 6.0
  773:return value+count(p,fid)
  759,762:return value+2.5+(0.5 if machines(p)>0 else 0.0)
 return value
func scheme_score(c: Dictionary,p: int,score: float) -> float:
 match num(c):
  772:return 1.0+count(p,e.hero_fighter(p))*1.8
  766:
   var helpers=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero)
   if not helpers.is_empty():return 6.5 if not helpers[0].alive else 1.0+mini(3,int(helpers[0].max_hp)-int(helpers[0].hp))
  754:return 4.5+(3-machines(p))*0.4
  758:return score+1.0
 return score
