extends SceneTree
var app
var folder = "res://../../work/verification-v0.5"
func _initialize(): run.call_deferred()
func settle():
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String):
	await settle()
	root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func start(ids: Array, map_id: String):
	if app.started:
		app._return_menu()
		await settle()
	app.engine.setup(ids,1,54,map_id)
	app._open_match()
	app.bot_timer.stop()
	await settle()
func reports():
	for i in range(12):
		if app.engine.phase == "combat_report": app._continue_combat()
		else: return
		await settle()
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	app.language_option.select(0)
	app.set_option.select(0)
	app._set_changed(0)
	await shot("menu")
	app.set_option.select(3)
	app._set_changed(3)
	await shot("new-set")
	app.set_option.select(2)
	app._set_changed(2)
	await shot("bruce-menu")
	await start(["raptors","ingen"],"raptor_paddock")
	var legal = app.engine.legal_trap_nodes(1)
	if not legal.is_empty(): app.engine._place_trap(1,int(legal[0]))
	app._refresh()
	app._select_card(0)
	await shot("game-ru")
	app.I18n.set_language("en")
	app._refresh()
	await shot("game-en")
	app.I18n.set_language("ru")
	await start(["medusa","king_arthur"],"marmoreal")
	await reports()
	var e = app.engine
	var medusa = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[medusa].node)
	var destination = int(e.nodes[home].neighbors[0])
	var used = [home,destination]
	for f in e.fighters:
		if int(f.id) in [medusa,foe]: continue
		for n in e.nodes:
			if not int(n.id) in used:
				f.node = int(n.id)
				used.append(int(n.id))
				break
	e.fighters[foe].node = destination
	e.active = 1
	e.phase = "action"
	e.actions_left = 0
	e.end_turn()
	await shot("medusa-choice")
	if e.phase == "effect_choice": app._choose_effect_option(e.pending_choice.allowed_fighters.find(foe))
	await shot("medusa")
	await start(["sinbad","king_arthur"],"marmoreal")
	e = app.engine
	e.players[0].discard = []
	for c in e.heroes.sinbad.cards:
		if str(c.id).begins_with("voyage_") and str(c.id) != "voyage_home" and e.players[0].discard.size() < 3: e.players[0].discard.append(c.duplicate(true))
	e.players[0].hand = []
	for c in e.heroes.sinbad.cards:
		if str(c.id) in ["voyage_home","feint","regroup"]: e.players[0].hand.append(c.duplicate(true))
	app.selected_card = -1
	app._refresh()
	for i in range(e.players[0].hand.size()):
		if e.players[0].hand[i].id == "voyage_home": app._select_card(i); break
	app._toggle_boost()
	app._begin_move()
	await shot("sinbad")
	app.started = false
	print("V05_RENDER_OK")
	quit()
