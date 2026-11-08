extends "res://scripts/mikula_rules_v29.gd"
func _init(engine):super(engine)
func _bag(ctx: Dictionary,distance=-1,zone=false,free=false,optional=false):
 if human(int(ctx.owner)):super._bag(ctx,distance,zone,free,optional);return
 var owner=int(ctx.owner);var p=int(ctx.get("bag_owner",owner));var previous=e.pending_choice.duplicate(true);var phase=e.phase;var interactive=e.interactive;var bot=e.players[owner].bot
 e.interactive=true;e.players[owner].bot=false
 super._bag(ctx,distance,zone,free,optional)
 var nodes=e.pending_choice.get("nodes",[]).duplicate();e.pending_choice=previous;e.phase=phase;e.interactive=interactive;e.players[owner].bot=bot
 if nodes.is_empty():return
 var hero=e.hero_fighter(p);var chosen=int(nodes[0]);var best=-INF
 for n in nodes:
  var distance_to_hero=e._v14.board_distance(int(e.fighters[hero].node),int(n));var score=float(distance_to_hero)*(1 if e.is_enemy(owner,p) else -1)
  if score>best:best=score;chosen=int(n)
 e.players[p].pouch_node=chosen
