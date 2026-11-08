extends SceneTree
## Exercise actual combat UI timing, the complete hand, zoom/back and resume.
var app
var checks = 0
var failures = 0
func _initialize(): run.call_deferred()
func settle():
	for i in range(4): await process_frame
func expect(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("HAND_UI: " + label)
func card(hero: String,id: String) -> Dictionary:
	for c in app.engine.heroes[hero].cards:
		if str(c.id) == id: return c.duplicate(true)
	expect(false,"known card " + id)
	return {}
func cards_in(node: Node) -> Array:
	var found = []
	if node.get_script() == app.CardScript: found.append(node)
	for child in node.get_children(): found.append_array(cards_in(child))
	return found
func start(hero: String):
	if app.started:
		app._return_menu()
		await settle()
	app.engine.setup([hero,"king_arthur"],1,706,"marmoreal")
	app._open_match()
	app.bot_timer.stop()
	await settle()
	var e = app.engine
	var own = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[own].node)
	var dest = int(e.nodes[home].neighbors[0])
	var used = [home,dest]
	for f in e.fighters:
		if int(f.id) in [own,foe]: continue
		for node in e.nodes:
			if not int(node.id) in used:
				f.node = int(node.id)
				used.append(int(node.id))
				break
	e.fighters[foe].node = dest
	e.players[1].hand = []
	for n in range(14):
		e.players[1].hand.append(card("king_arthur",["excalibur","noble_sacrifice","the_aid_of_morgana"][n%3]))
func resume():
	app._save_match()
	app._return_menu()
	await settle()
	app._resume_match()
	app.bot_timer.stop()
	await settle()
func finish():
	for n in range(30):
		match app.engine.phase:
			"combat_report": app._continue_combat()
			"effect_choice": app._choose_effect_option(0)
			"effect_move": app._finish_move()
			_: return
		await settle()
	expect(false,"flow finishes")
func check_browser(expected: Array):
	var e = app.engine
	expect(e.phase == "effect_choice" and e.pending_choice.kind == "hand_view","hand reveal opens a persistent browser")
	if e.phase != "effect_choice" or e.pending_choice.kind != "hand_view": return
	expect(app.popup_kind == "choice" and not app.popup_close_button.visible,"browser cannot silently skip the effect")
	expect(e.pending_choice.cards == expected,"browser contains the actual remaining opponent hand")
	var previews = cards_in(app.popup_layer)
	expect(previews.size() == expected.size(),"every card appears, rather than one card for the Continue option")
	for preview in previews:
		expect(preview.card_hero_id == "king_arthur" and not preview.card_image_path.is_empty(),"revealed card uses the opponent deck scan")
	var phase = e.phase
	app._bot_tick()
	app._close_popup()
	await settle()
	expect(e.phase == phase and app.popup_kind == "choice","bot ticks and Back cannot consume viewing")
	app.effect_scroll.scroll_vertical = 10000
	await settle()
	var offset = app.effect_scroll.scroll_vertical
	expect(offset > 0,"a large revealed hand scrolls")
	previews[-1].pressed.emit()
	await settle()
	expect(app.popup_kind == "info" and app._return_effect_choice,"card tap opens full card text without making a game choice")
	expect(e.pending_choice.cards == expected and e.players[1].hand == expected,"zoom does not discard, shuffle or consume a revealed card")
	app._close_popup()
	await settle()
	expect(app.popup_kind == "choice" and cards_in(app.popup_layer).size() == expected.size(),"Back returns to all revealed cards")
	expect(app.effect_scroll.scroll_vertical == offset,"Back preserves hand browser scroll")
	await resume()
	e = app.engine
	expect(e.phase == "effect_choice" and e.pending_choice.kind == "hand_view" and app.popup_kind == "choice","resume reopens the mandatory hand browser")
	expect(e.pending_choice.cards == expected,"revealed cards survive JSON save and load")
	app._choose_effect_option(0)
	await settle()
	expect(not (e.phase == "effect_choice" and e.pending_choice.get("kind","") == "hand_view"),"Continue resumes the actual combat")
	expect(e.players[1].hand == expected,"pure reveal leaves hand untouched")
func run():
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	await start("muhammad_ali")
	var e = app.engine
	e.players[0].hand = [card("muhammad_ali","hard_to_be_humble")]
	e.active = 1
	e.attack(e.hero_fighter(1),e.hero_fighter(0),0)
	await settle()
	app._continue_attack()
	await settle()
	app._select_card(0)
	app._play_selected()
	await settle()
	expect(e.pending_choice.kind == "hand_view" and e._combat_resolution.size() > 0,"Humble reveals during combat, before values finish")
	await check_browser(e.players[1].hand.duplicate(true))
	await finish()
	for hero in ["sinbad","sherlock_holmes"]:
		await start(hero)
		e = app.engine
		e.players[0].hand = [card(hero,"voyage_to_the_valley_of_the_giant_snakes" if hero == "sinbad" else "study_methods")]
		app.selected_card = -1
		app._refresh()
		app._select_card(0)
		app._play_selected()
		app._on_node(int(e.fighters[e.hero_fighter(1)].node))
		await settle()
		app._continue_attack()
		await settle()
		expect(e.phase == "combat_report","after-combat peek waits for the normal battle report")
		app._continue_combat()
		await settle()
		await check_browser(e.players[1].hand.duplicate(true))
		await finish()
	# Selecting a card to discard remains explicit; opening its picture is safe.
	await start("alice")
	e = app.engine
	e.players[0].hand = [card("alice","snicker_snack")]
	app.selected_card = -1
	app._refresh()
	app._select_card(0)
	app._play_selected()
	app._on_node(int(e.fighters[e.hero_fighter(1)].node))
	await settle()
	app._continue_attack()
	await settle()
	app._continue_combat()
	await settle()
	expect(e.phase == "effect_choice" and e.pending_choice.kind == "cards","Alice offers the revealed hand for discard selection")
	var old_count = e.players[1].hand.size()
	cards_in(app.popup_layer)[0].pressed.emit()
	await settle()
	expect(e.players[1].hand.size() == old_count and app.popup_kind == "info","reading a discard candidate does not discard it")
	app._close_popup()
	await settle()
	app._choose_effect_option(0)
	await settle()
	expect(e.players[1].hand.size() == old_count-1,"explicit choice discards exactly one selected card")
	await finish()
	app.started = false
	print("HAND_VIEW_UI_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
