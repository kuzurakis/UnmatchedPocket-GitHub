extends "res://tests/v23_render.gd"
func run():
 folder="res://../../work/verification-v0.25";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 for map in ["hells_kitchen","the_raft","navy_pier","helicarrier","sanctum_sanctorum"]:
  app.I18n.set_language("ru");await start(["king_arthur","medusa"],map);await shot(map)
  app._show_board_items();await shot(map+"-items");app._close_popup()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang);app._show_board_items();await settle();assert(not has_ru(app.popup_layer));await shot("items-"+lang);app._close_popup()
 app.I18n.set_language("ru");app.engine.battlefield_items=[{"id":10,"node":int(app.engine.fighters[0].node),"used":false}];app.engine.players[0].hand=[card("king_arthur","momentous_shift")];var foe=app.engine.hero_fighter(1);app.engine.fighters[foe].node=int(app.engine.nodes[int(app.engine.fighters[0].node)].neighbors[0]);app.engine.players[1].hand=[];app.engine.attack(0,foe,0);app._refresh();await shot("combat-item-choice")
 print("V25_UI_LANGUAGES_OK");quit()
