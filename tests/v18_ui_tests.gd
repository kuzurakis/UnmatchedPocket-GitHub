extends "res://tests/v17_ui_tests.gd"
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru");expect(app._playable_card_total()==1362,"catalog counts actual short decks")
 app.set_option.select(14);app._set_changed(14);await settle();expect(app.hero_buttons.size()==3,"Hell's Kitchen set has three decks")
 app.set_option.select(15);app._set_changed(15);await settle();expect(app.hero_buttons.size()==1,"Redemption Row filter currently Luke")
 app.engine.interactive=false;app.engine.setup(["elektra","bullseye","daredevil","luke_cage"],1,1818,"hells_kitchen",{"mode":"teams"});app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang)
  for owner in range(4):
   app._show_player_info(owner);await settle();expect(not has_cyrillic(app.popup_layer),"translated new hero sheet "+lang+str(owner));app._close_popup()
  app._refresh();await settle();expect(not has_cyrillic(app.game_ui),"new fighter names and states localized "+lang)
 app.I18n.set_language("ru");app.engine._damage(0,7);app.engine.active=0;app.engine.phase="action";app.engine._start_turn_ability();app._refresh();await settle()
 expect(app.popup_kind=="choice" and find_text(app.popup_layer,"Разместите бойца")!="","real resurrection placement popup visible")
 var before=JSON.stringify(app.engine.pending_choice);app._hide_popup();await settle();expect(not app.popup_layer.visible,"resurrection hides to inspect battlefield");app._restore_popup();await settle();expect(JSON.stringify(app.engine.pending_choice)==before and app.popup_layer.visible,"restoring does not answer resurrection")
 app._choose_effect_option(0);await settle();expect(app.engine.fighters[0].hp==9 and app.engine.pending_choice.action=="v18_resurrect","real button places hero and asks next ninja")
 print("V18_UI checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
