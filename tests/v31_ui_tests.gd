extends "res://tests/ui_tests.gd"
const Lang=preload("res://scripts/i18n.gd")
func node_text(node: Node,fragment: String) -> bool:
 if (node is Label or node is Button)and fragment in node.text:return true
 for child in node.get_children():
  if node_text(child,fragment):return true
 return false
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 expect(app.heroes.size()==62 and app.sets[-1].fan,"all four added and FAN stays last")
 for lang in ["ru","en","nb","es"]:
  Lang.set_language(lang);app._show_deadpool_setup();await settle();app._localize()
  expect(node_text(app.popup_layer,Lang.text("На столе есть еда")),"translated physical conditions "+lang);app._clear_popup()
  for hid in ["black_panther","black_widow","squirrel_girl","deadpool"]:
   if app.started:app._return_menu();await settle()
   app.engine.interactive=true;app.engine.setup([hid,"king_arthur"],1,3131,"marmoreal");app._open_match();app.bot_timer.stop();await settle();app._show_player_info(0);await settle()
   expect(node_text(app.popup_layer,(str(app.engine.heroes[hid].name) if lang=="ru" else Lang.hero_name(hid))),"new character information "+hid+":"+lang);app._clear_popup()
   if hid=="black_panther":
    var c=app.engine.heroes.king_arthur.cards[0].duplicate(true);c._suit_owner=1;app.engine.players[0].suit=[c];app._show_suit(0);await settle();expect(app.popup_layer!=null,"suit inventory accessible "+lang);app._clear_popup()
   if hid=="deadpool":app._show_deadpool_match(0);await settle();expect(app.popup_layer!=null,"Deadpool conditions visible in match "+lang);app._clear_popup()
 Lang.set_language("ru")
 if app.started:app._return_menu();await settle()
 app.engine.interactive=false;app.engine.setup(["squirrel_girl","king_arthur"],1,3131,"marmoreal");app.engine.interactive=true;app._open_match();app.bot_timer.stop();await settle()
 var hero=app.engine.hero_fighter(1);var node=int(app.engine.fighters[hero].node)
 for i in range(1,5):app.engine.fighters[i].node=node;app.engine.fighters[i].alive=true;app.engine.fighters[i].placed=true;app.engine.fighters[i].reserve=false
 app._show_space_fighters(app.engine._v31.occupants(node));await settle();expect(node_text(app.popup_layer,"Выбрать"),"shared space exposes each selectable squirrel");app._clear_popup()
 for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=size;app._show_deadpool_setup();await settle();expect(app.popup_layer!=null,"conditions scroll panel at "+str(size));app._clear_popup()
 print("V31_UI checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
