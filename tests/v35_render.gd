extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.35";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 var i=app.sets.find_custom(func(s):return s.id=="hellboy");app.set_option.select(i);app._set_changed(i);await shot("menu")
 app.engine.interactive=false
 await start(["hellboy","abe_sapien","liz_sherman","baba_yaga"],"bprd_hq")
 await finish_reports();app.engine.interactive=true;app.engine.players[1].intuition=2;app.engine.players[3].ongoing=card("baba_yaga","hb_841");app._refresh();await shot("game")
 app._show_hellboy_state(0);await shot("hellboy-forms");app._clear_popup()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang);app._refresh();app._show_player_info(0);await shot("hero-"+lang);app._clear_popup()
 app.I18n.set_language("ru");app._show_hellboy_state(3);await shot("baba-pact");app._clear_popup();app.engine.interactive=false
 await start(["liz_sherman","abe_sapien","hellboy","baba_yaga"],"pandemonium")
 await finish_reports();app._refresh();await shot("pandemonium")
 app.I18n.set_language("ru");app._save_ui_settings();print("V35_NATIVE_OK");quit()
