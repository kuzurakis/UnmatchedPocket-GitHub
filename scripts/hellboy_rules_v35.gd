extends "res://scripts/hero_rules_v8.gd"
var actor=-1
var actor_override=-2
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v35_"+action
func num(card: Dictionary) -> int:return int(card.get("hb_number",-1))
func ongoing_num(p: int) -> int:return num(e.players[p].get("ongoing",{}))
func active_pacts(n: int) -> Array:return range(e.players.size()).filter(func(p):return e.players[p].alive and ongoing_num(p)==n)
func destiny(p: int) -> int:return e.players[p].discard.filter(func(c):return c.get("destiny",false)).size()
func anung(p: int) -> bool:return e._is_hero(p,"hellboy")and destiny(p)>=6
func setup():
 for p in range(e.players.size()):
  if e._is_hero(p,"abe_sapien"):e.players[p].intuition=0
func current_actor() -> int:return actor_override if actor_override!=-2 else actor if actor>=0 and not e._flow.is_empty()else e.active
func shielded(p: int,source=-2) -> bool:
 if source==-2:source=current_actor()
 return ongoing_num(p)==825 and source>=0 and source!=p
func block_move(fid: int,source=-2) -> bool:
 return fid>=0 and fid<e.fighters.size()and shielded(int(e.fighters[fid].owner),source)
func action_blocked(p: int) -> bool:return not active_pacts(844).is_empty()or int(e.players[p].get("no_actions_turn",-1))==e.turn_number
func first_attack_blocked(p: int) -> bool:return not active_pacts(840).is_empty()and int(e.players[p].get("actions_taken",0))==0
func hand_limit() -> bool:return not active_pacts(843).is_empty()
func effect_amount(amount: int) -> int:return amount+active_pacts(841).size()if amount>0 else 0
func immune(fid: int) -> bool:
 var p=int(e.fighters[fid].owner)
 return int(e.players[p].get("hb_effect_immune",-1))==e.turn_number or shielded(p)
func discard(p: int,c: Dictionary,source: String) -> bool:
 if source=="hand"and shielded(p):e.players[p].hand.append(c);e._log("Щит защищает руку от сброса.");return true
 if e._is_hero(p,"liz_sherman")and c.get("burning",false)and source in["hand","deck","voluntary"]:
  e.players[p].hand.append(c);e._log("Горящая карта возвращена в руку: "+str(c.name));return true
 return false
func attack_bonus(fid: int) -> int:
 var p=int(e.fighters[fid].owner)
 return (2 if e.fighters[fid].hero and anung(p)else 0)+(int(e._combat_resolution.get("ctx",{}).get("hb_next_bonus",0))if int(e._combat_resolution.get("ctx",{}).get("attacker",-1))==fid else 0)
func card_bonus(p: int) -> int:return 1 if ongoing_num(p)==857 else 0
func start_turn() -> bool:
 var p=e.active;actor=p
 if ongoing_num(p)in[825,857]:e._v14._discard_ongoing(p)
 e.players[p].hb_next_attack=0
 if e._is_hero(p,"hellboy"):
  if anung(p):e._start_ability(p,"Анунг Ун Рама",[{"kind":"v35_anung"}],"start_turn");return true
  var node=int(e.fighters[e.hero_fighter(p)].node)
  if e._valid_fighter(e.hero_fighter(p))and range(e.players.size()).any(func(other):return e.is_enemy(p,other)and int(e.players[other].get("starting_space",-1))==node):e._start_ability(p,"Оккультный детектив",[{"kind":"v35_occult"}],"start_turn");return true
 if e._is_hero(p,"liz_sherman"):
  e._start_ability(p,"Дикий огонь",[{"kind":"v35_wildfire"}],"start_turn");return true
 return false
func end_turn() -> bool:
 if int(e.players[e.active].get("hb_end",-1))==e.turn_number:return false
 e.players[e.active].hb_end=e.turn_number
 var pacts=active_pacts(842)
 if pacts.is_empty():return false
 e._start_ability(e.active,"Договор мира",pacts.map(func(p):return {"kind":"v35_pact_end","pact_owner":p}),"end_turn");return true
func combat_received(fid: int,amount: int):
 var p=int(e.fighters[fid].owner)
 if amount>=2 and e.fighters[fid].hero and e._is_hero(p,"baba_yaga")and ongoing_num(p)in[840,841,842,843,844]:e._v14._discard_ongoing(p)
func intercept(fid: int,amount: int) -> bool:
 var p=int(e.fighters[fid].owner)
 if not e.fighters[fid].hero or not e._is_hero(p,"baba_yaga"):return false
 var kos=e.hero_fighter(p)+1
 if not e._valid_fighter(kos)or not e._same_zone(int(e.fighters[fid].node),int(e.fighters[kos].node)):return false
 var job={"effect":{"kind":"v35_redirect","fid":fid,"kos":kos,"amount":amount},"ctx":{"owner":p,"self":fid,"opponent":-1,"opponent_owner":-1,"card":{"name":"Роковые сделки"},"won":false,"value":0,"cancelled":false}}
 if human(p):
  if e._flow.is_empty():e._deferred_damage.append(job)
  else:e._effect_queue.push_front(job)
 else:e._damage_raw(kos,amount)
 return true
func after_combat_damage():
 if e._combat_resolution.get("hb_done",false):return
 e._combat_resolution.hb_done=true
 var a=e._combat_resolution.a;var d=e._combat_resolution.d;var before=e._combat_resolution.get("hb_hp",[])
 for ctx in [a,d]:
  var fid=int(ctx.self);var p=int(ctx.owner)
  if not e._is_hero(p,"abe_sapien")or not e.fighters[fid].hero:continue
  var dealt=(float(a.get("damage_dealt",0))>0 if ctx==a else float(a.get("reflected_damage",0))>0)
  if not dealt:continue
  for f in e.fighters:
   if int(f.id)<before.size()and int(f.hp)<int(before[int(f.id)])and e._int_array(e._combat_resolution.get("hb_adjacent",{}).get(str(fid),[])).has(int(f.id)):
    if int(e.players[p].get("intuition",0))<2:e.players[p].intuition=int(e.players[p].get("intuition",0))+1;e._log("Интуиция Эйба: жетон активирован.")
    break
func reveal_intuition():
 if e.pending_combat.get("hb_intuition_checked",false):return
 e.pending_combat.hb_intuition_checked=true
 var fid=int(e.pending_combat.target);var p=int(e.fighters[fid].owner)
 if e._is_hero(p,"abe_sapien")and e.fighters[fid].hero and int(e.players[p].get("intuition",0))>0:
  e.players[p].intuition=int(e.players[p].intuition)-1;e.pending_combat.face_up=true;e._draw(p,1);e._log("Интуиция: карта атаки открыта до защиты.")
func before_attack() -> bool:
 var q=e.pending_combat
 if num(q.attack_card)==829 and not q.get("hb_attack_predicted",false):
  if human(int(q.attack_owner)):
   var ctx={"owner":int(q.attack_owner),"self":int(q.attacker),"opponent":int(q.target),"opponent_owner":int(q.defender_owner),"card":q.attack_card};predict(ctx,false,-1);return true
  q.hb_attack_predicted=true;q.hb_prediction_a=3;q.face_up=true
 reveal_intuition();return e._check_winner()
func prepare_defense(index: int) -> bool:
 var q=e.pending_combat;var p=int(q.defender_owner)
 if q.get("hb_defense_predicted",false)or index<0 or index>=e.players[p].hand.size()or num(e.players[p].hand[index])!=829:return false
 if human(p):
  var ctx={"owner":p,"self":int(q.target),"opponent":int(q.attacker),"opponent_owner":int(q.attack_owner),"card":e.players[p].hand[index]};predict(ctx,true,index);return true
 q.hb_defense_predicted=true;q.hb_prediction_d=int(q.attack_card.get("value",0))if q.get("face_up",false)else 3;return false
func predict(ctx: Dictionary,defense: bool,index: int):
 var maxvalue=10
 for h in e.heroes.values():
  for c in h.cards:maxvalue=maxi(maxvalue,int(c.get("value",0)))
 var labels=["Не объявлять предположение"]+range(maxvalue+1).map(func(n):return "Открыто: предполагаю значение %d"%n)
 _options("predict",labels,ctx,{"defense":defense,"defense_index":index})
func resume_attack():
 reveal_intuition()
 if e._check_winner():return
 if not e._valid_fighter(int(e.pending_combat.target)):e.pending_combat.clear();e._after_action();return
 if e.interactive:e.phase="attack_notice"
 else:e._begin_defense()
 e.changed.emit()
func pick(ctx: Dictionary,action: String,p: int,source: String,indices: Array,extra={},optional=false,chooser=-1):
 if indices.is_empty():return
 if chooser<0:chooser=int(ctx.owner)
 if human(chooser):_cards(action,p,source,indices,ctx,extra,optional);e.pending_choice.owner=chooser;e.pending_choice.viewer=chooser
 else:apply_card(ctx,action,p,source,int(indices[0]),extra)
func indices(p: int,source: String,types: Array=[]) -> Array:return range(e.players[p][source].size()).filter(func(i):return types.is_empty()or e.players[p][source][i].type in types)
func apply_card(ctx: Dictionary,action: String,p: int,source: String,index: int,q: Dictionary):
 var c=e.players[p][source].pop_at(index)
 match action:
  "hand_shuffle":e.players[p].deck.append(c);e._shuffle(e.players[p].deck)
  "bottom_hand":
   e.players[p].deck.push_front(c)
   if int(q.get("left",1))>1:_queue({"kind":"v35_bottom_hand","left":int(q.left)-1},ctx)
  "discard_shuffle":
   e.players[p].deck.append(c);e._shuffle(e.players[p].deck)
   if int(q.get("left",1))>1:_queue({"kind":"v35_discard_shuffle","player":p,"left":int(q.left)-1,"types":q.get("types",[])},ctx)
  "discard_bottom":
   e.players[p].deck.push_front(c)
   if int(q.get("left",1))>1:_queue({"kind":"v35_discard_bottom","left":int(q.left)-1},ctx)
  "recover_scheme":e.players[p].hand.append(c)
  "anung":
   var distance=int(c.get("boost",0));e._discard(p,c,"voluntary");e._v31._move(ctx,e.hero_fighter(p),distance)
  "view_discard":e._discard(p,c)
  "view_top":e.players[p].deck.append(c)
  "memory_pick":
   e.players[p].hand.insert(index,c)
   if human(p):_options("memory_pay",["Сбросить выбранную карту: "+str(c.name),"Получить 2 урона"],ctx,{"victim":p,"index":index});e.pending_choice.owner=p;e.pending_choice.viewer=p
   elif e._card_quality(c)<2.0:memory_pay(ctx,p,index,true)
   else:memory_pay(ctx,p,index,false)
  "secrecy_keep":
   e.players[p].hand.insert(index,c);var selected=e._int_array(q.get("selected",[]));selected.append(index)
   if selected.size()<mini(2,e.players[p].hand.size()):pick(ctx,"secrecy_keep",p,"hand",indices(p,"hand").filter(func(i):return not selected.has(i)),{"selected":selected},false,p)
   else:
    var rest=[];var kept=[]
    for i in range(e.players[p].hand.size()):
     if selected.has(i):kept.append(e.players[p].hand[i])
     else:rest.append(e.players[p].hand[i])
    e.players[p].hand=kept;e.players[p].deck.append_array(rest);e._shuffle(e.players[p].deck)
func memory_pay(ctx: Dictionary,p: int,index: int,pay: bool):
 if pay and index<e.players[p].hand.size():e._discard(p,e.players[p].hand.pop_at(index),"voluntary")
 else:e._damage(int(ctx.opponent),2)
func view(ctx: Dictionary,mode: String):_queue({"kind":"v35_view","mode":mode},ctx)
func view_begin(ctx: Dictionary,mode: String):
 _queue({"kind":"v35_view_finish","mode":mode},ctx);var peek=ctx.duplicate(true);peek._peek_allowed=true;e._reveal_hand(int(ctx.owner),int(ctx.opponent_owner),peek)
func view_finish(ctx: Dictionary,mode: String):
 var p=int(ctx.opponent_owner)
 if p<0 or e.players[p].hand.is_empty():return
 if mode=="discard"and not shielded(p,int(ctx.owner)):pick(ctx,"view_discard",p,"hand",indices(p,"hand"))
 if mode=="top":pick(ctx,"view_top",p,"hand",indices(p,"hand"))
 if mode=="memory"and not e.players[int(ctx.owner)].get("ongoing",{}).is_empty():pick(ctx,"memory_pick",p,"hand",indices(p,"hand"))
func choose_fighter(ctx: Dictionary,ids: Array,mode: String,extra={},optional=false):
 ids=ids.filter(func(i):return i>=0 and (mode=="revive"or e._valid_fighter(int(i))))
 if ids.is_empty():return
 if human(int(ctx.owner)):_options("fighter",ids.map(func(i):return e.fighters[int(i)].name),ctx,{"ids":ids,"mode":mode,"extra":extra},optional)
 else:fighter_chosen(ctx,int(ids[0]),mode,extra)
func fighter_chosen(ctx: Dictionary,fid: int,mode: String,extra: Dictionary):
 match mode:
  "damage":e._damage(fid,int(extra.get("amount",1)))
  "heal":e._heal(fid,int(extra.get("amount",1)))
  "move":e._v31._move(ctx,fid,int(extra.get("spaces",3)))
  "place":_queue({"kind":"place","fixed_fighter":fid},ctx)
  "concussion":_queue({"kind":"v35_move_fixed","fid":fid,"spaces":3},ctx);e._damage(fid,2)
  "revive":place_return(ctx,fid,str(extra.get("where","zone")),int(extra.get("health",3)))
func place_return(ctx: Dictionary,fid: int,where: String,hp: int):
 var hero=e.hero_fighter(int(ctx.owner))
 if where in["zone","closest"]and not e._valid_fighter(hero):
  if e._valid_fighter(fid)and where=="closest":e.fighters[fid].hp=hp;e.fighters[fid].max_hp=maxi(hp,int(e.fighters[fid].max_hp))
  return
 var legal=e.nodes.filter(func(n):return e._v31.can_end(fid,int(n.id))and (where!="zone"or e._same_zone(int(e.fighters[hero].node),int(n.id)))).map(func(n):return int(n.id))
 if e._valid_fighter(fid)and not e._v13.can_relocate(fid):legal=[int(e.fighters[fid].node)]
 if e._valid_fighter(fid)and block_move(fid,int(ctx.owner)):return
 if e._v19.large(fid):legal=legal.filter(func(n):return not e._v19.orientations(fid,int(n)).is_empty())
 if where=="closest"and not legal.is_empty():
  var best=999
  for n in legal:best=mini(best,e._v8._graph_distance(int(e.fighters[hero].node),int(n),false))
  legal=legal.filter(func(n):return e._v8._graph_distance(int(e.fighters[hero].node),int(n),false)==best)
 if legal.is_empty():return
 if human(int(ctx.owner)):_options("return_space",legal.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":legal,"fid":fid,"hp":hp})
 else:returned(fid,int(legal[0]),hp)
func returned(fid: int,node: int,hp: int):
 var old=int(e.fighters[fid].node);e.fighters[fid].alive=true;e.fighters[fid].reserve=false;e.fighters[fid].offboard=false;e.fighters[fid].placed=true;e.fighters[fid].hp=hp;e.fighters[fid].max_hp=maxi(hp,int(e.fighters[fid].max_hp))
 if e.fighters[fid].hero:e.players[int(e.fighters[fid].owner)].alive=true
 var previous_lock=int(e.fighters[fid].get("locked_until",-1));e.fighters[fid].locked_until=-1;e._enter_node(fid,node);e.fighters[fid].locked_until=previous_lock;e._v19.moved(fid,old,true)
func pancakes(ctx: Dictionary,used: Array):
 if used.size()>=2:return
 var ids=range(3).filter(func(i):return not used.has(i))
 if human(int(ctx.owner)):_options("pancakes",ids.map(func(i):return ["Восстановить Хеллбою 2 здоровья","До 2 карт сброса под колоду","Взять 2 карты"][i]),ctx,{"ids":ids,"used":used})
 else:pancake_selected(ctx,int(ids[0]),used)
func pancake_selected(ctx: Dictionary,id: int,used: Array):
 used.append(id);_queue({"kind":"v35_pancakes","used":used},ctx)
 match id:
  0:e._heal(e.hero_fighter(int(ctx.owner)),2)
  1:_queue({"kind":"v35_discard_bottom","left":2},ctx)
  2:e._draw(int(ctx.owner),2)
func secrecy(ctx: Dictionary,p: int):
 if human(p):_options("secrecy_draw",["Не брать карты","Взять 1 карту","Взять 2 карты"],ctx,{"player":p});e.pending_choice.owner=p;e.pending_choice.viewer=p
 else:secrecy_draw(ctx,p,2 if e.players[p].deck.size()>=2 else 0)
func secrecy_draw(ctx: Dictionary,p: int,count: int):
 e._draw(p,count)
 if e.players[p].hand.size()>2:pick(ctx,"secrecy_keep",p,"hand",indices(p,"hand"),{},false,p)
func incinerate(ctx: Dictionary):
 var p=int(ctx.opponent_owner)
 if e.players[p].hand.size()<2:return
 if human(p):_options("incinerate_offer",["Сбросить 2 карты и игнорировать значение","Не сбрасывать"],ctx);e.pending_choice.owner=p;e.pending_choice.viewer=p
 else:
  if e.players[p].hand.size()>=3:pay_incinerate(ctx,[0,1])
func incinerate_select(ctx: Dictionary,selected: Array):
 var p=int(ctx.opponent_owner)
 pick(ctx,"incinerate_pick",p,"hand",indices(p,"hand").filter(func(i):return not selected.has(i)),{"selected":selected},false,p)
func pay_incinerate(ctx: Dictionary,ids: Array):
 var p=int(ctx.opponent_owner);ids.sort();ids.reverse()
 for i in ids:e._discard(p,e.players[p].hand.pop_at(int(i)),"voluntary")
 e._v6._other(ctx).ignore_opponent_value=true
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var kind=str(fx.get("kind",""));ctx=_live(ctx);var p=int(ctx.owner);var fid=int(ctx.self);var foe=int(ctx.get("opponent",-1));var hero=e.hero_fighter(p);actor=p
 match kind:
  "v35_friendly_move":e._v33.select_move(ctx,e._v33.friends(p),int(fx.spaces));return true
  "v35_friendly_heal":choose_fighter(ctx,e._v33.friends(p),"heal",{"amount":int(fx.get("amount",1))});return true
  "v35_move_fixed":e._v31._move(ctx,int(fx.fid),int(fx.spaces));return true
  "v35_discard_ongoing":e._v14._discard_ongoing(p);return true
  "v35_occult":
   if human(p):_options("occult",["Взять 2 карты","Не брать"],ctx)
   else:e._draw(p,2)
   return true
  "v35_anung":pick(ctx,"anung",p,"hand",indices(p,"hand"));return true
  "v35_wildfire":
   if not e.players[p].deck.is_empty():
    var c=e.players[p].deck.pop_front();e._discard(p,c,"deck")
    if c.get("burning",false):choose_fighter(ctx,e.fighters.filter(func(f):return int(f.id)!=hero and e._valid_fighter(int(f.id))and e._same_zone(int(e.fighters[hero].node),int(f.node))).map(func(f):return int(f.id)),"damage")
    else:e._v31._move(ctx,hero,2)
   return true
  "v35_redirect":
   if e._valid_fighter(int(fx.kos))and e._same_zone(int(e.fighters[int(fx.fid)].node),int(e.fighters[int(fx.kos)].node)):_options("redirect",["Передать урон Кощею","Получить урон Бабой-ягой"],ctx,{"fid":fx.fid,"kos":fx.kos,"amount":fx.amount})
   else:e._damage_raw(int(fx.fid),int(fx.amount))
   return true
  "v35_pact_end":
   actor=int(fx.pact_owner)
   if ongoing_num(actor)==842:e._damage_many(e.fighters.filter(func(f):return f.hero and e._valid_fighter(int(f.id))and int(f.get("hb_attack_turn",-1))==e.turn_number).map(func(f):return int(f.id)),1)
   return true
  "v35_view":view_begin(ctx,str(fx.mode));return true
  "v35_view_finish":view_finish(ctx,str(fx.mode));return true
  "v35_pancakes":pancakes(ctx,e._int_array(fx.used));return true
  "v35_bottom_hand":pick(ctx,"bottom_hand",p,"hand",indices(p,"hand"),{"left":fx.left},true);return true
  "v35_discard_bottom":pick(ctx,"discard_bottom",p,"discard",indices(p,"discard",["attack","defense","versatile"]),{"left":fx.left},true);return true
  "v35_discard_shuffle":
   var who=int(fx.get("player",p));var types=fx.get("types",[]);pick(ctx,"discard_shuffle",who,"discard",indices(who,"discard",types),{"left":fx.left,"types":types},true,who);return true
  "v35_secrecy":secrecy(ctx,int(fx.player));return true
  "v35_card":pass
  _:return false
 var n=int(fx.number);var stage=str(fx.stage)
 match n:
  86,864:pass
  170,839:
   if stage=="during":e._v33.select_card(ctx,"boost",p,"hand")
   else:e._flow.end_turn=true;e._flow.completion="end_turn"
  413:
   e._draw(p,1)
   if not ctx.won:view(ctx,"discard")
  821:
   e._draw(p,1)
   for id in e._v33.friends(p):e._v31._move(ctx,id,2)
  848:
   var old=e.players[p].hand.duplicate(true);e.players[p].hand=[]
   for c in old:e._discard(p,c,"hand")
   e._draw(p,2);e.gain_actions(p,2)
  849:e._draw(p,2);pick(ctx,"hand_shuffle",p,"hand",indices(p,"hand"))
  850:
   if not e._valid_fighter(fid):return true
   e._damage_many(e.fighters.filter(func(f):return int(f.id)!=fid and e._valid_fighter(int(f.id))and e._same_zone(int(e.fighters[fid].node),int(f.node))).map(func(f):return int(f.id)),1)
  851:
   if stage=="during":ctx.value=destiny(p)
   elif not ctx.won:e._heal(hero,2)
  852:pancakes(ctx,[])
  853:
   e.players[p].hb_effect_immune=e.turn_number
   if not anung(p):e._v31._cancel(ctx)
  854:_options("posthumous",["Каждый союзник лечит 1 здоровье","Нанести 1 урон любому бойцу","Переместить любого бойца на 3"],ctx)
  855:
   if not anung(p):e._v31._move(ctx,hero,1)
   choose_fighter(ctx,e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.fighters_adjacent(fid,int(f.id))).map(func(f):return int(f.id)),"move",{"spaces":1},true)
  12:
   if ctx.won:e._v33.select_move(ctx,[fid,foe],4)
  819:
   if e.fighters_adjacent(fid,foe):view(ctx,"only")
  820:
   if e.fighters_adjacent(fid,foe):var other=e._v6._other(ctx);other.value=maxi(0,int(other.value)-3)
  822:
   e.players[p].hb_next_attack=int(e.players[p].get("hb_next_attack",0))+1
   _queue({"kind":"gain_action","amount":1},ctx);_queue({"kind":"v35_friendly_move","spaces":1},ctx);_queue({"kind":"v35_friendly_heal","amount":1},ctx)
  823:
   var other=int(ctx.opponent_owner)
   if other>=0:e.players[other].no_draw_turn=e.turn_number;e.players[other].no_actions_turn=e.turn_number
  824:choose_fighter(ctx,e._v33.foes(p).filter(func(i):return e.fighters_adjacent(fid,i)),"concussion")
  825:e._draw(p,1);e.gain_actions(p,1)
  826:
   e._v31._move(ctx,hero,3)
   var ids=range(e.players.size()).filter(func(i):return e.is_enemy(p,i)and not e.is_dormant(i))
   if human(p):_options("view_player",ids.map(func(i):return e._player_name(i)),ctx,{"ids":ids,"mode":"top"})
   elif not ids.is_empty():var c=ctx.duplicate(true);c.opponent_owner=int(ids[0]);view(c,"top")
  827:
   if stage=="immediately":e._v31._move(ctx,hero,2)
   else:e.gain_actions(p,1)
  829:
   var prediction=int(e._combat_resolution.ctx.get("hb_prediction_"+str(ctx.get("_combat_slot","a")),-1));var other=e._v6._other(ctx)
   if prediction>=0 and not other.card.is_empty()and prediction==int(other.card.get("value",0)):ctx.value+=2
  830:
   var ids=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero and not e._valid_fighter(int(f.id))).map(func(f):return int(f.id))
   if ids.is_empty():ids=e.fighters.filter(func(f):return int(f.owner)==p and not f.hero).map(func(f):return int(f.id))
   _queue({"kind":"v35_friendly_move","spaces":2},ctx);choose_fighter(ctx,ids,"revive",{"where":"zone","health":1})
  831:
   if stage=="during":
    if e.changed_start_space(fid):ctx.value=4
   else:_queue({"kind":"opponent_discard","amount":1},ctx)
  832:
   if stage=="immediately":e._v31._cancel(ctx)
   else:pick(ctx,"recover_scheme",p,"discard",indices(p,"discard",["scheme"]))
  2:e._v31._cancel(ctx)
  20,13:e._draw(p,1)
  620:incinerate(ctx)
  856:
   if stage=="immediately":
    if e._valid_fighter(foe):e.fighters[foe].locked_until=e.turn_number
   elif e._valid_fighter(hero):e._damage_many(e._v33.foes(p).filter(func(i):return e._same_zone(int(e.fighters[hero].node),int(e.fighters[i].node))),1)
  857:e._draw(p,1);e._v31._move(ctx,hero,5,true)
  858:
   var defender=int(e._combat_resolution.ctx.target)
   e._damage_many(e._v33.foes(p).filter(func(i):return e.fighters_adjacent(defender,i)),1)
  859:
   if stage=="during":
    if not e.players[p].deck.is_empty():var c=e.players[p].deck.pop_front();ctx.value+=int(c.get("boost",0));e._discard(p,c,"deck")
   else:e.gain_actions(p,1)
  860:
   for who in[p,int(ctx.opponent_owner)]:
    if who>=0:e._force_discard(who,1,true)
   e._draw(p,1)
   if int(ctx.opponent_owner)>=0:e._draw(int(ctx.opponent_owner),1)
  861:_queue({"kind":"v35_bottom_hand","left":2},ctx)
  862:_queue({"kind":"v35_discard_shuffle","left":3},ctx)
  863:_queue({"kind":"gain_action","amount":1},ctx);pick(ctx,"discard_shuffle",p,"discard",indices(p,"discard",["attack","defense","versatile"]))
  833:
   var kos=hero+1
   if e._valid_fighter(kos)and e._same_zone(int(e.fighters[hero].node),int(e.fighters[kos].node)):ctx.hb_redirect=kos
  834:place_return(ctx,hero+1,"closest",3)
  835:
   e._heal(hero+1,2)
   if e._valid_fighter(hero+1):_queue({"kind":"place","fixed_fighter":hero+1},ctx)
  836:
   if not e.players[p].get("ongoing",{}).is_empty():_queue({"kind":"heal","target":"hero","amount":1},ctx)
   choose_fighter(ctx,[fid,foe],"place")
  837:var attacker=int(e._combat_resolution.ctx.attacker);e._damage(attacker,1);e.gain_actions(int(e._combat_resolution.ctx.attack_owner),1)
  838:
   if not e.players[p].get("ongoing",{}).is_empty():_queue({"kind":"heal","target":"hero","amount":2},ctx)
   choose_fighter(ctx,e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.fighters_adjacent(fid,int(f.id))).map(func(f):return int(f.id)),"damage")
  840:e._draw(p,2);choose_fighter(ctx,e.fighters.filter(func(f):return f.hero and e._valid_fighter(int(f.id))).map(func(f):return int(f.id)),"place")
  841:choose_fighter(ctx,e.fighters.filter(func(f):return not f.alive and not f.get("reserve",false)and not f.get("offboard",false)).map(func(f):return int(f.id)),"revive",{"where":"zone","health":3})
  842:e._damage_many(e.fighters.filter(func(f):return int(f.id)!=hero and e._valid_fighter(int(f.id))and e._same_zone(int(e.fighters[hero].node),int(f.node))).map(func(f):return int(f.id)),1);e.gain_actions(p,1)
  843:
   for who in range(e.players.size()-1,-1,-1):
    if e.players[who].alive:_queue({"kind":"v35_secrecy","player":who},ctx)
  844:
   for who in range(e.players.size()-1,-1,-1):
    if e.players[who].alive:_queue({"kind":"v35_discard_shuffle","player":who,"left":2},ctx)
  845:
   var top=[]
   for i in range(mini(5,e.players[p].deck.size())):top.append(e.players[p].deck.pop_back())
   if not top.is_empty():
    if human(p):_options("bones",[],ctx,{"kind":"cards","cards":top,"indices":range(top.size())});e._refresh_card_options()
    else:bones(ctx,top,0)
  846:view(ctx,"memory")
  847:
   if not e.players[p].get("ongoing",{}).is_empty():
    _queue({"kind":"v35_discard_ongoing"},ctx);e._damage_many(e.fighters.filter(func(f):return int(f.id)!=hero and e._valid_fighter(int(f.id))and e._same_zone(int(e.fighters[hero].node),int(f.node))).map(func(f):return int(f.id)),2)
 return true
func bones(ctx: Dictionary,cards: Array,index: int):
 var p=int(ctx.owner);e.players[p].hand.append(cards.pop_at(index));e._shuffle(cards)
 for c in cards:e.players[p].deck.push_front(c)
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 e.pending_choice.clear();var ctx=_live(q._ctx);var p=int(ctx.owner);actor=p
 match str(q.action).trim_prefix("v35_"):
  "predict":
   var side="d"if q.defense else"a";e.pending_combat["hb_prediction_"+side]=index-1;e.pending_combat["hb_"+("defense"if q.defense else"attack")+"_predicted"]=true
   if index>0:
    if not q.defense:e.pending_combat.face_up=true
    e._log("Эйб объявляет значение: %d."%(index-1))
   if q.defense:e._resolve_combat(int(q.defense_index))
   else:resume_attack()
   return true
  "occult":
   if index==0:e._draw(p,2)
  "redirect":e._damage_raw(int(q.kos)if index==0 else int(q.fid),int(q.amount))
  "anung","hand_shuffle","bottom_hand","discard_shuffle","discard_bottom","recover_scheme","view_discard","view_top","memory_pick","secrecy_keep":apply_card(ctx,str(q.action).trim_prefix("v35_"),int(q.victim),str(q.source),int(q.indices[index]),q)
  "pancakes":pancake_selected(ctx,int(q.ids[index]),e._int_array(q.used))
  "posthumous":
   var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))).map(func(f):return int(f.id))
   if index==0:
    for id in e._v33.friends(p):e._heal(id,1)
   else:choose_fighter(ctx,ids,"damage"if index==1 else"move")
  "fighter":fighter_chosen(ctx,int(q.ids[index]),str(q.mode),q.extra)
  "return_space":returned(int(q.fid),int(q.nodes[index]),int(q.hp))
  "view_player":ctx.opponent_owner=int(q.ids[index]);view(ctx,str(q.mode))
  "memory_pay":memory_pay(ctx,int(q.victim),int(q.index),index==0)
  "secrecy_draw":secrecy_draw(ctx,int(q.player),index)
  "incinerate_offer":
   if index==0:incinerate_select(ctx,[])
  "incinerate_pick":
   var selected=e._int_array(q.selected);selected.append(int(q.indices[index]))
   if selected.size()<2:incinerate_select(ctx,selected)
   else:pay_incinerate(ctx,selected)
  "bones":bones(ctx,q.cards.duplicate(true),int(q.indices[index]))
  "batch_discard":
   var selected=e._int_array(q.selected);selected.append(int(q.indices[index]));batch_discard(ctx,int(q.victim),int(q.batch_count),int(q.batch_viewer),selected)
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 _resume();return true
func summary(p: int) -> String:
 if e._is_hero(p,"hellboy"):return "%s · судьба в сбросе: %d/6"%["Анунг Ун Рама: атаки Хеллбоя +2"if anung(p)else"Оккультный детектив",destiny(p)]
 if e._is_hero(p,"abe_sapien"):return "Интуиция: %d/2 · %s"%[int(e.players[p].get("intuition",0)),"Контрмагический щит"if ongoing_num(p)==825 else"щита нет"]
 if e._is_hero(p,"liz_sherman"):return "Горящих карт в руке: %d · %s"%[e.players[p].hand.filter(func(c):return c.get("burning",false)).size(),"Бой +1 до начала своего хода"if ongoing_num(p)==857 else"без постоянного бонуса"]
 if e._is_hero(p,"baba_yaga"):return "Договор: "+str(e.players[p].ongoing.name)if not e.players[p].get("ongoing",{}).is_empty()else"Договор не заключён"
 return ""

func refresh_forms():
 for p in range(e.players.size()):
  if not e._is_hero(p,"hellboy"):continue
  var form="anung"if anung(p)else"occult"
  if e.players[p].get("hell_form","occult")!=form:e._log("Хеллбой меняет способность: "+("Анунг Ун Рама"if form=="anung"else"Оккультный детектив"))
  e.players[p].hell_form=form
func estimate(card: Dictionary,fid: int,value: float,defending=false) -> float:
 if not card.has("hb_number"):return value
 var p=int(e.fighters[fid].owner);var n=num(card)
 match n:
  851:value=destiny(p)
  820:value+=2
  831:
   if e.changed_start_space(fid):value=4
  829:value+=0.7
  853:
   if not anung(p):value+=1.5
  859:
   if not e.players[p].deck.is_empty():value+=1.5
  856:value+=1
  833:
   if e._valid_fighter(e.hero_fighter(p)+1):value+=1
 if not defending and e.fighters[fid].hero and anung(p):value+=2
 return value+card_bonus(p)
func scheme_score(card: Dictionary,p: int,value: float) -> float:
 match num(card):
  848:return 5.0 if e.players[p].hand.size()<=3 else 0.5
  825,857:return 4.5
  852:return 4.0 if int(e.fighters[e.hero_fighter(p)].hp)<int(e.fighters[e.hero_fighter(p)].max_hp)-1 else 3.0
  841:return 5.0 if e.fighters.any(func(f):return int(f.owner)==p and not f.alive and not f.get("reserve",false))else 0.7
  844:return 2.5
  840,842,843:return 3.0
 return value

func batch_discard(ctx: Dictionary,victim: int,count: int,viewer: int,selected: Array=[]):
 var left=indices(victim,"hand").filter(func(i):return not selected.has(i))
 if selected.size()>=count or left.is_empty():
  selected.sort();selected.reverse()
  for i in selected:e._discard_from_opponent(victim,e.players[victim].hand.pop_at(int(i)))
  return
 _cards("batch_discard",victim,"hand",left,ctx,{"selected":selected,"batch_count":count,"batch_viewer":viewer})
 e.pending_choice.owner=viewer;e.pending_choice.viewer=viewer
