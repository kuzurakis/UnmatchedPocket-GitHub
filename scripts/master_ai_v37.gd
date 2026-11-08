extends RefCounted
## Bounded information-set search. Simulation uses the real card/board engine.
var ref
var sim
var e:
 get:return ref.get_ref()
func _init(engine):ref=weakref(engine)
func shuffle_with(cards: Array,r: RandomNumberGenerator):
 for i in range(cards.size()-1,0,-1):
  var j=r.randi_range(0,i);var tmp=cards[i];cards[i]=cards[j];cards[j]=tmp
func world(seed_value: int):
 if sim==null:sim=e.get_script().new()
 sim.load_state(e.save_state());sim.difficulty=2;sim.interactive=false;sim._busy=false
 var r=RandomNumberGenerator.new();r.seed=seed_value
 for p in range(sim.players.size()):
  sim.players[p].bot=true;sim.players[p].ai_skill=2
  if p==e.active:
   shuffle_with(sim.players[p].deck,r)
   continue
  # Public deck list minus public discards/ongoing cards. Never inspect hidden IDs.
  var pool=[]
  for definition in e.heroes[str(e.players[p].hero_id)].cards:
   for i in range(int(definition.get("count",1))):pool.append(definition.duplicate(true))
  var visible=e.players[p].discard.duplicate();var ongoing=e.players[p].get("ongoing",{})
  if not ongoing.is_empty():visible.append(ongoing)
  for player in e.players:
   for c in player.get("charge",[]):
    if int(c.get("charge_owner",-1))==p:visible.append(c)
  for c in visible:
   var at=pool.find_custom(func(x):return str(x.id)==str(c.id))
   if at>=0:pool.remove_at(at)
  shuffle_with(pool,r)
  var hand_count=e.players[p].hand.size();var deck_count=e.players[p].deck.size()
  sim.players[p].hand=pool.slice(0,mini(hand_count,pool.size()))
  sim.players[p].deck=pool.slice(mini(hand_count,pool.size()),mini(hand_count+deck_count,pool.size()))
 sim.rng.seed=seed_value+7919
 return sim
func step(g):
 match g.phase:
  "action":g._bot_action()
  "move","discard":g.bot_step()
  "attack_notice":g.continue_attack()
  "defend":g.defend(g._choose_defense(int(g.pending_combat.target),int(g.pending_combat.attacker)))
  "combat_report":g.continue_combat()
  "effect_choice":
   if not g.choose_effect_option(0):g.skip_effect()
  "effect_move":
   if int(g.pending_choice.get("fighter",-1))<0 and not g.pending_choice.get("allowed_fighters",[]).is_empty():g.choose_effect_fighter(int(g.pending_choice.allowed_fighters[0]))
   if not g.pending_choice.get("legal",[]).is_empty():g.choose_effect_node(int(g.pending_choice.legal[-1]))
   else:g.skip_effect()
func settle(g,until_turn: int):
 for i in range(48):
  if g.winner>=0 or g.turn_number>=until_turn:return
  step(g)
func value(g,p: int) -> float:
 if not g.players[p].alive:return -150.0
 var result=0.0
 for f in g.fighters:
  if int(f.owner)!=p or not f.alive:continue
  result+=float(f.hp)*(1.45 if f.hero else 0.6)
  if f.hero and int(f.hp)<=4:result-=5.0
 var hand=g.players[p].hand
 result+=minf(7,hand.size())*1.8
 for c in hand:result+=g._card_quality(c)*0.10
 var defense=hand.filter(func(c):return g._defense_type(c)).size()
 if defense==0:result-=3.5
 result+=minf(12,g.players[p].deck.size())*0.24
 if g.players[p].deck.is_empty():result-=5.0
 var resources={"rage":0.8,"machines":1.1,"coils":1.3,"ruses":0.7,"doubloons":0.6,"intuition":0.7}
 for k in resources:result+=float(g.players[p].get(k,0))*resources[k]
 result+=g._voyages(p)*1.6 if g._is_hero(p,"sinbad")else 0.0
 result+=g._v36.feet(p).size()*0.65
 for k in ["insight","tracks","upgrade_active"]:
  var resource=g.players[p].get(k,[])
  if resource is Array:result+=resource.size()*0.6
 return result
func evaluate(g,p: int) -> float:
 if g.winner>=0:return 300.0 if g.are_allies(p,g.winner)else -300.0
 var result=value(g,p);var threats=[]
 for q in range(g.players.size()):
  if q==p:continue
  if g.are_allies(p,q):result+=value(g,q)*0.8
  elif g.players[q].alive:threats.append(value(g,q))
 if not threats.is_empty():result-=float(threats.max())*(0.85 if g.players.size()>2 else 1.0)
 return result
func apply(g,o: Dictionary) -> bool:
 match str(o.kind):
  "attack":return g.attack(int(o.fighter),int(o.target),int(o.card),int(o.get("boost",-1)))
  "scheme":return g.scheme(int(o.fighter),int(o.card))
  "item":g._v24.use(int(o.fighter),int(o.item));return true
  "maneuver":return g.begin_maneuver(int(o.get("boost",-1)))
 return false
func choose(options: Array) -> Dictionary:
 var candidates=options.duplicate(true);candidates.sort_custom(func(a,b):return float(a.score)>float(b.score))
 candidates=candidates.slice(0,5)
 if not candidates.is_empty()and candidates[0].kind=="attack"and e._is_hero(e.active,"arthur")and e.fighters[int(candidates[0].fighter)].hero:
  var boost_index=e._best_boost(e.active,int(candidates[0].card))
  if boost_index>=0:
   var boosted=candidates[0].duplicate(true);boosted.boost=boost_index;candidates.append(boosted)
 if e.actions_left>0:
  candidates.append({"kind":"maneuver"})
  var boost=e._best_boost(e.active)
  if boost>=0 and e.players[e.active].hand.size()>3:candidates.append({"kind":"maneuver","boost":boost})
 if candidates.is_empty():return {}
 var best=candidates[0];var best_score=-INF
 for option in candidates:
  var total=0.0;var worst=INF
  for sample in range(2):
   var seed_value=370003+e.turn_number*97+e.active*13+sample*1009
   var g=world(seed_value);var score=-1000.0
   if apply(g,option):
    settle(g,e.turn_number+2);score=evaluate(g,e.active)
   total+=score;worst=minf(worst,score)
  var score=total/2.0*0.8+worst*0.2
  if score>best_score:best_score=score;best=option
 return best
func defense(fid: int,attacker: int,choices: Array) -> int:
 var owner=int(e.fighters[fid].owner);var enemy=int(e.fighters[attacker].owner)
 var remaining=[]
 for c in e.heroes[str(e.players[enemy].hero_id)].cards:
  if not e._attack_type(c)or not e._card_usable(c,attacker):continue
  var used=e.players[enemy].discard.filter(func(x):return str(x.id)==str(c.id)).size()
  for i in range(maxi(0,int(c.get("count",1))-used)):remaining.append(c)
 var powers=[]
 if e.pending_combat.get("face_up",false):powers.append(float(e.pending_combat.attack_card.value))
 else:
  for c in remaining:powers.append(float(c.value))
 if powers.is_empty():powers=[4.0]
 var bonus=e._v13.attack_bonus(attacker)+e._v14.attack_bonus(attacker)+e._v35.attack_bonus(attacker)
 if e._is_hero(enemy,"alice")and e.alice_size.get(enemy,"big")=="big":bonus+=2
 if e._is_hero(enemy,"sinbad"):bonus+=e._voyages(enemy)
 var best=-1;var best_score=-INF
 var options=choices.duplicate();options.append(-1)
 for index in options:
  var c={}if int(index)<0 else e.players[owner].hand[int(index)]
  var strength=0.0 if c.is_empty()else float(c.value)
  if not c.is_empty():strength=e._v36.estimate(c,fid,attacker,e._v35.estimate(c,fid,e._v34.estimate(c,fid,e._v32.estimate(c,fid,attacker,strength,true),true),true))
  if not c.is_empty()and e._is_hero(owner,"alice")and e.alice_size.get(owner,"big")=="small":strength+=1
  var loss=0.0
  for power in powers:
   var damage=maxf(0.0,power+bonus-strength)
   if c.get("nature_hero","")=="kraken"and int(c.get("nature_number",0))==2:damage=ceil(damage/2.0)
   if c.get("nature_hero","")=="godzilla"and int(c.get("nature_number",0))==13:damage=floor(damage/2.0)
   if c.get("nature_hero","")=="birds"and int(c.get("nature_number",0))==9 and damage>=float(e.fighters[fid].hp)and e._v38.own(owner).size()>1:damage=1.0
   if not c.is_empty()and e._has_kind(c,"prevent_all_damage"):damage=0
   loss+=damage*(1.6 if e.fighters[fid].hero else 0.8)+(70.0 if damage>=float(e.fighters[fid].hp)else 0.0)
  var score=-loss/powers.size()
  if not c.is_empty():
   score-=1.0+e._card_quality(c)*0.18
   if e._has_kind(c,"cancel"):score+=1.7
   if e._has_kind(c,"draw"):score+=0.7
  if score>best_score:best_score=score;best=int(index)
 return best
