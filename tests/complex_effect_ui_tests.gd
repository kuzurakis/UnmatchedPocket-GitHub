extends SceneTree

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
		push_error("COMPLEX_UI: " + label)

func card(id: String) -> Dictionary:
	for c in app.engine.heroes.king_arthur.cards:
		if str(c.id) == id: return c.duplicate(true)
	return {}

func count_cards(node: Node) -> int:
	var count = 1 if node.get_script() == load("res://scripts/card_view.gd") else 0
	for child in node.get_children(): count += count_cards(child)
	return count

func find_scroll(node: Node):
	if node is ScrollContainer: return node
	for child in node.get_children():
		var found = find_scroll(child)
		if found != null: return found
	return null

func run():
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app._choose_hero("king_arthur")
	app.placement_option.select(1)
	app._start_match()
	await settle()
	var e = app.engine
	var merlin = -1
	for f in e.fighters:
		if int(f.owner) == 0 and not f.hero: merlin = int(f.id)
	e.players[0].hand = [card("restless_spirits")]
	app.selected_fighter = e.hero_fighter(0)
	app._refresh()
	app._select_card(0)
	expect(app.selected_fighter == merlin, "Merlin selected automatically for his scheme")
	app._play_selected()
	await settle()
	expect(e.phase == "effect_move" and e.pending_choice.kind == "spaces", "Spirits gives first cell choice")
	var first = int(e.pending_choice.legal[0])
	app._on_node(first)
	expect(e.phase == "effect_move" and first in app.board.targets, "first selected space remains highlighted")
	app._on_node(int(e.pending_choice.legal[0]))
	await settle()
	expect(e.phase == "combat_report" and app.popup_kind == "report", "Spirits effect report stays open")
	app._continue_combat()
	await settle()
	e.players[0].hand = [card("prophecy")]
	app.selected_card = -1
	app._refresh()
	app._select_card(0)
	app._play_selected()
	await settle()
	expect(e.phase == "effect_choice" and app.popup_kind == "choice", "Prophecy choice popup opens")
	expect(count_cards(app.popup_layer) == 4, "Prophecy displays all four real card previews")
	var scroll = find_scroll(app.popup_layer)
	expect(scroll != null, "card choices have scroll container")
	scroll.scroll_vertical = 180
	await settle()
	expect(scroll.scroll_vertical > 0, "four-card choice scrolls vertically")
	app._choose_effect_option(0)
	await settle()
	expect(count_cards(app.popup_layer) == 3, "choice refreshes after taking first card")
	app._choose_effect_option(0)
	await settle()
	expect(e.pending_choice.stage == "order" and count_cards(app.popup_layer) == 2, "remaining cards offer deck order")
	app._choose_effect_option(1)
	await settle()
	expect(e.phase == "combat_report", "Prophecy completes into persistent report")
	app.started = false
	print("COMPLEX_EFFECT_UI_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
