extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v33_"+action
func friends(p: int) -> Array:return e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.are_allies(p,int(f.owner))).map(func(f):return int(f.id))
func foes(p: int) -> Array:return e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))).map(func(f):return int(f.id))
func limit(p: int) -> int:return 3 if e._is_hero(p,"michelangelo")or e._v35.hand_limit()else 7
func bonus(fid: int,attack: bool) -> int:
 var p=int(e.fighters[fid].owner)
 return (1 if e._int_array(e.players[p].get("inventions",[])).has(721 if attack else 722)else 0)+(int(e.players[p].get("nunchaku",0))if attack and e.fighters[fid].hero else 0)
func played(p: int,card: Dictionary):
 e.players[p].played_turn=int(e.players[p].get("played_turn",0))+1
 if card.type=="scheme"and e._int_array(e.players[p].get("inventions",[])).has(724):e.gain_actions(p,1)
func collect(p: int,c: Dictionary) -> bool:
 var n=int(str(c.get("id","")).trim_prefix("tmnt_"))if str(c.get("id","")).begins_with("tmnt_")else 0
 if n not in[721,722,724]:return false
 if not e.players[p].has("inventions"):e.players[p].inventions=[]
 e.players[p].inventions.append(n);e._log("Изобретение действует до конца партии: "+str(c.name));return true
func start_turn() -> bool:
 if not e._is_hero(e.active,"leonardo"):return false
 e._start_ability(e.active,"Командная тактика",[{"kind":"v33_select_move","ids":e.fighters.filter(func(f):return e._valid_fighter(int(f.id))).map(func(f):return int(f.id)),"spaces":1}],"start_turn");return true
func lost(p: int):
 e.players[p].lost_turn=true
 if e.active==p and e._is_hero(p,"raphael")and not e.players[p].get("anger_used",false):e.players[p].anger_used=true;e.gain_actions(p,1)
func select_move(ctx: Dictionary,ids: Array,spaces: int,through=false):
 ids=ids.filter(func(id):return e._valid_fighter(int(id)))
 if ids.is_empty():return
 if human(int(ctx.owner)):_options("move",ids.map(func(id):return e.fighters[int(id)].name),ctx,{"ids":ids,"spaces":spaces,"through":through},true)
 else:e._v31._move(ctx,int(ids[0]),spaces,through)
func select_card(ctx: Dictionary,action: String,p: int,source: String,types: Array=[],extra={},optional=true):
 var ids=range(e.players[p][source].size()).filter(func(i):return types.is_empty()or e.players[p][source][i].type in types)
 if ids.is_empty():return
 if human(p):_cards(action,p,source,ids,ctx,extra,optional);e.pending_choice.viewer=p;e.pending_choice.owner=p
 else:apply_card(ctx,action,p,source,int(ids[0]),extra)
func apply_card(ctx: Dictionary,action: String,p: int,source: String,i: int,q: Dictionary):
 var c=e.players[p][source].pop_at(i)
 match action:
  "recover":e.players[p].hand.append(c)
  "bottom":e.players[p].deck.push_front(c)
  "pay":
   if q.get("bottom",false):e.players[p].deck.push_front(c)
   else:e._discard(p,c)
   match str(q.get("reward","action")):
    "action":e.gain_actions(p,1)
    "cancel":e._v31._cancel(ctx)
    "plan":e._v31._cancel(ctx);ctx.ignore_opponent_value=true
  "remove":
   if not e.players[p].has("removed"):e.players[p].removed=[]
   e.players[p].removed.append(c)
   match int(q.n):
    721:ctx.value+=1
    722:e._heal(e.hero_fighter(p),1)
    724:e.gain_actions(p,1)
   if int(q.left)>1:_queue({"kind":"v33_remove","n":q.n,"left":int(q.left)-1},ctx)
  "boost":
   ctx.value+=int(c.get("boost",0));e._discard(p,c);e._v8.boosted(p,c)
  "rage":
   e._discard(p,c);ctx.value+=2;_queue({"kind":"v33_rage"},ctx)
func random_return(p: int):
 for i in range(mini(2,e.players[p].discard.size())):
  e.players[p].deck.append(e.players[p].discard.pop_at(e.rng.randi_range(0,e.players[p].discard.size()-1)))
 e._shuffle(e.players[p].deck)
func target(ctx: Dictionary,ids: Array,amount: int):
 if ids.is_empty():return
 if human(int(ctx.owner)):_options("hit",ids.map(func(id):return e.fighters[int(id)].name),ctx,{"ids":ids,"amount":amount},true)
 else:e._damage(int(ids[0]),amount)
func shell(ctx: Dictionary,used: Array):
 var ids=range(4).filter(func(i):return not used.has(i))
 if used.size()>=2:return
 if human(int(ctx.owner)):_options("shell",ids.map(func(i):return ["Каждый соперник сбрасывает карту","Движение союзника на 2","Карта под колоду: +1 действие","Вернуть 2 случайные карты"][i]),ctx,{"ids":ids,"used":used})
 else:shell_apply(ctx,int(ids[0]),used)
func shell_apply(ctx: Dictionary,id: int,used: Array):
 used.append(id);_queue({"kind":"v33_shell","used":used},ctx)
 match id:
  0:
   for p in range(e.players.size()):
    if e.is_enemy(int(ctx.owner),p):_queue({"kind":"opponent_discard","amount":1},_opponent_ctx(ctx,p))
  1:select_move(ctx,friends(int(ctx.owner)),2)
  2:select_card(ctx,"pay",int(ctx.owner),"hand",[],{"bottom":true})
  3:random_return(int(ctx.owner))
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var kind=str(fx.get("kind",""));ctx=_live(ctx);var p=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1))
 if kind=="v33_boost":select_card(ctx,"boost",p,"hand");return true
 if kind=="v33_maneuver":_options("maneuver",["Взять 1 карту","Взять 2, затем карту под колоду"],ctx);return true
 if kind=="v33_select_move":select_move(ctx,fx.ids,int(fx.spaces));return true
 if kind=="v33_shell":shell(ctx,e._int_array(fx.used));return true
 if kind=="v33_remove":select_card(ctx,"remove",p,"discard",["attack","versatile"]if int(fx.n)==721 else["defense","versatile"]if int(fx.n)==722 else["scheme"],{"n":fx.n,"left":fx.left});return true
 if kind=="v33_rage":select_card(ctx,"rage",p,"hand",["defense","versatile"]);return true
 if kind!="v33_card":return false
 var n=int(fx.number);var stage=str(fx.stage)
 match n:
  698,708:_queue({"kind":"v33_boost","optional":true},ctx)
  699:
   _queue({"kind":"draw","amount":1},ctx)
   for id in friends(p):e._v31._move(ctx,id,3)
  700:
   _queue({"kind":"v33_pay_action"},ctx);e._v31._move(ctx,foe,1);e._v31._move(ctx,fid,1)
  701:select_card(ctx,"pay",p,"hand",[],{"reward":"plan"})
  702:
   for f in e.fighters:
    if int(f.id)!=fid and e._valid_fighter(int(f.id))and e.fighters_adjacent(fid,int(f.id)):_queue({"kind":"place","fixed_fighter":int(f.id),"zone_anchor":int(f.id),"other_space":true},ctx)
  703:e._draw(p,1)
  704:ctx.value+=2*friends(p).filter(func(id):return id!=fid and e.fighters_adjacent(id,foe)).size()
  705:
   var spl=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero and e._valid_fighter(int(f.id)))
   e.gain_actions(p,1)
   if not spl.is_empty():
    var ids=friends(p).filter(func(id):return id!=int(spl[0].id)and not e._v19.large(id)and e._v13.can_relocate(id)and e._v13.can_relocate(int(spl[0].id)))
    if not ids.is_empty():_options("swap",ids.map(func(id):return e.fighters[int(id)].name),ctx,{"ids":ids,"fid":int(spl[0].id)},true)
  706,718:
   var anchor=e.hero_fighter(p)if n==718 else e.fighters.filter(func(f):return int(f.owner)==p and not f.hero)[0].id
   if e._valid_fighter(foe)and e._valid_fighter(int(anchor))and zones(foe).size()<zones(int(anchor)).size():e._damage(foe,2 if n==718 else 1);e._draw(p,1 if n==706 else 0)
  720:
   _queue({"kind":"draw","amount":1},ctx)
   for owner in range(e.players.size()):
    if e.are_allies(p,owner):_queue({"kind":"v33_recover","player":owner},ctx)
  721,722,724:_queue({"kind":"v33_remove","n":n,"left":4},ctx)
  723:select_move(ctx,e.fighters.filter(func(f):return int(f.id)!=e.hero_fighter(p)and e._valid_fighter(int(f.id))and e._same_zone(e.hero_fighter(p),int(f.id))).map(func(f):return int(f.id)),3,true)
  725:
   if not e.players[p].deck.is_empty():var c=e.players[p].deck.pop_front();ctx.value+=int(c.get("boost",0));e._discard(p,c,"deck")
  726:
   var ids=friends(p).filter(func(id):return e._v13.can_relocate(id))
   if not ids.is_empty():_options("wagon_fighter",ids.map(func(id):return e.fighters[int(id)].name),ctx,{"ids":ids},true)
  727:
   var ids=range(e.players.size()).filter(func(i):return not e.players[i].deck.is_empty())
   if not ids.is_empty():_options("peek_deck",ids.map(func(i):return e._player_name(i)),ctx,{"ids":ids})
   _queue({"kind":"draw","amount":1},ctx);_queue({"kind":"gain_action","amount":1},ctx)
  728:
   if ctx.get("won",false):select_card(ctx,"bottom",p,"discard")
  729:e._v31._cancel(ctx,true)
  740:target(ctx,foes(p).filter(func(id):return e.fighters_adjacent(e.hero_fighter(p),id)),1);_queue({"kind":"draw","amount":1},ctx)
  73:e.players[p].nunchaku=int(e.players[p].get("nunchaku",0))+1;e.gain_actions(p,1)
  730:random_return(p)
  731:target(ctx,foes(p).filter(func(id):return e.fighters_adjacent(fid,id)),1);_queue({"kind":"v33_bottom_action"},ctx)
  732:select_move(ctx,friends(p),3)
  733:ctx.value+=maxi(0,int(e.players[p].get("played_turn",0))-1)
  735:e.gain_actions(p,2 if ctx.won else 1)
  736:shell(ctx,[])
  737:
   if stage=="immediately":select_card(ctx,"pay",p,"hand",[],{"reward":"cancel","bottom":true})
   elif e.players[p].hand.is_empty():e._draw(p,2)
  738:e._damage(foe,1);e.gain_actions(p,1)
  739:
   for id in friends(p):e._heal(id,1)
  709:
   e._damage_many(foes(p).filter(func(id):return friends(p).any(func(ally):return e.fighters_adjacent(ally,id))),1);e._draw(p,1)
  710:e._draw(p,2 if ctx.won else 1)
  711:
   if e.players[p].get("lost_turn",false):ctx.value=5
  712:
   var ids=foes(p).filter(func(id):return e.fighters_adjacent(fid,id));e._draw(p,ids.size());e._damage_many(ids,1)
  713:
   e._flow["pact_collected_"+str(ctx.get("_combat_slot","a"))]=true;e.players[p].deck.append(ctx.card.duplicate(true));e._shuffle(e.players[p].deck);e._draw(p,1)
  714:_queue({"kind":"v33_rage"},ctx)
  715:
   if stage=="immediately":
    var other=e._v6._other(ctx);var cancel=not e._card_uncancellable(int(other.owner),other.card)and other.card.get("effects",[]).any(func(f):return f.timing in["during","after"])
    ctx.break_cancelled=cancel
    if cancel:
     other.no_after=true;e._effect_queue=e._effect_queue.filter(func(job):return not(job.ctx.get("_combat_slot","")==other.get("_combat_slot","")and job.effect.get("timing","")in["during","after"]and not job.effect.get("intrinsic",false)))
   elif not ctx.get("break_cancelled",false):target(ctx,foes(p).filter(func(id):return e.fighters_adjacent(fid,id)),2)
  716:
   if ctx.won:e._v31._move(ctx,foe,3)
  717:
   var ids=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero and e._valid_fighter(int(f.id)))
   if not ids.is_empty()and e.fighters_adjacent(int(ids[0].id),foe):ctx.value=6
 return true
func extras(fx: Dictionary,ctx: Dictionary) -> bool:
 var p=int(ctx.owner)
 match str(fx.kind):
  "v33_pay_action":select_card(ctx,"pay",p,"hand")
  "v33_bottom_action":select_card(ctx,"pay",p,"hand",[],{"bottom":true})
  "v33_recover":select_card(ctx,"recover",int(fx.player),"discard",["attack","versatile","defense"])
  _:return false
 return true
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 e.pending_choice.clear();var ctx=_live(q._ctx)
 match str(q.action).trim_prefix("v33_"):
  "maneuver":
   e._draw(int(ctx.owner),index+1)
   if index==1:select_card(ctx,"bottom",int(ctx.owner),"hand",[],{},false)
  "wagon_fighter":wagon(ctx,int(q.ids[index]),[],5)
  "wagon_step":
   if int(q.ids[index])<0:wagon_finish(ctx,int(q.fid),e._int_array(q.path))
   else:
    var path=e._int_array(q.path);path.append(int(q.ids[index]));wagon(ctx,int(q.fid),path,int(q.left)-1)
  "move":e._v31._move(ctx,int(q.ids[index]),int(q.spaces),q.through)
  "hit":e._damage(int(q.ids[index]),int(q.amount))
  "recover","bottom","pay","remove","rage","boost":apply_card(ctx,str(q.action).trim_prefix("v33_"),int(q.victim),str(q.source),int(q.indices[index]),q)
  "shell":shell_apply(ctx,int(q.ids[index]),e._int_array(q.used))
  "swap":
   var a=int(q.fid);var b=int(q.ids[index]);var pos=int(e.fighters[a].node);e.fighters[a].node=e.fighters[b].node;e.fighters[b].node=pos;e._heal(a,2);e._heal(b,2)
  "peek_deck":
   var victim=int(q.ids[index]);var c=e.players[victim].deck[-1];_options("peek",[str(c.name)+" — оставить сверху",str(c.name)+" — под колоду"],ctx,{"victim":victim})
  "peek":
   if index==1:e.players[int(q.victim)].deck.push_front(e.players[int(q.victim)].deck.pop_back())
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true

func _opponent_ctx(ctx: Dictionary,p: int) -> Dictionary:
 var c=ctx.duplicate(true);c.opponent_owner=p;return c

func zones(fid: int) -> Array:
 var z=[]
 for node in e._v19.spaces(fid):
  for id in e.nodes[int(node)].zones:
   if not z.has(id):z.append(id)
 return z

func wagon(ctx: Dictionary,fid: int,path: Array,left: int):
 var node=int(e.fighters[fid].node)if path.is_empty()else int(path[-1]);var ids=[]
 if e._v31.can_end(fid,node):ids.append(-1)
 if left>0:ids.append_array(e._v34.links(fid,node).filter(func(n):return e._enemy_trap_at(int(n),int(e.fighters[fid].owner))<0 or e._v31.can_end(fid,int(n))))
 if ids.is_empty():wagon_finish(ctx,fid,path);return
 if human(int(ctx.owner)):_options("wagon_step",ids.map(func(n):return "Завершить движение"if n<0 else "Клетка %d"%(n+1)),ctx,{"ids":ids,"fid":fid,"path":path,"left":left})
 else:
  if ids.has(-1)and (left==0 or path.size()>=3):wagon_finish(ctx,fid,path)
  else:
   var n=int(ids[-1]);path.append(n);wagon(ctx,fid,path,left-1)
func wagon_finish(ctx: Dictionary,fid: int,path: Array):
 var passed=[];var p=int(ctx.owner)
 for node in path:
  for other in e._v31.occupants(int(node)):
   if e.is_enemy(p,int(e.fighters[int(other)].owner))and not passed.has(int(other)):passed.append(int(other))
  var trap=e._enemy_trap_at(int(node),int(e.fighters[fid].owner));e._enter_node(fid,int(node))
  if not e._valid_fighter(fid):return
  if trap>=0:break
 if ctx.get("v34_overrun",false):e._damage_many(passed,1)
 else:target(ctx,passed,2)
func summary(p: int) -> String:
 if e._is_hero(p,"donatello"):
  var inv=e._int_array(e.players[p].get("inventions",[]));return "Изобретения: атака +%d · защита +%d · приём +%d действие"%[1 if inv.has(721)else 0,1 if inv.has(722)else 0,1 if inv.has(724)else 0]
 if e._is_hero(p,"michelangelo"):return "Лимит руки: 3 · сыграно карт: %d · нунчаки: +%d"%[int(e.players[p].get("played_turn",0)),int(e.players[p].get("nunchaku",0))]
 if e._is_hero(p,"raphael"):return "Гнев: использован"if e.players[p].get("anger_used",false)else"Гнев: доступен"
 return ""
