extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.18";root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru");app.set_option.select(14);app._set_changed(14);await shot("menu")
 await start(["daredevil","bullseye","elektra","luke_cage"],"hells_kitchen",{"mode":"teams"});app.engine.players[0].hand=[]
 for id in ["through_adversity","man_without_fear","son_of_a_boxer","take_a_knee","devil_of_hell_s_kitchen"]:app.engine.players[0].hand.append(card("daredevil",id))
 app._refresh();await shot("game-ru");app._show_player_info(2);await shot("elektra");app._close_popup()
 app.engine.players[0].hand=[card("daredevil","through_adversity")];app.engine.scheme(0,0);app._refresh();await shot("route");app._hide_popup();await shot("route-hidden");app._restore_popup();app._close_popup()
 app.engine.interactive=false;await start(["luke_cage","bullseye"],"the_raft");app.engine.interactive=true;app.I18n.set_language("en");app._refresh();await shot("game-en")
 print("V18_RENDER_OK");quit()
