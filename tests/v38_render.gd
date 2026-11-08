extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.38";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 var i=app.sets.find_custom(func(s):return s.id=="fan_giants_nature");app.set_option.select(i);app._set_changed(i);await shot("menu")
 app.engine.interactive=false;await start(["godzilla","kraken","birds","moose"],"marmoreal");await finish_reports();app._refresh();await shot("game")
 app.engine.players[0].discard=[card("godzilla","nature_godzilla_8"),card("godzilla","nature_godzilla_9")];app.engine._v38.add_charge(0,0,2);app._show_nature_state(0);await shot("charge");app._clear_popup()
 for lang in ["ru","en","nb","es"]:
  app.I18n.set_language(lang);app._show_hero_info("mikula");await shot("mikula-"+lang);app._clear_popup()
 app.I18n.set_language("ru");app._save_ui_settings();print("V38_NATIVE_OK");quit()
