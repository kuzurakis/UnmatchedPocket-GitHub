extends "res://tests/v23_render.gd"
func run():
 folder="res://../../work/verification-v0.28";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();assert(app.sets[-1].fan and app.heroes[-1].id=="svyatogor")
 app.I18n.set_language("ru");app.set_option.select(app.sets.size()-1);app._set_changed(app.sets.size()-1);await shot("fan-menu")
 await start(["svyatogor","king_arthur"],"marmoreal");await shot("svyatogor-ru");app._show_player_info(0);await shot("hero-ru");app._close_popup()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang);app._show_player_info(0);await settle();assert(not has_ru(app.popup_layer));app._close_popup()
 app.I18n.set_language("en");app._refresh();await shot("svyatogor-en")
 print("V28_UI_LANGUAGES_OK");quit()
