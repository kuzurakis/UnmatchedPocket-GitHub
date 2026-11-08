extends SceneTree

func _initialize():
	run.call_deferred()

func run():
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../menu-preview.png")
	app.count_option.select(2)
	app.placement_option.select(1)
	app._start_match()
	await process_frame
	app._select_card(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../preview.png")
	app.bot_timer.stop()
	app._zoom_selected()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../card-preview.png")
	app._close_popup()
	var e = app.engine
	var hero = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[hero].node)
	var target = int(e.nodes[home].neighbors[0])
	var used = [home, target]
	for f in e.fighters:
		if f.id in [hero, foe]: continue
		for n in e.nodes:
			if not int(n.id) in used:
				f.node = int(n.id)
				used.append(int(n.id))
				break
	e.fighters[foe].node = target
	e.players[1].hand = []
	for c in e.heroes.alice.cards:
		if c.id == "i_m_late_i_m_late":
			e.players[0].hand = [c.duplicate(true)]
			break
	e.attack(hero, foe, 0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../attack-preview.png")
	app._continue_attack()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../battle-preview.png")
	app._continue_combat()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../effect-preview.png")
	app.started = false
	print("PREVIEWS_OK")
	quit()
