extends SceneTree
## Geometry and rendered-view regression checks for phone/tablet aspect ratios.
## Run with an isolated APPDATA. Add -- --render-responsive to save screenshots.

const CASES = [
	Vector2i(1280, 720),
	Vector2i(1600, 720),
	Vector2i(1280, 800),
	Vector2i(960, 540),
	Vector2i(1024, 768)
]

var checks = 0
var failures = 0
var app
var current_case = ""
var report: Array = []
var render_requested = false
var output_dir = ""

func _initialize():
	_run.call_deferred()

func expect(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		push_error("RESPONSIVE TEST [%s]: %s" % [current_case, label])

func settle(frames: int = 4):
	for i in range(frames):
		await process_frame

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.name) == property_name:
			return true
	return false

func _optional_control(property_name: String) -> Control:
	if _has_property(app, property_name):
		var value = app.get(property_name)
		if value is Control:
			return value
	return null

func _select_metadata(option: OptionButton, value: String) -> bool:
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == value:
			option.select(i)
			return true
	return false

func _inside(rect: Rect2, bounds: Rect2, tolerance: float = 2.0) -> bool:
	return rect.position.x >= bounds.position.x - tolerance and rect.position.y >= bounds.position.y - tolerance and rect.end.x <= bounds.end.x + tolerance and rect.end.y <= bounds.end.y + tolerance

func _has_scroll_ancestor(node: Node) -> bool:
	var parent = node.get_parent()
	while parent != null and parent != app:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false

func _check_hit_bounds(node: Node, bounds: Rect2):
	if node is BaseButton and node.is_visible_in_tree() and not _has_scroll_ancestor(node):
		var label = str(node.get("text")) if _has_property(node, "text") else node.name
		expect(_inside(node.get_global_rect(), bounds), "visible button fits viewport: %s %s" % [label.left(35), node.get_global_rect()])
	for child in node.get_children():
		_check_hit_bounds(child, bounds)

func _check_menu_card_content(node: Node, bounds: Rect2):
	if node is Label and node.is_visible_in_tree():
		expect(_inside(node.get_global_rect(), bounds), "hero menu text stays inside its card: " + str(node.text).left(30))
	for child in node.get_children():
		_check_menu_card_content(child, bounds)

func _rect_data(control: Control) -> Dictionary:
	var rect = control.get_global_rect()
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}

func _resize(target: Vector2i):
	root.size = target
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(target)
	await settle()

func _capture(name: String):
	if not render_requested or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	image.save_png(output_dir.path_join(current_case + "-" + name + ".png"))

func _finish_placement():
	for i in range(8):
		if app.engine.phase != "setup":
			return
		var fighter = int(app.engine.setup_fighter)
		if fighter < 0:
			expect(app.engine.finish_setup(), "manual placement can finish")
			await settle()
			return
		var legal = app.engine.legal_setup_nodes(fighter)
		expect(not legal.is_empty(), "current setup fighter has a legal starting space")
		if legal.is_empty():
			return
		expect(app.engine.place_setup_fighter(fighter, int(legal[0])), "legal manual starting space accepted")
		await settle()
	expect(false, "manual placement finishes within eight choices")

func _check_game_geometry() -> Dictionary:
	var bounds = app.get_viewport_rect()
	var app_rect = app.get_global_rect()
	expect(_inside(bounds, app_rect) and _inside(app_rect, bounds), "root Control covers expanded logical viewport")
	expect(app.board != null and app.hand_scroll != null, "board and hand exist")
	var result = {"case": current_case, "mode": app.engine.match_mode, "physical_width": root.size.x, "physical_height": root.size.y, "logical_width": bounds.size.x, "logical_height": bounds.size.y}
	if app.board == null or app.hand_scroll == null:
		return result
	var board_rect: Rect2 = app.board.get_global_rect()
	var image_local: Rect2 = app.board.image_rect()
	var image_rect := Rect2(board_rect.position + image_local.position, image_local.size)
	var hand_rect: Rect2 = app.hand_scroll.get_global_rect()
	var hand_visible = app.hand_scroll.is_visible_in_tree()
	expect(_inside(board_rect, bounds), "board remains within expanded viewport")
	expect(_inside(image_rect,board_rect), "aspect-fitted artwork remains inside board input surface")
	expect(image_rect.size.x >= 350 and image_rect.size.y >= 200, "actual map retains readable dimensions beside HUD wings")
	var native = app.engine.board_data
	if not native.is_empty():
		expect(absf(image_rect.size.x/image_rect.size.y - float(native.width)/float(native.height)) < 0.001, "map artwork preserves native aspect ratio")
	for hud_name in ["hud_left","hud_right"]:
		var hud = _optional_control(hud_name)
		expect(hud != null and hud.get_parent() == app.board, "player HUD is anchored inside the board wing")
		if hud != null:
			var hud_rect: Rect2 = hud.get_global_rect()
			expect(_inside(hud_rect,board_rect), "HUD wing remains within board surface")
			if hud_name == "hud_left":
				expect(hud_rect.end.x <= image_rect.position.x + 2, "left HUD does not cover map artwork or node targets")
			else:
				expect(hud_rect.position.x >= image_rect.end.x - 2, "right HUD does not cover map artwork or node targets")
			for player_button in hud.get_children():
				if player_button is Control:
					expect(_inside(player_button.get_global_rect(),hud_rect), "player status button fits its HUD wing")
	if hand_visible:
		expect(_inside(hand_rect, bounds), "hand scroll area remains within viewport")
		for card in app.hand_box.get_children():
			if _has_property(card, "_stats"):
				var stats: Label = card.get("_stats")
				var font = stats.get_theme_font("font")
				var width = font.get_string_size(stats.text, HORIZONTAL_ALIGNMENT_LEFT, -1, stats.get_theme_font_size("font_size")).x
				expect(width <= stats.size.x + 1, "card type/value/BOOST footer fits without clipping")
				expect("BOOST" in stats.text or "↑" in stats.text, "compact card keeps BOOST indicator")
	expect(board_rect.size.x >= 620 and board_rect.size.y >= 260, "board retains useful size at every aspect ratio")
	if hand_visible:
		expect(hand_rect.position.y >= board_rect.end.y - 2, "hand remains below the board")
	if app.board.has_method("point"):
		for node in app.engine.nodes:
				expect(image_local.has_point(app.board.point(int(node.id))), "board node %d remains inside the fitted artwork/input transform" % int(node.id))
	var sidebar = _optional_control("sidebar_panel")
	expect(sidebar != null, "full-height sidebar is exposed for geometry verification")
	if sidebar != null:
		var side_rect = sidebar.get_global_rect()
		expect(_inside(side_rect, bounds), "sidebar remains within viewport")
		var left_column = _optional_control("left_column")
		if left_column != null:
			expect(absf(side_rect.end.y - left_column.get_global_rect().end.y) <= 4, "sidebar reaches the bottom beside the full left column")
		if hand_visible:
			expect(hand_rect.end.x <= side_rect.position.x + 2, "hand stays in left column beside sidebar")
		expect(board_rect.end.x <= side_rect.position.x + 2, "board stays left of sidebar")
		result["sidebar"] = _rect_data(sidebar)
	result["board"] = _rect_data(app.board)
	result["map_image"] = {"x":image_rect.position.x,"y":image_rect.position.y,"width":image_rect.size.x,"height":image_rect.size.y}
	result["hand_visible"] = hand_visible
	if hand_visible:
		result["hand"] = _rect_data(app.hand_scroll)
	_check_hit_bounds(app, bounds)
	return result

func _run():
	render_requested = "--render-responsive" in OS.get_cmdline_user_args()
	output_dir = ProjectSettings.globalize_path("res://../../work/verification-v0.14")
	DirAccess.make_dir_recursive_absolute(output_dir)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.bot_timer.stop()
	app._language_changed(0)
	app.set_option.select(0)
	app._set_changed(0)
	await settle()
	expect(app.heroes.size() == 56 and app.boards.size() == 28 and app.sets.size() == 20, "v0.15 catalog contains forty factions, twenty-two maps and fourteen sets")
	expect(str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items", "canvas_items scaling enabled")
	expect(str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand", "expand scaling avoids fixed-aspect engine bars")
	for case_index in range(CASES.size()):
		var target: Vector2i = CASES[case_index]
		current_case = "%dx%d" % [target.x, target.y]
		await _resize(target)
		if app.started:
			app._return_menu()
			await settle()
		app.set_option.select(0)
		app._set_changed(0)
		app._choose_hero("alice")
		var mode_index = 3 if case_index in [1, 4] else 2
		app.count_option.select(mode_index)
		app._opponent_changed(mode_index)
		expect(_select_metadata(app.map_option,"marmoreal"), "four-player map remains available after set switch")
		app._map_changed(0)
		var requested_opponents = ["king_arthur", "medusa", "sinbad"]
		if _has_property(app, "opponent_options"):
			for i in range(app.opponent_options.size()):
				expect(_select_metadata(app.opponent_options[i], requested_opponents[i]), "requested opponent appears in menu")
		if _has_property(app, "placement_option"):
			app.placement_option.select(0)
		if _has_property(app, "start_slot_option"):
			app.start_slot_option.select(case_index % 4)
		await settle()
		_check_hit_bounds(app, app.get_viewport_rect())
		for item in app.hero_buttons:
			_check_menu_card_content(item.button, item.button.get_global_rect())
		await _capture("menu")
		app._start_match()
		app.bot_timer.stop()
		await settle()
		expect(app.engine.players.size() == 4, "four-player roster is retained at every screen size")
		expect(app.engine.match_mode == ("teams" if mode_index == 3 else "ffa"), "selected match mode reaches engine")
		for i in range(1, mini(4, app.engine.players.size())):
			expect(str(app.engine.players[i].hero_id) == requested_opponents[i - 1], "explicit opponent selection is retained")
		if _has_property(app, "start_slot_option"):
			expect(int(app.engine.start_slots[0]) == case_index % 4, "chosen starting corner is retained")
		if app.engine.phase == "setup":
			_check_game_geometry()
			await _capture("placement")
			await _finish_placement()
		await settle()
		var row = _check_game_geometry()
		report.append(row)
		await _capture("game")
		if app.has_method("_toggle_hand") and app.hand_scroll.is_visible_in_tree():
			var full_hand_board_height = app.board.size.y
			app._toggle_hand()
			await settle()
			expect(not app.hand_scroll.is_visible_in_tree(), "hand toggle collapses the hand")
			expect(app.board.size.y > full_hand_board_height + 20, "collapsing hand frees board height")
			_check_game_geometry()
			await _capture("hand-collapsed")
			app._toggle_hand()
			await settle()
		if app.has_method("_show_discards"):
			for player in app.engine.players:
				if not player.hand.is_empty():
					player.discard.append(player.hand.pop_back())
			app._refresh()
			app._show_discards()
			await settle()
			_check_hit_bounds(app, app.get_viewport_rect())
			await _capture("discards")
			app._close_popup()
			await settle()
		# The new set has a two-card menu and genuine two-start maps at every size.
		app._return_menu()
		await settle()
		app.set_option.select(1)
		app._set_changed(1)
		await settle()
		expect(app.hero_buttons.size() == 2, "new set shows both heroes without blank menu cards")
		for item in app.hero_buttons:
			_check_menu_card_content(item.button,item.button.get_global_rect())
		var new_hero = "robin_hood" if case_index%2 == 0 else "bigfoot"
		app._choose_hero(new_hero)
		app.count_option.select(0)
		app._opponent_changed(0)
		var new_map = "sherwood_forest" if case_index%2 == 0 else "yukon"
		expect(_select_metadata(app.map_option,new_map), "new set duel map is available")
		app._map_changed(0)
		expect(app.start_slot_option.item_count == 2, "new map has exactly two selectable printed starts")
		app.placement_option.select(0)
		await _capture("new-set-menu")
		app._start_match()
		app.bot_timer.stop()
		await settle()
		await _finish_placement()
		await settle()
		expect(app.engine.players.size() == 2 and app.engine.board_id == new_map, "new set duel uses selected two-start map")
		_check_game_geometry()
		await _capture("new-set-game")
		# Multi-hero roster, solo hero and trap faction must fit the same UI.
		app._return_menu()
		await settle()
		var expansion_hero = ["raptors","bruce_lee","ingen"][case_index%3]
		var expansion_set = 2 if expansion_hero == "bruce_lee" else 3
		app.set_option.select(expansion_set)
		app._set_changed(expansion_set)
		app._choose_hero(expansion_hero)
		app.count_option.select(0)
		app._opponent_changed(0)
		expect(_select_metadata(app.map_option,"raptor_paddock"), "Jurassic board available for all duel heroes")
		app._map_changed(0)
		app.placement_option.select(0)
		await settle()
		for item in app.hero_buttons:
			_check_menu_card_content(item.button,item.button.get_global_rect())
		await _capture("expansion-menu")
		app._start_match()
		app.bot_timer.stop()
		await settle()
		await _finish_placement()
		await settle()
		expect(app.engine.players[0].hero_id == expansion_hero, "selected expansion hero survives setup")
		_check_game_geometry()
		await _capture("expansion-game")
		# Four new menu cards, long names, fog and form state across all viewports.
		app._return_menu()
		await settle()
		app.set_option.select(4)
		app._set_changed(4)
		await settle()
		expect(app.hero_buttons.size() == 4, "Cobble & Fog displays all four heroes")
		for item in app.hero_buttons:
			_check_menu_card_content(item.button,item.button.get_global_rect())
		await _capture("cobble-menu")
		var v6_hero = ["muhammad_ali","dracula","sherlock_holmes","jekyll_hyde","invisible_man"][case_index]
		var v6_map = ["thrilla_in_manilla","soho","baskerville_manor","soho","baskerville_manor"][case_index]
		app._choose_hero(v6_hero)
		app.count_option.select(0)
		app._opponent_changed(0)
		expect(_select_metadata(app.map_option,v6_map), "new official board available")
		app._map_changed(0)
		app.placement_option.select(1)
		app._start_match()
		app.bot_timer.stop()
		await settle()
		expect(app.engine.players[0].hero_id == v6_hero, "new hero survives menu setup")
		_check_game_geometry()
		await _capture("v6-game")
		app._return_menu()
		await settle()
		app.set_option.select(5)
		app._set_changed(5)
		await settle()
		expect(app.hero_buttons.size() == 4, "Buffy set displays four hero cards")
		for item in app.hero_buttons:
			_check_menu_card_content(item.button,item.button.get_global_rect())
		await _capture("buffy-menu")
		var buffy_hero = ["buffy","buffy","angel","spike","willow"][case_index]
		app._choose_hero(buffy_hero)
		app.buffy_sidekick_option.select(case_index%2)
		app.count_option.select(3 if case_index%2 == 1 else 2)
		app._opponent_changed(0)
		expect(_select_metadata(app.map_option,"sunnydale_high" if case_index%2 == 0 else "the_bronze"),"Buffy maps support full four-player rosters")
		app._map_changed(0)
		app.placement_option.select(1)
		app._start_match()
		app.bot_timer.stop()
		await settle()
		expect(app.engine.players[0].hero_id == buffy_hero,"Buffy hero menu choice reaches engine")
		expect(app.buffy_sidekick_option.disabled == (buffy_hero != "buffy"),"Buffy sidekick selection enabled only for Buffy")
		if buffy_hero == "buffy":
			expect(app.engine.players[0].buffy_sidekick == ("giles" if case_index%2 == 0 else "xander"),"chosen Buffy sidekick survives game setup")
		_check_game_geometry()
		await _capture("buffy-game")
		for v8_hero in ["little_red","beowulf","houdini","genie"]:
			app._return_menu()
			await settle()
			app.engine.setup([v8_hero,"king_arthur"],1,808,"heorot" if v8_hero in ["little_red","beowulf"] else "king_solomons_mine")
			app._open_match()
			app.bot_timer.stop()
			await settle()
			if app.engine.phase == "effect_choice": app._skip_ability()
			for n in range(3):
				if app.engine.phase == "combat_report": app._continue_combat()
			await settle()
			_check_game_geometry()
			app._show_player_info(0)
			await settle()
			_check_hit_bounds(app,Rect2(Vector2.ZERO,app.get_viewport_rect().size))
			app._close_popup()
			await settle()
			app._begin_move()
			await settle()
			_check_game_geometry()
			await _capture("v8-"+v8_hero+"-maneuver")
		for bol2_hero in ["achilles","bloody_mary","sun_wukong","yennenga","nikola_tesla","dr_jill_trent","annie_christmas","golden_bat"]:
			app._return_menu()
			await settle()
			app.engine.interactive = false
			app.engine.setup([bol2_hero,"king_arthur"],1,1010,"point_pleasant" if bol2_hero in ["nikola_tesla","dr_jill_trent"] else "mcminnville_or" if bol2_hero in ["annie_christmas","golden_bat"] else "hanging_gardens")
			app.engine.interactive = true
			app._open_match()
			app.bot_timer.stop()
			await settle()
			_check_game_geometry()
			app._show_map_rules(true)
			await settle()
			_check_hit_bounds(app,Rect2(Vector2.ZERO,app.get_viewport_rect().size))
			app._close_popup()
			await settle()
			await _capture("v9-"+bol2_hero)
	var file = FileAccess.open(output_dir.path_join("responsive-results.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "cases": report}, "\t"))
	print("RESPONSIVE_TESTS ", checks, " checks, ", failures, " failures, ", report.size(), " sizes")
	quit(0 if failures == 0 else 1)
