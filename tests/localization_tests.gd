extends SceneTree

const I18n = preload("res://scripts/i18n.gd")
var checks = 0
var failures = 0
var untranslated: Dictionary = {}
var current_language = ""
var cyrillic = RegEx.new()
var app

func _initialize():
	cyrillic.compile("[А-Яа-яЁё]")
	run.call_deferred()

func expect(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("LOCALIZATION: " + label)

func settle():
	for i in range(4): await process_frame

func audit_text(value: String):
	if value == "Русский" or value.is_empty(): return
	if cyrillic.search(value) != null:
		untranslated[current_language + ": " + value] = true

func audit_tree(node: Node):
	if node is Control and not node.is_visible_in_tree(): return
	if node is OptionButton:
		for i in range(node.item_count): audit_text(node.get_item_text(i))
	elif node is Label or node is Button: audit_text(node.text)
	if node is TabContainer:
		for i in range(node.get_tab_count()): audit_text(node.get_tab_title(i))
	for child in node.get_children(): audit_tree(child)

func run():
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	for code in ["en", "nb", "es"]:
		current_language = code
		I18n.set_language(code)
		for h in app.heroes:
			for field in ["name", "ability"]:
				var rendered = I18n.hero_field(str(h.id), field, str(h[field]))
				expect(not rendered.is_empty() and cyrillic.search(rendered) == null, code + " hero " + str(h.id) + " " + field)
			for c in h.cards:
				for field in ["name", "text"]:
					var rendered = I18n.card_field(str(h.id), str(c.id), field, str(c[field]))
					expect(not rendered.is_empty() and cyrillic.search(rendered) == null, code + " card " + str(h.id) + "/" + str(c.id) + " " + field)
		for index in range(app.sets.size()):
			app.set_option.select(index)
			app._set_changed(index)
			await settle()
			audit_tree(app.menu_ui)
			for h in app.hero_buttons:
				app._show_hero_info(str(h.id))
				await settle()
				audit_tree(app.popup_layer)
				app._close_popup()
		app._show_help()
		await settle()
		audit_tree(app.popup_layer)
		app._close_popup()
		app._show_library()
		await settle()
		var tabs = app.popup_layer.find_children("*", "TabContainer", true, false)
		for t in tabs:
			for index in range(t.get_tab_count()):
				t.current_tab = index
				await settle()
				audit_tree(app.popup_layer)
		app._close_popup()
		app.placement_option.select(1)
		app._start_match()
		await settle()
		app._select_card(0)
		await settle()
		audit_tree(app.game_ui)
		expect(app.hand_box.get_child(0)._title.text.find("Робин") == -1, code + " hand card localized")
		app._show_discards()
		await settle()
		audit_tree(app.popup_layer)
		app._close_popup()
		app._show_log()
		await settle()
		audit_tree(app.popup_layer)
		app._close_popup()
		app._return_menu()
		await settle()
	for entry in untranslated: print("UNTRANSLATED ", entry.replace("\n", " | "))
	expect(untranslated.is_empty(), "visible strings translated; missing=" + str(untranslated.size()))
	I18n.set_language("ru")
	app._localize()
	app._save_ui_settings()
	app.started = false
	print("LOCALIZATION_TESTS checks=%d failures=%d untranslated=%d" % [checks, failures, untranslated.size()])
	quit(1 if failures else 0)
