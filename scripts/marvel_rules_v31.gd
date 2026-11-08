extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v31_"+action
func small(fid: int) -> bool:
 return fid>=0 and fid<e.fighters.size() and e._is_hero(int(e.fighters[fid].owner),"squirrel_girl") and not e.fighters[fid].hero
func occupants(node: int) -> Array:
 return e.fighters.filter(func(f):return e._valid_fighter(int(f.id)) and e._v19.spaces(int(f.id)).has(node)).map(func(f):return int(f.id))
func squirrels(p: int) -> Array:
 return e.fighters.filter(func(f):return int(f.owner)==p and small(int(f.id)) and e._valid_fighter(int(f.id))).map(func(f):return int(f.id))
func can_end(fid: int,node: int) -> bool:
 if small(fid):return occupants(node).filter(func(id):return small(int(id)) and int(id)!=fid).size()<4
 return e._occupant(node) in [-1,fid]
func adjacent(node: int,fid: int) -> bool:
 return e.node_adjacent_to_fighter(node,fid) or (small(fid) and int(e.fighters[fid].node)==node)
func adjacent_count(p: int,fid: int) -> int:
 return squirrels(p).filter(func(n):return e.fighters_adjacent(int(n),fid)).size()
func zone_count(p: int,fid: int) -> int:
 return squirrels(p).filter(func(n):return e._same_zone(int(e.fighters[int(n)].node),int(e.fighters[fid].node))).size()
func setup(config: Dictionary):
 for p in range(e.players.size()):
  e.players[p].real_name=str(config.get("real_names",{}).get(str(p),""));e.players[p].deadpool_conditions=config.get("deadpool_conditions",{}).duplicate(true)
  if e._is_hero(p,"black_panther"):e.players[p].suit=[]
  if e._is_hero(p,"black_widow"):
   for pile in ["hand","deck"]:
    var at=e.players[p][pile].find_custom(func(c):return str(c.id)=="the_moscow_protocol")
    if at>=0:
     var c=e.players[p][pile].pop_at(at);e.players[p].hand.push_front(c)
     if pile=="hand":e._draw(p,1)
     break
  if e._is_hero(p,"squirrel_girl"):
   for f in e.fighters:
    if int(f.owner)==p and not f.hero:f.alive=false;f.reserve=true;f.node=-1
  if e._is_hero(p,"deadpool"):
   e.players[p].deadpool_conditions=config.get("deadpool_conditions",{}).duplicate(true);e.players[p].signed_names=[]
func start_turn() -> bool:
 if not e._is_hero(e.active,"squirrel_girl"):return false
 e._start_ability(e.active,"Вперёд, белки!",[{"kind":"v31_summon","where":"adjacent","amount":1,"empty":true}],"start_turn");return true
func summary(p: int) -> String:
 if p<0 or p>=e.players.size():return ""
 if e._is_hero(p,"black_panther"):return "В костюме: %d карт"%e.players[p].get("suit",[]).size()
 if e._is_hero(p,"squirrel_girl"):return "Белки на поле: %d/8"%squirrels(p).size()
 if e._is_hero(p,"black_widow"):return "Миссии в руке: %d"%e.players[p].hand.filter(func(c):return c.type=="scheme").size()
 if e._is_hero(p,"deadpool"):return "После атаки: восстановить 1 здоровье · условия в карточке персонажа"
 return ""
func mission_allowed(p: int,c: Dictionary) -> bool:
 if not e._is_hero(p,"black_widow") or c.type!="scheme":return true
 var hero=e.hero_fighter(p);var node=int(e.fighters[hero].node)
 match str(c.id):
  "the_moscow_protocol":return e.fighters.any(func(f):return e.is_enemy(p,int(f.owner)) and int(f.get("damaged_turn",-1))==e.turn_number)
  "the_budapest_gambit":return e.players[p].hand.size()<=3
  "the_firenze_agenda":return e.fighters.any(func(f):return f.hero and e.is_enemy(p,int(f.owner)) and e.fighters_adjacent(hero,int(f.id)))
  "the_kinshasa_directive":return node==int(e.board_data.get("starts",[0,4,24,20])[int(e.start_slots[p])])
  "the_madripoor_sanction":
   for other in range(e.players.size()):
    if e.is_enemy(p,other) and node==int(e.board_data.get("starts",[0,4,24,20])[int(e.start_slots[other])]):return true
   return false
 return true
func acquire(p: int):
 var revealed=[]
 while not e.players[p].deck.is_empty():
  var c=e.players[p].deck.pop_back();e._log("Поиск миссии: "+str(c.name))
  if c.type=="scheme":e.players[p].hand.append(c);break
  revealed.append(c)
 e.players[p].deck.append_array(revealed);e._shuffle(e.players[p].deck)
func _enemy(ctx: Dictionary,action: String):
 var ids=range(e.players.size()).filter(func(p):return e.is_enemy(int(ctx.owner),p) and not e.is_dormant(p))
 if ids.is_empty():return
 if human(int(ctx.owner)) and ids.size()>1:_options("enemy",ids.map(func(p):return e._player_name(p)),ctx,{"ids":ids,"next":action})
 else:_enemy_done(ctx,int(ids[0]),action)
func _enemy_done(ctx: Dictionary,p: int,action: String):
 ctx=ctx.duplicate(true);ctx.opponent_owner=p
 match action:
  "scan":store(ctx,2)
  "spies":
   var count=2 if e.fighters.any(func(f):return int(f.owner)==p and e._valid_fighter(int(f.id)) and adjacent_count(int(ctx.owner),int(f.id))>=4)else 1
   _queue({"kind":"reveal_choose_discard","amount":count},ctx)
  "kinshasa":_queue({"kind":"opponent_discard","amount":2},ctx)
  "fish":
   var names=[];var cards=[]
   for c in e.heroes[str(e.players[p].hero_id)].cards:
    if not names.has(str(c.id)):names.append(str(c.id));cards.append(c.duplicate(true))
   if human(int(ctx.owner)):_options("fish",cards.map(func(c):return str(c.name)),ctx,{"names":names})
   else:_fish(ctx,str(names[e.rng.randi_range(0,names.size()-1)]))
func _fish(ctx: Dictionary,id: String):
 var p=int(ctx.opponent_owner);var removed=false
 for i in range(e.players[p].hand.size()-1,-1,-1):
  if str(e.players[p].hand[i].id)==id:removed=e._discard_from_opponent(p,e.players[p].hand.pop_at(i)) or removed
 if not removed:e._draw(int(ctx.owner),1);e._log("Go fish!")
func store(ctx: Dictionary,count: int):
 var p=int(ctx.owner);var victim=int(ctx.opponent_owner)
 if victim<0:return
 for n in range(count):
  if e.players[victim].deck.is_empty():break
  var c=e.players[victim].deck.pop_back();c._suit_owner=victim;c._stolen_boost_effect=e._is_hero(victim,"houdini");e.players[p].suit.append(c);e._log("Вибраниумовый костюм: "+str(c.name))
func offer_boost(ctx: Dictionary,times=1):
 var p=int(ctx.owner);var cards=[];var refs=[]
 for pile in ["hand","suit"]:
  for i in range(e.players[p].get(pile,[]).size()):
   var c=e.players[p][pile][i]
   if e.can_boost_card(c):cards.append(c.duplicate(true));refs.append({"pile":pile,"index":i})
 if cards.is_empty():return
 if human(p):_options("boost",cards.map(func(c):return str(c.name)+" · BOOST "+str(c.boost)),ctx,{"kind":"cards","cards":cards,"refs":refs,"times":times},true)
 else:
  var best=0
  for i in range(cards.size()):
   if int(cards[i].boost)>int(cards[best].boost):best=i
  _boost(ctx,refs[best],times)
func _boost(ctx: Dictionary,ref: Dictionary,times: int):
 var p=int(ctx.owner);ctx=_live(ctx);var c=e.players[p][str(ref.pile)].pop_at(int(ref.index));ctx.value+=int(c.boost)
 if not e._flow.has("boosts"):e._flow.boosts=[]
 e._flow.boosts.append({"owner":p,"card":c.duplicate(true)});e._v8.boosted(p,c)
 if times>1:_queue({"kind":"v31_boost","times":times-1},ctx)
func suit_maneuver(p: int,index: int) -> bool:
 if p!=e.active or not e._is_hero(p,"black_panther") or index<0 or index>=e.players[p].suit.size():return false
 if not e.can_boost_card(e.players[p].suit[index]) or (e.phase=="action" and not e._can_act()):return false
 if e.phase!="action" and not(e.phase=="move"and not e.maneuver_boosted and e.maneuver_moved.is_empty()):return false
 var c=e.players[p].suit.pop_at(index);e.players[p].hand.append(c);var i=e.players[p].hand.size()-1
 return e.begin_maneuver(i)if e.phase=="action"else e.boost_maneuver(i)
func best_suit(p: int) -> int:
 var result=-1
 for i in range(e.players[p].get("suit",[]).size()):
  if e.can_boost_card(e.players[p].suit[i]) and (result<0 or int(e.players[p].suit[i].boost)>int(e.players[p].suit[result].boost)):result=i
 return result
func summon(ctx: Dictionary,fx: Dictionary):
 var p=int(ctx.owner);var hero=e.hero_fighter(p)
 if not e._valid_fighter(hero):return
 var reserve=e.fighters.filter(func(f):return int(f.owner)==p and small(int(f.id)) and not e._valid_fighter(int(f.id)))
 var pool=reserve.map(func(f):return int(f.id))if not reserve.is_empty()else squirrels(p)
 if pool.is_empty():return
 var ids=pool
 if reserve.is_empty() and human(p) and not fx.has("chosen"):
  _options("summon_source",ids.map(func(id):return "Белка #%d · клетка %d"%[int(id),int(e.fighters[int(id)].node)+1]),ctx,{"ids":ids,"fx":fx});return
 var fid=int(fx.get("chosen",pool[0]));var legal=[]
 for node in e.nodes:
  var n=int(node.id)
  if not can_end(fid,n):continue
  if fx.get("empty",false) and not occupants(n).is_empty():continue
  if fx.get("where","")=="adjacent" and not e.node_adjacent_to_fighter(n,hero):continue
  if fx.get("where","")=="hero" and n!=int(e.fighters[hero].node):continue
  legal.append(n)
 if legal.is_empty():return
 if human(p):_options("summon",legal.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":legal,"fid":fid,"fx":fx})
 else:
  var best=int(legal[0]);var value=-INF
  for node in legal:
   var score=e._position_score(hero,int(node))
   if score>value:value=score;best=int(node)
  _summoned(ctx,fid,best,fx)
func _summoned(ctx: Dictionary,fid: int,node: int,fx: Dictionary):
 e.fighters[fid].node=node;e.fighters[fid].alive=true;e.fighters[fid].hp=1;e.fighters[fid].reserve=false;e.fighters[fid].placed=true;e.fighters[fid].offboard=false
 e._log("Белка призвана: клетка %d"%(node+1))
 if int(fx.get("amount",1))>1:
  var next=fx.duplicate(true);next.amount=int(fx.amount)-1;next.erase("chosen");_queue(next,ctx)
func small_reach(fid: int,distance: int) -> Array[int]:
 var result:Array[int]=[];var origin=int(e.fighters[fid].node)
 if not e._valid_fighter(fid):return result
 if int(e.fighters[fid].get("locked_until",-1))==e.turn_number:return [origin]
 var queue=[[origin,0]];var seen={origin:true}
 while not queue.is_empty():
  var step=queue.pop_front();var node=int(step[0]);var cost=int(step[1])
  if can_end(fid,node):result.append(node)
  if cost>=distance or(node!=origin and e._enemy_trap_at(node,int(e.fighters[fid].owner))>=0):continue
  for n in e.nodes[node].get("move_neighbors",e.nodes[node].neighbors):
   if not seen.has(int(n)):seen[int(n)]=true;queue.append([int(n),cost+1])
 return result
func _move(ctx: Dictionary,fid: int,spaces: int,through=false):
 if e._v34.rail_eligible(fid,ctx):_queue({"kind":"v34_rail","fid":fid,"spaces":spaces},ctx);return
 if e._valid_fighter(fid):_queue({"kind":"move","fixed_fighter":fid,"spaces":spaces,"through_enemies":through},ctx)
func _move_own(ctx: Dictionary,spaces: int,through=false):
 for f in e.fighters:
  if int(f.owner)==int(ctx.owner) and e._valid_fighter(int(f.id)):_move(ctx,int(f.id),spaces,through)
func _select_move(ctx: Dictionary,ids: Array,spaces: int):
 ids=ids.filter(func(id):return e._valid_fighter(int(id)))
 if ids.is_empty():return
 if human(int(ctx.owner)) and ids.size()>1:_options("move_fighter",ids.map(func(id):return str(e.fighters[int(id)].name)),ctx,{"ids":ids,"spaces":spaces})
 else:_move(ctx,int(ids[0]),spaces)
func _cancel(ctx: Dictionary,after_only=false):
 var other=e._v6._other(ctx)
 if other.is_empty() or e._card_uncancellable(int(other.owner),other.card):return
 if after_only:other.no_after=true
 else:
  other.cancelled=true;e._effect_queue=e._effect_queue.filter(func(job):return job.ctx.get("_combat_slot","")!=other.get("_combat_slot","") or job.effect.get("intrinsic",false))
func _revive(ctx: Dictionary):
 var p=int(ctx.owner);var hero=e.hero_fighter(p);var fid=int(ctx.self)
 if e._valid_fighter(fid) or not e._valid_fighter(hero):return
 var legal=e.nodes.filter(func(n):return e.node_adjacent_to_fighter(int(n.id),hero)and can_end(fid,int(n.id))).map(func(n):return int(n.id))
 if legal.is_empty():return
 if human(p):_options("revive",legal.map(func(n):return "Клетка %d"%(n+1)),ctx,{"nodes":legal,"fid":fid})
 else:_revived(fid,int(legal[0]))
func _revived(fid: int,node: int):
 e.fighters[fid].alive=true;e.fighters[fid].hp=3;e.fighters[fid].node=node;e.fighters[fid].placed=true
func _widow_swap(ctx: Dictionary):
 var p=int(ctx.owner);var own=e.fighters.filter(func(f):return int(f.owner)==p and e._valid_fighter(int(f.id))).map(func(f):return int(f.id))
 if own.size()!=2 or not own.all(func(fid):return e._v13.can_relocate(int(fid))):return
 if human(p):_options("swap",["Поменяться местами","Пропустить"],ctx,{"ids":own})
 else:_swapped(ctx,own)
func _swapped(ctx: Dictionary,ids: Array):
 var a=int(ids[0]);var b=int(ids[1]);var n=int(e.fighters[a].node);e.fighters[a].node=e.fighters[b].node;e.fighters[b].node=n
 var old=int(ctx.self);var new=b if old==a else a;ctx.self=new;var other=e._v6._other(ctx);other.opponent=new
 if str(ctx.get("_combat_slot",""))=="d":e._combat_resolution.ctx.target=new;e.pending_combat.target=new
 else:e._combat_resolution.ctx.attacker=new;e.pending_combat.attacker=new
func _replace(ctx: Dictionary):
 var p=int(ctx.owner);var slot=str(ctx._combat_slot);var indices=[];var cards=[]
 for i in range(e.players[p].deck.size()):
  var c=e.players[p].deck[i]
  if (e._attack_type(c)if slot=="a"else e._defense_type(c)) and e._card_usable(c,int(ctx.self)):indices.append(i);cards.append(c.duplicate(true))
 if cards.is_empty():return
 if human(p):_options("replace",cards.map(func(c):return str(c.name)),ctx,{"kind":"cards","cards":cards,"indices":indices})
 else:
  var best=0
  for i in range(cards.size()):
   if int(cards[i].value)>int(cards[best].value):best=i
  _replaced(ctx,int(indices[best]))
func _replaced(ctx: Dictionary,index: int):
 var p=int(ctx.owner);var slot=str(ctx._combat_slot);e._discard(p,ctx.card,"played");var c=e.players[p].deck.pop_at(index);ctx.card=c;ctx.value=int(c.value)
 e._combat_resolution.ctx["attack_card"if slot=="a"else"defense_card"]=c
 e._effect_queue=e._effect_queue.filter(func(job):return job.ctx.get("_combat_slot","")!=slot or job.effect.get("intrinsic",false))
 var added=[]
 for stage in ["immediately","during"]:
  for fx in c.effects:
   if fx.timing==stage:added.append(fx)
 for i in range(added.size()-1,-1,-1):_queue(added[i],ctx)
func _place(ctx: Dictionary,fid: int,legal: Array,mode="place",extra={}):
 legal=legal.filter(func(n):return can_end(fid,int(n))and(e._v13.can_relocate(fid)or int(n)==int(e.fighters[fid].node)))
 if legal.is_empty():return
 if human(int(ctx.owner)):
  var data={"nodes":legal,"fid":fid};data.merge(extra,true);_options(mode,legal.map(func(n):return "Клетка %d"%(int(n)+1)),ctx,data)
 else:
  e._enter_node(fid,int(legal[0]))
  if mode=="yellow" and int(extra.get("remaining",1))>1:_yellow(ctx,int(extra.remaining)-1,int(legal[0]))
func _yellow(ctx: Dictionary,remaining=2,exclude=-1):
 var legal=[]
 for node in e.nodes:
  if int(node.id)==exclude:continue
  var keys=e.board_data.get("zone_keys",[])
  if node.zones.any(func(z):return int(z)<keys.size() and str(keys[int(z)]) in ["yellow","gold","ochre","orange"]):legal.append(int(node.id))
 _place(ctx,int(ctx.self),legal,"yellow",{"remaining":remaining})
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 var kind=str(fx.kind);var p=int(ctx.owner);var fid=int(ctx.get("self",-1));var foe=int(ctx.get("opponent",-1));var id=str(ctx.card.get("id",""));var stage=str(fx.get("stage",""))
 if kind=="v31_boost":offer_boost(ctx,int(fx.get("times",1)));return true
 if kind=="v31_summon":summon(ctx,fx);return true
 if kind=="v31_acquire":acquire(p);return true
 if kind=="v31_recycle":
  if human(p):_cards("recycle",p,"discard",range(e.players[p].discard.size()),ctx,{"count":5,"chosen":[]})
  else:
   for n in range(mini(5,e.players[p].discard.size())):e.players[p].deck.append(e.players[p].discard.pop_back())
   e._shuffle(e.players[p].deck)
  return true
 if kind!="v31_card":return false
 match id:
  "feint","super_feint":
   if stage=="immediately":_cancel(ctx)
   elif stage=="after":e._draw(p,1)
  "analyze_and_adjust":store(ctx,1)
  "ancestral_insight":
   if ctx.won:store(ctx,1)
  "anti_metal_claws":ctx.value+=int(e._v6._other(ctx).card.get("boost",0));offer_boost(ctx)
  "wakanda_forever":offer_boost(ctx,2)
  "vibranium_shockwave","microweave_mesh","cha_ching":offer_boost(ctx)
  "cat_like_reflexes":
   if ctx.won:_select_move(ctx,[fid,foe],3)
  "evade":e._draw(p,1)
  "regroup":e._draw(p,2 if ctx.won else 1)
  "nanotriage_processor":
   e._heal(fid,1);var hero=e.hero_fighter(p)
   if e._valid_fighter(hero)and e._same_zone(int(e.fighters[hero].node),int(e.fighters[fid].node)):e._heal(hero,1)
  "stalking_panther":e.gain_actions(p,1);_move_own(ctx,3,true)
  "tactical_remote_scanning":_enemy(ctx,"scan")
  "acting_director_of_shield":_queue({"kind":"v31_recycle_scheme"},ctx);_move_own(ctx,3,true)
  "caught_in_a_web":_cancel(ctx,true)
  "double_identity":_widow_swap(ctx)
  "fake_out":
   if not ctx.won:e._draw(p,1);e.gain_actions(p,1)
  "life_model_decoy":_revive(ctx)
  "widows_kiss":
   if e._valid_fighter(foe):e.fighters[foe].locked_until=e.turn_number
  "widows_line":_move(ctx,foe,2)
  "widows_sting":_move(ctx,e.hero_fighter(p),3)
  "widows_bite":
   if ctx.won:_queue({"kind":"opponent_discard","amount":1},ctx)
  "the_moscow_protocol":e._draw(p,1);e.gain_actions(p,1);_queue({"kind":"v31_acquire"},ctx)
  "the_budapest_gambit":
   e._draw(p,5)
   for other in range(e.players.size()):
    if e.is_enemy(p,other)and not e.players[other].hand.is_empty():e._discard_from_opponent(other,e.players[other].hand.pop_at(e.rng.randi_range(0,e.players[other].hand.size()-1)))
   _queue({"kind":"v31_acquire"},ctx)
  "the_firenze_agenda":
   var hero=e.hero_fighter(p);e._damage_many(e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and e._same_zone(int(f.node),int(e.fighters[hero].node))).map(func(f):return int(f.id)),2);_queue({"kind":"v31_acquire"},ctx)
  "the_kinshasa_directive":_queue({"kind":"v31_acquire"},ctx);_enemy(ctx,"kinshasa")
  "the_madripoor_sanction":
   var hero=e.hero_fighter(p)
   for other in range(e.players.size()):
    if e.is_enemy(p,other)and int(e.fighters[hero].node)==int(e.board_data.get("starts",[0,4,24,20])[int(e.start_slots[other])]):e._damage_many(e.fighters.filter(func(f):return int(f.owner)==other).map(func(f):return int(f.id)),2)
   _queue({"kind":"v31_acquire"},ctx)
  "bite_of_steel":
   if zone_count(p,foe)>=4:ctx.value=5
  "call_of_the_mild":
   if stage=="during"and zone_count(p,fid)>=4:ctx.value=4
   elif stage=="after"and ctx.won:e._draw(p,2)
  "eat_nuts":e._heal(e.hero_fighter(p),2);_queue({"kind":"v31_summon","where":"adjacent","empty":true},ctx)
  "fuzzball_special":
   for sq in squirrels(p):_move(ctx,int(sq),3)
  "get_em_tippy_toe":_queue({"kind":"v31_summon","where":"any","amount":2},ctx)
  "horde_of_squirrels":
   var ids=e.fighters.filter(func(f):return e._valid_fighter(int(f.id))and adjacent_count(p,int(f.id))>=4).map(func(f):return int(f.id))
   if not ids.is_empty():
    if human(p):_options("damage",ids.map(func(n):return str(e.fighters[int(n)].name)+" · клетка %d"%(int(e.fighters[int(n)].node)+1)),ctx,{"ids":ids,"amount":2})
    else:
     var enemies=ids.filter(func(n):return e.is_enemy(p,int(e.fighters[int(n)].owner)))
     e._damage(e._best_public_target(enemies)if not enemies.is_empty()else int(ids[0]),2)
  "kick_butts":ctx.value+=adjacent_count(p,foe)
  "nutwork_of_spies":_enemy(ctx,"spies")
  "squirgility":_queue({"kind":"v31_squirgility"},ctx)
  "unbeatable_squirrel_girl":
   if adjacent_count(p,foe)>=4:_cancel(ctx);ctx.ignore_opponent_value=true
  "squirmish":_queue({"kind":"place","fixed_fighter":e.hero_fighter(p),"same_zone":true},ctx);_queue({"kind":"v31_summon","where":"hero"},ctx)
  "dash":_move(ctx,fid,3)
  "chimichanga_break":
   if physical(p,"food"):ctx.value=5
  "eat_me_deadpool":
   if stage!="after"or not ctx.won:e._log("Дэдпул: «Съешь меня!»")
  "and_for_my_next_move":
   if human(p):_options("next_move",["Нанести 2 урона","Переместиться до 3 клеток"],ctx)
   else:e._damage(foe,2)
  "three_of_hearts","push_to_teleport":e._draw(p,1)
  "gimme_gimme_chimichanga":e._draw(p,1);e._heal(fid,1)
  "dumpster_divin_deadpool":e._heal(fid,1);_queue({"kind":"v31_recycle"},ctx)
  "non_retinal_scan_access_to_danger_room":e._heal(fid,1);_queue({"kind":"reveal_hand"},ctx)
  "time_out_time_out_time_out":_replace(ctx)
  "holy_mackerel":_enemy(ctx,"fish")
  "sweeet":_yellow(ctx)
  "wanna_bet":e._log("Пари Дэдпула: проигравший угощает победителя напитком после партии.")
  "robs_pouch_and_shoe_emporium":_move(ctx,foe,1)
  "i_always_get_the_last_word":
   if str(ctx._combat_slot)=="a":e._damage(foe,1)
  "klunkin_heads":
   if ctx.won:e._damage_many(e.fighters.filter(func(f):return int(f.id)!=foe and e._valid_fighter(int(f.id))and e.is_enemy(p,int(f.owner))and e.fighters_adjacent(int(f.id),foe)).map(func(f):return int(f.id)),3)
  "deadpool_merc_for_hire_llc":
   if physical(p,"owns_set"):e._damage(foe,1)
  "exploding_card":
   if human(p):_options("explosion",["Произнёс звук взрыва: сила 4","Без звука: сила 1"],ctx)
   elif physical(p,"explosion"):ctx.value=4
  "passwords":
   var other=ctx.duplicate(true);other.owner=int(ctx.opponent_owner);other.opponent_owner=p;_queue({"kind":"reveal_choose_discard","amount":1},other)
  "gaze_of_stone":
   if ctx.won:
    if physical(int(ctx.opponent_owner),"mirror"):
     for f in e.fighters:
      if e._is_hero(int(f.owner),"medusa")and f.hero:e._damage(int(f.id),8)
    else:e._damage(foe,8)
  "excuse_me_while_i_grow_some_limbs":_queue({"kind":"opponent_discard","amount":2 if ctx.won else 1},ctx)
  "transit_card":_queue({"kind":"place","fixed_fighter":fid,"same_zone":true},ctx)
  "faint":e._heal(fid,2);e._log("Дэдпул падает в обморок и снова встаёт.")
  "call_me":
   var victim=int(ctx.opponent_owner);var name=real_name(victim)
   if stage=="during"and not name.is_empty()and e.players[p].get("signed_names",[]).has(name):ctx.value=4
   if stage=="after"and not name.is_empty()and not e.players[p].signed_names.has(name):e.players[p].signed_names.append(name)
  "i_m_not_wearing_pants":
   if stage=="during"and not physical(p,"sleeved"):ctx.value=5
   elif stage=="after":e._log("Дэдпул напоминает надеть штаны.")
  "they_have_an_amazing_buffet":
   e._heal(fid,2)
   if e._valid_fighter(fid)and int(e.fighters[fid].hp)==int(e.fighters[fid].max_hp):e._damage(fid,2)
 return true
func physical(p: int,key: String) -> bool:
 if p<0 or p>=e.players.size():return false
 return bool(e.players[p].get("deadpool_conditions",{}).get(key,false))
func real_name(p: int) -> String:
 if p<0 or p>=e.players.size():return ""
 return str(e.players[p].get("real_name","")).strip_edges().to_lower()
func extras(fx: Dictionary,ctx: Dictionary) -> bool:
 if fx.kind=="v31_recycle_scheme":
  var p=int(ctx.owner);var indices=range(e.players[p].discard.size()).filter(func(i):return e.players[p].discard[i].type=="scheme")
  if not indices.is_empty():
   if human(p):_cards("scheme_recycle",p,"discard",indices,ctx)
   else:e.players[p].deck.append(e.players[p].discard.pop_at(int(indices[0])));e._shuffle(e.players[p].deck)
  return true
 if fx.kind=="v31_squirgility":
  var fid=e.hero_fighter(int(ctx.owner));var legal=squirgility_reach(fid)
  _place(ctx,fid,legal);return true
 return false
func squirgility_reach(fid: int) -> Array:
 if not e._valid_fighter(fid):return []
 var start=int(e.fighters[fid].node);var costs={start:0};var queue=[start]
 if not e._v13.can_relocate(fid):return [start]
 while not queue.is_empty():
  var node=int(queue.pop_front())
  if node!=start and e._enemy_trap_at(node,int(e.fighters[fid].owner))>=0:continue
  for next in e.nodes[node].get("move_neighbors",e.nodes[node].neighbors):
   var n=int(next);var occ=e._occupant(n)
   if occ>=0 and e.is_enemy(int(e.fighters[fid].owner),int(e.fighters[occ].owner))and e.fighters[occ].hero:continue
   var sidekick=occupants(n).any(func(id):return not e.fighters[int(id)].hero);var cost=int(costs[node])+(0 if sidekick else 1)
   if cost<=3 and cost<int(costs.get(n,999)):costs[n]=cost;queue.append(n)
 return costs.keys().filter(func(n):return can_end(fid,int(n)))
func choose_option(index: int) -> bool:
 var q=e.pending_choice.duplicate(true)
 if index<0 or index>=q.options.size():return false
 e.pending_choice.clear();var ctx=_live(q._ctx);var mode=str(q.action).trim_prefix("v31_");var p=int(ctx.owner)
 match mode:
  "enemy":_enemy_done(ctx,int(q.ids[index]),str(q.next))
  "fish":_fish(ctx,str(q.names[index]))
  "boost":_boost(ctx,q.refs[index],int(q.times))
  "summon":_summoned(ctx,int(q.fid),int(q.nodes[index]),q.fx)
  "summon_source":var fx=q.fx.duplicate(true);fx.chosen=int(q.ids[index]);summon(ctx,fx)
  "move_fighter":_move(ctx,int(q.ids[index]),int(q.spaces))
  "revive":_revived(int(q.fid),int(q.nodes[index]))
  "swap":
   if index==0:_swapped(ctx,q.ids)
  "replace":_replaced(ctx,int(q.indices[index]))
  "place":e._enter_node(int(q.fid),int(q.nodes[index]))
  "yellow":
   e._enter_node(int(q.fid),int(q.nodes[index]))
   if int(q.remaining)>1:_yellow(ctx,int(q.remaining)-1,int(q.nodes[index]))
  "damage":e._damage(int(q.ids[index]),int(q.amount))
  "next_move":
   if index==0:e._damage(int(ctx.opponent),2)
   else:_move(ctx,int(ctx.self),3)
  "explosion":
   if index==0:ctx.value=4
  "scheme_recycle":e.players[p].deck.append(e.players[p].discard.pop_at(int(q.indices[index])));e._shuffle(e.players[p].deck)
  "recycle":
   var chosen=q.chosen;chosen.append(int(q.indices[index]));var remaining=range(e.players[p].discard.size()).filter(func(i):return not chosen.has(i))
   if chosen.size()<mini(int(q.count),e.players[p].discard.size()):
    _cards("recycle",p,"discard",remaining,ctx,{"chosen":chosen,"count":q.count})
   else:
    chosen.sort();chosen.reverse()
    for i in chosen:e.players[p].deck.append(e.players[p].discard.pop_at(int(i)))
    e._shuffle(e.players[p].deck)
 if not e.pending_choice.is_empty():e.changed.emit();return true
 _resume();return true
func skip() -> bool:
 if not e.pending_choice.get("can_skip",false):return false
 e.pending_choice.clear();_resume();return true
