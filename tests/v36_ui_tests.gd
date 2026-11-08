extends "res://tests/v35_ui_tests.gd"
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 var i=app.sets.find_custom(func(s):return s.id=="tmnt_villains");app.set_option.select(i);app._set_changed(i);await settle();expect(app.hero_buttons.size()==2 and app.heroes.size()==80 and app.sets[-1].fan,"last official duo and FAN ordering")
 for lang in ["ru","en","nb","es"]:
  Lang.set_language(lang)
  if app.started:app._return_menu();await settle()
  app.engine.interactive=false;app.engine.setup(["shredder","krang","svyatogor","mikula"],1,3636,"marmoreal");app._open_match();app.bot_timer.stop();await settle()
  for p in range(4):app._show_player_info(p);await settle();app._localize();audit35(app.popup_layer);app._clear_popup()
  app.engine.players[0].bot=false;app.engine.interactive=true;app.engine._v36.start_turn();app._refresh();await settle();app._localize();audit35(app.popup_layer)
  app.engine.choose_effect_option(0);app.engine.interactive=false
  while app.engine.phase=="combat_report":app.engine.continue_combat()
  app.engine.active=1;app.engine.phase="action";app.engine.interactive=true;app.engine.players[1].bot=false;app.engine.actions_left=2;app.engine.players[1].hand=[app.engine.heroes.krang.cards.filter(func(c):return c.id=="tmntv_754")[0].duplicate(true)];app.engine.scheme(app.engine.hero_fighter(1),0);app._refresh();await settle();app._localize();expect(app.popup_layer!=null,"Krang visible die choice");if app.popup_layer!=null:audit35(app.popup_layer)
  app._clear_popup()
 Lang.set_language("ru");app._save_ui_settings()
 print("V36_UI checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
