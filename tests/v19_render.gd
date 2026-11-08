extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.19";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru");app.set_option.select(16);app._set_changed(16);await shot("menu")
 await start(["t_rex","dr_ellie_sattler"],"t_rex_paddock");await shot("game")
 print("V19_UI_OK");quit()
