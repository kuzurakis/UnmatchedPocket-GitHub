extends "res://tests/v31_ui_tests.gd"
func audit35(node: Node):
 var rx=RegEx.new();rx.compile("[А-Яа-яЁё]")
 if (node is Label or node is Button)and Lang.language!="ru":expect(rx.search(node.text)==null,"translated Hellboy UI "+Lang.language+": "+node.text)
 for child in node.get_children():audit35(child)
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 var index=app.sets.find_custom(func(s):return s.id=="hellboy");app.set_option.select(index);app._set_changed(index);await settle();expect(app.hero_buttons.size()==4 and app.heroes.size()==78 and app.sets[-1].fan,"new set and FAN ordering")
 for lang in ["ru","en","nb","es"]:
  Lang.set_language(lang)
  if app.started:app._return_menu();await settle()
  app.engine.interactive=false;app.engine.setup(["hellboy","abe_sapien","liz_sherman","baba_yaga"],1,3434,"bprd_hq");app._open_match();app.bot_timer.stop();await settle()
  app.engine.players[1].ongoing=app.engine.heroes.abe_sapien.cards.filter(func(c):return c.id=="hb_825")[0];app.engine.players[3].ongoing=app.engine.heroes.baba_yaga.cards.filter(func(c):return c.id=="hb_841")[0]
  for owner in range(4):app._show_player_info(owner);await settle();app._localize();audit35(app.popup_layer);app._clear_popup()
  app._show_hellboy_state(0);await settle();app._localize();audit35(app.popup_layer);app._clear_popup()
  app.engine.phase="action";app.engine.actions_left=0;app.engine.active=0;app.engine._v34.grant_free(0);app._refresh();await settle();expect(app.move_finish_button.visible and app.maneuver_button.disabled,"only attack or explicit skip when normal actions exhausted")
  app._finish_move();expect(not app.engine._v34.has_free(0),"skip clears free attack")
 Lang.set_language("ru")
 for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:root.size=size;app._show_hellboy_state(0);await settle();expect(app.popup_layer!=null,"upgrade scroll at "+str(size));app._clear_popup()
 print("V35_UI checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
