extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v34_"+action
func setup():
 for p in range(e.players.size()):
  if e._is_hero(p,"george_washington"):e.players[p].ruses=4
  if e._is_hero(p,"rosie_the_riveter"):e.players[p].upgrades=[0,1,2,3];e.players[p].upgrade_active=[]
  if e._is_hero(p,"john_henry"):e.players[p].tracks=[];e.players[p].used_paths=[]
func active_upgrades(p: int) -> Array:return e._int_array(e.players[p].get("upgrade_active",[]))
func upgrade(p: int,on: bool):
 var order=e._int_array(e.players[p].get("upgrades",[0,1,2,3]));var active=active_upgrades(p)
 for id in order:
  if on and not active.has(id):active.append(id);break
  if not on and active.has(id):active.erase(id);order.erase(id);order.append(id);break
 e.players[p].upgrades=order;e.players[p].upgrade_active=active;sync_rosie(p)
func sync_rosie(p: int):
 var fid=e.hero_fighter(p)
 if fid>=0 and e._is_hero(p,"rosie_the_riveter"):e.fighters[fid].ranged=active_upgrades(p).has(3)
func movement_bonus(fid: int) -> int:return 1 if e.fighters[fid].hero and e._is_hero(int(e.fighters[fid].owner),"rosie_the_riveter")and active_upgrades(int(e.fighters[fid].owner)).has(0)else 0
func attack_bonus(fid: int) -> int:return 1 if e.fighters[fid].hero and e._is_hero(int(e.fighters[fid].owner),"rosie_the_riveter")and active_upgrades(int(e.fighters[fid].owner)).has(2)else 0
func has_free(p: int) -> bool:return not e.players.is_empty()and int(e.players[p].get("free_attack",0))>0
func grant_free(p: int,target=-1):
 if e.active==p and not e._v35.action_blocked(p):e.players[p].free_attack=1;e.players[p].free_target=target
func spend_attack(p: int,target: int) -> bool:
 var free=has_free(p)and int(e.players[p].get("free_target",-1))in[-1,target]
 clear_free(p);return free
func clear_free(p: int):e.players[p].free_attack=0;e.players[p].free_target=-1
func start_turn() -> bool:
 var p=e.active;e.players[p].showdown=[]
 for player in e.players:player.used_paths=[]
 if e._is_hero(p,"rosie_the_riveter"):upgrade(p,true)
 if e._is_hero(p,"john_henry"):
  e._start_ability(p,"Прокладка рельсов",[{"kind":"v34_track"}],"start_turn");return true
 return false
func track_options(ctx: Dictionary,replace_node=-1):
 var p=int(ctx.owner);var hero=e.hero_fighter(p);var tracks=e._int_array(e.players[p].tracks)
 if tracks.size()>=10 and replace_node<0:
  if human(p):_options("track_source",tracks.map(func(n):return "Перенести рельсы с клетки %d"%(n+1)),ctx,{"nodes":tracks})
  else:track_options(ctx,int(tracks[0]))
  return
 var ids=e.nodes.filter(func(n):return e._same_zone(int(e.fighters[hero].node),int(n.id))and not tracks.has(int(n.id))).map(func(n):return int(n.id))
 if ids.is_empty():return
 if human(p):_options("track",ids.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":ids,"replace_node":replace_node})
 else:add_track(p,int(ids[0]),replace_node)
func add_track(p: int,node: int,old: int):
 var tracks=e._int_array(e.players[p].tracks);tracks.erase(old)
 if not tracks.has(node):tracks.append(node)
 e.players[p].tracks=tracks
func rail_eligible(fid: int,ctx: Dictionary) -> bool:return e._valid_fighter(fid)and e._is_hero(int(e.fighters[fid].owner),"john_henry")and int(ctx.owner)==int(e.fighters[fid].owner)
func path_key(a: int,b: int) -> String:return str(mini(a,b))+":"+str(maxi(a,b))
func departed(fid: int,a: int,b: int):
 if a==b or not e._is_hero(int(e.fighters[fid].owner),"john_henry"):return
 var p=int(e.fighters[fid].owner);var used=e.players[p].get("used_paths",[]);var key=path_key(a,b)
 if e.nodes[a].neighbors.has(b)and not used.has(key):used.append(key)
 e.players[p].used_paths=used
func momentum(p: int) -> bool:return e.players[p].get("used_paths",[]).size()>=4
func rail(ctx: Dictionary,fid: int,spaces: int,path: Array=[],track_owner=-1):
 if not e._valid_fighter(fid):return
 var p=int(ctx.owner)
 if track_owner<0:track_owner=int(e.fighters[fid].owner)
 var tracks=e._int_array(e.players[track_owner].get("tracks",[]));var origin=int(e.fighters[fid].node);var node=origin if path.is_empty()else int(path[-1]);var ids=[]
 if e._v31.can_end(fid,node):ids.append(-1)
 if e._v13.can_relocate(fid):
  for next in links(fid,node):
   var cost=0 if tracks.has(int(next))else 1
   if cost>spaces:continue
   var occupant=e._occupant(int(next))
   if occupant>=0 and occupant!=fid and e.is_enemy(int(e.fighters[fid].owner),int(e.fighters[occupant].owner)):continue
   if cost==spaces and occupant>=0 and occupant!=fid and not tracks.has(int(next)):continue
   ids.append(int(next))
 if ids.is_empty():rail_finish(ctx,fid,path);return
 if human(p):_options("rail",ids.map(func(n):return "Завершить движение"if n<0 else "Клетка %d · шагов: %d"%[n+1,0 if tracks.has(n)else 1]),ctx,{"ids":ids,"fid":fid,"path":path,"spaces":spaces,"track_owner":track_owner})
 else:
  if ids.has(-1)and(path.size()>=12 or path.size()>=4 and momentum_path(fid,path)) :rail_finish(ctx,fid,path);return
  var next=-1;var used={}
  var prev=origin
  for n in path:used[path_key(prev,int(n))]=true;prev=int(n)
  for n in ids:
   if n>=0 and not used.has(path_key(node,n)):next=n;break
  if next<0 and ids.has(-1):rail_finish(ctx,fid,path);return
  if next<0:next=int(ids[-1])
  path.append(next);rail(ctx,fid,spaces-(0 if tracks.has(next)else 1),path,track_owner)
func momentum_path(fid: int,path: Array) -> bool:
 var used={};var prev=int(e.fighters[fid].node)
 for n in path:used[path_key(prev,int(n))]=true;prev=int(n)
 return used.size()>=4
func rail_finish(ctx: Dictionary,fid: int,path: Array):
 for node in path:
  var old=int(e.fighters[fid].node);var trap=e._enemy_trap_at(int(node),int(e.fighters[fid].owner));e._enter_node(fid,int(node));e._v19.moved(fid,old,false)
  if e._flow.get("completion","")=="v34_maneuver":e._v36.crossed(fid,old,int(node),[],true)
  if not e._valid_fighter(fid)or trap>=0:break
 if e._flow.get("completion","")=="v34_maneuver"and not e.maneuver_moved.has(fid):e.maneuver_moved.append(fid)
func links(fid: int,node: int) -> Array:
 var ids=e._int_array(e.nodes[node].neighbors if e._v19.large(fid)else e.nodes[node].get("move_neighbors",e.nodes[node].neighbors))
 var passages=e._int_array(e.board_data.get("secret_passages",[]))
 if not e._v19.large(fid)and passages.has(node):
  for id in passages:
   if id!=node and not ids.has(id):ids.append(id)
 return ids
func ruse_offer() -> bool:
 if e.pending_combat.is_empty()or e.pending_combat.get("ruse_ready",false):return false
 var q=e.pending_combat;var p=int(q.attack_owner)
 if not e._is_hero(p,"george_washington")or int(e.players[p].get("ruses",0))<=0:q.ruse_ready=true;return false
 var ctx={"owner":p,"self":int(q.attacker),"opponent":int(q.target),"opponent_owner":int(q.defender_owner),"card":{"name":"Шпионская уловка"}}
 if human(p):_options("ruse",["Использовать уловку","Не использовать"],ctx);return true
 var use=q.attack_card.get("effects",[]).any(func(f):return f.get("ruse",false))or e.difficulty>=2 and e.rng.randf()<0.3
 ruse_selected(ctx,use);return true
func ruse_selected(ctx: Dictionary,use: bool):
 e.pending_combat.ruse_ready=true;e.pending_combat.ruse=use
 if not use:e._begin_defense();return
 var p=int(ctx.owner);e.players[p].ruses=maxi(0,int(e.players[p].ruses)-1);var other=int(ctx.opponent_owner)
 if e.players[other].hand.is_empty():e._begin_defense();return
 if human(other):_options("ruse_counter",["Сбросить случайную карту: убрать уловку","Сохранить руку"],ctx);e.pending_choice.owner=other;e.pending_choice.viewer=other
 else:ruse_counter(ctx,e.players[other].hand.size()>=5)
func ruse_counter(ctx: Dictionary,pay: bool):
 var p=int(ctx.opponent_owner)
 if pay and not e.players[p].hand.is_empty():e._discard(p,e.players[p].hand.pop_at(e.rng.randi_range(0,e.players[p].hand.size()-1)),"voluntary");e.pending_combat.ruse=false
 e._begin_defense()
func summary(p: int) -> String:
 if e._is_hero(p,"george_washington"):return "Готовых уловок: %d"%int(e.players[p].get("ruses",0))
 if e._is_hero(p,"john_henry"):return "Рельсы: %d/10 · разных путей: %d/4"%[e.players[p].get("tracks",[]).size(),e.players[p].get("used_paths",[]).size()]
 if e._is_hero(p,"rosie_the_riveter"):
  var active=active_upgrades(p);return "Улучшения: "+", ".join(e._int_array(e.players[p].get("upgrades",[0,1,2,3])).map(func(i):return ["Двигатель +1 шаг","Магнетрон: добор после атаки","Кулак: атаки +1","Ракеты: дальний бой"][i]+(" ✓"if active.has(i)else" ○")))
 if e._is_hero(p,"wyatt_earp"):return "Дуэль: использовано вариантов %d/3"%e.players[p].get("showdown",[]).size()
 return ""
func target(ctx: Dictionary,ids: Array,amount: int):e._v33.target(ctx,ids,amount)
func move(ctx: Dictionary,fid: int,distance: int,force_tracks=false):
 if rail_eligible(fid,ctx)or force_tracks:_queue({"kind":"v34_rail","fid":fid,"spaces":distance,"track_owner":int(ctx.owner)},ctx)
 else:e._v31._move(ctx,fid,distance)
func free_action(ctx: Dictionary,target=-1):grant_free(int(ctx.owner),target)
func regain(p: int):e.players[p].ruses=mini(4,int(e.players[p].get("ruses",0))+1)
func change_upgrade(ctx: Dictionary):
 if human(int(ctx.owner)):_options("upgrade",["Активировать улучшение","Деактивировать улучшение"],ctx)
 else:upgrade(int(ctx.owner),active_upgrades(int(ctx.owner)).size()<4)
func showdown(ctx: Dictionary):
 var p=int(ctx.owner);var used=e._int_array(e.players[p].get("showdown",[]));var ids=range(3).filter(func(i):return not used.has(i))
 if ids.is_empty():return
 if human(p):_options("showdown",ids.map(func(i):return ["Взять карту","Бесплатная атака","Переместить атакующего на 1"][i]),ctx,{"ids":ids},true)
 else:showdown_apply(ctx,int(ids[0]))
func showdown_apply(ctx: Dictionary,id: int):
 var p=int(ctx.owner);var used=e._int_array(e.players[p].get("showdown",[]));used.append(id);e.players[p].showdown=used
 match id:
  0:e._draw(p,1)
  1:free_action(ctx)
  2:move(ctx,int(ctx.self),1)
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var kind=str(fx.get("kind",""));ctx=_live(ctx);var p=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1));var hero=e.hero_fighter(p)
 match kind:
  "v34_track":track_options(ctx);return true
  "v34_rail":rail(ctx,int(fx.fid),int(fx.spaces),[],int(fx.get("track_owner",-1)));return true
  "v34_showdown":showdown(ctx);return true
  "v34_rosie_draw":
   if active_upgrades(p).has(1):e._v32._options("hunger",["Взять карту","Не брать"],ctx)
   return true
  "v34_scatter":
   var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))).map(func(f):return int(f.id));var chooser=p if int(fx.step)%2==0 else int(ctx.opponent_owner)
   if ids.is_empty()or chooser<0:return true
   if human(chooser):_options("scatter",ids.map(func(i):return e.fighters[int(i)].name),ctx,{"ids":ids,"step":fx.step});e.pending_choice.owner=chooser;e.pending_choice.viewer=chooser
   else:scatter(ctx,int(fx.step),int(ids[0]))
   return true
  "v34_look":look(ctx);return true
  "v34_look_finish":
   if e.players[int(ctx.opponent_owner)].hand.is_empty():
    if spies_adjacent(p,int(ctx.opponent_owner)):regain(p)
    return true
   if spies_adjacent(p,int(ctx.opponent_owner)):
    if human(p):_cards("spy_discard",int(ctx.opponent_owner),"hand",range(e.players[int(ctx.opponent_owner)].hand.size()),ctx)
    else:e._discard(int(ctx.opponent_owner),e.players[int(ctx.opponent_owner)].hand.pop_at(0));regain(p)
   return true
  "v34_card":pass
  _:return false
 if fx.get("ruse",false)and not e._combat_resolution.get("ctx",{}).get("ruse",false):return true
 var n=int(fx.number);var stage=str(fx.stage)
 match n:
  2:e._v31._cancel(ctx)
  786:
   if ctx.won:
    var victim=int(ctx.opponent_owner)
    for i in range(mini(2,e.players[victim].hand.size())):e._discard(victim,e.players[victim].hand.pop_at(e.rng.randi_range(0,e.players[victim].hand.size()-1)))
  787:ctx.ignore_opponent_value=true
  788:e._v33.select_move(ctx,[fid,foe],2)
  789:
   if not e.changed_start_space(fid):ctx.value=5
  790:ctx.value+=e._v33.friends(p).filter(func(id):return id!=fid and e._same_zone(int(e.fighters[hero].node),int(e.fighters[id].node))).size()
  791:
   e._draw(p,3)
   for f in e.fighters:
    if e._valid_fighter(int(f.id),p):e._v31._move(ctx,int(f.id),3,true)
  792:
   if ctx.won:e._damage(foe,7)
  793:
   var ids=range(e.players.size()).filter(func(i):return e.is_enemy(p,i)and not e.is_dormant(i))
   if human(p):_options("spy_player",ids.map(func(i):return e._player_name(i)),ctx,{"ids":ids})
   elif not ids.is_empty():var c=ctx.duplicate(true);c.opponent_owner=int(ids[0]);_queue({"kind":"v34_look"},c)
  794:
   if fx.get("ruse",false):e._heal(hero,3)
   else:free_action(ctx)
  795:
   if ctx.won:regain(p)
  796:
   var ids=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero and e._valid_fighter(int(f.id))and e.fighters_adjacent(hero,int(f.id))and e._v13.can_relocate(int(f.id))and e._v13.can_relocate(hero)).map(func(f):return int(f.id))
   if fid==hero and str(ctx.get("_combat_slot",""))=="d"and not ids.is_empty():_options("spy_swap",ids.map(func(i):return e.fighters[int(i)].name),ctx,{"ids":ids},true)
  797:revive_spy(ctx)
  5:
   if e.changed_start_space(fid):ctx.value=5
  798:_options("arc",["Активировать улучшение","Урон соседним врагам"],ctx)
  799:e._draw(p,2);free_action(ctx);change_upgrade(ctx)
  800:upgrade(p,true)
  801:
   for f in e.fighters:
    if e._valid_fighter(int(f.id),p):e._v31._move(ctx,int(f.id),3)
   change_upgrade(ctx)
  802:ctx.value+=active_upgrades(p).size()
  803:ctx.v34_overrun=true;e._v33.wagon(ctx,hero,[],3)
  804:
   if not active_upgrades(p).is_empty():upgrade(p,false);e._heal(hero,3)
  805:reveal_top(ctx,false)
  806:
   free_action(ctx)
   if active_upgrades(p).size()==4:e._damage(foe,1);e._heal(hero,1)
   else:e.players[p].upgrade_active=[0,1,2,3];sync_rosie(p)
  807:
   if active_upgrades(p).size()>=3:e._v31._cancel(ctx)
  775:e._draw(p,1);move(ctx,hero,1);free_action(ctx)
  776:ctx.v34_damage_cap=2
  777:ctx.v34_no_after_if_win=true
  778:
   if momentum(p):_options("hammer_fighter",[e.fighters[fid].name,e.fighters[foe].name],ctx,{"ids":[fid,foe]},true)
  779:_options("power_fighter",[e.fighters[fid].name,e.fighters[foe].name],ctx,{"ids":[fid,foe]},true)
  781:move(ctx,hero,4);e.gain_actions(p,1)
  782:ctx.value+=e.players[p].discard.filter(func(c):return c.get("hammer",false)).size()
  783:e._heal(hero,3);e._draw(p,1)
  784:
   if momentum(p):e._v31._cancel(ctx)
  785:
   if momentum(p):e._damage_many(e._v33.foes(p).filter(func(id):return e._same_zone(int(e.fighters[hero].node),int(e.fighters[id].node))),2)
  170:e._v33.select_card(ctx,"boost",p,"hand")
  809:e._draw(p,maxi(0,4-e.players[p].hand.size()));free_action(ctx)
  810:
   var ids=e._v33.foes(p)
   if not ids.is_empty():_options("die_first",ids.map(func(i):return e.fighters[int(i)].name),ctx,{"ids":ids})
  811:
   if ctx.won:target(ctx,e._v33.foes(p).filter(func(i):return e._same_zone(int(e.fighters[fid].node),int(e.fighters[i].node))),1)
  812:
   var other=e._v6._other(ctx);var ids=e._v33.foes(p).filter(func(i):return i!=foe and e._same_zone(int(e.fighters[hero+1].node),int(e.fighters[i].node)))
   if not other.card.is_empty():target(ctx,ids,int(other.card.get("value",0)))
  813:reveal_top(ctx,true)
  814:
   if stage=="immediately":e._v31._cancel(ctx)
   else:reveal_top(ctx,true,true)
  815:
   if not e._valid_fighter(foe):e._flow["return_"+str(ctx.get("_combat_slot","a"))]=true
  816:e._draw(p,2)
  817:
   if str(ctx.get("_combat_slot",""))=="d":e._draw(p,1)
   else:_queue({"kind":"opponent_discard","amount":1},ctx)
  818:_queue({"kind":"v34_scatter","step":0},ctx)
 return true
func scatter(ctx: Dictionary,step: int,id: int):
 e._damage(id,1)
 if step<3:_queue({"kind":"v34_scatter","step":step+1},ctx)
func spies_adjacent(p: int,victim: int) -> bool:
 return e.fighters.any(func(f):return int(f.owner)==p and not f.hero and e._valid_fighter(int(f.id))and e._v33.foes(p).any(func(id):return int(e.fighters[id].owner)==victim and e.fighters_adjacent(int(f.id),id)))
func look(ctx: Dictionary):
 _queue({"kind":"v34_look_finish"},ctx)
 var peek=ctx.duplicate(true);peek._peek_allowed=true;e._reveal_hand(int(ctx.owner),int(ctx.opponent_owner),peek)
func reveal_top(ctx: Dictionary,add: bool,bottom=false):
 var other=int(ctx.opponent_owner)
 if other<0 or e.players[other].deck.is_empty():return
 var card=e.players[other].deck[-1]
 if bottom:_options("top_bottom",[str(card.name)+" — оставить сверху",str(card.name)+" — под колоду"],ctx,{"victim":other})
 else:
  if add:ctx.value+=2*int(card.get("boost",0))
  else:e._v6._other(ctx).value=maxi(0,int(e._v6._other(ctx).value)-int(card.get("boost",0)))
  e._log("Раскрыта верхняя карта: "+str(card.name))
  if human(int(ctx.owner)):_options("revealed",[str(card.name)+" · BOOST "+str(card.get("boost",0))+" · Продолжить"],ctx)
func revive_spy(ctx: Dictionary):
 var p=int(ctx.owner);var ids=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero and not f.alive).map(func(f):return int(f.id))
 if not ids.is_empty():_options("spy_revive",ids.map(func(i):return e.fighters[int(i)].name),ctx,{"ids":ids},true)
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 e.pending_choice.clear();var ctx=_live(q._ctx);var p=int(ctx.owner)
 match str(q.action).trim_prefix("v34_"):
  "ruse":ruse_selected(ctx,index==0);return true
  "ruse_counter":ruse_counter(ctx,index==0);return true
  "track_source":track_options(ctx,int(q.nodes[index]))
  "track":add_track(p,int(q.nodes[index]),int(q.replace_node))
  "rail":
   var id=int(q.ids[index]);var path=e._int_array(q.path)
   if id<0:rail_finish(ctx,int(q.fid),path)
   else:path.append(id);rail(ctx,int(q.fid),int(q.spaces)-(0 if e._int_array(e.players[int(q.track_owner)].get("tracks",[])).has(id)else 1),path,int(q.track_owner))
  "showdown":showdown_apply(ctx,int(q.ids[index]))
  "upgrade":upgrade(p,index==0)
  "arc":
   if index==0:upgrade(p,true)
   else:e._damage_many(e._v33.foes(p).filter(func(i):return e.fighters_adjacent(int(ctx.self),i)),1)
  "spy_player":ctx.opponent_owner=int(q.ids[index]);_queue({"kind":"v34_look"},ctx)
  "spy_discard":e._discard(int(q.victim),e.players[int(q.victim)].hand.pop_at(int(q.indices[index])));regain(p)
  "spy_swap":
   var hero=e.hero_fighter(p);var id=int(q.ids[index]);var pos=int(e.fighters[hero].node);e.fighters[hero].node=e.fighters[id].node;e.fighters[id].node=pos
   ctx.self=id;e._combat_resolution.ctx.target=id;e._combat_resolution.a.opponent=id
  "spy_revive":
   var id=int(q.ids[index]);var hero=e.hero_fighter(p);var nodes=e.nodes.filter(func(n):return e._v31.can_end(id,int(n.id))and (ctx.get("won",false)or e.node_adjacent_to_fighter(int(n.id),hero))).map(func(n):return int(n.id))
   if not nodes.is_empty():_options("spy_place",nodes.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":nodes,"fid":id})
  "spy_place":var id=int(q.fid);e.fighters[id].alive=true;e.fighters[id].hp=1;e.fighters[id].node=int(q.nodes[index]);e.fighters[id].placed=true
  "die_first":var id=int(q.ids[index]);free_action(ctx,id);move(ctx,id,1)
  "power_fighter":move(ctx,int(q.ids[index]),2,true)
  "hammer_fighter":
   var id=int(q.ids[index]);var nodes=e._int_array(e.players[p].get("tracks",[])).filter(func(n):return e._v31.can_end(id,int(n))and e._v13.can_relocate(id))
   if not nodes.is_empty():_options("hammer_place",nodes.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":nodes,"fid":id})
  "hammer_place":var old=int(e.fighters[int(q.fid)].node);e._enter_node(int(q.fid),int(q.nodes[index]));e._v19.moved(int(q.fid),old,true)
  "scatter":scatter(ctx,int(q.step),int(q.ids[index]))
  "top_bottom":
   if index==1:e.players[int(q.victim)].deck.push_front(e.players[int(q.victim)].deck.pop_back())
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true



func estimate(card: Dictionary,fid: int,value: float,defending=false) -> float:
 if not card.has("sns_number"):return value
 var n=int(card.sns_number);var p=int(e.fighters[fid].owner)
 match n:
  5:
   if e.changed_start_space(fid):value=5
  789:
   if not e.changed_start_space(fid):value=5
  790:value+=e._v33.friends(p).filter(func(i):return i!=fid and e._same_zone(int(e.fighters[e.hero_fighter(p)].node),int(e.fighters[i].node))).size()
  802:value+=active_upgrades(p).size()
  782:value+=e.players[p].discard.filter(func(c):return c.get("hammer",false)).size()
  776:
   if defending:value=maxf(5,value)
  784:
   if momentum(p):value+=1.5
  787:
   if not defending and int(e.players[p].get("ruses",0))>0:value+=3
  792:
   if not defending and int(e.players[p].get("ruses",0))>0:value+=2
  807:
   if active_upgrades(p).size()>=3:value+=1.5
 if not defending:value+=attack_bonus(fid)
 return value
