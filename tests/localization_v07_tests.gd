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
	if current_language == "ru" or value == "Русский" or value.is_empty(): return
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

func count_card_previews(node: Node) -> int:
	var total = 1 if node.get_script() == preload("res://scripts/card_view.gd") else 0
	for child in node.get_children(): total += count_card_previews(child)
	return total

func check_hand_screens(code: String):
	app.engine.setup(["muhammad_ali", "buffy"], 0, 711, "training", {"buffy_sidekick":"giles"})
	app.engine.interactive = true
	for player in app.engine.players: player.bot = false
	var cards: Array = []
	for i in range(21): cards.append(app.engine.heroes.buffy.cards[i % app.engine.heroes.buffy.cards.size()].duplicate(true))
	app.engine.players[1].hand = cards.duplicate(true)
	app.engine._flow = {"kind":"ability", "stage":"effects", "owner":0, "card":{"name":"Рука противника"}, "completion":"action", "effect_logs":[]}
	app.engine.combat_report = {"kind":"ability", "stage":"effects", "owner":0, "title":"Рука противника", "effect_logs":[]}
	app.engine.phase = "effect_choice"
	app.engine.pending_choice = {"kind":"hand_view", "action":"view_hand", "title":"Трудно быть скромным", "prompt":"Посмотрите карты руки противника", "cards":cards.duplicate(true), "viewer":0, "victim":1, "options":["Продолжить"], "can_skip":false, "_ctx":{}}
	app._show_effect_choice()
	await settle()
	audit_tree(app.popup_layer)
	expect(count_card_previews(app.popup_layer) == 21, code + " every revealed card is visible in the scroll grid")
	var hand_before = JSON.stringify(app.engine.players[1].hand)
	app._zoom_effect_card(cards[20], "buffy")
	await settle()
	audit_tree(app.popup_layer)
	expect(app.popup_close_button.text == I18n.text("К открытой руке ←"), code + " zoom returns to revealed hand")
	app._close_popup()
	await settle()
	audit_tree(app.popup_layer)
	expect(count_card_previews(app.popup_layer) == 21, code + " zoom preserves complete revealed hand")
	expect(JSON.stringify(app.engine.players[1].hand) == hand_before, code + " inspecting a card preserves the hand")
	app._choose_effect_option(0)
	await settle()
	expect(app.engine.pending_choice.get("kind", "") != "hand_view", code + " explicit continue completes viewing")
	app.bot_timer.stop()
	app._clear_popup()
	app.engine.phase = "effect_choice"
	app.engine.pending_choice = {"kind":"hand_view", "title":"Рука противника", "prompt":"Рука противника пуста", "cards":[], "viewer":0, "victim":1, "options":["Продолжить"], "can_skip":false, "_ctx":{}}
	app._show_effect_choice()
	await settle()
	audit_tree(app.popup_layer)
	expect(count_card_previews(app.popup_layer) == 0, code + " empty hand renders without cards")
	app._clear_popup()
	app.engine.phase = "effect_choice"
	app.engine.pending_choice = {"kind":"cards", "action":"discard", "title":cards[0].name, "prompt":"Посмотрите руку соперника и выберите карту для сброса", "cards":[cards[0]], "options":[cards[0].name], "viewer":0, "victim":1, "can_skip":false, "_ctx":{"owner":0}}
	app._show_effect_choice()
	await settle()
	audit_tree(app.popup_layer)
	app._zoom_effect_card(cards[0], "buffy")
	await settle()
	audit_tree(app.popup_layer)
	expect(app.popup_close_button.text == I18n.text("К выбору эффекта ←"), code + " selection card zoom has translated return label")
	app._close_popup()
	await settle()
	audit_tree(app.popup_layer)
	app._clear_popup()
	app.engine.pending_choice.clear()
	app.engine._flow.clear()
	app.engine.phase = "action"

func check_new_hero_screens(code: String):
	app.engine.interactive = false
	app.engine.setup(["buffy", "angel", "spike", "willow"], 0, 712, "training", {"buffy_sidekick":"xander"})
	for player in app.engine.players: player.bot = false
	app.engine.shadow_tokens = [{"id":0,"owner":2,"node":2}]
	app.selected_card = -1
	for fighter in app.engine.fighters:
		app.selected_fighter = int(fighter.id)
		app._refresh()
		app.bot_timer.stop()
		await settle()
		audit_tree(app.game_ui)
	app.engine.willow_form[3] = "dark"
	app.selected_fighter = app.engine.hero_fighter(3)
	app._refresh()
	app.bot_timer.stop()
	await settle()
	audit_tree(app.game_ui)
	expect(app.detail_title.text == I18n.text("Тёмная Уиллоу"), code + " Dark Willow has a translated fighter title")

func check_trap_screens(code: String):
	app.engine.interactive = false
	app.engine.setup(["ingen", "alice"], 0, 713, "training")
	app.engine.interactive = true
	for player in app.engine.players: player.bot = false
	var card: Dictionary = {}
	for source in app.engine.heroes.ingen.cards:
		if source.id == "call_for_backup": card = source
	var ctx = {"owner":0, "self":app.engine.hero_fighter(0), "opponent":app.engine.hero_fighter(1), "opponent_owner":1, "card":card, "won":false}
	app.engine._flow = {"kind":"ability", "stage":"effects", "owner":0, "card":card, "completion":"action", "effect_logs":[]}
	app.engine.combat_report = {"kind":"ability", "stage":"effects", "owner":0, "title":card.name, "effect_logs":[]}
	app.engine._begin_manual_effect({"kind":"call_for_backup"}, ctx)
	app._show_effect_choice()
	await settle()
	audit_tree(app.popup_layer)
	app._choose_effect_option(0)
	await settle()
	audit_tree(app.popup_layer)
	expect(app.engine.phase == "effect_choice", code + " two effects are selected before trap placement")
	app._choose_effect_option(1)
	await settle()
	app.bot_timer.stop()
	audit_tree(app.game_ui)
	expect(app.engine.phase == "effect_move", code + " trap placement prompt is displayed")
	expect(app.move_finish_button.text == I18n.text("Завершить ловушки"), code + " trap placement has a clear finish button")
	expect(app.detail_text.text.contains(I18n.text("Можно завершить размещение раньше. Неиспользованные жетоны остаются в запасе.")), code + " trap guidance explains unused supply")
	app._show_board_zoom()
	await settle()
	audit_tree(app.popup_layer)
	var finish_found = false
	for button in app.popup_layer.find_children("*", "Button", true, false):
		if button.text == I18n.text("Завершить ловушки"): finish_found = true
	expect(finish_found, code + " enlarged board has the translated trap finish button")
	app._close_popup()
	await settle()
	app.engine.choose_effect_node(int(app.engine.pending_choice.legal[0]))
	app._refresh()
	await settle()
	audit_tree(app.game_ui)
	app._clear_popup()
	app.engine.pending_choice.clear()
	app.engine._effect_queue.clear()
	app.engine._flow.clear()
	app.engine.phase = "action"

func run():
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	expect(I18n.language == "ru", "Russian is the first-run language")
	for code in ["ru", "en", "nb", "es"]:
		current_language = code
		I18n.set_language(code)
		for h in app.heroes:
			for field in ["name", "ability"]:
				var rendered = I18n.hero_field(str(h.id), field, str(h[field]))
				expect(rendered == str(h[field]) if code == "ru" else not rendered.is_empty() and cyrillic.search(rendered) == null, code + " hero " + str(h.id) + " " + field)
			for c in h.cards:
				for field in ["name", "text"]:
					var rendered = I18n.card_field(str(h.id), str(c.id), field, str(c[field]))
					expect(rendered == str(c[field]) if code == "ru" else not rendered.is_empty() and cyrillic.search(rendered) == null, code + " card " + str(h.id) + "/" + str(c.id) + " " + field)
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
		await check_hand_screens(code)
		await check_new_hero_screens(code)
		await check_trap_screens(code)
		app._return_menu()
		await settle()
	for entry in untranslated: print("UNTRANSLATED ", entry.replace("\n", " | "))
	expect(untranslated.is_empty(), "visible strings translated; missing=" + str(untranslated.size()))
	I18n.set_language("ru")
	app._localize()
	app._save_ui_settings()
	app.started = false
	print("LOCALIZATION_V07_TESTS checks=%d failures=%d untranslated=%d" % [checks, failures, untranslated.size()])
	quit(1 if failures else 0)
