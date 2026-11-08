extends SceneTree
const Model = preload("res://scripts/game_engine.gd")
var checks = 0
var failures = 0

func _initialize(): run.call_deferred()
func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		push_error("V7: " + label)
func game(ids: Array, human = true, config = {}):
	var g = Model.new()
	g.setup(ids,1,7026,"training",config)
	g.interactive = human
	for p in g.players: p.bot = true
	g.players[0].bot = not human
	return g
func card(g, owner: int, id: String):
	for c in g.heroes[g.players[owner].hero_id].cards:
		if str(c.id) == id: return c.duplicate(true)
	check(false,"known card " + id)
	return {}
func clone(g):
	var other = Model.new()
	check(other.load_state(JSON.parse_string(JSON.stringify(g.save_state()))),"JSON roundtrip " + g.phase)
	return other
func context(g, c, won = false):
	return {"owner":0,"self":g.hero_fighter(0),"opponent":g.hero_fighter(1),"opponent_owner":1,"card":c,"won":won,"value":int(c.get("value",0))}
func effect(g, c, kind: String, won = false):
	g._flow = {"kind":"ability","stage":"effects","effect_logs":[],"completion":"start_turn"}
	g.combat_report = {"kind":"ability"}
	g._effect_queue = [{"effect":{"kind":kind},"ctx":context(g,c,won)}]
	g._pump_effects()
func finish(g):
	for n in range(120):
		match g.phase:
			"action", "discard", "game_over": return
			"attack_notice": g.continue_attack()
			"combat_report": g.continue_combat()
			"effect_choice": check(g.choose_effect_option(0),"resolve choice " + str(g.pending_choice.get("action","")))
			"effect_move":
				if int(g.pending_choice.get("fighter",-1)) < 0 and not g.pending_choice.get("allowed_fighters",[]).is_empty(): g.choose_effect_fighter(int(g.pending_choice.allowed_fighters[0]))
				if not g.pending_choice.get("legal",[]).is_empty(): g.choose_effect_node(int(g.pending_choice.legal[-1]))
				else: check(g.skip_effect(),"skip empty movement")
			"defend": g.defend(-1)
			_: check(false,"supported phase " + g.phase); return
	check(false,"effect flow terminates")

func test_hand_views():
	for hid in ["muhammad_ali","sinbad","sherlock_holmes"]:
		var g = game([hid,"king_arthur"])
		var c = card(g,0,{"muhammad_ali":"hard_to_be_humble","sinbad":"voyage_to_the_valley_of_the_giant_snakes","sherlock_holmes":"study_methods"}[hid])
		var expected = g.players[1].hand.duplicate(true)
		effect(g,c,"reveal_hand",true)
		check(g.phase == "effect_choice" and g.pending_choice.kind == "hand_view",hid + " pure hand viewing pauses")
		check(g.pending_choice.cards == expected and int(g.pending_choice.viewer) == 0 and int(g.pending_choice.victim) == 1,"actual victim hand and viewer metadata")
		check(not g.skip_effect(),"view requires Continue")
		var loaded = clone(g)
		check(loaded.pending_choice.cards == expected and loaded.pending_choice.kind == "hand_view","view survives save")
		check(not loaded.choose_effect_option(1) and loaded.choose_effect_option(0),"Continue only valid response")
		finish(loaded)
		check(loaded.players[1].hand == expected,"viewing never removes a card")
		for hidden in expected:
			check(not "\n".join(g.logs).contains(str(hidden.name)),"hidden hand names absent from log")
	var g = game(["muhammad_ali","king_arthur"])
	g.players[1].hand.clear()
	effect(g,card(g,0,"stronger_than_the_skill"),"stronger_than_skill")
	check(g.phase == "effect_choice" and g.pending_choice.cards.is_empty(),"empty hand still displays explicit information")
	finish(g)
	for win in [false,true]:
		g = game(["muhammad_ali","king_arthur"])
		var before = g.players[1].hand.size()
		effect(g,card(g,0,"stronger_than_the_skill"),"stronger_than_skill",win)
		check(g.pending_choice.kind == ("cards" if win else "hand_view"),"stronger only shuffles on win")
		g = clone(g)
		finish(g)
		check(g.players[1].hand.size() == before - (1 if win else 0),"stronger card removal follows combat result")
	g = game(["sherlock_holmes","king_arthur"])
	effect(g,card(g,0,"confirm_suspicion"),"confirm_suspicion")
	check(g.choose_effect_option(10),"suspicion impossible value")
	check(g.pending_choice.kind == "hand_view","suspicion without a matching card reveals whole hand")
	finish(g)
	for hid in ["alice","sherlock_holmes"]:
		g = game([hid,"king_arthur"])
		var before = g.players[1].hand.size()
		effect(g,card(g,0,"snicker_snack" if hid == "alice" else "eliminate_the_impossible"),"reveal_choose_discard" if hid == "alice" else "eliminate_impossible",true)
		check(g.pending_choice.cards == g.players[1].hand,"reveal and discard presents full hand")
		g = clone(g)
		finish(g)
		check(g.players[1].hand.size() == before - 1,"reveal and discard removes one selected card")
	for hid in ["muhammad_ali","sinbad","sherlock_holmes"]:
		g = game([hid,"king_arthur"],false)
		effect(g,{"name":"Bot hand view"},"reveal_hand")
		check(g.pending_choice.is_empty() and g.phase == "action","bot views resolve automatically")

func test_real_combat_conditions():
	for scenario in [["butterfly",false],["bee",false],["butterfly",true]]:
		var g = game(["muhammad_ali","king_arthur"])
		var foe = g.hero_fighter(1)
		g.fighters[0].node = 12
		g.fighters[foe].node = 13
		g.fighters[foe+1].node = 0
		g.ali_stance[0] = scenario[0]
		g.players[0].hand = [card(g,0,"hard_to_be_humble")]
		g.players[1].hand = [card(g,1,"feint" if scenario[1] else "excalibur"),card(g,1,"noble_sacrifice")]
		g.active = 1
		check(g.attack(foe,0,0) and g.continue_attack() and g.defend(0),"Humble actual defensive combat starts")
		check((g.phase == "effect_choice" and g.pending_choice.get("kind","") == "hand_view") == (scenario[0] == "butterfly" and not scenario[1]),"Humble obeys Butterfly and cancel conditions")
		finish(g)
	for defense in ["the_holy_grail","divine_intervention","feint"]:
		var g = game(["sherlock_holmes","king_arthur"])
		var own = g.hero_fighter(0)
		var foe = g.hero_fighter(1)
		g.fighters[own].node = 12
		g.fighters[foe].node = 13
		g.players[0].hand = [card(g,0,"study_methods")]
		g.players[1].hand = [card(g,1,defense),card(g,1,"excalibur")]
		check(g.attack(own,foe,0) and g.continue_attack() and g.continue_combat(),"Study Methods actual combat and effects start")
		check((g.phase == "effect_choice" and g.pending_choice.get("kind","") == "hand_view") == (defense == "the_holy_grail"),"Study Methods reveals only after a winning uncanceled combat")
		finish(g)

func run():
	test_hand_views()
	test_real_combat_conditions()
	print("V7_ENGINE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
