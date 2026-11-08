extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.21";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 app.set_option.select(15);app._set_changed(15);await shot("menu")
 await start(["moon_knight","ghost_rider","ms_marvel","winter_soldier"],"helicarrier",{"mode":"teams"});await shot("game")
 app._show_player_info(1);await shot("ghost");app._close_popup()
 app.engine.phase="action";app.engine.active=1;app.engine.players[1].bot=false;app.engine.begin_maneuver();app._refresh();await shot("cycle")
 print("V21_UI_OK");quit()
