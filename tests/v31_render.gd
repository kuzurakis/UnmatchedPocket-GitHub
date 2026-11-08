extends "res://tests/v07_render.gd"
func run():
 folder="res://../../work/verification-v0.31";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru")
 for i in range(app.sets.size()):
  if app.sets[i].id=="king_country":app.set_option.select(i);app._set_changed(i);break
 await shot("menu")
 app._show_deadpool_setup();await shot("deadpool-settings");app._clear_popup()
 await start(["black_panther","black_widow","squirrel_girl","deadpool"],"helicarrier",{"mode":"teams"})
 await finish_reports();app._refresh();await shot("game")
 var e=app.engine;var c=e.heroes.deadpool.cards[0].duplicate(true);c._suit_owner=3;e.players[0].suit=[c];app._show_suit(0);await shot("suit");app._clear_popup()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang)
  for owner in range(4):app._show_player_info(owner);await settle();app._clear_popup()
 app.I18n.set_language("ru");app._refresh()
 for i in range(4,8):
  if i<e.fighters.size()and e._v31.small(i):e.fighters[i].node=int(e.fighters[0].node);e.fighters[i].alive=true;e.fighters[i].reserve=false;e.fighters[i].placed=true
 app._refresh();await shot("small-fighters")
 print("V31_RENDER_READY")
 # Keep the test window available for an accessibility/screenshot observation.
 await create_timer(40).timeout
 print("V31_NATIVE_OK");quit()
