extends "res://tests/v35_ui_tests.gd"
func run():
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();expect(app.level_option.item_count==4,"four skill levels")
 for code in ["ru","en","nb","es"]:
  Lang.set_language(code);app._return_menu();await settle();app.level_option.select(3);app._localize();expect(app.level_option.get_item_text(3)==Lang.text("Мастер"),"Master translated "+code)
 Lang.set_language("ru");app._save_ui_settings();print("V37_UI checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
