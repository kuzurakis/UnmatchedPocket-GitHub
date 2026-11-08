extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v29_"+action
func pouch(p: int) -> int:return int(e.players[p].get("pouch_node",-1))
func near(p: int,fid: int) -> bool:
 return pouch(p)>=0 and e._valid_fighter(fid) and e._v19.spaces(fid).any(func(n):return int(n)==pouch(p) or e.nodes[pouch(p)].neighbors.has(int(n)))
func on_pouch(fid: int) -> int:
 for p in range(e.players.size()):
  if e._is_hero(p,"mikula") and e.is_enemy(p,int(e.fighters[fid].owner)) and e._v19.spaces(fid).has(pouch(p)):return p
 return -1
func before_attack(fid: int) -> bool:
 if on_pouch(fid)>=0:e._damage(fid,1)
 return not e._valid_fighter(fid)
func bonus(fid: int) -> int:return 2 if on_pouch(fid)>=0 else 0
func start_turn() -> bool:
 for p in range(e.players.size()):
  if e._is_hero(p,"mikula") and pouch(p)<0:
   if not human(p):e.players[p].pouch_node=int(e.fighters[e.hero_fighter(p)].node);continue
   e._start_ability(p,"Сумочка с тягой земной",[{"kind":"v29_setup"}],"start_turn");return true
 return false
func _bag(ctx: Dictionary,distance=-1,zone=false,free=false,optional=false):
 var p=int(ctx.get("bag_owner",ctx.owner));var hero=e.hero_fighter(p);var legal=[];var origin=pouch(p);var reach=[]
 if distance>=0:
  var queue=[[origin,0]];var seen={origin:true}
  while not queue.is_empty():
   var row=queue.pop_front();reach.append(int(row[0]))
   if int(row[1])>=distance:continue
   for n in e.nodes[int(row[0])].get("move_neighbors",e.nodes[int(row[0])].neighbors):
    if not seen.has(int(n)):seen[int(n)]=true;queue.append([int(n),int(row[1])+1])
 for n in e.nodes:
  if free and e._occupant(int(n.id))>=0:continue
  if zone and not e._same_zone(int(n.id),int(e.fighters[hero].node)):continue
  if distance>=0 and not reach.has(int(n.id)):continue
  legal.append(int(n.id))
 if legal.is_empty():return
 if human(int(ctx.owner)):_options("bag",legal.map(func(n):return "Клетка %d"%(int(n)+1)),ctx,{"nodes":legal,"bag_owner":p,"kind":"spaces","legal":legal},optional)
 else:e.players[p].pouch_node=int(legal[0])
func _target(mode: String,ctx: Dictionary):
 var ids=range(e.players.size()).filter(func(p):return e.players[int(p)].alive and e.is_enemy(int(ctx.owner),int(p)))
 if ids.is_empty():return
 if human(int(ctx.owner)):_options(mode,ids.map(func(p):return str(e.players[int(p)].name)),ctx,{"ids":ids})
 else:_apply(mode,int(ids[0]),ctx)
func _apply(mode: String,victim: int,ctx: Dictionary):
 var p=int(ctx.owner)
 if mode=="mill":
  if not e.players[victim].deck.is_empty():e._discard_from_opponent(victim,e.players[victim].deck.pop_back(),false)
 elif mode=="tribute":
  var c=ctx.duplicate(true);c.opponent_owner=victim
  if near(p,int(ctx.self)):_queue({"kind":"reveal_choose_discard","amount":1},c)
  else:e._force_discard(victim,1,true)
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var p=int(ctx.owner);var fid=int(ctx.self)
 if fx.kind=="v29_setup":_bag(ctx,-1,true);return true
 if fx.kind=="v29_discard":
  if near(p,fid):_target("mill",ctx)
  else:_queue({"kind":"v24_discard","victim":p,"amount":1,"self_cost":true},ctx)
  return true
 if fx.kind!="v29_card":return false
 var enabled=near(p,fid)
 if fx.get("marked",false) and not enabled:return true
 if ctx.get("cancelled",false) and not fx.get("marked",false) and not (int(fx.number)==13 and enabled):return true
 var foe=int(ctx.get("opponent",-1));var part=int(fx.part)
 match int(fx.number):
  1:
   if part==0:ctx.value+=1
   else:e._v6._cancel(ctx)
  2:e._draw(p,2 if ctx.won else 1);_bag(ctx,-1,true,true)
  3:
   if ctx.won:
    if human(p):_options("skirmish",["Микула","Участник боя","Сумочка"],ctx)
    else:_queue({"kind":"move","spaces":2},ctx)
  4:
   if near(p,foe) and not e.players[int(ctx.opponent_owner)].hand.is_empty():
    var c=e.players[int(ctx.opponent_owner)].hand.pop_at(e.rng.randi_range(0,e.players[int(ctx.opponent_owner)].hand.size()-1));ctx.value+=int(c.boost);e._discard_from_opponent(int(ctx.opponent_owner),c)
  5:e._heal(fid,int(e._v6._other(ctx).card.get("boost",0)))
  6:
   if part==0:_bag(ctx,4)
   else:e._v18._path(ctx,3,"adversity")
  7:
   if part==0:ctx.value=4
   elif ctx.won:e._draw(p,2)
  8:
   if part==0:
    _queue({"kind":"gain_action","amount":1},ctx)
    if enabled:e._v18._path(ctx,5,"adversity")
    else:_queue({"kind":"move","spaces":5},ctx)
  9:
   if part==0:e._heal(fid,1)
   else:
    var c=ctx.duplicate(true);c.bag_owner=p;c.owner=int(ctx.opponent_owner);_bag(c,-1,false,true,true)
  10:
   if not e.fighters_adjacent(fid,foe):_queue({"kind":"move","spaces":2},ctx)
  11:
   if part==0:e._draw(p,3);_queue({"kind":"v29_discard"},ctx)
  12:e._draw(p,maxi(0,e.players[int(ctx.opponent_owner)].hand.size()-e.players[p].hand.size()))
  13:
   if ctx.won:_apply("tribute",int(ctx.opponent_owner),ctx)
 return true
func choose_option(index: int) -> bool:
 var choice=e.pending_choice.duplicate(true)
 if index<0 or index>=choice.options.size():return false
 e.pending_choice.clear();var ctx=_live(choice._ctx);var mode=str(choice.action).trim_prefix("v29_")
 match mode:
  "bag":e.players[int(choice.bag_owner)].pouch_node=int(choice.nodes[index])
  "skirmish":
   if index==2:_bag(ctx,2)
   else:_queue({"kind":"move","fixed_fighter":int(ctx.self)if index==0 else int(ctx.opponent),"spaces":2},ctx)
  "mill":_apply(mode,int(choice.ids[index]),ctx)
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true
