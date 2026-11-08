extends SceneTree
const Model=preload("res://tests/balance_policy_engine_v29.gd")
var results=[]
func _initialize():run.call_deferred()
func run():
 var args=OS.get_cmdline_user_args();var fan="svyatogor";var reps=2
 for arg in args:
  if arg.begins_with("--fan="):fan=arg.trim_prefix("--fan=")
  if arg.begins_with("--reps="):reps=int(arg.trim_prefix("--reps="))
 var catalog=Model.new();var opponents=[]
 for hid in catalog.heroes:
  if not catalog.heroes[hid].get("fan",false):opponents.append(str(hid))
 opponents.append("mikula" if fan=="svyatogor" else "svyatogor")
 var began=Time.get_ticks_msec()
 for opponent in opponents:
  for map in ["marmoreal","sarpedon","soho"]:
   for rep in range(reps):
    for order in range(2):
     var ids=[fan,opponent]if order==0 else[opponent,fan];var fan_owner=0 if order==0 else 1
     var seed=710000+rep*1009+["marmoreal","sarpedon","soho"].find(map)*37
     var g=Model.new();g.interactive=false;var slots=[0,1] if rep%2==0 else[1,0]
     g.setup(ids,2,seed,map,{"start_slots":slots,"buffy_sidekick":"giles"if rep%2==0 else"xander","sorceress_hero":"yennefer"if rep%2==0 else"triss"})
     for p in g.players:p.bot=true
     var steps=0;var stuck="";var near_steps=0;var fan_steps=0
     while g.winner<0 and steps<2500 and g.turn_number<300:
      if g.active==fan_owner and g.phase=="action":
       fan_steps+=1
       if fan=="mikula" and g._v29.near(fan_owner,g.hero_fighter(fan_owner)):near_steps+=1
      match g.phase:
       "action","move","discard":g.bot_step()
       "attack_notice":g.continue_attack()
       "combat_report":g.continue_combat()
       "effects":g._pump_effects()
       _:
        stuck=g.phase;break
      steps+=1
     var won=g.winner==fan_owner;var hp=0;var max_hp=0
     for f in g.fighters:
      if int(f.owner)==g.winner and f.hero:hp+=maxi(0,int(f.hp));max_hp+=int(f.max_hp)
     results.append({"fan":fan,"opponent":opponent,"map":map,"rep":rep,"seed":seed,"fan_first":order==0,"slots":slots,"winner":str(g.players[g.winner].hero_id)if g.winner>=0 else"","fan_won":won,"finished":g.winner>=0,"stuck":stuck,"turns":g.turn_number,"steps":steps,"winner_hp":hp,"winner_max_hp":max_hp,"fan_hp":int(g.fighters[g.hero_fighter(fan_owner)].hp),"pouch_active_steps":near_steps,"fan_action_steps":fan_steps})
  var f=FileAccess.open("res://../../work/balance-v29/"+fan+"-policy.json",FileAccess.WRITE);f.store_string(JSON.stringify(results));f.close()
  print("BALANCE ",fan," ",opponent," matches=",results.size()," elapsed=",(Time.get_ticks_msec()-began)/1000.0)
 print("BALANCE_DONE ",fan," ",results.size());quit()
