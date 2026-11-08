extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.36";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 var i=app.sets.find_custom(func(s):return s.id=="tmnt_villains");app.set_option.select(i);app._set_changed(i);await shot("menu")
 app.engine.interactive=false;await start(["shredder","krang","svyatogor","mikula"],"marmoreal");await finish_reports()
 app.engine.players[0].foot=[[0,1],[1,2],[2,3],[12,13],[13,14]];app._refresh();await shot("board")
 app.engine.interactive=true;app.engine.players[0].bot=false;app.engine._v36.start_turn();app._refresh();await shot("foot-deploy")
 app.engine.interactive=false;await start(["krang","shredder"],"sarpedon");await finish_reports();app.engine.interactive=true;app.engine.players[0].bot=false;app.engine.players[0].hand=[card("krang","tmntv_754")];app.engine.scheme(0,0);app._refresh();await shot("krang-roll")
 app.I18n.set_language("en");app._refresh();await shot("krang-en")
 app.I18n.set_language("ru");app.engine.interactive=false;await start(["svyatogor","krang"],"marmoreal");await finish_reports();app._show_player_info(0);await shot("svyatogor")
 app.I18n.set_language("ru");app._save_ui_settings();print("V36_NATIVE_OK");quit()
