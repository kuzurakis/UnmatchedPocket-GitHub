extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.32";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 var i=app.sets.find_custom(func(s):return s.id=="bol3");app.set_option.select(i);app._set_changed(i);await shot("menu")
 app.engine.interactive=false
 await start(["blackbeard","loki","chupacabra","pandora"],"venice")
 app.engine.interactive=true;await finish_reports();app._refresh();await shot("venice")
 app._show_legends_state(0);await shot("blackbeard");app._clear_popup()
 app._show_misery_reference();await shot("pandora-reference");app._clear_popup()
 app.engine.interactive=false
 await start(["loki","blackbeard","chupacabra","pandora"],"santas_workshop")
 app.engine.interactive=true;await finish_reports();app._refresh();await shot("santas-workshop")
 var e=app.engine
 for c in e.heroes.loki.cards:
  if c.get("trick",false):
   var t=c.duplicate(true);t.trick_owner=0;e.players[1].hand.append(t);break
 app._show_legends_state(0);await shot("loki-tricks");app._clear_popup()
 app.I18n.set_language("en");app._show_misery_reference();await shot("pandora-reference-en");app._clear_popup()
 print("V32_NATIVE_OK");quit()
