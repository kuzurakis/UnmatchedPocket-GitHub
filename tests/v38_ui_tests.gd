extends "res://tests/v35_ui_tests.gd"
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 var i=app.sets.find_custom(func(s):return s.id=="fan_giants_nature");app.set_option.select(i);app._set_changed(i);await settle();expect(app.hero_buttons.size()==4 and app.heroes.size()==84 and app.sets[-1].fan and app.sets[-2].fan,"four new FAN profiles, FAN sets last")
 for code in ["ru","en","nb","es"]:
  Lang.set_language(code)
  if app.started:app._return_menu();await settle()
  app.engine.interactive=false;app.engine.setup(["godzilla","kraken","birds","moose"],2,3838,"marmoreal");app._open_match();app.bot_timer.stop();await settle()
  for p in range(4):app._show_player_info(p);await settle();app._localize();audit35(app.popup_layer);app._clear_popup()
  app.engine.players[0].discard=[app.engine.heroes.godzilla.cards[0].duplicate(true)];app.engine._v38.add_charge(0,0,1);app._show_nature_state(0);await settle();app._localize();audit35(app.popup_layer);app._clear_popup()
 Lang.set_language("ru");app._save_ui_settings();print("V38_UI checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
