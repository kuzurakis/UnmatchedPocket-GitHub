extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.37";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru");app.level_option.select(3);await shot("master-menu")
 app.I18n.set_language("ru");app._save_ui_settings();print("V37_NATIVE_OK");quit()
