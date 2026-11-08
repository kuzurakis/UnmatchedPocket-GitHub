extends "res://tests/v07_render.gd"
func has_ru(node: Node) -> bool:
 var regex=RegEx.new();regex.compile("[А-Яа-яЁё]")
 if (node is Label or node is Button) and regex.search(node.text)!=null:return true
 for child in node.get_children():
  if has_ru(child):return true
 return false
func run():
 folder="res://../../work/verification-v0.23";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));root.size=Vector2i(1280,720)
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();app.bot_timer.stop();app.I18n.set_language("ru");app.set_option.select(19);app._set_changed(19);await shot("menu")
 await start(["she_hulk","spider_man","doctor_strange","cloak_and_dagger"],"sanctum_sanctorum",{"mode":"teams"})
 if app.engine.phase=="effect_choice":app.engine.skip_effect()
 await finish_reports();app._refresh();await shot("game")
 for lang in ["en","nb","es"]:
  app.I18n.set_language(lang)
  for owner in range(4):
   app._show_player_info(owner);await settle();assert(not has_ru(app.popup_layer));app._close_popup()
  app._refresh();await shot("game-"+lang)
 print("V23_UI_LANGUAGES_OK");quit()
