extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String, labels: Array, ctx: Dictionary, extra={}, optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v19_"+action
func large(fid: int) -> bool:return fid>=0 and e.fighters[fid].hero and (e._is_hero(int(e.fighters[fid].owner),"t_rex") or e._hero_id(int(e.fighters[fid].owner))in["svyatogor","moose","kraken","godzilla"])
func spaces(fid: int) -> Array:
 var result=[int(e.fighters[fid].node)]
 if large(fid) and int(e.fighters[fid].get("tail",-1))>=0:result.append(int(e.fighters[fid].tail))
 return result
func add_token(owner: int, node: int):
 var tokens=e.players[owner].get("insight",[])
 if tokens.size()<5:tokens.append(node);e.players[owner].insight=tokens
func moved(fid: int, old: int, placed: bool):
 if not placed and old!=int(e.fighters[fid].node) and e._is_hero(int(e.fighters[fid].owner),"dr_ellie_sattler"):add_token(int(e.fighters[fid].owner),int(e.fighters[fid].node))
func body(fid: int, node: int, old: int):
 if not large(fid):return
 var options=e.nodes[node].neighbors.duplicate()
 if options.has(old):options.erase(old);options.push_front(old)
 e.fighters[fid].tail=-1
 for n in options:
  if e._occupant(int(n)) in [-1,fid]:
   var delta=e.nodes[node].pos-e.nodes[int(n)].pos
   var w=float(e.board_data.get("width",1000));var h=float(e.board_data.get("height",1000))
   if Vector2(delta.x*w,delta.y*h).length()<=float(e.board_data.get("node_radius",60))*3.4:e.fighters[fid].tail=int(n)
   break
func end_turn():
 if e._is_hero(e.active,"t_rex"):e._draw(e.active,1)
func run(effect: Dictionary, ctx: Dictionary) -> bool:
 var owner=int(ctx.owner);var fid=int(ctx.self);var tokens=e.players[owner].get("insight",[])
 match str(effect.kind):
  "v19_self_damage":e._damage(fid,int(effect.amount))
  "v19_ignore":ctx.ignore_opponent_value=true
  "v19_roar":
   for f in e.fighters:
    if f.alive:f.locked_until=e.turn_number
  "v19_return":e._flow["return_"+str(ctx.get("_combat_slot","a"))]=true
  "v19_thrash":
   var ids=[]
   for f in e.fighters:
    if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)) and e._same_zone(int(e.fighters[fid].node),int(f.node)):ids.append(int(f.id))
   e._damage_many(ids,1)
  "v19_ripples":
   var victims=[]
   for f in e.fighters:
    if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)) and e.fighters_adjacent(fid,int(f.id)) and not victims.has(int(f.owner)):victims.append(int(f.owner))
   for p in victims:e._force_discard(int(p),1,true)
  "v19_retrieve":
   var ids=[]
   for i in range(e.players[owner].discard.size()):
    if e.players[owner].discard[i].id!="65_million_years_of_gut_instinct":ids.append(i)
   if human(owner):_cards("retrieve",owner,"discard",ids,ctx)
   elif not ids.is_empty():e.players[owner].hand.append(e.players[owner].discard.pop_at(int(ids[0])))
  "v19_heal_tokens":e._heal(e.hero_fighter(owner),tokens.size());e.players[owner].insight=[]
  "v19_tokens_value":ctx.value+=tokens.size();e.players[owner].insight=[]
  "v19_hand_value":ctx.value=e.players[owner].hand.size()
  "v19_malcolm_token":
   for f in e.fighters:
    if int(f.owner)==owner and not f.hero and e._valid_fighter(int(f.id)):add_token(owner,int(f.node))
  "v19_token":
   if tokens.size()<5:
    if human(owner):
     var labels=[]
     for n in e.nodes:labels.append("Клетка %d"%(int(n.id)+1))
     _options("token",labels,ctx)
    else:add_token(owner,int(e.fighters[fid].node))
  "v19_life":
   var victim=int(ctx.opponent_owner)
   if victim>=0 and not e.players[victim].deck.is_empty():
    var c=e.players[victim].deck.pop_back();e._discard_from_opponent(victim,c,false)
    for f in e.fighters:
     if int(f.owner)==owner:e._heal(int(f.id),int(c.boost))
  "v19_violence":
   var ids=[]
   for f in e.fighters:
    if e._valid_fighter(int(f.id)) and e.is_enemy(owner,int(f.owner)):
     for n in tokens:
      if spaces(int(f.id)).any(func(cell):return int(cell)==int(n) or e.nodes[int(n)].neighbors.has(int(cell))):ids.append(int(f.id));break
   e._damage_many(ids,2)
  "v19_other_move":
   for f in e.fighters:
    if int(f.owner)==owner and int(f.id)!=fid:_queue({"kind":"move","fixed_fighter":int(f.id),"spaces":4},ctx)
  "v19_faster":
   for f in e.fighters:
    if int(f.owner)==owner and f.alive:_queue({"kind":"place","fixed_fighter":int(f.id),"optional":true},ctx)
  "v19_attraction":
   var legal=[]
   for n in tokens:
    if e._occupant(int(n))<0 and not legal.has(int(n)):legal.append(int(n))
   if not legal.is_empty() and e._v13.can_relocate(fid):
    if human(owner):_options("attraction",legal.map(func(n):return "Клетка %d"%(int(n)+1)),ctx,{"nodes":legal},true)
    else:e._enter_node(fid,int(legal[0]))
  _:return false
 return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true
func choose_option(index: int) -> bool:
 var p=e.pending_choice.duplicate(true)
 if index<0 or index>=p.options.size():return false
 e.pending_choice.clear();var ctx=_live(p._ctx)
 match str(p.action).trim_prefix("v19_"):
  "token":add_token(int(ctx.owner),index)
  "retrieve":e.players[int(ctx.owner)].hand.append(e.players[int(ctx.owner)].discard.pop_at(int(p.indices[index])))
  "attraction":e._enter_node(int(ctx.self),int(p.nodes[index]))
  _:return false
 _resume();return true

func zones(node: int) -> Array:
 var result=e.nodes[node].zones.duplicate()
 for f in e.fighters:
  if f.alive and large(int(f.id)) and int(f.node)==node and int(f.get("tail",-1))>=0:
   for z in e.nodes[int(f.tail)].zones:
    if not result.has(z):result.append(z)
 return result
