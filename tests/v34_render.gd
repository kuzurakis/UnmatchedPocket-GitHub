extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.34";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 var i=app.sets.find_custom(func(s):return s.id=="stars_stripes");app.set_option.select(i);app._set_changed(i);await shot("menu")
 app.engine.interactive=false
 await start(["rosie_the_riveter","george_washington","john_henry","wyatt_earp"],"the_white_house")
 await finish_reports();app.engine.interactive=true;app.engine.players[0].upgrade_active=[0,1,2,3];app.engine._v34.sync_rosie(0);app._refresh();await shot("game")
 app._show_rosie_upgrades(0);await shot("rosie-upgrades");app._clear_popup()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang);app._refresh();app._show_player_info(0);await shot("hero-"+lang);app._clear_popup()
 app.I18n.set_language("ru");app.engine.interactive=false
 await start(["john_henry","wyatt_earp","george_washington","rosie_the_riveter"],"the_alamo")
 await finish_reports();app.engine.players[0].tracks=[0,1,2,3,4,5];app._refresh();await shot("the-alamo")
 app.I18n.set_language("ru");app._save_ui_settings();print("V34_NATIVE_OK");quit()
