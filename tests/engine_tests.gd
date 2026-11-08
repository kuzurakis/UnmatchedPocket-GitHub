extends SceneTree
const EngineModel = preload("res://scripts/game_engine.gd")
var failures: int = 0
var assertions: int = 0

func _init() -> void:
	_test_setup_and_maneuver()
	_test_maneuver_boost()
	_test_combat_and_range()
	_test_effects()
	_test_rule_regressions()
	_test_exhaustion_and_save()
	_test_interactive_moves()
	_test_interactive_looking_glass()
	_test_matches()
	_test_interactive_matches()
	_test_real_boards()
	_test_manual_placement()
	_test_team_rules()
	_test_team_matches()
	_test_unusual_schemes_v4()
	_test_new_hero_rules()
	_test_all_new_cards()
	_test_new_set_matches()
	print("ENGINE_TESTS: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func check(condition: bool, detail: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("TEST FAILED: " + detail)

func game(ids: Array = ["alice", "king_arthur"], level: int = 1):
	var g = EngineModel.new()
	g.setup(ids, level, 12345)
	return g

func card(g, owner: int, id: String) -> Dictionary:
	for c in g.heroes[g.players[owner].hero_id].cards:
		if str(c.id) == id: return c.duplicate(true)
	return {}

func _test_setup_and_maneuver() -> void:
	var g = game(["alice", "king_arthur", "medusa", "sinbad"])
	check(g.players.size() == 4 and g.fighters.size() == 10, "four heroes and six helpers")
	for p in g.players:
		check(p.hand.size() == 5 and p.deck.size() == 25, "initial five-card hands, 30-card decks")
	check(g.actions_left == 2 and g.active == 0, "two actions start")
	var before := int(g.players[0].hand.size())
	check(g.begin_maneuver(), "maneuver begins")
	check(g.players[0].hand.size() == before + 1 and g.actions_left == 1 and g.phase == "move", "draw once and charge one action")
	check(g.move_fighter(0, 0), "zero-space movement is legal")
	check(not g.move_fighter(0, 0), "fighter moves only once per maneuver")
	var helper := 1
	check(g.move_fighter(helper, int(g.fighters[helper].node)), "helper can also move during same maneuver")
	g.finish_maneuver()
	check(g.phase == "action" and g.active == 0, "finish maneuver keeps remaining action")
	# Friendly fighters can be passed through; enemies block movement.
	g.fighters[0].node = 10
	g.fighters[1].node = 11
	g.fighters[2].node = 12
	check(g.legal_moves(0).has(16), "friendly fighters may be passed")
	check(not g.legal_moves(0).has(12), "occupied enemy spaces cannot be entered")
	check(not g.legal_moves(0).has(11), "cannot stop on friendly fighter")
	check(not g.attack(0, 2, -1), "invalid attack index rejected")

func _test_combat_and_range() -> void:
	var g = game()
	for f in g.fighters: f.node = 20 + int(f.id)
	g.fighters[0].node = 5
	g.fighters[2].node = 6
	g.players[0].hand = [card(g, 0, "feint")]
	g.players[1].hand = [card(g, 1, "feint")]
	check(g.legal_targets(0, 0).has(2), "melee adjacent attack")
	g.attack(0, 2, 0)
	# Big Alice's +2 applies to printed 2, even though her Feint was cancelled.
	check(g.last_combat.damage == 2, "Alice big attack ability survives Feint")
	check(g.fighters[2].hp == 16 and g.players[1].discard.size() == 1, "damage and defending discard")
	var ranged = game(["medusa", "sinbad"])
	ranged.fighters[0].node = 0
	ranged.fighters[4].node = 12
	ranged.players[0].hand = [card(ranged, 0, "gaze_of_stone")]
	check(ranged.legal_targets(0, 0).has(4), "ranged shared zone")
	ranged.fighters[4].node = 24
	check(not ranged.legal_targets(0, 0).has(4), "ranged does not reach other zone")
	var pending = game(["sinbad", "king_arthur"])
	pending.active = 1
	pending.fighters[2].node = 1
	pending.players[1].hand = [card(pending, 1, "excalibur")]
	pending.players[0].hand = [card(pending, 0, "exploit")]
	check(pending.attack(2, 0, 0) and pending.phase == "defend", "human gets defense decision")
	check(not pending.defend(99), "invalid human defense rejected")
	check(pending.defend(0) and pending.pending_combat.is_empty(), "valid human defense resolves")
	check(pending.last_combat.damage == 2, "six attack versus four defense")

func _test_maneuver_boost() -> void:
	var g = game()
	var drawn := card(g, 0, "looking_glass")
	g.players[0].deck = [drawn]
	var old_hand := int(g.players[0].hand.size())
	check(not g.boost_maneuver(0), "cannot boost outside maneuver")
	g.begin_maneuver()
	check(g.players[0].hand.size() == old_hand + 1 and not g.maneuver_boosted, "mandatory draw precedes optional boost")
	check(g.boost_maneuver(old_hand), "newly drawn card may boost same maneuver")
	check(g.maneuver_distance == 6 and g.players[0].hand.size() == old_hand, "drawn boost adds four movement and discards one card")
	check(not g.boost_maneuver(0), "cannot boost maneuver twice")
	var restored = EngineModel.new()
	check(restored.load_state(JSON.parse_string(JSON.stringify(g.save_state()))), "save boosted maneuver")
	check(restored.maneuver_boosted and restored.maneuver_distance == 6 and not restored.boost_maneuver(0), "save retains boosted flag and prevents double boost")
	g = game()
	g.begin_maneuver()
	g.move_fighter(0, int(g.fighters[0].node))
	check(not g.boost_maneuver(0), "cannot boost after a fighter movement")
	g = game()
	g.players[0].hand = [card(g, 0, "looking_glass")]
	g.begin_maneuver(0)
	check(g.maneuver_boosted and g.maneuver_distance == 6 and g.players[0].hand.size() == 1, "preselected boost shortcut still draws then discards")
	g = game()
	g.players[0].deck.clear()
	g.fighters[0].hp = 2
	var initial_discard := int(g.players[0].discard.size())
	g.begin_maneuver(0)
	check(g.phase == "game_over" and g.players[0].discard.size() == initial_discard, "fatigue eliminates before optional boost is spent")

func _test_effects() -> void:
	var g = game(["sinbad", "king_arthur"])
	for f in g.fighters: f.node = 20 + int(f.id)
	g.fighters[0].node = 5
	g.fighters[2].node = 6
	g.players[0].discard = [card(g, 0, "voyage_to_the_island_that_was_a_whale")]
	g.players[0].hand = [card(g, 0, "voyage_home")]
	g.players[1].hand = []
	g.attack(0, 2, 0)
	check(g.last_combat.attack_value == 3, "voyage counts existing discard only")
	check(g.players[0].hand.size() == 1 and g.players[0].hand[0].voyage, "Voyage Home retrieves other voyages")
	check(g.players[0].discard.size() == 1 and g.players[0].discard[0].effect == "voyage_home", "current voyage goes to discard after effects")
	var arthur = game(["king_arthur", "alice"])
	for f in arthur.fighters: f.node = 20 + int(f.id)
	arthur.fighters[0].node = 5
	arthur.fighters[2].node = 6
	arthur.players[0].hand = [card(arthur, 0, "excalibur"), card(arthur, 0, "noble_sacrifice")]
	arthur.players[1].hand = [card(arthur, 1, "feint")]
	arthur.attack(0, 2, 0, 1)
	check(arthur.last_combat.attack_value == 9, "effectless Excalibur keeps Arthur boost against Feint")
	var prevent = game(["sinbad", "king_arthur"])
	for f in prevent.fighters: f.node = 20 + int(f.id)
	prevent.fighters[0].node = 5
	prevent.fighters[3].node = 6
	prevent.players[0].hand = [card(prevent, 0, "voyage_to_the_city_of_the_man_eating_apes")]
	prevent.players[1].hand = [card(prevent, 1, "bewilderment")]
	prevent.attack(0, 3, 0)
	check(prevent.fighters[3].hp == 7, "Bewilderment prevents combat and later effect damage in this combat")

func _test_exhaustion_and_save() -> void:
	var g = game(["sinbad", "king_arthur", "medusa"])
	g.players[0].deck.clear()
	g.begin_maneuver()
	check(g.fighters[0].hp == 13 and g.fighters[1].hp == 4, "exhaustion harms each friendly fighter")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.save_state()))
	var restored = EngineModel.new()
	check(restored.load_state(saved), "JSON save restores mid-maneuver")
	check(restored.phase == "move" and restored.players[0].deck.is_empty(), "save retains phase and deck")
	restored.finish_maneuver()
	check(restored.actions_left == 1, "restored maneuver finishes")
	g = game(["sinbad", "king_arthur", "medusa"])
	g.players[0].deck.clear()
	g.fighters[0].hp = 2
	g.begin_maneuver()
	check(not g.players[0].alive and g.active == 1 and g.phase == "action", "exhaustion elimination skips dead active player")
	check(not g.fighters[1].alive, "eliminating hero removes helpers")
	var hand_game = game()
	while hand_game.players[0].hand.size() < 9: hand_game.players[0].hand.append(card(hand_game, 0, "feint"))
	hand_game.end_turn()
	check(hand_game.phase == "discard" and hand_game.active == 0, "hand limit checked at turn end")
	hand_game.discard_card(0)
	hand_game.discard_card(0)
	check(hand_game.active == 1 and hand_game.actions_left == 2, "discarding to seven continues turn order")

func _test_rule_regressions() -> void:
	var g = game(["medusa", "sinbad"])
	g.fighters[0].node = 0
	g.fighters[1].node = 4
	g.fighters[2].node = 20
	g.fighters[3].node = 24
	g.fighters[4].node = 23
	g.fighters[5].node = 19
	g.players[0].hand = [card(g, 0, "a_momentary_glance")]
	check(g.scheme(0, 0), "mandatory damage scheme can resolve with only friendly eligible fighter")
	check(g.fighters[0].hp == 14, "Momentary Glance must hit friendly when no enemy eligible")
	var jaws = game()
	for f in jaws.fighters: f.node = 20 + int(f.id)
	jaws.fighters[1].node = 5
	jaws.fighters[2].node = 6
	jaws.players[0].hand = [card(jaws, 0, "jaws_that_bite")]
	jaws.players[1].hand = [{"id": "test_retaliation", "name": "Контрудар", "type": "defense", "fighter": "hero", "value": 0, "boost": 0, "effects": [{"timing": "after", "kind": "damage", "target": "opposing_combatant", "amount": 10}]}]
	jaws.attack(1, 2, 0)
	check(not jaws.fighters[1].alive and jaws.fighters[2].hp == 14, "defeated Jabberwock has no adjacent spaces for Jaws")
	var simultaneous = game(["sinbad", "king_arthur"])
	for f in simultaneous.fighters: f.node = 20 + int(f.id)
	simultaneous.fighters[0].node = 5
	simultaneous.fighters[2].node = 6
	simultaneous.players[0].hand = [{"id": "test_lethal", "name": "Удар", "type": "attack", "fighter": "hero", "value": 100, "boost": 0, "effects": []}]
	simultaneous.players[1].hand = [{"id": "test_retaliation", "name": "Контрудар", "type": "defense", "fighter": "hero", "value": 0, "boost": 0, "effects": [{"timing": "after", "kind": "damage", "target": "opposing_combatant", "amount": 100}]}]
	simultaneous.attack(0, 2, 0)
	check(simultaneous.fighters[0].alive and not simultaneous.fighters[2].alive, "last opponent defeat ends game before their after-combat retaliation")
	check(simultaneous.phase == "game_over" and simultaneous.winner == 0, "last opposing hero defeated ends duel immediately")
	var pending = game(["sinbad", "king_arthur"])
	pending.active = 1
	pending.fighters[2].node = 1
	pending.players[1].hand = [card(pending, 1, "excalibur")]
	pending.players[0].hand = [card(pending, 0, "exploit")]
	pending.attack(2, 0, 0)
	var restored = EngineModel.new()
	check(restored.load_state(JSON.parse_string(JSON.stringify(pending.save_state()))), "save restores pending human defense")
	check(restored.phase == "defend" and restored.defend(0) and restored.last_combat.damage == 2, "restored human defense resolves identical combat")
	var original = game(["sinbad", "king_arthur", "medusa", "alice"], 2)
	for p in original.players: p.bot = true
	for i in range(13): original.bot_step()
	var clone = EngineModel.new()
	clone.load_state(JSON.parse_string(JSON.stringify(original.save_state())))
	for i in range(20):
		original.bot_step()
		clone.bot_step()
	var original_state = JSON.parse_string(JSON.stringify(original.save_state()))
	var cloned_state = JSON.parse_string(JSON.stringify(clone.save_state()))
	if original_state != cloned_state:
		for key in original_state:
			if original_state[key] != cloned_state[key]: print("STATE_DIFF ", key, " ORIGINAL=", original_state[key], " RESTORED=", cloned_state[key])
	check(original_state == cloned_state, "save preserves random state and deterministic subsequent bot play")

func _test_matches() -> void:
	var ids := ["alice", "king_arthur", "medusa", "sinbad"]
	for level in range(3):
		for count in range(2, 5):
			for seed_value in range(1, 6):
				var roster: Array = []
				for i in range(count): roster.append(ids[(i + seed_value) % 4])
				var g = EngineModel.new()
				g.setup(roster, level, seed_value * 1000 + count)
				for p in g.players: p.bot = true
				var steps := 0
				while g.winner == -1 and steps < 1800:
					g.bot_step()
					steps += 1
					if steps % 11 == 0:
						var restored = EngineModel.new()
						check(restored.load_state(JSON.parse_string(JSON.stringify(g.save_state()))), "match save/restore")
						g = restored
					for f in g.fighters:
						check(int(f.hp) >= 0 and int(f.hp) <= int(f.max_hp), "fighter health within limits")
					var occupied := {}
					for f in g.fighters:
						if not f.alive: continue
						check(not occupied.has(int(f.node)), "one living fighter per space")
						occupied[int(f.node)] = true
					check(g.phase in ["action", "move", "discard", "game_over"], "bot game cannot await human defense")
				check(g.winner != -1 and g.phase == "game_over", "bots finish level %d count %d seed %d after %d steps" % [level, count, seed_value, steps])
				print("MATCH level=%d players=%d seed=%d steps=%d winner=%d" % [level, count, seed_value, steps, g.winner])

func save_clone(g):
	var clone = EngineModel.new()
	check(clone.load_state(JSON.parse_string(JSON.stringify(g.save_state()))), "interactive state roundtrip: " + g.phase)
	return clone

func setup_close(g) -> void:
	for f in g.fighters: f.node = 20 + int(f.id)
	g.fighters[0].node = 5
	g.fighters[2].node = 6
	g.players[1].hand = []

func _test_interactive_moves() -> void:
	var g = game()
	setup_close(g)
	g.interactive = true
	g.players[0].hand = [card(g, 0, "the_other_side_of_the_mushroom")]
	var hp := int(g.fighters[2].hp)
	check(g.attack(0, 2, 0) and g.phase == "attack_notice", "interactive attacks pause before defense/damage")
	check(g.fighters[2].hp == hp and g.players[1].discard.is_empty(), "notice does not resolve hidden attack")
	g = save_clone(g)
	check(g.continue_attack() and g.phase == "combat_report", "continue attack reveals bot defense and combat report")
	check(g.combat_report.attack_card.id == "the_other_side_of_the_mushroom" and g.combat_report.damage == 5, "report retains cards and actual values")
	check(g.fighters[0].node == 5 and g.alice_size[0] == "big", "after-combat effects wait for report acknowledgement")
	g = save_clone(g)
	g.continue_combat()
	check(g.phase == "effect_move" and g.pending_choice.fighter == 0, "human Alice movement is manual")
	check(g.alice_size[0] == "big" and g.fighters[0].node == 5, "size change waits until preceding movement completes")
	check(not g.choose_effect_node(99), "illegal effect destination rejected")
	g = save_clone(g)
	var destination := int(g.pending_choice.legal.back())
	check(g.choose_effect_node(destination), "manual after-combat destination accepted")
	check(g.fighters[0].node == destination and g.alice_size[0] == "small", "manual move then size change retains exact order")
	check(g.phase == "combat_report" and g.combat_report.stage == "effects" and not g.combat_report.effect_logs.is_empty(), "effect results pause before action completion")
	g = save_clone(g)
	g.continue_combat()
	check(g.phase == "action" and g.actions_left == 1 and g.pending_combat.is_empty(), "final acknowledgement completes exactly one action")
	# A winning Skirmish lets the human move either fighter, including an enemy.
	g = game()
	setup_close(g)
	g.interactive = true
	g.players[0].hand = [card(g, 0, "skirmish")]
	g.attack(0, 2, 0)
	g.continue_attack()
	g.continue_combat()
	check(g.phase == "effect_move" and g.pending_choice.allowed_fighters.has(0) and g.pending_choice.allowed_fighters.has(2), "Skirmish exposes either combatant")
	check(g.choose_effect_fighter(2), "human may select enemy fighter for Skirmish")
	var enemy_destination := int(g.pending_choice.legal.back())
	g.choose_effect_node(enemy_destination)
	check(g.fighters[2].node == enemy_destination and g.fighters[0].node == 5, "manual enemy movement applies to selected enemy only")
	# Group effects do not skip helpers and let the human choose their order.
	g = game()
	setup_close(g)
	g.interactive = true
	g.players[0].hand = [card(g, 0, "mad_as_a_hatter")]
	g.attack(0, 2, 0)
	g.continue_attack()
	g.continue_combat()
	check(g.pending_choice.allowed_fighters.has(0) and g.pending_choice.allowed_fighters.has(1), "group effect offers both allied fighters")
	g.choose_effect_fighter(1)
	g.choose_effect_node(int(g.fighters[1].node))
	check(g.phase == "effect_move" and not g.pending_choice.allowed_fighters.has(1), "each fighter moves at most once per group effect")
	g.skip_effect()
	check(g.phase == "combat_report" and g.alice_size[0] == "small", "skipping remaining group movement resumes following effect")
	# A scheme controlled by the human can move enemy fighters too.
	g = game(["king_arthur", "sinbad"])
	g.interactive = true
	g.players[0].hand = [card(g, 0, "command_the_storms")]
	check(g.scheme(1, 0) and g.phase == "effect_move", "scheme movement pauses directly")
	check(g.pending_choice.allowed_fighters.size() == 4 and g.choose_effect_fighter(2), "Command Storms gives control of every fighter")
	g.choose_effect_node(int(g.pending_choice.legal.back()))
	g = save_clone(g)
	check(not g.pending_choice.allowed_fighters.has(2), "saved group movement retains completed fighters")
	g.skip_effect()
	check(g.phase == "combat_report" and g.combat_report.kind == "scheme", "scheme produces final effect report")
	g.continue_combat()
	check(g.phase == "action" and g.actions_left == 1, "scheme completes after effect acknowledgement")
	# Revival placement is controlled by the human as well.
	g = game(["medusa", "sinbad"])
	g.interactive = true
	g.fighters[1].alive = false
	g.fighters[1].hp = 0
	g.players[0].hand = [card(g, 0, "winged_frenzy")]
	g.scheme(0, 0)
	g.skip_effect()
	check(g.phase == "effect_move" and g.pending_choice.kind == "revive_sidekick", "revival asks for placement")
	var revive_node := int(g.pending_choice.legal.back())
	g.choose_effect_node(revive_node)
	check(g.fighters[1].alive and g.fighters[1].hp == 1 and g.fighters[1].node == revive_node, "human chooses revived harpy's legal node")

func _test_interactive_looking_glass() -> void:
	var g = game()
	g.interactive = true
	g.active = 1
	g.fighters[2].node = 1
	g.players[1].hand = [card(g, 1, "excalibur")]
	g.players[0].hand = [card(g, 0, "looking_glass")]
	g.attack(2, 0, 0)
	g.continue_attack()
	check(g.phase == "defend" and g.defend(0), "human defense is chosen after notice")
	g.continue_combat()
	check(g.phase == "effect_choice" and g.pending_choice.options.size() == 3 and not g.skip_effect(), "Looking Glass requires two different manual choices")
	g = save_clone(g)
	g.choose_effect_option(2)
	check(g.phase == "effect_choice" and g.pending_choice.options.size() == 2 and g.pending_choice.remaining_count == 1, "Looking Glass selects both different effects before resolving either")
	g = save_clone(g)
	g.choose_effect_option(1)
	check(g.phase == "effect_move" and g.pending_choice.kind == "place", "Looking Glass placement is manual")
	g = save_clone(g)
	var destination := int(g.pending_choice.legal.back())
	g.choose_effect_node(destination)
	check(g.fighters[0].node == destination and g.fighters[0].hp == 12 and g.phase == "combat_report", "Looking Glass applies chosen place and heal options")
	check(not g.choose_effect_option(0), "no third Looking Glass option")

func _advance_interactive(g) -> void:
	match g.phase:
		"attack_notice": check(g.continue_attack(), "advance attack notice")
		"combat_report": check(g.continue_combat(), "advance combat report")
		"effect_choice": check(g.choose_effect_option(0), "advance effect options")
		"effect_move":
			if int(g.pending_choice.fighter) < 0: check(g.choose_effect_fighter(int(g.pending_choice.allowed_fighters.back())), "advance effect fighter")
			if g.pending_choice.legal.is_empty(): check(g.skip_effect(), "skip no legal effect destination")
			else: check(g.choose_effect_node(int(g.pending_choice.legal.back())), "advance effect destination")
		"defend":
			var legal: Array = g.legal_defenses()
			check(g.defend(int(legal[0]) if not legal.is_empty() else -1), "advance human defense")
		"action":
			if g.players[g.active].bot: g.bot_step()
			else: g._bot_action()
		"move":
			if g.players[g.active].bot: g.bot_step()
			else:
				for f in g.fighters:
					if f.alive and int(f.owner) == int(g.active):
						var legal: Array = g.legal_moves(int(f.id))
						if not legal.is_empty(): g.move_fighter(int(f.id), int(legal.back()))
				g.finish_maneuver()
		"discard": g.discard_card(0)
		_: check(false, "unsupported interactive phase: " + g.phase)

func _test_interactive_matches() -> void:
	var ids := ["alice", "king_arthur", "medusa", "sinbad"]
	for level in range(3):
		for count in range(2, 5):
			for seed_value in range(1, 5):
				var roster: Array = []
				for i in range(count): roster.append(ids[(i + seed_value) % 4])
				var g = EngineModel.new()
				g.setup(roster, level, seed_value * 100 + count)
				g.interactive = true
				var steps := 0
				var initial_failures := failures
				while g.winner == -1 and steps < 2000:
					_advance_interactive(g)
					steps += 1
					if failures > initial_failures: break
					if steps % 7 == 0: g = save_clone(g)
				check(g.winner >= 0 and g.phase == "game_over", "interactive game finishes level%d count%d seed%d in%d steps" % [level, count, seed_value, steps])
				print("INTERACTIVE_MATCH level=%d players=%d seed=%d steps=%d winner=%d" % [level, count, seed_value, steps, g.winner])

func _test_real_boards() -> void:
	var ids := ["alice", "king_arthur", "medusa", "sinbad"]
	for board_name in ["marmoreal", "sarpedon"]:
		var g = EngineModel.new()
		g.setup(ids, 1, 100, board_name)
		check(g.board_id == board_name and not g.board_data.is_empty(), "real board metadata: " + board_name)
		check(g.nodes.size() == (31 if board_name == "marmoreal" else 38), "real graph node count: " + board_name)
		for owner in range(4):
			var hero := int(g.hero_fighter(owner))
			check(g.fighters[hero].node == g.board_data.starts[owner], "official hero start: " + board_name)
			for f in g.fighters:
				if int(f.owner) == owner and not f.hero: check(g._same_zone(int(f.node), int(g.fighters[hero].node)), "helpers start in hero zone: " + board_name)
		for node in g.nodes:
			for neighbor in node.neighbors:
				check(g._distance(int(node.id), int(neighbor)) == 1 and g.nodes[int(neighbor)].neighbors.has(int(node.id)), "graph distance uses real reciprocal edge")
		var clone = save_clone(g)
		check(clone.board_id == board_name and clone.nodes.size() == g.nodes.size() and clone.nodes[0].pos == g.nodes[0].pos, "save restores real map geometry")
		for level in range(3):
			for count in range(2, 5):
				for interactive_mode in [false, true]:
					var roster: Array = []
					for i in range(count): roster.append(ids[(i + level) % 4])
					g = EngineModel.new()
					g.setup(roster, level, 1000 + level * 10 + count, board_name)
					g.interactive = interactive_mode
					if not interactive_mode:
						for p in g.players: p.bot = true
					var steps := 0
					var initial_failures := failures
					while g.winner == -1 and steps < 2000:
						if interactive_mode: _advance_interactive(g)
						else: g.bot_step()
						steps += 1
						if steps % 13 == 0: g = save_clone(g)
						if failures > initial_failures: break
					check(g.winner >= 0 and g.phase == "game_over", "real map game ends: %s level%d count%d interactive%s" % [board_name, level, count, interactive_mode])
					print("BOARD_MATCH board=%s level=%d players=%d interactive=%s steps=%d winner=%d" % [board_name, level, count, interactive_mode, steps, g.winner])

func team_game(roster: Array = ["alice", "king_arthur", "medusa", "sinbad"], board_name: String = "training", manual: bool = false):
	var g = EngineModel.new()
	g.setup(roster, 2, 1001, board_name, {"mode": "teams", "start_slots": [0, 1, 2, 3], "human_placement": manual})
	return g

func _test_manual_placement() -> void:
	var ids := ["alice", "king_arthur", "medusa", "sinbad"]
	for board_name in ["marmoreal", "sarpedon"]:
		for own_slot in range(4):
			for rotation in range(4):
				var roster: Array = []
				var slots: Array = []
				for i in range(4):
					roster.append(ids[(i + rotation) % 4])
					slots.append((own_slot + i) % 4)
				var g = EngineModel.new()
				g.setup(roster, 1, 111, board_name, {"mode": "teams", "start_slots": slots, "human_placement": true})
				check(g.phase == "setup" and g.setup_fighter == g.hero_fighter(0), "manual placement begins with human hero")
				check(not g.finish_setup() and not g.begin_maneuver(), "cannot start battle before placement")
				var occupied := {}
				for f in g.fighters:
					if not f.placed: continue
					check(not occupied.has(int(f.node)), "automatic setup never overlaps fighters")
					occupied[int(f.node)] = true
					if not f.hero: check(not g.board_data.starts.has(float(f.node)), "helpers never occupy reserved official hero start")
				var assigned_start := int(g.board_data.starts[own_slot])
				check(g.legal_setup_nodes(g.setup_fighter) == [assigned_start], "hero confirms assigned menu start")
				check(not g.place_setup_fighter(g.setup_fighter, -1), "illegal starting space rejected")
				g = save_clone(g)
				while g.setup_fighter >= 0:
					var fid := int(g.setup_fighter)
					var legal: Array = g.legal_setup_nodes(fid)
					check(not legal.is_empty(), "each human fighter has legal setup placement")
					for node in legal:
						check(g._occupant(int(node)) < 0, "placement offers only unoccupied spaces")
						if not g.fighters[fid].hero: check(g._same_zone(int(node), assigned_start), "helper placement stays in own hero zone")
					check(g.place_setup_fighter(fid, int(legal.back())), "manual fighter placement succeeds")
					g = save_clone(g)
				check(g.phase == "setup" and g.finish_setup(), "all placements await explicit start")
				check(g.phase == "action" and g.active == 0 and g.actions_left == 2, "manual setup does not consume turn actions")
				for f in g.fighters: check(f.placed, "all figures placed when battle begins")
	var g = EngineModel.new()
	g.setup(ids, 1, 10, "training", {"mode": "teams", "start_slots": [3, 3, -1, 99]})
	check(g.start_slots == [3, 0, 1, 2], "invalid duplicate starting slots normalize to distinct slots")
	var legacy: Dictionary = g.save_state()
	legacy.version = 1
	for key in ["match_mode", "winner_team", "start_slots", "setup_fighter", "setup_order"]: legacy.erase(key)
	for p in legacy.players: p.erase("team")
	for f in legacy.fighters: f.erase("placed")
	var old = EngineModel.new()
	check(old.load_state(JSON.parse_string(JSON.stringify(legacy))) and old.match_mode == "ffa", "v1 saves migrate to free-for-all with placed fighters")
	check(old.players[2].team == 2 and old.fighters[0].placed, "legacy team and placement fields are normalized")

func _test_team_rules() -> void:
	var g = team_game()
	check(g.match_mode == "teams" and g.players[0].team == 0 and g.players[1].team == 1 and g.players[2].team == 0 and g.players[3].team == 1, "alternating 2v2 teams")
	check(g.are_allies(0, 2) and g.are_allies(1, 3) and g.is_enemy(0, 1) and not g.is_enemy(0, 2), "team alliance predicates")
	for f in g.fighters: f.node = 15 + int(f.id)
	g.fighters[0].node = 6
	g.fighters[2].node = 7
	g.fighters[4].node = 5
	g.fighters[8].node = 11
	g.players[0].hand = [card(g, 0, "feint")]
	var legal: Array = g.legal_targets(0, 0)
	check(legal.has(2) and legal.has(8) and not legal.has(4), "both opponents are valid attack targets, ally is excluded")
	check(not g.attack(0, 4, 0), "attack cannot target ally")
	g.fighters[0].node = 0
	g.fighters[4].node = 1
	g.fighters[2].node = 12
	check(g.legal_moves(0).has(2) and not g.legal_moves(0).has(1), "can pass allied fighter but cannot stop on it")
	g.fighters[4].node = 4
	g.fighters[2].node = 1
	check(not g.legal_moves(0).has(2), "enemy still blocks movement")
	var public_target := int(g._public_target(0))
	check(public_target >= 0 and g.is_enemy(0, int(g.fighters[public_target].owner)), "public target heuristic excludes teammate")
	# Enemy-only abilities and schemes do not harm the other allied player.
	g = team_game(["medusa", "king_arthur", "alice", "sinbad"])
	g.fighters[0].node = 12
	var allied_hp := int(g.fighters[g.hero_fighter(2)].hp)
	g._start_turn_ability()
	check(g.fighters[g.hero_fighter(2)].hp == allied_hp, "Medusa ability ignores allied hero")
	var own_ctx := {"owner": 0, "self": 0, "opponent": g.hero_fighter(2), "opponent_owner": 2, "card": {}, "value": 0, "won": false}
	var ally_hand := int(g.players[2].hand.size())
	g._run_effects({"effects": [{"timing": "test", "kind": "opponent_discard", "amount": 1}]}, "test", own_ctx)
	check(g.players[2].hand.size() == ally_hand, "opponent discard cannot consume allied hand")
	# Any-fighter text may still target a friendly fighter deliberately; AI
	# declines a scheme when only allies are eligible instead of treating them as enemies.
	g.fighters[0].node = 0
	for f in g.fighters:
		if g.is_enemy(0, int(f.owner)): f.node = 24 - int(f.id) % 3
	var glance := card(g, 0, "a_momentary_glance")
	check(g._scheme_score(glance, 0) < 0, "bot does not play targeted damage scheme against allies")
	g = team_game(["king_arthur", "medusa", "alice", "sinbad"])
	var ally_health: Dictionary = {}
	for f in g.fighters:
		if g.are_allies(0, int(f.owner)): ally_health[int(f.id)] = int(f.hp)
	g._restless_spirits(1, 0)
	for id in ally_health: check(g.fighters[int(id)].hp == ally_health[id], "Restless Spirits ignores teammate fighters")
	# Official team rules keep a defeated hero's sidekicks in play and keep
	# giving that player turns; victory is based on the two opposing heroes.
	g = team_game()
	g._damage(0, 99)
	check(not g.fighters[0].alive and g.fighters[1].alive and g.players[0].alive, "team hero defeat keeps own helper and player in play")
	check(not g._check_winner(), "one allied hero defeated is not team elimination")
	g.fighters[1].node = 5
	g.fighters[2].node = 6
	g.players[0].hand = [card(g, 0, "feint")]
	check(g.legal_targets(1, 0).has(2), "human may keep playing surviving helper")
	check("помощники" in g.state_summary(0), "status explains surviving helper continuation")
	g.end_turn()
	check(g.active == 1, "turn order remains alternating after hero defeat")
	g._damage(1, 99)
	check(not g.players[0].alive and g.players[2].alive and not g._check_winner(), "all human fighters gone leaves allied bot in match")
	g.active = 3
	g.end_turn()
	check(g.active == 1, "turn order skips player with no surviving fighters")
	g._damage(2, 99)
	g._damage(8, 99)
	check(g.fighters[3].alive and g.fighters[9].alive and g._check_winner(), "two opposing hero defeats win even with opposing helpers alive")
	check(g.winner_team == 0 and g.winner == 2 and g.are_allies(g.winner, 0), "allied bot victory is a human team victory")
	g = save_clone(g)
	check(g.match_mode == "teams" and g.winner_team == 0 and g.winner == 2, "team victory survives JSON save")
	g = team_game()
	g._damage(0, 99)
	g._damage(4, 99)
	check(g._check_winner() and g.winner_team == 1 and g.players[0].alive, "own helpers cannot prevent loss when both own team heroes defeated")
	g = team_game()
	g.active = 3
	for owner in range(4): g._damage(g.hero_fighter(owner), 99)
	check(g._check_winner() and g.winner_team == 1 and g.are_allies(g.winner, 3), "active team wins simultaneous final hero defeats")
	var bad = EngineModel.new()
	bad.setup(["alice", "king_arthur", "medusa"], 1, 10, "training", {"mode": "teams"})
	check(bad.match_mode == "ffa", "team mode requires exactly four players")

func _test_team_matches() -> void:
	var ids := ["alice", "king_arthur", "medusa", "sinbad"]
	for board_name in ["marmoreal", "sarpedon"]:
		for level in range(3):
			for interactive_mode in [false, true]:
				for seed_value in range(3):
					var roster: Array = []
					for i in range(4): roster.append(ids[(i + seed_value) % 4])
					var g = EngineModel.new()
					g.setup(roster, level, 100 + level * 10 + seed_value, board_name, {"mode": "teams", "start_slots": [seed_value % 4, (seed_value + 1) % 4, (seed_value + 2) % 4, (seed_value + 3) % 4]})
					g.interactive = interactive_mode
					if not interactive_mode:
						for p in g.players: p.bot = true
					var steps := 0
					var initial_failures := failures
					while g.winner == -1 and steps < 2500:
						if interactive_mode: _advance_interactive(g)
						else: g.bot_step()
						steps += 1
						if not g.last_combat.is_empty():
							check(g.is_enemy(int(g.fighters[int(g.last_combat.attacker)].owner), int(g.fighters[int(g.last_combat.target)].owner)), "AI and human attacks never target teammate")
						if not g.pending_combat.is_empty(): check(g.is_enemy(int(g.pending_combat.attack_owner), int(g.pending_combat.defender_owner)), "pending team combat is between opponents")
						if steps % 11 == 0: g = save_clone(g)
						if failures > initial_failures: break
					check(g.winner >= 0 and g.phase == "game_over" and g.winner_team in [0, 1], "2v2 game finishes with team winner")
					print("TEAM_MATCH board=%s level=%d interactive=%s seed=%d steps=%d winner_team=%d" % [board_name, level, interactive_mode, seed_value, steps, g.winner_team])

func _test_unusual_schemes_v4() -> void:
	# Restless Spirits chooses spaces, rather than silently selecting a victim.
	var g = game(["king_arthur", "medusa", "sinbad"])
	g.interactive = true
	g.fighters[1].node = 0
	g.fighters[2].node = 1
	g.fighters[3].node = 2
	g.fighters[4].node = 6
	g.fighters[5].node = 7
	g.fighters[6].node = 23
	g.fighters[7].node = 24
	g.players[0].hand = [card(g, 0, "restless_spirits")]
	check(not g.scheme(0, 0) and g.players[0].hand.size() == 1 and g.actions_left == 2, "Merlin scheme rejects Arthur without consuming card or action")
	var original_deck := int(g.players[0].deck.size())
	check(g.scheme(1, 0) and g.phase == "effect_move" and g.pending_choice.kind == "spaces", "Restless Spirits asks human for first space")
	check(not g.choose_effect_node(24), "first spirit space must share Merlin zone")
	check(g.choose_effect_node(1) and g.pending_choice.stage == "second", "spirit first space accepted in Merlin zone")
	check(not g.choose_effect_node(24), "second spirit space must be adjacent to selected first")
	g = save_clone(g)
	check(g.choose_effect_node(2), "adjacent second spirit space accepted after save")
	check(g.fighters[2].hp == 14 and not g.fighters[3].alive, "spirits deal two to both chosen cells")
	check(g.players[0].hand.size() == 1 and g.players[0].deck.size() == original_deck - 1, "spirit kill draws exactly one")
	check(g.phase == "combat_report" and not g.combat_report.effect_logs.is_empty(), "spirits report actual damage and draw")
	# Multiple defeats still draw one card, as printed, rather than one per kill.
	g = game(["king_arthur", "medusa"])
	g.interactive = true
	g.fighters[1].node = 0
	g.fighters[3].node = 1
	g.fighters[4].node = 2
	g.players[0].hand = [card(g, 0, "restless_spirits")]
	g.scheme(1, 0)
	g.choose_effect_node(1)
	g.choose_effect_node(2)
	check(not g.fighters[3].alive and not g.fighters[4].alive and g.players[0].hand.size() == 1, "two spirit defeats produce one card total")
	# Normal damage, empty spaces, and team immunity have distinct reports/results.
	g = team_game(["king_arthur", "medusa", "alice", "sinbad"])
	g.interactive = true
	for f in g.fighters: f.node = 15 + int(f.id)
	g.fighters[1].node = 0
	g.fighters[2].node = 1
	g.fighters[6].node = 2
	var ally_hp := int(g.fighters[6].hp)
	g.players[0].hand = [card(g, 0, "restless_spirits")]
	g.scheme(1, 0)
	g.choose_effect_node(1)
	g.choose_effect_node(2)
	check(g.fighters[2].hp == 14 and g.fighters[6].hp == ally_hp and g.players[0].hand.is_empty(), "spirits ignore teammate and draw nothing without defeat")
	g = game(["king_arthur", "sinbad"])
	g.interactive = true
	g.fighters[1].node = 0
	g.players[0].hand = [card(g, 0, "restless_spirits")]
	g.scheme(1, 0)
	g.choose_effect_node(10)
	g.choose_effect_node(11)
	check("нет противников" in " ".join(g.combat_report.effect_logs), "empty spirit area explains why no damage occurred")
	# Prophecy takes two chosen cards, then explicitly chooses the top-card order.
	g = game(["king_arthur", "sinbad"])
	g.interactive = true
	g.players[0].hand = [card(g, 0, "prophecy")]
	g.players[0].deck = [card(g, 0, "excalibur"), card(g, 0, "the_holy_grail"), card(g, 0, "divine_intervention"), card(g, 0, "noble_sacrifice")]
	g.scheme(1, 0)
	check(g.pending_choice.action == "prophecy" and g.pending_choice.cards.size() == 4, "Prophecy exposes four owned top cards")
	g.choose_effect_option(3)
	g = save_clone(g)
	g.choose_effect_option(1)
	check(g.players[0].hand[0].id == "excalibur" and g.players[0].hand[1].id == "divine_intervention", "Prophecy gives exactly selected cards")
	check(g.pending_choice.stage == "order" and g.pending_choice.cards.size() == 2, "Prophecy asks remaining-card order")
	g.choose_effect_option(1)
	check(g.players[0].deck.back().id == "the_holy_grail" and g.players[0].deck.front().id == "noble_sacrifice", "Prophecy selected top order is preserved")
	# Glance/Jaws choose a fighter, not an automatically selected target.
	g = game(["medusa", "sinbad"])
	g.interactive = true
	g.fighters[0].node = 12
	g.players[0].hand = [card(g, 0, "a_momentary_glance")]
	g.scheme(0, 0)
	check(g.phase == "effect_choice" and g.pending_choice.kind == "fighters", "Momentary Glance asks for fighter target")
	var victim := int(g.hero_fighter(1))
	var victim_hp := int(g.fighters[victim].hp)
	check(g.choose_effect_fighter(victim) and g.fighters[victim].hp == victim_hp - 2, "chosen glance target takes damage")

func _test_new_hero_rules() -> void:
	# New abilities and cards are checked with known hands; no hidden-card assumptions.
	var g = game(["robin_hood", "king_arthur"])
	var enemy := int(g.hero_fighter(1))
	g.fighters[0].node = 5
	g.fighters[enemy].node = 6
	g.players[0].hand = [card(g, 0, "ambush")]
	g.players[1].hand = [card(g, 1, "noble_sacrifice")]
	g.attack(0, enemy, 0)
	check(g.last_combat.attack_value == 5 and g.last_combat.damage == 5 and g.players[1].discard.size() == 1, "Ambush randomly discards then adds boost")
	g = game(["robin_hood", "bigfoot"])
	enemy = int(g.hero_fighter(1))
	g.fighters[0].node = 5
	g.fighters[enemy].node = 6
	g.players[0].hand = [card(g, 0, "ambush")]
	g.players[1].hand = [card(g, 1, "it_s_just_your_imagination"), card(g, 1, "larger_than_life")]
	g.attack(0, enemy, 0)
	check(g.last_combat.attack_value == 2 and g.last_combat.damage == 0 and g.players[1].hand.size() == 1, "Bigfoot Imagination cancels Ambush discard and boost")
	g = game(["robin_hood", "alice"])
	enemy = int(g.hero_fighter(1))
	g.alice_size[1] = "small"
	g.fighters[1].node = 5
	g.fighters[enemy].node = 6
	g.players[0].hand = [card(g, 0, "highway_robbery")]
	g.players[1].hand = [card(g, 1, "looking_glass")]
	g.attack(1, enemy, 0)
	check(g.last_combat.defense_value == 0 and g.last_combat.damage == 2 and g.last_combat.defense_cancelled, "Highway Robbery ignores total Alice small defense and cancels effects")
	g = game(["robin_hood", "alice"])
	g.interactive = true
	enemy = int(g.hero_fighter(1))
	g.fighters[1].node = 5
	g.fighters[enemy].node = 6
	g.players[0].hand = [card(g, 0, "highway_robbery")]
	g.players[1].hand = [card(g, 1, "feint")]
	g.attack(1, enemy, 0)
	g.continue_attack()
	check(g.combat_report.attack_cancelled and g.combat_report.damage == 0, "defender Feint cancels Highway ignore defense")
	g.continue_combat()
	check(g.phase == "effect_move" and g.pending_choice.fighter == 1 and g.pending_choice.spaces == 2, "Robin ability moves attacking Outlaw even after cancelled card")
	g.choose_effect_node(int(g.pending_choice.legal.back()))
	check(g.phase == "combat_report", "Robin retreat completes as one after-attack ability")
	g = game(["robin_hood", "king_arthur"])
	enemy = int(g.hero_fighter(1))
	g.fighters[0].node = 5
	g.fighters[enemy].node = 6
	g.players[0].hand = [card(g, 0, "disarming_shot")]
	g.players[1].hand = [card(g, 1, "regroup")]
	g.attack(0, enemy, 0)
	check(g.last_combat.damage == 3 and g.players[0].hand.size() == 3, "Disarming Shot draws actual combat damage")
	g = game(["bigfoot", "king_arthur"])
	g.fighters[0].node = 5
	g.fighters[1].node = 0
	g.fighters[2].node = 6
	g.players[0].hand = [card(g, 0, "savagery")]
	g.players[1].hand = []
	g.attack(0, 2, 0)
	check(g.fighters[1].hp == 5 and g.fighters[2].hp == 13, "winning Savagery damages adjacent friends and enemies")
	g = game(["bigfoot", "king_arthur"])
	g.interactive = true
	g.fighters[0].node = 5
	g.fighters[2].node = 6
	g.players[0].hand = [card(g, 0, "disengage")]
	g.players[1].hand = []
	g.attack(0, 2, 0)
	g.continue_attack()
	g.continue_combat()
	check(g.phase == "effect_move" and not g.pending_choice.legal.has(24) and g.pending_choice.legal.has(12), "Disengage placement is restricted to same zone")
	g.choose_effect_node(12)
	check(g.fighters[0].node == 12, "Disengage can place beyond normal movement in shared zone")
	g = game(["bigfoot", "king_arthur"])
	g.interactive = true
	g.fighters[1].node = 0
	g.fighters[2].node = 3
	g.players[0].hand = [card(g, 0, "jackalope_horns")]
	g.scheme(1, 0)
	check(g.pending_choice.legal.has(2), "Jackalope Horns offers movement before choosing damage target")
	g.choose_effect_node(2)
	check(g.phase == "effect_choice" and g.pending_choice.allowed_fighters.has(2), "Jackalope Horns selects target after moved position")
	g.choose_effect_fighter(2)
	check(g.fighters[2].hp == 16, "Jackalope Horns damages chosen adjacent fighter by two")
	# Wily Fighting affects only enemies; a defeated Outlaw has no adjacency.
	g = team_game(["robin_hood", "king_arthur", "alice", "sinbad"])
	for f in g.fighters: f.node = 14 + int(f.id)
	g.fighters[0].node = 6
	g.fighters[1].node = 1
	g.fighters[5].node = 7
	g.fighters[7].node = 5
	g.fighters[9].node = 11
	g.players[0].hand = [card(g, 0, "wily_fighting")]
	g.players[1].hand = []
	g.attack(0, 5, 0)
	check(g.fighters[5].hp == 14 and g.fighters[9].hp == 14 and g.fighters[7].hp == 13 and g.fighters[1].hp == 1, "Wily Fighting damages every adjacent opponent and spares allies")
	g = game(["robin_hood", "king_arthur"])
	enemy = int(g.hero_fighter(1))
	g.active = 1
	g.fighters[1].node = 5
	g.fighters[enemy].node = 6
	g.players[0].hand = [card(g, 0, "wily_fighting")]
	g.players[1].hand = [card(g, 1, "excalibur")]
	g.attack(enemy, 1, 0)
	g.defend(0)
	check(not g.fighters[1].alive and g.fighters[enemy].hp == 18, "dead Outlaw cannot apply adjacent Wily Fighting damage")
	g = game(["robin_hood", "king_arthur"])
	var snark_ctx := {"owner": 0, "self": 0, "opponent": g.hero_fighter(1), "opponent_owner": 1, "card": {}, "value": 3, "won": false}
	g.fighters[0].node = 5
	g.fighters[g.hero_fighter(1)].node = 6
	var hand_before := int(g.players[0].hand.size())
	g._run_effects(card(g, 0, "snark"), "after", snark_ctx)
	check(g.players[0].hand.size() == hand_before + 1, "Snark draws while combatants remain adjacent")
	g.fighters[g.hero_fighter(1)].node = 24
	g._run_effects(card(g, 0, "snark"), "after", snark_ctx)
	check(g.players[0].hand.size() == hand_before + 1, "Snark does not draw after opponent moved away")
	g = game(["robin_hood", "king_arthur"])
	g.interactive = true
	g.active = 1
	enemy = int(g.hero_fighter(1))
	g.fighters[0].node = 5
	g.fighters[enemy].node = 6
	g.fighters[1].alive = false
	g.fighters[1].hp = 0
	g.players[0].hand = [card(g, 0, "defenders_of_sherwood")]
	g.players[1].hand = [card(g, 1, "excalibur")]
	g.attack(enemy, 0, 0)
	g.continue_attack()
	g.defend(0)
	g.continue_combat()
	check(g.phase == "effect_move" and g.pending_choice.kind == "revive_sidekick" and not g.pending_choice.can_skip, "Defenders of Sherwood requires legal Outlaw revival placement")
	var outlaw_space := int(g.pending_choice.legal.back())
	g.choose_effect_node(outlaw_space)
	check(g.fighters[1].alive and g.fighters[1].hp == 1 and g.fighters[1].node == outlaw_space and g.phase == "combat_report", "Sherwood Outlaw revives with one health without defending-side Robin retreat")
	# Bigfoot's optional draw policy draws when available, before final seven-card limit.
	g = game(["bigfoot", "king_arthur"])
	g.fighters[0].node = 0
	g.fighters[2].node = 24
	g.fighters[3].node = 23
	while g.players[0].hand.size() < 7: g.players[0].hand.append(card(g, 0, "feint"))
	var deck_before := int(g.players[0].deck.size())
	g.end_turn()
	check(g.phase == "discard" and g.players[0].hand.size() == 8 and g.players[0].deck.size() == deck_before - 1, "Bigfoot draws before enforcing seven-card hand limit")
	g = save_clone(g)
	g.discard_card(0)
	check(g.active == 1 and g.players[0].deck.size() == deck_before - 1, "Bigfoot end ability cannot trigger twice after saved discard")
	g = game(["bigfoot", "king_arthur"])
	g.fighters[0].node = 0
	g.fighters[2].node = 1
	deck_before = int(g.players[0].deck.size())
	g.end_turn()
	check(g.players[0].deck.size() == deck_before, "enemy in Bigfoot zone blocks end draw")
	g = team_game(["bigfoot", "king_arthur", "alice", "sinbad"])
	g.fighters[0].node = 0
	for f in g.fighters:
		if g.is_enemy(0, int(f.owner)): f.node = 23 + int(f.id) % 2
	g.fighters[g.hero_fighter(2)].node = 1
	deck_before = int(g.players[0].deck.size())
	g.end_turn()
	check(g.players[0].deck.size() == deck_before - 1, "allied fighter does not block Bigfoot end draw")
	g = team_game(["bigfoot", "king_arthur", "alice", "sinbad"])
	g._damage(0, 99)
	deck_before = int(g.players[0].deck.size())
	g.end_turn()
	check(g.players[0].deck.size() == deck_before, "Bigfoot ability does not work after hero defeat with Jackalope alive")
	# Steal: the human Robin selects which opponent; the human victim chooses response and card.
	g = game(["robin_hood", "king_arthur", "sinbad"])
	g.interactive = true
	g.players[0].hand = [card(g, 0, "steal_from_the_rich")]
	g.players[2].hand = []
	var other_hand := int(g.players[1].hand.size())
	g.scheme(0, 0)
	check(g.pending_choice.action == "steal_target" and g.players[0].hand.size() == 1, "Steal draws first and asks which opponent")
	g = save_clone(g)
	g.choose_effect_option(1)
	check(g.players[0].hand.size() == 2 and g.players[1].hand.size() == other_hand and g.phase == "combat_report", "chosen empty-handed opponent grants second draw without touching other opponent")
	g = game(["king_arthur", "robin_hood"])
	g.interactive = true
	g.active = 1
	g.players[1].hand = [card(g, 1, "steal_from_the_rich")]
	g.players[0].hand = [card(g, 0, "excalibur"), card(g, 0, "feint")]
	g.scheme(g.hero_fighter(1), 0)
	check(g.phase == "effect_choice" and g.pending_choice.action == "steal_response", "human victim decides whether to discard for Steal")
	g.choose_effect_option(0)
	g = save_clone(g)
	check(g.pending_choice.kind == "cards" and g.pending_choice.cards.size() == 2, "human victim chooses exact discard card")
	g.choose_effect_option(1)
	check(g.players[0].hand[0].id == "excalibur" and g.players[1].hand.size() == 1 and g.phase == "combat_report", "Steal chosen discard avoids bonus draw and preserves other card")
	g = game(["king_arthur", "robin_hood"])
	g.interactive = true
	g.active = 1
	g.players[1].hand = [card(g, 1, "steal_from_the_rich")]
	other_hand = int(g.players[0].hand.size())
	g.scheme(g.hero_fighter(1), 0)
	g.choose_effect_option(1)
	check(g.players[0].hand.size() == other_hand and g.players[1].hand.size() == 2 and g.phase == "combat_report", "human may refuse Steal discard and give Robin bonus draw")

func _test_all_new_cards() -> void:
	var tested := 0
	for hid in ["robin_hood", "bigfoot"]:
		var catalog = EngineModel.new()
		var total := 0
		for source in catalog.heroes[hid].cards:
			total += int(source.count)
			var g = game([hid, "king_arthur"])
			var own := 1 if str(source.fighter) == "sidekick" else 0
			var enemy := int(g.hero_fighter(1))
			g.fighters[own].node = 12
			g.fighters[enemy].node = 13
			g.players[0].hand = [source.duplicate(true)]
			g.players[1].hand = []
			if str(source.type) == "scheme": check(g.scheme(own, 0), "new scheme plays: " + str(source.id))
			elif str(source.type) == "defense":
				g.active = 1
				g.players[1].hand = [card(g, 1, "excalibur")]
				check(g.attack(enemy, own, 0) and g.phase == "defend" and g.defend(0), "new defense resolves: " + str(source.id))
			else: check(g.attack(own, enemy, 0), "new attack resolves: " + str(source.id))
			check(g.phase in ["action", "discard", "game_over"], "new card returns to valid stable phase: " + str(source.id))
			tested += 1
		check(total == 30, "new official deck has exactly thirty cards: " + hid)
	check(tested == 22, "all twenty-two new card definitions exercised")

func _test_new_set_matches() -> void:
	for board_name in ["sherwood_forest", "yukon"]:
		for level in range(3):
			for reverse_roster in [false, true]:
				for interactive_mode in [false, true]:
					var roster: Array = ["bigfoot", "robin_hood"] if reverse_roster else ["robin_hood", "bigfoot"]
					var g = EngineModel.new()
					g.setup(roster, level, 600 + level, board_name, {"start_slots": [1, 0], "human_placement": true})
					check(g.board_id == board_name and g.start_slots == [1, 0], "new two-start map accepts legal swapped starts")
					while g.setup_fighter >= 0:
						var legal: Array = g.legal_setup_nodes(g.setup_fighter)
						check(not legal.is_empty(), "new map supports manual hero plus all helpers")
						if legal.is_empty(): break
						g.place_setup_fighter(g.setup_fighter, int(legal.back()))
					g = save_clone(g)
					check(g.finish_setup(), "new map setup finishes")
					g.interactive = interactive_mode
					if not interactive_mode:
						for p in g.players: p.bot = true
					var steps := 0
					var initial_failures := failures
					while g.winner < 0 and steps < 2500:
						if interactive_mode: _advance_interactive(g)
						else: g.bot_step()
						steps += 1
						if steps % 9 == 0: g = save_clone(g)
						if failures > initial_failures: break
					check(g.winner >= 0 and g.phase == "game_over", "new-set duel finishes")
					print("NEW_SET_MATCH board=%s level=%d reverse=%s interactive=%s steps=%d" % [board_name, level, reverse_roster, interactive_mode, steps])
	var mixed := ["robin_hood", "bigfoot", "medusa", "king_arthur"]
	for board_name in ["marmoreal", "sarpedon"]:
		for level in range(3):
			for mode in ["ffa", "teams"]:
				for interactive_mode in [false, true]:
					var g = EngineModel.new()
					g.setup(mixed, level, 900 + level, board_name, {"mode": mode})
					g.interactive = interactive_mode
					if not interactive_mode:
						for p in g.players: p.bot = true
					var steps := 0
					var initial_failures := failures
					while g.winner < 0 and steps < 2500:
						if interactive_mode: _advance_interactive(g)
						else: g.bot_step()
						steps += 1
						if steps % 11 == 0: g = save_clone(g)
						if failures > initial_failures: break
					check(g.winner >= 0 and g.phase == "game_over", "mixed-set four-player match finishes")
					print("MIXED_SET_MATCH board=%s level=%d mode=%s interactive=%s steps=%d" % [board_name, level, mode, interactive_mode, steps])
	var g = EngineModel.new()
	g.setup(mixed, 1, 1, "yukon", {"mode": "teams"})
	check(g.nodes.size() >= 31 and g.board_id != "yukon" and g.players.size() == 4, "incompatible two-start board safely falls back for four players")
	g.setup(["robin_hood", "bigfoot"], 1, 1, "sherwood_forest", {"start_slots": [3, 3]})
	check(g.start_slots == [0, 1], "invalid two-start-map slots normalize within real capacity")
