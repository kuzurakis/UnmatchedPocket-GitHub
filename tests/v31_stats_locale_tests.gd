extends "res://tests/v31_ui_tests.gd"
func audit(node: Node):
 var rx=RegEx.new();rx.compile("[А-Яа-яЁё]")
 if node is Label or node is Button:
  expect(rx.search(node.text)==null,"translated stat popup: "+node.text)
 for child in node.get_children():audit(child)
func run():
 root.size=Vector2i(1280,720);app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop()
 for lang in ["en","nb","es"]:
  Lang.set_language(lang);app._show_hero_info("svyatogor");await settle();app._localize();audit(app.popup_layer);app._clear_popup()
 print("V31_STATS_LOCALE checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
