extends "res://scripts/hero_rules_v8.gd"
func _init(engine):super(engine)
func _options(action: String,labels: Array,ctx: Dictionary,extra={},optional=false):
 super._options(action,labels,ctx,extra,optional);e.pending_choice.action="v26_"+action
func run(fx: Dictionary,ctx: Dictionary) -> bool:
 if fx.kind!="v26_card":return false
 var fid=int(ctx.self);var foe=int(ctx.opponent)
 match int(fx.number):
  2:
   var other=e._v6._other(ctx)
   if not other.card.is_empty() and int(other.value)<=2:ctx.value+=2
  3:
   e._draw(int(ctx.owner),1)
   if int(ctx.get("damage_taken",0))>0:e._damage(foe,1)
  7:
   var slot="a" if str(ctx._combat_slot)=="d"else"d";var other=e._combat_resolution.get(slot,{})
   if not other.is_empty() and not e._card_uncancellable(int(other.owner),other.card):
    other.cancelled=true;e._effect_queue=e._effect_queue.filter(func(job):return job.ctx.get("_combat_slot","")!=slot or job.effect.get("intrinsic",false))
  9:
   if human(int(ctx.owner)):_options("pay",["Получить 2 урона: сила 6","Пропустить"],ctx)
   elif int(e.fighters[fid].hp)>2:e._damage(fid,2);ctx.value=6
  11:_queue({"kind":"v26_stomp"},ctx);_queue({"kind":"move","fixed_fighter":fid,"spaces":2},ctx)
  13:ctx.value+=int((int(e.fighters[fid].max_hp)-int(e.fighters[fid].hp))/6)
 return true
func extras(fx: Dictionary,ctx: Dictionary) -> bool:
 if fx.kind!="v26_stomp":return false
 var ids=e._v14._adjacent(int(ctx.self));e._damage_many(ids,1);return true
func choose_option(index: int) -> bool:
 if index not in [0,1]:return false
 var p=e.pending_choice.duplicate(true);e.pending_choice.clear();var ctx=_live(p._ctx)
 if index==0:e._damage(int(ctx.self),2);ctx.value=6
 _resume();return true
func skip() -> bool:return false
