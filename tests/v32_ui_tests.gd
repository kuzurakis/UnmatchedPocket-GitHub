extends "res://tests/v31_ui_tests.gd"
func audit32(node: Node):
 var rx=RegEx.new();rx.compile("[А-Яа-яЁё]")
 if (node is Label or node is Button)and Lang.language!="ru":expect(rx.search(node.text)==null,"translated new UI "+Lang.language+": "+node.text)
 for child in node.get_children():audit32(child)
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 expect(app.heroes.size()==66 and app.sets[-1].fan,"66 profiles with FAN still last")
 var set_index=app.sets.find_custom(func(s):return s.id=="bol3");app.set_option.select(set_index);app._set_changed(set_index);await settle();expect(app.hero_buttons.size()==4,"four heroes in new set")
 for lang in ["ru","en","nb","es"]:
  Lang.set_language(lang)
  for hid in ["blackbeard","loki","chupacabra","pandora"]:
   if app.started:app._return_menu();await settle()
   app.engine.interactive=false;app.engine.setup([hid,"king_arthur"],1,3232,"venice");app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle();app._show_legends_state(0);await settle();app._localize();audit32(app.popup_layer);app._clear_popup()
  app._show_misery_reference();await settle();app._localize();audit32(app.popup_layer);expect(app.popup_layer!=null,"all seven misery cards reference "+lang);app._clear_popup()
 var c=app.engine.heroes.loki.cards[0].duplicate(true);c.trick_owner=0;var preview=preload("res://scripts/card_view.gd").new();preview.set_card(c,"king_arthur");expect(preview.card_hero_id=="loki"and not preview.card_image_path.is_empty(),"foreign Trick retains original scan and translated text");preview.free()
 Lang.set_language("ru")
 for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:root.size=size;app._show_misery_reference();await settle();expect(app.popup_layer!=null,"misery reference at "+str(size));app._clear_popup()
 print("V32_UI checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
