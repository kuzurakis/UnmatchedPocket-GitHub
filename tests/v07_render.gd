extends SceneTree
var app
var folder = "res://../../work/verification-v0.7"
func _initialize(): run.call_deferred()
func settle():
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String):
	await settle()
	root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func finish_reports():
	for i in range(8):
		if app.engine.phase == "combat_report": app._continue_combat()
		else: return
		await settle()
func start(ids: Array,map_id: String,config = {}):
	if app.started:
		app._return_menu()
		await settle()
	app.engine.setup(ids,1,707,map_id,config)
	app._open_match()
	app.bot_timer.stop()
	await settle()
func card(hero: String,id: String):
	for c in app.engine.heroes[hero].cards:
		if str(c.id) == id: return c.duplicate(true)
	return {}
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	app.language_option.select(0)
	app.set_option.select(5)
	app._set_changed(5)
	app.buffy_sidekick_option.select(1)
	await shot("menu")
	app._show_hero_info("buffy")
	await shot("new-set")
	app._close_popup()
	await start(["buffy","angel","spike","willow"],"the_bronze",{"buffy_sidekick":"xander"})
	var e = app.engine
	e.shadow_tokens = [{"owner":2,"id":0,"node":int(e.fighters[e.hero_fighter(2)].node)},{"owner":2,"id":1,"node":int(e.nodes[int(e.fighters[e.hero_fighter(2)].node)].neighbors[0])}]
	for node in e.nodes[int(e.fighters[e.hero_fighter(2)].node)].neighbors:
		if e._occupant(int(node)) < 0: e.shadow_tokens[1].node = int(node); break
	e.willow_form[3] = "dark"
	e.players[0].hand = []
	for id in ["right_hand_man","daring_strike","cartwheel_kick","slayer_s_strength","feint"]: e.players[0].hand.append(card("buffy",id))
	app._refresh()
	app._select_card(0)
	await shot("game-ru")
	app.I18n.set_language("en")
	app._refresh()
	await shot("game-en")
	app.I18n.set_language("ru")
	await start(["buffy","angel"],"sunnydale_high",{"buffy_sidekick":"xander"})
	app._select_card(0)
	await shot("buffy")
	await start(["willow","spike"],"the_bronze")
	e = app.engine
	e._damage(e.hero_fighter(0),1)
	app._refresh()
	await shot("willow")
	await start(["muhammad_ali","king_arthur"],"marmoreal")
	e = app.engine
	var own = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[own].node)
	var dest = int(e.nodes[home].neighbors[0])
	for f in e.fighters:
		if int(f.id) not in [own,foe]: f.node = 5
	e.fighters[foe].node = dest
	e.players[0].hand = [card("muhammad_ali","hard_to_be_humble")]
	e.players[1].hand = [card("king_arthur","excalibur")]
	for id in ["noble_sacrifice","the_aid_of_morgana","the_holy_grail","prophecy","feint","swift_strike","momentous_shift"]: e.players[1].hand.append(card("king_arthur",id))
	e.active = 1
	e.attack(foe,own,0)
	await settle()
	app._continue_attack()
	await settle()
	app._select_card(0)
	app._play_selected()
	await shot("hand-view")
	app._zoom_effect_card(e.pending_choice.cards[0],"king_arthur")
	await shot("hand-zoom")
	app._close_popup()
	await start(["ingen","raptors"],"raptor_paddock")
	e = app.engine
	if e.phase == "effect_move": app._skip_ability()
	await finish_reports()
	e.traps.clear()
	e._trap_stock[0] = 8
	e.players[0].hand = [card("ingen","call_for_backup")]
	app.selected_card = -1
	app._refresh()
	app._select_card(0)
	app._play_selected()
	await settle()
	app._choose_effect_option(0)
	await shot("traps-choice")
	app._choose_effect_option(1)
	await settle()
	for i in range(2):
		var node = int(e.pending_choice.legal[-1])
		for n in e.pending_choice.legal:
			if not e._same_zone(int(e.fighters[e.hero_fighter(0)].node),int(n)): node = int(n); break
		app._on_node(node)
		await settle()
	await shot("traps")
	app.started = false
	print("V07_RENDER_OK")
	quit()
