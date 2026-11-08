extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.20";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 await start(["t_rex","dr_ellie_sattler"],"t_rex_paddock");await shot("game")
 var g=app.engine;g.interactive=true;g.begin_maneuver();g.maneuver_distance=3
 for n in g.legal_moves(0):
  var states=g._v19.candidates(0,int(n),3);var tails=[]
  for s in states:
   if not tails.has(int(s.tail)):tails.append(int(s.tail))
  if tails.size()>1:g.move_fighter(0,int(n));break
 assert(g.pending_choice.get("action","")=="v19_orientation")
 app._refresh();await shot("orientation");var before=JSON.stringify(g.pending_choice);app._hide_popup();await shot("hidden");app._restore_popup();await settle();assert(JSON.stringify(g.pending_choice)==before)
 app._choose_effect_option(0);await settle();assert(g.phase=="move");await shot("chosen")
 print("V20_UI_OK");quit()
