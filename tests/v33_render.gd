extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.33";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 var i=app.sets.find_custom(func(s):return s.id=="tmnt");app.set_option.select(i);app._set_changed(i);await shot("menu")
 app.engine.interactive=false
 await start(["donatello","leonardo","michelangelo","raphael"],"venice")
 await finish_reports();app.engine.interactive=true;app.engine.players[0].inventions=[721,722,724];app._refresh();await shot("game")
 app._show_player_info(0);await shot("donatello");app._clear_popup()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang);app._refresh();app._show_player_info(0);await shot("hero-"+lang);app._clear_popup()
 print("V33_NATIVE_OK");quit()
