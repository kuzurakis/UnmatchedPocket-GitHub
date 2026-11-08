extends SceneTree
## Actual menu, modal, board taps and resume flows for the five v0.6 heroes.
var app
var checks = 0
var failures = 0
func _initialize(): run.call_deferred()
func settle():
	for i in range(4): await process_frame
func expect(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("V6_UI: " + message)
func card(hero: String,id: String):
	for c in app.engine.heroes[hero].cards:
		if str(c.id) == id: return c.duplicate(true)
	expect(false,"known card " + hero + "/" + id)
	return {}
func text_in(node: Node,fragment: String) -> bool:
	if node is Label or node is Button:
		if fragment in node.text: return true
	for child in node.get_children():
		if text_in(child,fragment): return true
	return false
func start(hero: String,manual = false):
	if app.started:
		app._return_menu()
		await settle()
	app.engine.setup([hero,"king_arthur"],1,6026,"marmoreal",{"human_placement":manual})
	app._open_match()
	app.bot_timer.stop()
	await settle()
func finish():
	for i in range(50):
		match app.engine.phase:
			"attack_notice": app._continue_attack()
			"combat_report": app._continue_combat()
			"effect_choice": app._choose_effect_option(0)
			"effect_move":
				if not app.engine.pending_choice.get("legal",[]).is_empty(): app._on_node(int(app.engine.pending_choice.legal[0]))
				else: app._finish_move()
			_: return
		await settle()
	expect(false,"UI decisions reach stable phase")
func position_enemy(distance = 1) -> int:
	var e = app.engine
	var own = e.hero_fighter(0)
	var foe = e.hero_fighter(1)
	var home = int(e.fighters[own].node)
	if e.players[0].hero_id == "dracula":
		for node in e.nodes:
			if node.neighbors.size() >= 3:
				home = int(node.id)
				e.fighters[own].node = home
				break
	var destination = -1
	for node in e.nodes:
		if e._distance(home,int(node.id)) == distance:
			destination = int(node.id)
			break
	expect(destination >= 0,"map has requested attack distance")
	var used = [home,destination]
	for f in e.fighters:
		if int(f.id) in [own,foe]: continue
		for node in e.nodes:
			if not int(node.id) in used:
				f.node = int(node.id)
				used.append(int(node.id))
				break
	e.fighters[foe].node = destination
	e.players[1].hand = []
	return foe
func resume():
	app._save_match()
	app._return_menu()
	await settle()
	app._resume_match()
	app.bot_timer.stop()
	await settle()
func run():
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app.I18n.set_language("ru")
	await start("muhammad_ali")
	await finish()
	var e = app.engine
	var foe = position_enemy(2)
	e.players[0].hand = [card("muhammad_ali","jab")]
	app.selected_card = -1
	app._refresh()
	expect("Бабочка" in app.state_label.text,"Ali butterfly stance is visible")
	expect("2 клетки" in app.detail_text.text,"Ali sidebar explains extended attack range")
	app._select_card(0)
	app._play_selected()
	expect(app.attack_mode,"Ali selects a two-space attack through UI")
	app._on_node(int(e.fighters[foe].node))
	await settle()
	expect(e.phase == "attack_notice","two-space board tap announces attack")
	app._continue_attack()
	await settle()
	expect(e.phase == "combat_report" and e.stance_for(0) == "butterfly","stance stays butterfly during first combat report")
	await finish()
	expect(e.stance_for(0) == "bee" and "Пчела" in app.state_label.text,"winning attack updates stance and UI after effects")
	await resume()
	expect(app.engine.stance_for(0) == "bee","Ali stance survives app resume")
	await start("jekyll_hyde")
	e = app.engine
	expect(e.phase == "effect_choice" and app.popup_kind == "choice","Jekyll start opens form modal")
	expect(text_in(app.popup_layer,"Мистер Хайд"),"form modal exposes full Hyde option")
	app._choose_effect_option(1)
	await settle()
	await finish()
	expect(e.form_for(0) == "hyde" and "Хайд" in app.detail_title.text,"Hyde is shown as current fighter form")
	e.players[0].hand = [card("jekyll_hyde","with_haste"),card("jekyll_hyde","forever_hyde")]
	app.selected_card = -1
	app._refresh()
	app._select_card(0)
	app._play_selected()
	expect(not app.attack_mode and "формы Джекилла" in app.toast,"Jekyll-only attack cannot be used by Hyde")
	position_enemy()
	app._select_card(1)
	app._play_selected()
	expect(app.attack_mode,"Hyde-specific attack is selectable")
	app.attack_mode = false
	var hp = int(e.fighters[e.hero_fighter(0)].hp)
	app._begin_move()
	app._finish_move()
	await settle()
	expect(e.fighters[e.hero_fighter(0)].hp == hp-1,"Hyde maneuver costs exactly one health via UI")
	await resume()
	expect(app.engine.form_for(0) == "hyde","Hyde form survives resume")
	await start("dracula")
	await finish()
	e = app.engine
	foe = position_enemy()
	var home = int(e.fighters[e.hero_fighter(0)].node)
	var sister = -1
	for f in e.fighters:
		if int(f.owner) == 0 and not f.hero and f.alive:
			sister = int(f.id)
			break
	for node in e.nodes[home].neighbors:
		if int(node) != int(e.fighters[foe].node):
			for f in e.fighters:
				if f.id != sister and f.id != foe and f.id != e.hero_fighter(0) and int(f.node) == int(node): f.node = 30
			e.fighters[sister].node = int(node)
			break
	e._start_turn_ability()
	await settle()
	expect(e.phase == "effect_choice" and app.popup_kind == "choice","Dracula bite opens target modal")
	expect(foe in e.pending_choice.allowed_fighters and sister in e.pending_choice.allowed_fighters,"Dracula may bite enemy or own adjacent sister")
	await resume()
	e = app.engine
	expect(e.phase == "effect_choice" and app.popup_kind == "choice","Dracula target choice survives resume")
	hp = int(e.fighters[foe].hp)
	var hand_count = e.players[0].hand.size()
	app._choose_effect_option(e.pending_choice.allowed_fighters.find(foe))
	await settle()
	expect(e.fighters[foe].hp == hp-1 and e.players[0].hand.size() == hand_count+1,"chosen Dracula bite deals one and draws one")
	expect(app.popup_kind == "report" and text_in(app.popup_layer,"Дракулы"),"bite outcome remains visible until confirmation")
	await finish()
	await start("sherlock_holmes")
	await finish()
	e = app.engine
	foe = position_enemy()
	e.players[0].hand = [card("sherlock_holmes","elementary")]
	e.players[1].hand = [card("king_arthur","excalibur")]
	e.active = 1
	e.attack(foe,e.hero_fighter(0),0)
	await settle()
	app._continue_attack()
	await settle()
	app._select_card(0)
	app._play_selected()
	await settle()
	expect(e.phase == "effect_choice" and e.pending_choice.action == "v6_elementary_guess","Elementary asks prediction through actual defense UI")
	expect(not text_in(app.popup_layer,"Экскалибур"),"prediction modal keeps enemy attack secret")
	await resume()
	e = app.engine
	expect(e.pending_choice.action == "v6_elementary_guess","closed prediction survives resume")
	app._choose_effect_option(6)
	await settle()
	expect(e.phase == "combat_report" and e.combat_report.damage == 0,"correct prediction protects Holmes")
	expect(text_in(app.popup_layer,"Экскалибур"),"attack is revealed in combat result after prediction")
	await finish()
	await start("invisible_man",true)
	e = app.engine
	expect(e.phase == "setup","Invisible Man supports manual hero start")
	app._on_node(int(e.legal_setup_nodes(e.setup_fighter)[0]))
	app._finish_move()
	await settle()
	expect(e.phase == "effect_move" and e.pending_choice.action == "v6_setup_fog","fog placement follows normal hero placement")
	expect(not app.hand_scroll.is_visible_in_tree(),"hand collapses to expose fog placement map")
	for i in range(3):
		expect(not app.board.highlighted.is_empty(),"fog placement offers board targets")
		app._on_node(int(e.pending_choice.legal[0]))
		await settle()
		if i == 0:
			await resume()
			e = app.engine
			expect(e.fog_tokens.size() == 1 and e.pending_choice.action == "v6_setup_fog","partially placed fog survives resume")
	await finish()
	expect(e.fog_tokens.size() == 3 and app.hand_scroll.is_visible_in_tree(),"all fog tokens placed and hand restored")
	foe = position_enemy()
	e.players[0].hand = [card("invisible_man","vanish")]
	app.selected_card = -1
	app._refresh()
	app._select_card(0)
	app._play_selected()
	await settle()
	expect(bool(e.fighters[e.hero_fighter(0)].get("offboard",false)),"Vanish removes fighter through scheme UI")
	expect("Исчез" in app.state_label.text,"offboard status is visible")
	await resume()
	e = app.engine
	expect(bool(e.fighters[e.hero_fighter(0)].get("offboard",false)),"offboard state survives resume")
	await finish()
	if e.active == 0 and e.phase == "action":
		e.end_turn()
		await settle()
	if e.active == 1:
		e.actions_left = 0
		e.end_turn()
		await settle()
	expect(e.phase == "effect_move" and not app.board.highlighted.is_empty(),"return from invisibility asks human to select destination")
	if e.phase == "effect_move":
		var destination = int(e.pending_choice.legal[-1])
		app._on_node(destination)
		await settle()
		expect(int(e.fighters[e.hero_fighter(0)].node) == destination and not e.fighters[e.hero_fighter(0)].offboard,"Invisible Man returns at selected board space")
	await finish()
	app.started = false
	print("V6_UI_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
