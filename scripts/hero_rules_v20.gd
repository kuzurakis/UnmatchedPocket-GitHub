extends "res://scripts/hero_rules_v19.gd"
## State search uses a single fighter ID with two occupied spaces.
func orientations(fid: int, head: int) -> Array:
 var result=[]
 for back in e.nodes[head].neighbors:
  var tail=tail_for(head,int(back),fid)
  if e._occupant(head) not in [-1,fid] or (tail>=0 and e._occupant(tail) not in [-1,fid]):continue
  if not result.has(tail):result.append(tail)
 return result
func tail_for(head: int, back: int, fid=-1) -> int:
 if head==back:return -1
 if fid>=0 and e._is_hero(int(e.fighters[fid].owner),"svyatogor"):return back
 var overrides=e.board_data.get("large_single_edges",[])
 if overrides.any(func(pair):return pair.map(func(v):return int(v)).has(head) and pair.map(func(v):return int(v)).has(back)):return -1
 var delta=e.nodes[head].pos-e.nodes[back].pos
 var w=float(e.board_data.get("width",1000));var h=float(e.board_data.get("height",1000))
 return back if Vector2(delta.x*w,delta.y*h).length()<=float(e.board_data.get("node_radius",60))*3.4 else -1
func paths(fid: int, distance: int, through=false) -> Array:
 var start={"head":int(e.fighters[fid].node),"tail":int(e.fighters[fid].get("tail",-1)),"route":[]};var queue=[start];var seen={};var result=[]
 while not queue.is_empty():
  var s=queue.pop_front();var key=str(s.head)+":"+str(s.tail)
  if seen.has(key):continue
  seen[key]=true
  var cells=[int(s.head)]
  if int(s.tail)>=0:cells.append(int(s.tail))
  if cells.all(func(n):return e._occupant(int(n)) in [-1,fid]):result.append(s)
  if s.route.size()>=distance or int(e.fighters[fid].get("locked_until",-1))==e.turn_number:continue
  if not s.route.is_empty() and cells.any(func(n):return e._enemy_trap_at(int(n),int(e.fighters[fid].owner))>=0):continue
  for origin in cells:
   for n in e.nodes[int(origin)].neighbors:
    var head=int(n)
    if e._is_hero(int(e.fighters[fid].owner),"moose")and head==int(s.tail):continue
    var tail=tail_for(head,int(origin),fid);var occupied=[head]
    if tail>=0:occupied.append(tail)
    var blocked=false
    for cell in occupied:
     var occupant=e._occupant(int(cell))
     if occupant>=0 and occupant!=fid and e.is_enemy(int(e.fighters[fid].owner),int(e.fighters[occupant].owner)) and not through:blocked=true
    if not blocked:queue.append({"head":head,"tail":tail,"route":s.route+[{"head":head,"tail":tail}]})
 return result
func candidates(fid: int, node: int, distance: int, through=false) -> Array:
 return paths(fid,distance,through).filter(func(s):return int(s.head)==node)
func reach(fid: int, distance: int, through=false) -> Array[int]:
 var result:Array[int]=[]
 for s in paths(fid,distance,through):
  if not result.has(int(s.head)):result.append(int(s.head))
 return result
func offer(fid: int, node: int, operation: String, distance=0, through=false) -> bool:
 if not large(fid) or e.fighters[fid].has("chosen_tail"):return false
 if int(e.fighters[fid].get("locked_until",-1))==e.turn_number:return false
 var states=[]
 if operation=="move" or (operation=="effect" and e.pending_choice.kind=="move"):states=candidates(fid,node,distance,through)
 else:
  for tail in orientations(fid,node):states.append({"head":node,"tail":tail,"route":[]})
 if states.is_empty():return false
 var tails=[];var unique=[]
 for s in states:
  if not tails.has(int(s.tail)):tails.append(int(s.tail));unique.append(s)
 states=unique
 var chooser=e.active if operation=="move" or operation=="setup" else int(e.pending_choice.get("_ctx",{}).get("owner",e.active))
 if not human(chooser) or states.size()==1:
  var best=states[0];var value=-INF
  for state in states:
   var score=orientation_score(fid,state)
   if score>value:value=score;best=state
  e.fighters[fid].chosen_tail=int(best.tail);return false
 var labels=[]
 for state in states:labels.append("Голова: %d · хвост: %d"%[node+1,int(state.tail)+1] if int(state.tail)>=0 else "Голова: %d · база на одной клетке"%(node+1))
 var previous=e.pending_choice.duplicate(true);var phase=e.phase
 _options("orientation",labels,{"owner":chooser,"card":{"name":str(e.fighters[fid].name)}},{"states":states,"fighter_id":fid,"destination":node,"operation":operation,"previous":previous,"previous_phase":phase})
 e.changed.emit();return true
func orientation_score(fid: int, state: Dictionary) -> float:
 var score=0.0;var cells=[int(state.head)]
 if int(state.tail)>=0:cells.append(int(state.tail))
 for f in e.fighters:
  if not e._valid_fighter(int(f.id)) or not e.is_enemy(int(e.fighters[fid].owner),int(f.owner)):continue
  var distance=999
  for n in cells:
   for target in spaces(int(f.id)):distance=mini(distance,e._v14.board_distance(int(n),int(target)))
  if distance<=2:score+=3.0
  if distance<=1:score-=1.0 if e.fighters[fid].hp<8 else 0.0
 for n in cells:
  if e._enemy_trap_at(int(n),int(e.fighters[fid].owner))>=0:score-=10
 return score
func body(fid: int, node: int, old: int):
 if not large(fid):return
 if e.fighters[fid].has("chosen_tail"):
  var chosen=int(e.fighters[fid].chosen_tail);e.fighters[fid].erase("chosen_tail")
  if chosen!=node and (chosen<0 or (e.nodes[node].neighbors.has(chosen) and e._occupant(chosen) in [-1,fid])):
   if chosen>=0 or not e._is_hero(int(e.fighters[fid].owner),"svyatogor"):e.fighters[fid].tail=chosen;return
 if old<0:
  var legal=orientations(fid,node);e.fighters[fid].tail=int(legal[0]) if not legal.is_empty() else -1;return
 if node==old:
  if int(e.fighters[fid].get("tail",-1))==node or (e._is_hero(int(e.fighters[fid].owner),"svyatogor") and int(e.fighters[fid].get("tail",-1))<0):
   var legal=orientations(fid,node);e.fighters[fid].tail=int(legal[0]) if not legal.is_empty() else -1
  return
 var states=candidates(fid,node,e.nodes.size())
 if not states.is_empty():
  var best=states[0]
  for s in states:
   if orientation_score(fid,s)>orientation_score(fid,best):best=s
  e.fighters[fid].tail=int(best.tail)
 else:
  var legal=orientations(fid,node);e.fighters[fid].tail=int(legal[0]) if not legal.is_empty() else -1
func choose_option(index: int) -> bool:
 if e.pending_choice.get("action","")!="v19_orientation":return super.choose_option(index)
 var p=e.pending_choice.duplicate(true)
 if index<0 or index>=p.states.size():return false
 e.pending_choice=p.previous
 for key in ["legal","allowed_fighters","remaining","indices"]:
  if e.pending_choice.has(key):e.pending_choice[key]=e.pending_choice[key].map(func(v):return int(v))
 e.phase=p.previous_phase;e.fighters[int(p.fighter_id)].chosen_tail=int(p.states[index].tail)
 if p.operation=="move":return e.move_fighter(int(p.fighter_id),int(p.destination))
 if p.operation=="setup":return e.place_setup_fighter(int(p.fighter_id),int(p.destination))
 return e.choose_effect_node(int(p.destination))
