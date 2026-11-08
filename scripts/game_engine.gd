extends RefCounted
class_name BattleEngine
## Offline, deterministic battle model. UI never needs to mutate this state.

signal changed
signal message(text: String)

var players: Array = []
var fighters: Array = []
var nodes: Array = []
var active: int = 0
var actions_left: int = 2
var phase: String = "action"
var winner: int = -1
var winner_team: int = -1
var match_mode: String = "ffa"
var start_slots: Array = []
var setup_fighter: int = -1
var _setup_order: Array = []
var _reserved_starts: Array = []
var logs: Array[String] = []
var selected_fighter: int = -1
var pending_combat: Dictionary = {}
var maneuver_moved: Array = []
var maneuver_distance: int = 0
var maneuver_boosted: bool = false
var difficulty: int = 1
var turn_number: int = 1
var heroes: Dictionary = {}
var rng := RandomNumberGenerator.new()
var turn_start_nodes: Array = []
var turn_start_tails: Array = []
var alice_size: Dictionary = {}
var last_combat: Dictionary = {}
var interactive: bool = false
var pending_choice: Dictionary = {}
var combat_report: Dictionary = {}
var map_id: String = "training"
var boards: Dictionary = {}
var board_id: String:
	get: return map_id
var board_data: Dictionary:
	get: return boards.get(map_id, {})
var _effect_queue: Array = []
var _flow: Dictionary = {}
var _combat_resolution: Dictionary = {}
var traps: Array = []
var _trap_stock: Dictionary = {}
var _maneuver_boost: int = 0
var _busy: bool = false
var ali_stance: Dictionary = {}
var jekyll_form: Dictionary = {}
var fog_tokens: Array = []
var _v6 = preload("res://scripts/hero_rules_v6.gd").new(self)
var shadow_tokens: Array = []
var willow_form: Dictionary = {}
var _v7 = preload("res://scripts/hero_rules_v7.gd").new(self)
var _v8 = preload("res://scripts/hero_rules_v8.gd").new(self)
var _v9 = preload("res://scripts/hero_rules_v9.gd").new(self)
var _v22 = preload("res://scripts/hero_rules_v22.gd").new(self)
var _v21 = preload("res://scripts/hero_rules_v21.gd").new(self)
var _v19 = preload("res://scripts/hero_rules_v20.gd").new(self)
var _v18 = preload("res://scripts/hero_rules_v18.gd").new(self)
var _v17 = preload("res://scripts/hero_rules_v17.gd").new(self)
var _v16 = preload("res://scripts/hero_rules_v16.gd").new(self)
var _v15 = preload("res://scripts/hero_rules_v15.gd").new(self)
var _v14 = preload("res://scripts/hero_rules_v14.gd").new(self)
var _v13 = preload("res://scripts/hero_rules_v13.gd").new(self)
var _v12 = preload("res://scripts/hero_rules_v12.gd").new(self)
var _v10 = preload("res://scripts/hero_rules_v10.gd").new(self)
var _combat_stack: Array = []
var _deferred_damage: Array = []
var _v38 = preload("res://scripts/nature_rules_v38.gd").new(self)
var _master = preload("res://scripts/master_ai_v37.gd").new(self)
var _v36 = preload("res://scripts/tmnt_villains_v36.gd").new(self)
var _v35 = preload("res://scripts/hellboy_rules_v35.gd").new(self)
var _v34 = preload("res://scripts/stars_rules_v34.gd").new(self)
var _v33 = preload("res://scripts/tmnt_rules_v33.gd").new(self)
var _v32 = preload("res://scripts/legends_rules_v32.gd").new(self)
var _v31 = preload("res://scripts/marvel_rules_v31.gd").new(self)
var _v29 = preload("res://scripts/mikula_rules_v29.gd").new(self)
var _v26 = preload("res://scripts/fan_rules_v26.gd").new(self)
var battlefield_items: Array = []
var _v24 = preload("res://scripts/battlefield_rules_v24.gd").new(self)
var door_states: Array = []
var door_movement_spent: Dictionary = {}
var door_active_fighter: int = -1

func _init() -> void:
	_load_heroes()
	_load_boards()
	_build_board()

func _load_boards() -> void:
	boards.clear()
	var file := FileAccess.open("res://data/boards.json", FileAccess.READ)
	if file == null: return
	var data = JSON.parse_string(file.get_as_text())
	var list = data.get("boards", []) if data is Dictionary else data
	if list is Array:
		for board in list: boards[str(board.id)] = board

func _load_heroes() -> void:
	var file := FileAccess.open("res://data/heroes.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	var list = parsed.get("heroes", []) if parsed is Dictionary else parsed
	if list is Array:
		for hero in list:
			heroes[str(hero.id)] = hero

func _build_board(requested_map: String = "training") -> void:
	nodes.clear()
	map_id = requested_map if boards.has(requested_map) else "training"
	if boards.has(map_id):
		for source in boards[map_id].nodes:
			var node: Dictionary = source.duplicate(true)
			node.id = int(node.id)
			node.pos = Vector2(float(source.pos[0]), float(source.pos[1]))
			node.neighbors = _int_array(node.neighbors)
			if node.has("move_neighbors"): node.move_neighbors = _int_array(node.move_neighbors)
			node.zones = _int_array(node.zones)
			if node.has("move_neighbors"): node.move_neighbors = _int_array(node.move_neighbors)
			nodes.append(node)
		return
	# An original symmetric arena. Shared boundary spaces belong to both zones.
	for row in range(5):
		for col in range(5):
			var zones: Array = []
			if col <= 2 and row <= 2: zones.append(0)
			if col >= 2 and row <= 2: zones.append(1)
			if col >= 2 and row >= 2: zones.append(2)
			if col <= 2 and row >= 2: zones.append(3)
			var links: Array = []
			if col > 0: links.append(row * 5 + col - 1)
			if col < 4: links.append(row * 5 + col + 1)
			if row > 0: links.append((row - 1) * 5 + col)
			if row < 4: links.append((row + 1) * 5 + col)
			nodes.append({"id": row * 5 + col, "pos": Vector2(0.12 + col * 0.19, 0.12 + row * 0.19), "zones": zones, "neighbors": links})

func setup(hero_ids: Array, skill: int, seed_value: int = 0, requested_map: String = "training", config: Dictionary = {}) -> void:
	_load_heroes()
	_load_boards()
	_build_board(requested_map)
	if boards.has(map_id) and boards[map_id].starts.size() < mini(hero_ids.size(), 4):
		_build_board("marmoreal" if boards.has("marmoreal") else "training")
	_combat_stack.clear()
	_deferred_damage.clear()
	players.clear()
	fighters.clear()
	logs.clear()
	alice_size.clear()
	ali_stance.clear()
	jekyll_form.clear()
	fog_tokens.clear()
	shadow_tokens.clear()
	willow_form.clear()
	door_states.clear()
	for door in board_data.get("doors",[]): door_states.append(false)
	door_movement_spent.clear()
	door_active_fighter = -1
	difficulty = clampi(skill, 0, 3)
	rng.seed = seed_value if seed_value != 0 else Time.get_ticks_usec()
	active = 0
	actions_left = 2
	phase = "action"
	winner = -1
	winner_team = -1
	match_mode = "teams" if str(config.get("mode", "ffa")) == "teams" and hero_ids.size() == 4 else "ffa"
	setup_fighter = -1
	_setup_order.clear()
	start_slots.clear()
	turn_number = 1
	selected_fighter = -1
	pending_combat.clear()
	pending_choice.clear()
	combat_report.clear()
	_effect_queue.clear()
	_flow.clear()
	_combat_resolution.clear()
	traps.clear()
	_trap_stock.clear()
	maneuver_moved.clear()
	maneuver_boosted = false
	var starts: Array = boards[map_id].starts if boards.has(map_id) else [0, 4, 24, 20]
	var capacity := starts.size()
	var requested_slots: Array = config.get("start_slots", [])
	for i in range(mini(hero_ids.size(), 4)):
		var slot := int(requested_slots[i]) if i < requested_slots.size() else i
		if slot < 0 or slot >= capacity or start_slots.has(slot):
			for candidate in range(capacity):
				if not start_slots.has(candidate):
					slot = candidate
					break
		start_slots.append(slot)
	_reserved_starts.clear()
	for slot in start_slots: _reserved_starts.append(int(starts[int(slot)]))
	for i in range(mini(hero_ids.size(), 4)):
		var hid := str(hero_ids[i])
		if not heroes.has(hid): continue
		var hero: Dictionary = heroes[hid]
		var sorceress=str(config.get("sorceresses",{}).get(i,config.get("sorceresses",{}).get(str(i),config.get("sorceress_hero","yennefer") if i==0 else ("yennefer" if rng.randi_range(0,1)==0 else "triss")))) if hid=="yennefer_triss" else "yennefer"
		if sorceress not in ["yennefer","triss"]:sorceress="yennefer"
		if hid=="yennefer_triss":hero=_v17.definition(sorceress)
		var sidekick_variant := str(config.get("sidekick_variants", {}).get(i, config.get("sidekick_variants", {}).get(str(i), config.get("buffy_sidekick", config.get("sidekick_variant", "giles")) if i == 0 else ("giles" if rng.randi_range(0,1) == 0 else "xander"))))
		if sidekick_variant not in ["giles", "xander"]: sidekick_variant = "giles"
		var deck: Array = []
		var chosen_gear=_v14.select_gear(i,config) if hid=="geralt_of_rivia" else {}
		for source in hero.get("cards", hero.get("deck", [])):
			if source.has("gear_slot") and str(source.gear_option)!=str(chosen_gear.get(str(source.gear_slot),"")): continue
			if hid == "buffy" and source.has("sidekick_variant") and str(source.sidekick_variant) != sidekick_variant: continue
			for copy in range(int(source.get("count", source.get("quantity", 1)))):
				var instance = source.duplicate(true)
				if source.has("basket_symbols"):
					instance.basket_symbol = source.basket_symbols[copy % source.basket_symbols.size()]
					instance.basket_copy = copy
				deck.append(instance)
		_shuffle(deck)
		var owner := players.size()
		players.append({"hero_id": hid, "name": str(hero.name), "hand": [], "deck": deck, "discard": [], "alive": true, "bot": owner != 0, "move": int(hero.get("move", 2)), "voyages": 0, "team": owner % 2 if match_mode == "teams" else owner, "actions_taken": 0, "turn_attack_bonus": 0})
		players[owner].buffy_sidekick = sidekick_variant
		if hid=="yennefer_triss":players[owner].sorceress=sorceress
		if hid=="geralt_of_rivia": players[owner].gear=chosen_gear
		willow_form[owner] = "willow"
		alice_size[owner] = "big"
		var start_node := int(starts[int(start_slots[owner])])
		players[owner].starting_space=start_node
		var hero_count := int(hero.get("hero_count", 1))
		for number in range(hero_count):
			var hero_names: Array = hero.get("hero_names", [])
			var fighter_name := str(hero_names[number]) if number < hero_names.size() else str(hero.name) + (" %d" % (number + 1) if hero_count > 1 else "")
			var position := start_node if number == 0 else _nearest_free(start_node, true)
			_add_fighter(owner, fighter_name, int(hero.get("health", hero.get("hp", 15))), position, bool(hero.get("ranged", false)), true)
		if hid == "ingen": _trap_stock[owner] = 8
		var helper: Dictionary = hero.get("sidekick", {})
		if hid == "buffy": helper = hero.get("sidekick_variants", {}).get(sidekick_variant, helper)
		for n in range(int(helper.get("count", 0))):
			var position := _nearest_free(start_node, boards.has(map_id))
			_add_fighter(owner, str(helper.get("name", "Помощник")), int(helper.get("health", 1)), position, bool(helper.get("ranged", false)), false)
		for n in range(3 if hid=="michelangelo" else 5): _draw(owner)
	_v31.setup(config)
	_v35.setup()
	_v36.setup()
	_v34.setup()
	_v32.setup()
	_reserved_starts.clear()
	_v6.setup_tokens(bool(config.get("human_placement", false)))
	_v9.setup()
	_v13.setup()
	_v14.setup()
	_v24.setup()
	_v38.setup()
	for f in fighters:
		if _v19.large(int(f.id)):_v19.body(int(f.id),int(f.node),-1)
	_snapshot_positions()
	if bool(config.get("human_placement", false)):
		phase = "setup"
		for f in fighters:
			if int(f.owner) == 0 and f.alive:
				f.placed = false
				_setup_order.append(int(f.id))
		if not _setup_order.is_empty(): setup_fighter = int(_setup_order[0])
		_log("Разместите героя на выбранном старте, затем его помощников в той же зоне.")
		changed.emit()
		return
	_log("Бой начинается. Первый ход: %s." % _player_name(active))
	_start_turn_ability()
	changed.emit()

func _add_fighter(owner: int, fighter_name: String, hp: int, node: int, ranged: bool, hero: bool) -> void:
	fighters.append({"id": fighters.size(), "owner": owner, "name": fighter_name, "hp": hp, "max_hp": hp, "node": node, "ranged": ranged, "hero": hero, "alive": true, "placed": true})

func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var item = items[i]
		items[i] = items[j]
		items[j] = item

func _int_array(values: Array) -> Array:
	var result: Array = []
	for value in values: result.append(int(value))
	return result

func _nearest_free(origin: int, same_zone_only: bool = false) -> int:
	var queue := [origin]
	var seen := {origin: true}
	while not queue.is_empty():
		var here: int = queue.pop_front()
		if _occupant(here) < 0 and not _reserved_starts.has(here) and (not same_zone_only or _same_zone(origin, here)): return here
		for next in nodes[here].neighbors:
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return _nearest_free(origin, false) if same_zone_only else origin

func _occupant(node: int) -> int:
	for f in fighters:
		if not _v31.small(int(f.id)) and f.alive and bool(f.get("placed", true)) and not bool(f.get("offboard",false)) and (int(f.node) == node or (_v19.large(int(f.id)) and int(f.get("tail",-1))==node)): return int(f.id)
	return -1

func are_allies(owner_a: int, owner_b: int) -> bool:
	if owner_a < 0 or owner_b < 0 or owner_a >= players.size() or owner_b >= players.size(): return false
	return owner_a == owner_b or (match_mode == "teams" and int(players[owner_a].get("team", owner_a)) == int(players[owner_b].get("team", owner_b)))

func is_enemy(owner_a: int, owner_b: int) -> bool:
	return owner_a >= 0 and owner_b >= 0 and owner_a < players.size() and owner_b < players.size() and not are_allies(owner_a, owner_b)

func legal_setup_nodes(fighter_id: int) -> Array[int]:
	var result: Array[int] = []
	if phase != "setup" or fighter_id != setup_fighter or not _valid_fighter(fighter_id, 0): return result
	var hero := hero_fighter(0)
	if fighters[fighter_id].hero and fighter_id == hero:
		var starts: Array = boards[map_id].starts if boards.has(map_id) else [0, 4, 24, 20]
		var assigned := int(starts[int(start_slots[0])])
		var occupant := _occupant(assigned)
		if (occupant < 0 or occupant == fighter_id) and (not _v19.large(fighter_id) or not _v19.orientations(fighter_id,assigned).is_empty()): result.append(assigned)
		return result
	if not bool(fighters[hero].get("placed", false)): return result
	if _is_hero(0,"birds"):
		for node in nodes:
			if _occupant(int(node.id))in[-1,fighter_id] and fighters.any(func(f):return int(f.owner)==0 and f.id!=fighter_id and f.get("placed",false)and node_adjacent_to_fighter(int(node.id),int(f.id))):result.append(int(node.id))
		return result
	for node in nodes:
		var occupant := _occupant(int(node.id))
		if occupant >= 0 and occupant != fighter_id: continue
		if _same_zone(int(fighters[hero].node), int(node.id)): result.append(int(node.id))
	return result

func place_setup_fighter(fighter_id: int, node: int) -> bool:
	if not legal_setup_nodes(fighter_id).has(node): return false
	if _v19.offer(fighter_id,node,"setup"):return true
	_v19.body(fighter_id,node,int(fighters[fighter_id].node))
	fighters[fighter_id].node = node
	fighters[fighter_id].placed = true
	_log("Расстановка: %s — клетка %d." % [fighters[fighter_id].name, node + 1])
	setup_fighter = -1
	for id in _setup_order:
		if not bool(fighters[int(id)].get("placed", false)):
			setup_fighter = int(id)
			break
	changed.emit()
	return true

func finish_setup() -> bool:
	if phase != "setup" or setup_fighter >= 0: return false
	for id in _setup_order:
		if not bool(fighters[int(id)].get("placed", false)): return false
	phase = "action"
	_snapshot_positions()
	_log("Бой начинается. Первый ход: %s." % _player_name(active))
	if _is_hero(0, "invisible_man"):
		var count := 0
		for fog in fog_tokens:
			if int(fog.owner) == 0: count += 1
		if count < 3:
			_start_ability(0, "Расстановка тумана", [{"kind":"setup_fog"}], "start_turn")
			changed.emit()
			return true
	_start_turn_ability()
	changed.emit()
	return true

func state_summary(owner: int) -> String:
	if _is_hero(owner,"godzilla"):return "Заряд: %d карт · атака +%d"%[_v38.charge(owner).size(),_v38.bonus(hero_fighter(owner),hero_fighter(owner))]
	if _is_hero(owner,"birds"):return "Птиц на поле: %d/6"%_v38.own(owner).size()
	var tmntv_state=_v36.summary(owner)
	if not tmntv_state.is_empty():return tmntv_state
	var hell_state=_v35.summary(owner)
	if not hell_state.is_empty():return hell_state
	var stars=_v34.summary(owner)
	if not stars.is_empty():return stars
	var tmnt_state=_v33.summary(owner)
	if not tmnt_state.is_empty():return tmnt_state
	var state32=_v32.summary(owner)
	if not state32.is_empty():return state32
	var state31=_v31.summary(owner)
	if not state31.is_empty():return state31
	var state21=_v21.summary(owner)
	if not state21.is_empty():return state21
	if _is_hero(owner,"dr_ellie_sattler"):return "Прозрение: %d/5 · клетки %s" % [players[owner].get("insight",[]).size(),str(players[owner].get("insight",[]).map(func(n):return int(n)+1))]
	var marvel_state=_v18.summary(owner)
	if not marvel_state.is_empty():return marvel_state
	if owner < 0 or owner >= players.size(): return ""
	var parts: Array[String] = []
	var sorceress_state=_v17.summary(owner)
	if not sorceress_state.is_empty():parts.append(sorceress_state)
	var realms_state=_v15.summary(owner)
	if not realms_state.is_empty():parts.append(realms_state)
	var witcher_state=_v14.summary(owner)
	if not witcher_state.is_empty(): parts.append(witcher_state)
	var new_state=_v13.summary(owner)
	if not new_state.is_empty(): parts.append(new_state)
	if match_mode == "teams": parts.append("Команда %d" % (int(players[owner].team) + 1))
	if _is_hero(owner, "alice"): parts.append("Алиса большая · атака +2" if str(alice_size.get(owner, "big")) == "big" else "Алиса маленькая · защита +1")
	if _is_hero(owner,"nikola_tesla"): parts.append("Катушки: %d/2" % _v10.coils(owner))
	if _is_hero(owner,"dr_jill_trent"): parts.append("Гипнолучевой бластер" if _v10.gadget(owner) == "hypno" else "Ультрабиотический тоник")
	if _is_hero(owner,"golden_bat"): parts.append("Атака +2 без манёвра" if int(players[owner].get("maneuvered_turn",-1)) != turn_number else "Манёвр выполнен: без бонуса")
	if _is_hero(owner,"achilles"): parts.append("Гнев: атака +2" if _v9.enraged(owner) else "Патрокл жив")
	if _is_hero(owner,"sun_wukong"): parts.append("Клоны на поле: %d/3" % _v9.helpers(owner).size())
	if _is_hero(owner,"bloody_mary"): parts.append("Действие в ходу: %d" % int(players[owner].get("actions_taken",0)))
	if _is_hero(owner,"beowulf"): parts.append("Ярость: %d/3" % _v8.rage(owner))
	if _is_hero(owner,"little_red"): parts.append("Корзина: %s" % {"wild":"звезда","pelt":"шкура","knife":"нож","flower":"цветок"}.get(_v8.basket(owner),"звезда"))
	if bool(players[owner].get("fixed_four",false)): parts.append("Сила всех карт: 4 до конца хода")
	if _is_hero(owner, "sinbad"): parts.append("Плавания: %d · манёвр %d" % [_voyages(owner), _movement(owner)])
	if _is_hero(owner, "sinbad"):
		parts.append("Бонус плаваний: +%d" % _voyages(owner))
		if phase == "move" and active == owner: parts.append("Текущий манёвр: %d" % maneuver_distance)
	if _is_hero(owner, "medusa"):
		var medusa := hero_fighter(owner)
		var count := 0
		if _valid_fighter(medusa):
			for f in fighters:
				if _valid_fighter(int(f.id)) and is_enemy(owner, int(f.owner)) and _same_zone(int(fighters[medusa].node), int(f.node)): count += 1
		parts.append("Целей в зоне: %d" % count)
	if _is_hero(owner, "ingen"): parts.append("Ловушки в запасе: %d" % trap_supply(owner))
	if _is_hero(owner, "raptors"): parts.append("Рапторы в бою: %d/3" % _living_heroes(owner).size())
	if _is_hero(owner,"buffy"):
		parts.append("Помощник: %s" % str(heroes.buffy.get("sidekick_variants",{}).get(str(players[owner].get("buffy_sidekick","giles")),{}).get("name","Джайлз")))
	if _is_hero(owner,"spike"):
		var count = 0
		for token in shadow_tokens:
			if int(token.owner) == owner: count += 1
		parts.append("Тени на поле: %d/3" % count)
	if _is_hero(owner,"willow"): parts.append("Тёмная Уиллоу" if willow_form_for(owner) == "dark" else "Уиллоу")
	if _is_hero(owner, "muhammad_ali"): parts.append("Бабочка · атаки с 2 клеток" if stance_for(owner) == "butterfly" else "Пчела · атака +2")
	if _is_hero(owner, "jekyll_hyde"): parts.append("Доктор Джекилл" if form_for(owner) == "jekyll" else "Мистер Хайд · после манёвра −1 ОЗ")
	if _is_hero(owner, "invisible_man"):
		parts.append("Туман: 3 жетона · защита в тумане +1")
		if bool(fighters[hero_fighter(owner)].get("offboard",false)): parts.append("Исчез до начала своего хода")
	if _is_hero(owner, "sherlock_holmes"): parts.append("Именные карты Холмса и Ватсона нельзя отменить")
	var hero := hero_fighter(owner)
	if hero >= 0 and not fighters[hero].alive and players[owner].alive: parts.append("Герой повержен · помощники продолжают бой")
	for f in fighters:
		if f.owner == owner and f.alive and int(f.get("locked_until",-1)) == turn_number:
			parts.append("Движение запрещено до конца текущего хода");break
	return " · ".join(parts)

func basket_description(owner: int) -> String:
	if not _is_hero(owner,"little_red"): return ""
	var item = {"wild":"Любой один","pelt":"Шкура","knife":"Нож","flower":"Цветок"}.get(_v8.basket(owner),"Любой один")
	var top = "Стартовая корзинка" if players[owner].discard.is_empty() else str(players[owner].discard[-1].name)
	return "Текущая корзинка: %s\nВерхняя карта сброса: %s" % [item,top]

func hero_fighter(owner: int) -> int:
	var fallback := -1
	for f in fighters:
		if int(f.owner) == owner and f.hero:
			if fallback < 0: fallback = int(f.id)
			if f.alive: return int(f.id)
	return fallback

func _living_heroes(owner: int) -> Array:
	var result: Array = []
	for f in fighters:
		if int(f.owner) == owner and f.hero and f.alive: result.append(int(f.id))
	return result

func _player_name(owner: int) -> String:
	return str(players[owner].name) if owner >= 0 and owner < players.size() else "—"

func _hero_id(owner: int) -> String:
	return str(players[owner].hero_id).to_lower()

func _is_hero(owner: int, key: String) -> bool:
	return key in _hero_id(owner)

func stance_for(owner: int) -> String:
	return str(ali_stance.get(owner,"butterfly"))

func form_for(owner: int) -> String:
	return str(jekyll_form.get(owner,"jekyll"))

func can_use_card(card: Dictionary, fighter_id: int) -> bool:
	return _card_usable(card,fighter_id)

func is_dormant(owner: int) -> bool:
	if owner < 0 or owner >= players.size() or not players[owner].alive: return true
	for f in fighters:
		if int(f.owner) == owner and _valid_fighter(int(f.id)): return false
	return true

func fog_at(node: int, owner: int = -1) -> int:
	for i in range(fog_tokens.size()):
		if int(fog_tokens[i].node) == node and (owner < 0 or int(fog_tokens[i].owner) == owner): return i
	return -1

func legal_fog_nodes(owner: int) -> Array[int]:
	var result: Array[int] = []
	var hero := hero_fighter(owner)
	if not _valid_fighter(hero): return result
	for node in nodes:
		if _occupant(int(node.id)) < 0 and fog_at(int(node.id)) < 0 and _same_zone(int(fighters[hero].node),int(node.id)): result.append(int(node.id))
	return result

func _card_uncancellable(owner: int, card: Dictionary) -> bool:
	return (_is_hero(owner,"ciri") and _v14.source_count(owner)>=7) or bool(card.get("uncancellable",false)) or _is_hero(owner,"sherlock_holmes") and str(card.get("fighter","any")).to_lower() not in ["any","all","все","любой"]

func _snapshot_positions() -> void:
	for player in players:player.used_paths=[]
	turn_start_nodes.clear();turn_start_tails.clear()
	for f in fighters:
		turn_start_nodes.append(int(f.node));turn_start_tails.append(int(f.get("tail",-1)))
	for owner in range(players.size()):
		var hero := hero_fighter(owner)
		players[owner].started_on_fog = _valid_fighter(hero) and fog_at(int(fighters[hero].node),owner) >= 0

func _draw(owner: int, count: int = 1) -> void:
	if int(players[owner].get("no_draw_turn",-1))==turn_number:return
	if is_dormant(owner): return
	for n in range(count):
		if not players[owner].alive: break
		if players[owner].deck.is_empty():
			_log("%s: колода пуста, каждый боец теряет 2 здоровья." % _player_name(owner))
			# Resolve helpers first so hero elimination does not mask their damage.
			for f in fighters:
				if f.alive and int(f.owner) == owner and not f.hero: _damage(int(f.id), 2, false, true)
			for f in fighters:
				if f.alive and int(f.owner) == owner and f.hero: _damage(int(f.id), 2, false, true)
		else:
			players[owner].hand.append(players[owner].deck.pop_back())

func _damage(fid: int, amount: int, combat_damage: bool = false, exhaustion: bool = false) -> void:
	if not _valid_fighter(fid) or amount <= 0 or _v9.protected(fid): return
	if not combat_damage and not exhaustion:
		if _v35.immune(fid):return
		amount=_v35.effect_amount(amount)
	if not combat_damage and (_v21.protected(fid) or _v10.effect_protected(fid) or _v13.effect_protected(fid) or (not exhaustion and _v15.protected(fid))): return
	if not combat_damage and not exhaustion and _v35.intercept(fid,amount):return
	if not combat_damage and not exhaustion and _v38.roost_effect(fid,amount):return
	if combat_damage:_v35.combat_received(fid,amount)
	if _v9.intercept_damage(fid,amount): return
	if _v31.small(fid):
		for other in _v31.occupants(int(fighters[fid].node)):
			if _v31.small(int(other)):_damage_raw(int(other),amount)
		return
	if combat_damage:_v32.combat_damaged(fid,amount)
	_damage_raw(fid,amount)

func _damage_many(ids: Array, amount: int) -> int:
	# Apply one simultaneous damage packet to helpers before heroes. An Archer
	# already defeated by this packet cannot absorb Yennenga's part of it.
	var ordered = ids.duplicate()
	ordered.sort_custom(func(a,b): return not bool(fighters[int(a)].hero) and bool(fighters[int(b)].hero))
	var dealt = 0
	for id in ordered:
		if not _valid_fighter(int(id)) or _v9.protected(int(id)) or _v21.protected(int(id)) or _v10.effect_protected(int(id)) or _v13.effect_protected(int(id)) or _v15.protected(int(id))or _v35.immune(int(id)): continue
		dealt += mini(_v10.limit_damage(int(id),_v35.effect_amount(amount)),int(fighters[int(id)].hp))
		_damage(int(id),amount)
	return dealt

func _damage_raw(fid: int, amount: int) -> void:
	amount = _v10.limit_damage(fid,amount)
	if fid < 0 or fid >= fighters.size() or amount <= 0 or not fighters[fid].alive: return
	if bool(fighters[fid].get("offboard",false)): return
	if _is_hero(int(fighters[fid].owner), "willow"):
		willow_form[int(fighters[fid].owner)] = "dark"
	if fighters[fid].hero and _is_hero(int(fighters[fid].owner),"beowulf"): _v8.add_rage(int(fighters[fid].owner),1)
	_v38.damaged(fid)
	fighters[fid].damaged_turn=turn_number
	fighters[fid].hp = maxi(0, int(fighters[fid].hp) - amount)
	if fighters[fid].hp == 0:
		fighters[fid].alive = false
		_v9.defeated(fid)
		_log("%s повержен." % fighters[fid].name)
		if _v18.first_defeat(fid) or _v8.protects_from_defeat(fid): return
		if fighters[fid].hero:
			var owner := int(fighters[fid].owner)
			if match_mode != "teams" and _living_heroes(owner).is_empty():
				players[owner].alive = false
				for helper in fighters:
					if int(helper.owner) == owner: helper.alive = false
		if match_mode == "teams":
			var owner := int(fighters[fid].owner)
			players[owner].alive = false
			for friendly in fighters:
				if int(friendly.owner) == owner and friendly.alive:
					players[owner].alive = true
					break

func _heal(fid: int, amount: int) -> void:
	if fid >= 0 and fid < fighters.size() and fighters[fid].alive:
		fighters[fid].hp = mini(int(fighters[fid].max_hp), int(fighters[fid].hp) + amount)

func _check_winner() -> bool:
	if phase == "game_over" and winner >= 0: return true
	if match_mode == "teams":
		var hero_teams: Array = []
		for f in fighters:
			if f.hero and (f.alive or _v18.protects(int(f.id)) or _v8.protects_from_defeat(int(f.id))):
				var team := int(players[int(f.owner)].team)
				if not hero_teams.has(team): hero_teams.append(team)
		if hero_teams.size() > 1: return false
		winner_team = int(hero_teams[0]) if not hero_teams.is_empty() else int(players[active].team)
		winner = -1
		for f in fighters:
			if f.alive and f.hero and int(players[int(f.owner)].team) == winner_team:
				winner = int(f.owner)
				break
		if winner < 0:
			for i in range(players.size()):
				if int(players[i].team) == winner_team and players[i].alive:
					winner = i
					break
		if winner < 0: winner = active
		phase = "game_over"
		_log("Победила команда %d!" % (winner_team + 1))
		return true
	var living: Array = []
	for i in range(players.size()):
		if players[i].alive: living.append(i)
	if living.size() <= 1:
		# If the last heroes fall during the same action, the active player wins.
		winner = int(living[0]) if living.size() == 1 else active
		winner_team = winner
		phase = "game_over"
		_log("Победитель: %s!" % _player_name(winner) if winner >= 0 else "Бой завершён вничью.")
		return true
	return false

func _can_act() -> bool:
	return phase == "action" and winner == -1 and (actions_left > 0 or _v34.has_free(active)) and not players.is_empty() and players[active].alive and not is_dormant(active)

func _valid_fighter(fid: int, owner: int = -1) -> bool:
	return fid >= 0 and fid < fighters.size() and fighters[fid].alive and not bool(fighters[fid].get("offboard",false)) and (owner < 0 or int(fighters[fid].owner) == owner)

func _movement(owner: int) -> int:
	var distance := int(players[owner].move)
	if _is_hero(owner, "sinbad"): distance += _voyages(owner)
	if _v15.enraged(owner):distance=3
	if _v14.ongoing(owner)=="polymorphy":distance=5
	return distance+_v32.move_bonus(owner)+_v36.move_bonus(owner)

func _maneuver_budget(fid: int) -> int:
	return maneuver_distance+_v34.movement_bonus(fid)+(2 if _is_hero(int(fighters[fid].owner),"ancient_leshen") and not fighters[fid].hero else 0)

func legal_moves(fighter_id: int, boost_index: int = -1) -> Array[int]:
	var result: Array[int] = []
	if not _valid_fighter(fighter_id, active): return result
	if fighters.any(func(f):return _valid_fighter(int(f.id)) and f.has("friendly_transit") and int(f.id)!=fighter_id):return result
	if phase != "action" and phase != "move": return result
	if phase == "move" and maneuver_moved.has(fighter_id): return result
	var distance := (maneuver_distance if phase == "move" else _movement(active))+_v34.movement_bonus(fighter_id)
	if _is_hero(active,"ancient_leshen") and not fighters[fighter_id].hero: distance+=2
	if phase == "move" and _v12.stepwise(fighter_id) and door_states.is_empty(): distance -= int(door_movement_spent.get(fighter_id,0))
	if phase == "action" and boost_index >= 0 and boost_index < players[active].hand.size():
		var boost: Dictionary = players[active].hand[boost_index]
		if not can_boost_card(boost): return result
		distance += int(boost.get("boost", 0))
		if _is_hero(active, "sinbad") and bool(boost.get("voyage", false)): distance += 1
	if phase == "move" and not door_states.is_empty(): distance -= int(door_movement_spent.get(fighter_id,0))
	if _is_hero(active,"houdini") and fighters[fighter_id].hero and ((phase == "move" and maneuver_boosted) or (phase == "action" and boost_index >= 0)) and int(fighters[fighter_id].get("locked_until",-1)) != turn_number:
		for node in nodes:
			if _occupant(int(node.id)) in [-1,fighter_id]: result.append(int(node.id))
		return result
	return _reachable(fighter_id, mini(distance,1) if _v12.stepwise(fighter_id) else distance)

func can_boost_card(card: Dictionary) -> bool:
	return bool(card.get("can_boost", not (bool(card.get("voyage", false)) and int(card.get("boost", 0)) == 0))) and card.get("boost", null) != null

func _reachable(fid: int, distance: int) -> Array[int]:
	return _reachable_options(fid, distance, false)

func _reachable_options(fid: int, distance: int, through_enemies: bool, through_sidekicks = false, friendly_endpoints=false) -> Array[int]:
	if _v31.small(fid):return _v31.small_reach(fid,distance)
	if _v19.large(fid):return _v19.reach(fid,distance,through_enemies)
	var result: Array[int] = []
	if not _valid_fighter(fid): return result
	var origin := int(fighters[fid].node)
	if int(fighters[fid].get("locked_until",-1)) == turn_number:
		result.append(origin)
		return result
	var owner := int(fighters[fid].owner)
	through_enemies = through_enemies or _v13.glamour(owner)=="invisibility" or (_is_hero(owner,"buffy") and bool(fighters[fid].hero))
	var queue: Array = [[origin, 0]]
	if _v19.large(fid) and int(fighters[fid].get("tail",-1))>=0:queue.append([int(fighters[fid].tail),0])
	var seen := {origin: true}
	while not queue.is_empty():
		var current: Array = queue.pop_front()
		var here := int(current[0])
		var steps := int(current[1])
		var occupant := _occupant(here)
		if occupant < 0 or occupant == fid or (friendly_endpoints and not is_enemy(owner,int(fighters[occupant].owner)) and _enemy_trap_at(here,owner)<0): result.append(here)
		if steps >= distance: continue
		if here != origin and _enemy_trap_at(here, owner) >= 0: continue
		var links: Array = _v34.links(fid,here)
		if _is_hero(owner,"invisible_man") and bool(fighters[fid].hero) and fog_at(here,owner) >= 0:
			for fog in fog_tokens:
				if int(fog.owner) == owner and not links.has(int(fog.node)): links.append(int(fog.node))
		for next in links:
			if seen.has(next): continue
			seen[next] = true
			var blocking := _occupant(int(next))
			if not through_enemies and blocking >= 0 and is_enemy(owner, int(fighters[blocking].owner)) and not (through_sidekicks and not fighters[blocking].hero): continue
			queue.append([int(next), steps + 1])
	return result

func begin_maneuver(boost_index: int = -1) -> bool:
	if not _can_act() or actions_left<=0: return false
	if boost_index<0 and players[active].bot and _is_hero(active,"black_panther") and _v31.best_suit(active)>=0:
		var at=_v31.best_suit(active)
		players[active].hand.append(players[active].suit.pop_at(at));boost_index=players[active].hand.size()-1
	if boost_index >= players[active].hand.size(): return false
	if boost_index >= 0 and not can_boost_card(players[active].hand[boost_index]): return false
	_v34.clear_free(active)
	players[active].maneuvered_turn = turn_number
	_maneuver_boost = 0
	maneuver_boosted = false
	maneuver_distance = _movement(active)
	maneuver_moved.clear()
	players[active].foot_crossed=[]
	door_movement_spent.clear()
	door_active_fighter = -1
	actions_left -= 1
	players[active].actions_taken = int(players[active].get("actions_taken", 0)) + 1
	if _is_hero(active,"svyatogor"):_damage(hero_fighter(active),1)
	# Mandatory draw happens before any optional BOOST. A newly drawn card may
	# therefore be selected through boost_maneuver before moving any fighter.
	if not _is_hero(active,"donatello"):_draw(active,2 if _is_hero(active,"hamlet") and players[active].get("question","be")=="be" else 1)
	if _check_winner():
		changed.emit()
		return true
	if not players[active].alive:
		phase = "action"
		end_turn()
		return true
	phase = "move"
	if _is_hero(active,"john_henry"):
		if boost_index>=0:_apply_maneuver_boost(boost_index)
		_start_ability(active,"Движение по рельсам",[{"kind":"v34_rail","fid":hero_fighter(active),"spaces":maneuver_distance}],"v34_maneuver");changed.emit();return true
	if _is_hero(active,"donatello"):
		if boost_index>=0:_apply_maneuver_boost(boost_index)
		_start_ability(active,"Изобретатель",[{"kind":"v33_maneuver"}],"v33_maneuver");changed.emit();return true
	if _v21.maneuver(boost_index):return true
	if boost_index >= 0:
		if _v36.boost_offer(boost_index,{"owner":active,"self":hero_fighter(active),"card":{"name":"Усиление манёвра"}},"maneuver_boost"):changed.emit();return true
		_apply_maneuver_boost(boost_index)
	_v9.flush_damage()
	_log("%s: манёвр, перемещение до %d." % [_player_name(active), maneuver_distance])
	_v13.maneuver()
	changed.emit()
	return true

func _apply_maneuver_boost(card_index: int) -> void:
	var boost: Dictionary = players[active].hand.pop_at(card_index)
	var base_before := _movement(active)
	_maneuver_boost = int(boost.get("boost", 0))
	maneuver_boosted = true
	maneuver_distance += _maneuver_boost + _movement(active) - base_before
	if _is_hero(active,"sinbad") and bool(boost.get("voyage",false)): maneuver_distance += 1
	_log("Усиление манёвра: %s (+%d)." % [boost.get("name", "карта"), _maneuver_boost])
	_v8.boosted(active,boost,true)

func boost_maneuver(card_index: int) -> bool:
	if phase != "move" or maneuver_boosted or not maneuver_moved.is_empty(): return false
	if card_index < 0 or card_index >= players[active].hand.size(): return false
	if not can_boost_card(players[active].hand[card_index]): return false
	if _v36.boost_offer(card_index,{"owner":active,"self":hero_fighter(active),"card":{"name":"Усиление манёвра"}},"maneuver_boost"):changed.emit();return true
	_apply_maneuver_boost(card_index)
	changed.emit()
	return true

func move_fighter(fighter_id: int, destination: int) -> bool:
	if phase != "move" or not legal_moves(fighter_id).has(destination): return false
	if _v19.offer(fighter_id,destination,"move",mini(maneuver_distance,1) if _v12.stepwise(fighter_id) else maneuver_distance):return true
	if not door_states.is_empty():
		_v8.activate_fighter(fighter_id)
		door_movement_spent[fighter_id] = int(door_movement_spent.get(fighter_id,0))+_v8.move_cost(fighter_id,destination)
	var _v12_origin=int(fighters[fighter_id].node)
	var insight_origin=int(fighters[fighter_id].node)
	_enter_node(fighter_id, destination)
	if not fighters.any(func(f):return int(f.id)!=fighter_id and _valid_fighter(int(f.id)) and int(f.node)==int(fighters[fighter_id].node)):fighters[fighter_id].erase("friendly_transit")
	_v19.moved(fighter_id,insight_origin,false)
	if _v12.stepwise(fighter_id) and door_states.is_empty():
		door_movement_spent[fighter_id]=int(door_movement_spent.get(fighter_id,0))+int(destination != _v12_origin)
		if int(door_movement_spent[fighter_id]) >= maneuver_distance: maneuver_moved.append(fighter_id)
	elif door_states.is_empty() or (_is_hero(active,"houdini") and fighters[fighter_id].hero and maneuver_boosted): maneuver_moved.append(fighter_id)
	if _flow.is_empty(): _v9.flush_damage()
	if _check_winner():
		changed.emit()
		return true
	if not players[active].alive: finish_maneuver()
	changed.emit()
	return true

func legal_friendly_transits(fid: int) -> Array[int]:
	var result:Array[int]=[]
	if phase!="move" or door_states.is_empty() or not _valid_fighter(fid,active) or _v19.large(fid) or maneuver_moved.has(fid):return result
	if _is_hero(active,"houdini") and fighters[fid].hero and maneuver_boosted:return result
	if fighters.any(func(f):return _valid_fighter(int(f.id)) and f.has("friendly_transit") and int(f.id)!=fid):return result
	var remaining=maneuver_distance-int(door_movement_spent.get(fid,0))
	if _is_hero(active,"ancient_leshen") and not fighters[fid].hero:remaining+=2
	var distance=mini(remaining-1,1) if _v12.stepwise(fid) else remaining-1
	if distance<1:return result
	for node in _reachable_options(fid,distance,false,false,true):
		var occupant=_occupant(int(node))
		if occupant>=0 and occupant!=fid and not is_enemy(active,int(fighters[occupant].owner)):result.append(int(node))
	return result
func enter_friendly_transit(fid: int, node: int) -> bool:
	if not legal_friendly_transits(fid).has(node):return false
	var cost=0
	for distance in range(1,maneuver_distance+1):
		if _reachable_options(fid,distance,false,false,true).has(node):cost=distance;break
	_v8.activate_fighter(fid);door_movement_spent[fid]=int(door_movement_spent.get(fid,0))+cost
	fighters[fid].friendly_transit=true;_enter_node(fid,node);changed.emit();return true

func finish_maneuver() -> void:
	if phase != "move": return
	if fighters.any(func(f):return _valid_fighter(int(f.id)) and f.has("friendly_transit")):
		_log("Продолжите движение: нельзя закончить на занятой клетке.");return
	if _v36.finish_maneuver():return
	if _is_hero(active,"jekyll_hyde") and form_for(active) == "hyde":
		_damage(hero_fighter(active),1)
		_log("Мистер Хайд: после манёвра потеря 1 здоровья.")
	phase = "action"
	_after_action()
	changed.emit()

func maneuver(fighter_id: int, destination: int, boost_index: int = -1) -> bool:
	if not legal_moves(fighter_id, boost_index).has(destination): return false
	if not begin_maneuver(boost_index): return false
	if phase == "move":
		move_fighter(fighter_id, destination)
		finish_maneuver()
	return true

func _card_usable(card: Dictionary, fid: int) -> bool:
	if not _valid_fighter(fid): return false
	var user := str(card.get("fighter", "any")).to_lower()
	if user in ["jekyll","hyde"]: return bool(fighters[fid].hero) and _is_hero(int(fighters[fid].owner),"jekyll_hyde") and form_for(int(fighters[fid].owner)) == user
	if user in ["any", "all", "все", "любой"]: return true
	if user in ["hero", "герой"]: return bool(fighters[fid].hero)
	if user in ["sidekick", "sidekicks", "помощник"]: return not bool(fighters[fid].hero)
	if user == str(fighters[fid].name).to_lower(): return true
	return user == _hero_id(int(fighters[fid].owner)) and bool(fighters[fid].hero)

func _attack_type(card: Dictionary) -> bool:
	return str(card.get("type", "")) in ["attack", "versatile", "атака", "универсальная"] or (card.get("enraged_attack",false) and _v15.enraged(active))

func _defense_type(card: Dictionary) -> bool:
	return str(card.get("type", "")) in ["defense", "versatile", "защита", "универсальная"]

func _in_range(a: int, b: int) -> bool:
	if not _valid_fighter(a) or not _valid_fighter(b): return false
	if _v38.in_range(a,b):return true
	if _is_hero(int(fighters[a].owner),"moose"):return fighters_adjacent(a,b)
	if _v19.large(a):
		for origin in _v19.spaces(a):
			for target in _v19.spaces(b):
				if _v14.board_distance(int(origin),int(target))<=2:return true
	if _v19.large(b):
		for target in _v19.spaces(b):
			if nodes[int(fighters[a].node)].neighbors.has(int(target)) or (fighters[a].ranged and _same_zone(int(fighters[a].node),int(target))):return true
	if _is_hero(int(fighters[a].owner),"ms_marvel") and fighters_distance(a,b)<=2:return true
	if fighters_adjacent(a,b): return true
	if _is_hero(int(fighters[a].owner),"bullseye") and fighters_distance(a,b)<=5:return true
	if _is_hero(int(fighters[a].owner),"muhammad_ali") and bool(fighters[a].hero) and stance_for(int(fighters[a].owner)) == "butterfly":
		for middle in nodes[int(fighters[a].node)].neighbors:
			if node_adjacent_to_fighter(int(middle),b): return true
	return bool(fighters[a].ranged) and _same_zone(int(fighters[a].node), int(fighters[b].node))

func _same_zone(a: int, b: int) -> bool:
	for zone in _v19.zones(a):
		if _v19.zones(b).has(zone): return _v8.zone_path_open(a,b)
	return false

func changed_start_space(fid: int) -> bool:
	if fid<0 or fid>=turn_start_nodes.size():return false
	if not _v19.large(fid) or fid>=turn_start_tails.size():return int(fighters[fid].node)!=int(turn_start_nodes[fid])
	var before=[int(turn_start_nodes[fid])]
	if fid<turn_start_tails.size() and int(turn_start_tails[fid])>=0:before.append(int(turn_start_tails[fid]))
	var now=_v19.spaces(fid);before.sort();now.sort()
	return before!=now

func node_adjacent_to_fighter(node: int, fid: int) -> bool:
	if not _valid_fighter(fid):return false
	for cell in _v19.spaces(fid):
		if nodes[node].neighbors.has(int(cell)):return true
	return false

func fighters_adjacent(a: int, b: int) -> bool:
	if a==b or not _valid_fighter(a) or not _valid_fighter(b):return false
	if (_v31.small(a) or _v31.small(b)) and _v19.spaces(a).any(func(n):return _v19.spaces(b).has(n)):return true
	for origin in _v19.spaces(a):
		for target in _v19.spaces(b):
			if nodes[int(origin)].neighbors.has(int(target)):return true
	return false
func fighters_distance(a: int, b: int) -> int:
	var result=999
	if not _valid_fighter(a) or not _valid_fighter(b):return result
	for origin in _v19.spaces(a):
		for target in _v19.spaces(b):result=mini(result,_v14.board_distance(int(origin),int(target)))
	return result

func legal_targets(fighter_id: int, card_index: int) -> Array[int]:
	var result: Array[int] = []
	if not _can_act() or not _valid_fighter(fighter_id, active): return result
	if _v35.first_attack_blocked(active):return result
	if card_index < 0 or card_index >= players[active].hand.size(): return result
	var card: Dictionary = players[active].hand[card_index]
	if not _card_usable(card, fighter_id): return result
	if not _attack_type(card):
		if str(card.get("type", "")) == "scheme":
			for f in fighters:
				if _valid_fighter(int(f.id)) and is_enemy(active, int(f.owner)): result.append(int(f.id))
		return result
	for f in fighters:
		if str(card.get("id",""))=="witness_my_last_battle" and not fighters_adjacent(fighter_id,int(f.id)): continue
		if actions_left<=0 and _v34.has_free(active) and int(players[active].get("free_target",-1))not in[-1,int(f.id)]:continue
		if _valid_fighter(int(f.id)) and is_enemy(active, int(f.owner)) and (_in_range(fighter_id, int(f.id)) or _v36.foot_range(fighter_id,int(f.id)) or _v36.ranged(card,fighter_id,int(f.id)) or _v38.ranged(card,fighter_id,int(f.id)) or _v15.global_attack(card,active) or _v24.global_attack(active) or (str(card.id)=="xavier_institute_faculty" and _is_hero(active,"deadpool") and _same_zone(int(fighters[fighter_id].node),int(f.node)))): result.append(int(f.id))
	return result

func attack(fighter_id: int, target_id: int, card_index: int, boost_index: int = -1) -> bool:
	if not legal_targets(fighter_id, card_index).has(target_id): return false
	if str(players[active].hand[card_index].id)=="witness_my_last_battle" and not fighters_adjacent(fighter_id,target_id): return false
	var hand: Array = players[active].hand
	if not _attack_type(hand[card_index]): return false
	var boost := 0
	var boosted := false
	if boost_index >= 0:
		if not _is_hero(active, "arthur") or not fighters[fighter_id].hero: return false
		if boost_index == card_index or boost_index >= hand.size(): return false
		if not can_boost_card(hand[boost_index]): return false
		var extra: Dictionary = hand[boost_index]
		boost = int(extra.get("boost", 0))
		_discard(active, extra)
		hand.remove_at(boost_index)
		if boost_index < card_index: card_index -= 1
		boosted = true
	var card: Dictionary = hand.pop_at(card_index)
	if not _v34.spend_attack(active,target_id):actions_left -= 1
	players[active].actions_taken = int(players[active].get("actions_taken", 0)) + 1
	_v14.attack_started(fighter_id)
	_v24.used_attack(active)
	players[active].nature_attacks=int(players[active].get("nature_attacks",0))+1
	pending_combat = {"face_up":_v15.global_attack(card,active) or _v36.num(card)==759 or (card.get("nature_hero","")=="moose"and int(card.get("nature_number",0))==6) or (card.get("nature_hero","")=="godzilla"and int(card.get("nature_number",0))==2),"attacker": fighter_id, "target": target_id, "attack_card": card, "defender_owner": int(fighters[target_id].owner), "attack_owner": active, "boost": boost, "boosted": boosted}
	pending_combat.hb_next_bonus=int(players[active].get("hb_next_attack",0));players[active].hb_next_attack=0;fighters[fighter_id].hb_attack_turn=turn_number
	if _v29.before_attack(fighter_id):
		_discard(active,card);pending_combat.clear();_after_action();changed.emit();return true
	_log("%s атакует %s." % [fighters[fighter_id].name, fighters[target_id].name])
	if _v35.before_attack():changed.emit();return true
	if _v24.offer("a"):return true
	if interactive:
		phase = "attack_notice"
	else:
		_begin_defense()
	changed.emit()
	return true

func continue_attack() -> bool:
	if phase != "attack_notice" or pending_combat.is_empty(): return false
	_begin_defense()
	changed.emit()
	return true

func _begin_defense() -> void:
	_v35.reveal_intuition()
	if _check_winner():return
	if _v34.ruse_offer():changed.emit();return
	if _v13.prepare_defense(): return
	var target_id := int(pending_combat.target)
	var fighter_id := int(pending_combat.attacker)
	if not players[int(fighters[target_id].owner)].bot:
		phase = "defend"
	else:
		phase = "combat"
		_resolve_combat(_choose_defense(target_id, fighter_id))

func legal_defenses() -> Array[int]:
	var result: Array[int] = []
	if pending_combat.is_empty(): return result
	var owner := int(pending_combat.defender_owner)
	var fid := int(pending_combat.target)
	for i in range(players[owner].hand.size()):
		var card: Dictionary = players[owner].hand[i]
		if (_defense_type(card) or (_is_hero(owner,"little_red") and str(card.get("id","")) == "what_big_ears_you_have" and _v8.basket(owner) in ["knife","wild"])) and _card_usable(card, fid): result.append(i)
	return result

func defend(card_index: int = -1) -> bool:
	if phase != "defend" or pending_combat.is_empty(): return false
	if card_index >= 0 and not legal_defenses().has(card_index): return false
	_resolve_combat(card_index)
	changed.emit()
	return true

func _discard(owner: int, card: Dictionary, source: String = "hand") -> void:
	if _v35.discard(owner,card,source):return
	if _v32.discarded(owner,card,source):return
	if card.has("_suit_owner"):
		owner=int(card._suit_owner);card=card.duplicate(true);card.erase("_suit_owner");card.erase("_stolen_boost_effect")
	if _is_hero(owner,"the_wayward_sisters"):
		if not players[owner].has("cauldron"): players[owner].cauldron=[]
		players[owner].cauldron.append(card)
	else: players[owner].discard.append(card)
	players[owner].voyages = _voyages(owner)
	_v35.refresh_forms()

func _discard_from_opponent(owner: int, card: Dictionary, forced_hand=true) -> bool:
	if forced_hand and (_v14.owl_protected(owner)or _v35.shielded(owner)):
		players[owner].hand.append(card)
		_log("Неясыть: сброс из руки проигнорирован.")
		return false
	_discard(owner,card,"hand" if forced_hand else "deck")
	_v8.opponent_discarded(owner,card)
	return true

func _voyages(owner: int) -> int:
	var count := 0
	for card in players[owner].discard:
		var effect := str(card.get("effect", ""))
		if effect.begins_with("voyage_"): count += 1
	return count

func _after_action() -> void:
	if _flow.is_empty() and _v32.flush_returns("action"):return
	if _check_winner(): return
	phase = "action"
	if not players[active].alive or is_dormant(active) or (actions_left <= 0 and not _v34.has_free(active)):
		end_turn()

func end_turn() -> void:
	_v34.clear_free(active)
	if phase not in ["action", "discard"] or players.is_empty(): return
	if int(players[active].get("end_ability_turn",-1)) != turn_number:
		players[active].end_ability_turn = turn_number
		_v21.end_turn()
		_v19.end_turn()
		_v14.end_turn()
		_v7.end_turn()
		if _v16.end_turn(): return
		if _v13.end_turn(): return
		if _v10.end_turn(): return
		players[active].fixed_four = false
		if _is_hero(active, "bigfoot") and _valid_fighter(hero_fighter(active)):
			var alone := true
			for f in fighters:
				if _valid_fighter(int(f.id)) and is_enemy(active, int(f.owner)) and _same_zone(int(fighters[hero_fighter(active)].node), int(f.node)): alone = false
			if alone:
				_start_ability(active, "Способность Бигфута", [{"kind": "optional_draw", "amount": 1}], "end_turn")
				return
		if _is_hero(active, "bruce_lee") and _valid_fighter(hero_fighter(active)):
			_start_ability(active, "Способность Брюса Ли", [{"kind": "move", "target": "self", "spaces": 1}], "end_turn")
			return
	if _v36.end_turn():return
	if players[active].alive and not is_dormant(active) and players[active].hand.size() > _v33.limit(active):
		phase = "discard"
		_log("%s: сбросьте до 7 карт." % _player_name(active))
		changed.emit()
		return
	if _is_hero(active,"rosie_the_riveter") and _v34.active_upgrades(active).size()==4:players[active].upgrade_active=[];_v34.sync_rosie(active)
	if _v35.end_turn():return
	if _v32.end_board():return
	if _check_winner():
		changed.emit()
		return
	for n in range(players.size()):
		active = (active + 1) % players.size()
		if players[active].alive: break
	actions_left = 2
	phase = "action"
	turn_number += 1
	players[active].turn_attack_bonus = 0
	players[active].won_combat_turn = false
	players[active].played_turn=0;players[active].lost_turn=false;players[active].anger_used=false;players[active].nunchaku=0
	players[active].combat_damage_turn = 0
	players[active].actions_taken = 0
	players[active].actions_taken = 0
	_snapshot_positions()
	_log("Ход %d: %s." % [turn_number, _player_name(active)])
	_start_turn_ability()
	if not _check_winner() and not players[active].alive: end_turn()
	changed.emit()

func discard_card(index: int) -> bool:
	if phase != "discard" or index < 0 or index >= players[active].hand.size(): return false
	_discard(active, players[active].hand.pop_at(index),"limit")
	if _v32.flush_returns("v32_discard"):changed.emit();return true
	if players[active].hand.size() <= _v33.limit(active): end_turn()
	changed.emit()
	return true

func _start_turn_ability() -> void:
	if _v38.start_turn():return
	if _v36.start_turn():return
	if _v35.start_turn():return
	if _v34.start_turn():return
	if _v33.start_turn():return
	if _v32.start_turn():return
	if _v31.start_turn():return
	if _v29.start_turn():return
	if _v22.start_turn():return
	if _v21.start_turn():return
	if _v18.start_turn():return
	if _v14.start_turn(): return
	if _v13.start_turn(): return
	if _v10.start_turn(): return
	if _v9.start_turn(): return
	if _v8.start_turn(): return
	if _v7.start_turn(): return
	if _v6.start_turn(): return
	if _is_hero(active, "medusa"):
		var hero := hero_fighter(active)
		if _valid_fighter(hero):
			_start_ability(active, "Взгляд Медузы", [{"kind": "damage", "target": "enemy_in_hero_zone", "amount": 1, "optional": true}], "start_turn")
	if _is_hero(active, "ingen") and _valid_fighter(hero_fighter(active)):
		_start_ability(active, "Ловушка Малдуна", [{"kind": "place_traps", "amount": 1, "optional": true}], "start_turn")

func _start_ability(owner: int, title: String, effects: Array, completion: String) -> void:
	var card := {"name": title, "effects": effects, "text": "Способность героя"}
	var ctx := {"owner": owner, "self": hero_fighter(owner), "opponent": -1, "opponent_owner": -1, "card": card, "value": 0, "won": false}
	_flow = {"kind": "ability", "stage": "effects", "owner": owner, "card": card, "completion": completion, "effect_logs": []}
	combat_report = {"kind": "ability", "stage": "effects", "owner": owner, "title": title, "card": card, "effect_logs": []}
	_effect_queue.clear()
	for effect in effects: _effect_queue.append({"effect": effect.duplicate(true), "ctx": ctx.duplicate(true)})
	_pump_effects()

func trap_supply(owner: int) -> int:
	return int(_trap_stock.get(owner, 0))

func _trap_at(node: int) -> int:
	for i in range(traps.size()):
		if int(traps[i].node) == node: return i
	return -1

func _enemy_trap_at(node: int, owner: int) -> int:
	var index := _trap_at(node)
	return index if index >= 0 and is_enemy(owner, int(traps[index].owner)) else -1

func legal_trap_nodes(owner: int, anywhere: bool = false) -> Array[int]:
	var result: Array[int] = []
	var hero := hero_fighter(owner)
	if trap_supply(owner) <= 0 or not _valid_fighter(hero): return result
	for node in nodes:
		if _occupant(int(node.id)) >= 0 or _trap_at(int(node.id)) >= 0 or fog_at(int(node.id)) >= 0 or shadow_at(int(node.id)) >= 0: continue
		if anywhere or _same_zone(int(fighters[hero].node), int(node.id)): result.append(int(node.id))
	return result

func _place_trap(owner: int, node: int, anywhere: bool = false) -> bool:
	if not legal_trap_nodes(owner,anywhere).has(node): return false
	traps.append({"owner": owner, "node": node})
	_trap_stock[owner] = trap_supply(owner) - 1
	_log("Ловушка Малдуна установлена: клетка %d. В запасе: %d." % [node + 1, trap_supply(owner)])
	return true

func _return_trap(index: int) -> void:
	if index < 0 or index >= traps.size(): return
	var trap: Dictionary = traps.pop_at(index)
	_log("Ловушка с клетки %d возвращена в коробку; Малдун берёт 1 карту." % (int(trap.node) + 1))
	_draw(int(trap.owner), 1)

func _enter_node(fid: int, node: int) -> void:
	if _v35.block_move(fid):return
	if _v31.small(fid) and not _v31.can_end(fid,node):return
	if int(fighters[fid].get("locked_until",-1)) == turn_number and int(fighters[fid].node) != node:
		_log("Клинч: боец не может покинуть клетку до конца хода.")
		return
	var old := int(fighters[fid].node)
	var old_cells=_v19.spaces(fid).duplicate()
	_v19.body(fid,node,old)
	fighters[fid].node = node
	_v34.departed(fid,old,node)
	_v36.crossed(fid,old,node,old_cells)
	if old != node and not fighters[fid].get("returning_offboard",false):
		fighters[fid].left_space_turn=turn_number
		_v12.departed(fid,old,node,{"old_cells":old_cells})
	if old == node or not _valid_fighter(fid): return
	_trigger_trap(fid)

func _trigger_trap(fid: int) -> void:
	if not _valid_fighter(fid): return
	for node in _v19.spaces(fid):
		var trap := _enemy_trap_at(int(node), int(fighters[fid].owner))
		if trap >= 0 and _valid_fighter(fid):
			_log("Ловушка: %s останавливается и получает 1 урон." % fighters[fid].name)
			var previous_actor=_v35.actor_override;_v35.actor_override=int(traps[trap].owner)
			_damage(fid, 1)
			_v35.actor_override=previous_actor
			if phase=="move":door_movement_spent[fid]=_maneuver_budget(fid)
			_return_trap(trap)

func _log(line: String) -> void:
	logs.append(line)
	if logs.size() > 120: logs.pop_front()
	if str(_flow.get("stage", "")) == "effects": _flow.effect_logs.append(line)
	message.emit(line)

func save_state() -> Dictionary:
	return {"version": 24, "battlefield_items":battlefield_items.duplicate(true), "combat_stack":_combat_stack.duplicate(true), "deferred_damage":_deferred_damage.duplicate(true), "door_states":door_states.duplicate(), "door_movement_spent":door_movement_spent.duplicate(), "door_active_fighter":door_active_fighter, "shadow_tokens":shadow_tokens.duplicate(true), "willow_form":willow_form.duplicate(), "ali_stance":ali_stance.duplicate(), "jekyll_form":jekyll_form.duplicate(), "fog_tokens":fog_tokens.duplicate(true), "players": players.duplicate(true), "fighters": fighters.duplicate(true), "active": active, "actions_left": actions_left, "phase": phase, "winner": winner, "logs": logs.duplicate(), "selected_fighter": selected_fighter, "pending_combat": pending_combat.duplicate(true), "maneuver_moved": maneuver_moved.duplicate(), "maneuver_distance": maneuver_distance, "maneuver_boosted": maneuver_boosted, "maneuver_boost": _maneuver_boost, "difficulty": difficulty, "turn_number": turn_number, "turn_start_nodes": turn_start_nodes.duplicate(), "turn_start_tails":turn_start_tails.duplicate(), "alice_size": alice_size.duplicate(), "rng_state": str(rng.state), "rng_seed": str(rng.seed), "interactive": interactive, "pending_choice": pending_choice.duplicate(true), "combat_report": combat_report.duplicate(true), "last_combat": last_combat.duplicate(true), "effect_queue": _effect_queue.duplicate(true), "flow": _flow.duplicate(true), "map_id": map_id, "match_mode": match_mode, "winner_team": winner_team, "start_slots": start_slots.duplicate(), "setup_fighter": setup_fighter, "setup_order": _setup_order.duplicate(), "traps": traps.duplicate(true), "trap_stock": _trap_stock.duplicate(true), "combat_resolution": _combat_resolution.duplicate(true)}

func load_state(state: Dictionary) -> bool:
	if int(state.get("version", 0)) not in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] or not state.get("players", null) is Array or not state.get("fighters", null) is Array: return false
	if state.players.size() < 2 or state.players.size() > 4: return false
	_load_boards()
	_build_board(str(state.get("map_id", "training")))
	players = state.players.duplicate(true)
	fighters = state.fighters.duplicate(true)
	match_mode = "teams" if str(state.get("match_mode", "ffa")) == "teams" and players.size() == 4 else "ffa"
	for i in range(players.size()): players[i].team = i % 2 if match_mode == "teams" else i
	for f in fighters:
		f.id = int(f.id)
		f.owner = int(f.owner)
		f.node = int(f.node)
		f.hp = int(f.hp)
		f.max_hp = int(f.max_hp)
		f.placed = bool(f.get("placed", true))
	start_slots = _int_array(state.get("start_slots", []))
	if start_slots.size() != players.size():
		start_slots.clear()
		for i in range(players.size()): start_slots.append(i)
	setup_fighter = int(state.get("setup_fighter", -1))
	_setup_order = _int_array(state.get("setup_order", []))
	_reserved_starts.clear()
	active = int(state.get("active", 0))
	if active < 0 or active >= players.size(): return false
	for f in fighters:
		if (int(f.get("node", -1)) < 0 and not (bool(f.get("reserve",false)) and (_v31.small(int(f.id)) or (_is_hero(int(f.owner),"pandora") and not f.hero)))) or int(f.node) >= nodes.size(): return false
		if int(f.get("owner", -1)) < 0 or int(f.owner) >= players.size(): return false
	actions_left = int(state.get("actions_left", 2))
	phase = str(state.get("phase", "action"))
	if phase not in ["setup", "action", "move", "defend", "discard", "game_over", "attack_notice", "combat_report", "effect_move", "effect_choice"]: return false
	winner = int(state.get("winner", -1))
	winner_team = int(state.get("winner_team", int(players[winner].team) if winner >= 0 and winner < players.size() else -1))
	logs.assign(state.get("logs", []))
	selected_fighter = int(state.get("selected_fighter", -1))
	pending_combat = state.get("pending_combat", {}).duplicate(true)
	interactive = bool(state.get("interactive", interactive))
	pending_choice = state.get("pending_choice", {}).duplicate(true)
	for key in ["legal", "allowed_fighters", "remaining", "selected_spaces", "ids", "indices", "costs", "chosen"]:
		if pending_choice.has(key): pending_choice[key] = _int_array(pending_choice[key])
	if pending_choice.has("route"): pending_choice.route.passed = _int_array(pending_choice.route.get("passed",[]))
	if str(pending_choice.get("action",""))=="v14_path":
		pending_choice.choices=_int_array(pending_choice.choices)
		pending_choice.state.route=_int_array(pending_choice.state.route)
	combat_report = state.get("combat_report", {}).duplicate(true)
	last_combat = state.get("last_combat", {}).duplicate(true)
	_combat_resolution = state.get("combat_resolution", {}).duplicate(true)
	traps.clear()
	for token in state.get("traps", []):
		var trap_owner = int(token.get("owner", -1))
		var trap_node = int(token.get("node", -1))
		if trap_owner < 0 or trap_owner >= players.size() or trap_node < 0 or trap_node >= nodes.size(): return false
		traps.append({"owner":trap_owner,"node":trap_node})
	_trap_stock.clear()
	for key in state.get("trap_stock", {}): _trap_stock[int(key)] = int(state.trap_stock[key])
	_effect_queue = state.get("effect_queue", []).duplicate(true)
	_combat_stack = state.get("combat_stack",[]).duplicate(true)
	_deferred_damage = state.get("deferred_damage",[]).duplicate(true)
	_flow = state.get("flow", {}).duplicate(true)
	maneuver_moved = _int_array(state.get("maneuver_moved", []))
	maneuver_distance = int(state.get("maneuver_distance", 0))
	maneuver_boosted = bool(state.get("maneuver_boosted", false))
	_maneuver_boost = int(state.get("maneuver_boost", 0))
	difficulty = clampi(int(state.get("difficulty", 1)),0,3)
	turn_number = int(state.get("turn_number", 1))
	turn_start_nodes = state.get("turn_start_nodes", []).duplicate()
	turn_start_tails = state.get("turn_start_tails", []).duplicate()
	alice_size.clear()
	for key in state.get("alice_size", {}): alice_size[int(key)] = str(state.alice_size[key])
	ali_stance.clear()
	jekyll_form.clear()
	fog_tokens.clear()
	for key in state.get("ali_stance",{}): ali_stance[int(key)] = str(state.ali_stance[key])
	for key in state.get("jekyll_form",{}): jekyll_form[int(key)] = str(state.jekyll_form[key])
	for token in state.get("fog_tokens",[]):
		var fog_owner := int(token.get("owner",-1))
		var fog_node := int(token.get("node",-1))
		if fog_owner < 0 or fog_owner >= players.size() or fog_node < 0 or fog_node >= nodes.size() or fog_at(fog_node) >= 0: return false
		fog_tokens.append({"id":int(token.get("id",fog_tokens.size())),"owner":fog_owner,"node":fog_node})
	shadow_tokens.clear()
	willow_form.clear()
	for token in state.get("shadow_tokens",[]):
		var shadow_owner := int(token.get("owner",-1))
		var shadow_node := int(token.get("node",-1))
		if shadow_owner < 0 or shadow_owner >= players.size() or shadow_node < 0 or shadow_node >= nodes.size(): return false
		shadow_tokens.append({"id":int(token.get("id",shadow_tokens.size())),"owner":shadow_owner,"node":shadow_node})
	for key in state.get("willow_form",{}): willow_form[int(key)] = str(state.willow_form[key])
	door_states = state.get("door_states",[]).duplicate()
	if door_states.size() != board_data.get("doors",[]).size():
		door_states.clear()
		for door in board_data.get("doors",[]): door_states.append(false)
	door_movement_spent.clear()
	for key in state.get("door_movement_spent",{}): door_movement_spent[int(key)] = int(state.door_movement_spent[key])
	door_active_fighter = int(state.get("door_active_fighter",-1))
	battlefield_items=state.get("battlefield_items",[]).duplicate(true)
	_v8.rebuild_doors()
	for f in fighters:
		if _valid_fighter(int(f.id)) and _is_hero(int(f.owner),"svyatogor") and (int(f.get("tail",-1))<0 or int(f.get("tail",-1))==int(f.node) or not nodes[int(f.node)].neighbors.has(int(f.get("tail",-1)))):_v19.body(int(f.id),int(f.node),-1)
	_v8.migrate_basket_cards()
	rng.seed = int(state.get("rng_seed", "0"))
	rng.state = int(state.get("rng_state", "0"))
	changed.emit()
	return true

# Combat and AI helpers below deliberately inspect only the current bot's hand.

func _has_kind(card: Dictionary, kind: String) -> bool:
	for effect in card.get("effects", []):
		if str(effect.get("kind", "")) == kind: return true
	return false

func _resolve_combat(defense_index: int) -> void:
	if not pending_combat.is_empty() and _v35.prepare_defense(defense_index):changed.emit();return
	if pending_combat.is_empty(): return
	if _v24.offer("d",defense_index):return
	if _v6.prepare_defense(defense_index): return
	var ctx: Dictionary = pending_combat.duplicate(true)
	var attacker := int(ctx.attacker)
	var defender := int(ctx.target)
	var ao := int(ctx.attack_owner)
	var do := int(ctx.defender_owner)
	var attack_card: Dictionary = ctx.attack_card
	var defense_card: Dictionary = {}
	if defense_index >= 0 and defense_index < players[do].hand.size():
		defense_card = players[do].hand.pop_at(defense_index)
	var a := {"owner": ao, "self": attacker, "opponent": defender, "opponent_owner": do, "card": attack_card, "value": int(attack_card.get("value", 0)), "won": false, "prevent": false, "cancelled": false, "_combat_slot": "a", "item":ctx.get("item_a",{})}
	var d := {"owner": do, "self": defender, "opponent": attacker, "opponent_owner": ao, "card": defense_card, "value": int(defense_card.get("value", 0)), "won": false, "prevent": false, "cancelled": false, "_combat_slot": "d", "item":ctx.get("item_d",{})}
	_combat_resolution = {"ctx": ctx, "a": a, "d": d}
	_flow = {"kind": "combat_pre", "stage": "effects", "effect_logs": []}
	_effect_queue.clear()
	_v33.played(ao,attack_card)
	# Resolve immediate effects in order, without undoing an effect that already
	# happened when a later card cancels the remaining effects.
	_queue_card_effects(defense_card, "immediately", d)
	_v17.queue_immediate(a)
	_v18.queue_during(d)
	_v18.queue_during(a)
	_v10.queue_gadget(a,"during")
	_pump_effects()

func _finish_combat_values() -> void:
	var ctx: Dictionary = _combat_resolution.ctx
	var a: Dictionary = _combat_resolution.a
	var d: Dictionary = _combat_resolution.d
	var attacker := int(ctx.attacker)
	var defender := int(ctx.target)
	var ao := int(ctx.attack_owner)
	var do := int(ctx.defender_owner)
	var attack_card: Dictionary = a.card
	var defense_card: Dictionary = d.card
	var attack_cancelled := bool(a.cancelled)
	var defense_cancelled := bool(d.cancelled)
	# These locks fix the card's value. Hero and battlefield attack bonuses
	# are separate modifiers and apply afterwards (e.g. Ali's Bee stance).
	if a.has("locked_value"): a.value = int(a.locked_value)
	if d.has("locked_value"): d.value = int(d.locked_value)
	if bool(players[ao].get("fixed_four",false)): a.value = 4
	if not defense_card.is_empty() and bool(players[do].get("fixed_four",false)): d.value = 4
	for value_ctx in [a,d]:
		if str(value_ctx.card.get("id",""))=="seven_suns_of_cinnibus" and not value_ctx.cancelled and int(value_ctx.value)>7:value_ctx.value=0
	if _is_hero(ao,"muhammad_ali") and fighters[attacker].hero and stance_for(ao) == "bee":
		a.value += 2
		_log("Стойка пчелы: атака Али +2.")
	if not defense_card.is_empty() and _is_hero(do,"invisible_man") and fog_at(int(fighters[defender].node),do) >= 0:
		d.value += 1
		_log("Защита в тумане: +1.")
	if _is_hero(ao, "alice") and fighters[attacker].hero and str(alice_size.get(ao, "big")) == "big":
		a.value += 2
		_log("Большая Алиса: атака +2.")
	if not defense_card.is_empty() and _is_hero(do, "alice") and fighters[defender].hero and str(alice_size.get(do, "big")) == "small":
		d.value += 1
		_log("Маленькая Алиса: защита +1.")
	if _is_hero(ao, "raptors"):
		var bonus := _raptor_bonus(attacker, defender)
		a.value += bonus
		_log("Стая рапторов: другие свои рапторы рядом с целью, атака +%d." % bonus)
	var turn_bonus := int(players[ao].get("turn_attack_bonus", 0))
	if turn_bonus > 0 and not a.has("locked_value"):
		a.value += turn_bonus
		_log("Нунчаки: атака +%d до конца хода." % turn_bonus)
	# Excalibur has no printed effects; official Arthur clarification keeps its boost.
	if not attack_cancelled or str(attack_card.get("effect", "none")) == "none":
		a.value += int(ctx.boost)
		if int(ctx.boost) > 0: _log("Способность Артура: усиление атаки +%d." % int(ctx.boost))
	if _v9.enraged(ao) and fighters[attacker].hero: a.value += 2
	a.value += _v13.attack_bonus(attacker)+_v14.attack_bonus(attacker)
	a.value += _v10.attack_bonus(attacker,defender)+int(a.get("gadget_bonus",0))+_v12.inspire(attacker)
	a.value+=_v15.bonus(ao)
	if not defense_card.is_empty(): d.value += _v12.inspire(defender)+_v15.bonus(do)
	var height_bonus = _v9.fighter_high_ground(attacker,defender)
	if _is_hero(ao,"deadpool") and _v31.real_name(do) in ["logan","логан"]:a.value+=5
	a.value += _v35.attack_bonus(attacker)+_v35.card_bonus(ao)
	if not defense_card.is_empty():d.value+=_v35.card_bonus(do)
	a.value += _v38.bonus(attacker,defender)
	a.value += _v34.attack_bonus(attacker)
	a.value += _v33.bonus(attacker,true)
	if not defense_card.is_empty():d.value+=_v33.bonus(defender,false)
	a.value += _v32.attack_bonus(attacker)
	a.value += _v29.bonus(attacker)
	a.value += height_bonus
	if height_bonus > 0: _log("Возвышение: атака +1.")
	if _is_hero(ao,"moon_knight") and _v21.form(ao)==1:a.value+=2
	if _is_hero(do,"moon_knight") and _v21.form(do)==2:d.value+=1
	if a.get("frozen_printed",false):a.value=int(a.card.get("value",0))
	if d.get("frozen_printed",false):d.value=int(d.card.get("value",0))
	var damage := maxi(0, int(a.value) - int(d.value))
	if not attack_cancelled and bool(a.get("ignore_defense", false)):
		d.value = 0
		damage = maxi(0,int(a.value))
	if bool(a.get("ignore_opponent_value",false)): damage = maxi(0,int(a.value))
	if bool(d.get("ignore_opponent_value",false)): damage = 0
	if bool(d.prevent) or bool(d.get("ignore_attack",false)): damage = 0
	damage = mini(damage,int(d.get("v34_damage_cap",damage)))
	damage = mini(damage,int(d.get("combat_cap",damage)))
	if d.get("nature_halve","")=="up":damage=int(ceil(float(damage)/2.0))
	if d.get("nature_halve","")=="down":damage=int(floor(float(damage)/2.0))
	damage=_v18.reduce_damage(defender,damage)
	var reflecting = bool(d.get("reflect",false))
	var reflected = _v10.limit_damage(attacker,damage) if reflecting else 0
	damage = 0 if reflecting else _v10.limit_damage(defender,damage)
	a.reflected_damage = reflected
	a.damage_dealt = damage
	a.damage_taken = reflected
	d.damage_dealt = 0
	d.damage_taken = damage
	a.won = damage > 0
	d.won = not a.won
	players[ao].combat_damage_turn = int(players[ao].get("combat_damage_turn",0)) + damage
	if a.get("v34_no_after_if_win",false)and a.won and not _card_uncancellable(int(d.owner),d.card):d.no_after=true
	if d.get("v34_no_after_if_win",false)and d.won and not _card_uncancellable(int(a.owner),a.card):a.no_after=true
	_v33.lost(do if damage>0 else ao)
	if damage > 0: players[ao].won_combat_turn = true
	else: players[do].won_combat_turn = true
	_log("%s [%s: %d] — %s [%s: %d]. Урон: %d." % [fighters[attacker].name, attack_card.get("name", "—"), a.value, fighters[defender].name, defense_card.get("name", "без защиты"), d.value, damage])
	if attack_cancelled: _log("Эффекты атаки отменены.")
	if defense_cancelled: _log("Эффекты защиты отменены.")
	var modifiers: Array = _flow.effect_logs.duplicate()
	var damage_target = attacker if reflected > 0 else defender
	if reflected<=0 and _valid_fighter(int(d.get("hb_redirect",-1))):damage_target=int(d.hb_redirect);_log("Боевой урон перенаправлен Кощею.")
	_combat_resolution.hb_hp=fighters.map(func(f):return int(f.hp))
	_combat_resolution.hb_adjacent={}
	for f in fighters:
		if f.hero and _is_hero(int(f.owner),"abe_sapien"):_combat_resolution.hb_adjacent[str(int(f.id))]=fighters.filter(func(other):return fighters_adjacent(int(f.id),int(other.id))).map(func(other):return int(other.id))
	var incoming = reflected if reflected > 0 else damage
	if _v38.roost(damage_target,incoming):return
	if _v9.combat_damage(damage_target,incoming): return
	_damage(damage_target,incoming,true)
	_finish_combat_damage()

func _finish_combat_damage() -> void:
	_v35.after_combat_damage()
	if _check_winner():
		changed.emit()
		return
	var ctx: Dictionary = _combat_resolution.ctx
	var a: Dictionary = _combat_resolution.a
	var d: Dictionary = _combat_resolution.d
	var attacker = int(ctx.attacker)
	var defender = int(ctx.target)
	var ao = int(ctx.attack_owner)
	var do = int(ctx.defender_owner)
	var attack_card: Dictionary = a.card
	var defense_card: Dictionary = d.card
	var attack_cancelled = bool(a.cancelled)
	var defense_cancelled = bool(d.cancelled)
	var damage = int(d.damage_taken)
	var modifiers: Array = _flow.effect_logs.duplicate()
	last_combat = {"kind": "combat", "stage": "combat", "defense_card_owner":do, "attacker": attacker, "target": defender, "attack_card": attack_card, "defense_card": defense_card, "attack_value": a.value, "defense_value": d.value, "damage": damage, "outcome": "Атакующий выиграл бой" if damage > 0 else "Защитник выиграл бой", "attack_cancelled": attack_cancelled, "defense_cancelled": defense_cancelled, "effect_logs": [], "modifier_logs": modifiers}
	combat_report = last_combat.duplicate(true)
	var boost_cards = _flow.get("boosts",[]).duplicate(true)
	_flow = {"boosts":boost_cards,"kind": "combat", "stage": "report" if interactive else "effects", "attack_owner": ao, "defender_owner": do, "attack_card": attack_card, "defense_card": defense_card, "effect_logs": []}
	if bool(a.get("return_card",false)): _flow.return_a=true
	if bool(d.get("return_card",false)): _flow.return_d=true
	_effect_queue.clear()
	# Queue in the tabletop order. Pausing never lets an attacker effect overtake
	# a defender effect, including when the human is choosing a destination.
	if (not defense_cancelled or _is_hero(do,"mikula")) and not d.get("no_after",false): _queue_card_effects(defense_card, "after", d)
	if (not attack_cancelled or _is_hero(ao,"mikula")) and not a.get("no_after",false): _queue_card_effects(attack_card, "after", a)
	_v38.after_queue(a)
	_v10.queue_gadget(a,"after")
	if ao==active and a.won and _is_hero(ao,"wyatt_earp"):_effect_queue.append({"effect":{"kind":"v34_showdown","intrinsic":true},"ctx":a.duplicate(true)})
	if _is_hero(ao,"rosie_the_riveter")and fighters[attacker].hero:_effect_queue.append({"effect":{"kind":"v34_rosie_draw","intrinsic":true},"ctx":a.duplicate(true)})
	if _is_hero(ao,"michelangelo") and ao==active:_effect_queue.append({"effect":{"kind":"draw","amount":1,"intrinsic":true},"ctx":a.duplicate(true)})
	if _is_hero(ao,"chupacabra"):_effect_queue.append({"effect":{"kind":"v32_hunger"},"ctx":a.duplicate(true)})
	if _is_hero(ao,"deadpool"):_effect_queue.append({"effect":{"kind":"heal","target":"hero","amount":1},"ctx":a.duplicate(true)})
	if _is_hero(ao,"robin_hood"):
		var robin_context = a.duplicate(true)
		robin_context.card = {"name":"Способность Робина Гуда"}
		_effect_queue.append({"effect":{"kind":"move","target":"self","spaces":2},"ctx":robin_context})
	if _v9.enraged(ao) and fighters[attacker].hero and bool(a.won): _effect_queue.append({"effect":{"kind":"draw","amount":1},"ctx":a.duplicate(true)})
	if _v9.enraged(do) and fighters[defender].hero and bool(d.won): _effect_queue.append({"effect":{"kind":"draw","amount":1},"ctx":d.duplicate(true)})
	if _is_hero(ao,"angel") and not bool(a.won): _effect_queue.append({"effect":{"kind":"draw","amount":1},"ctx":a.duplicate(true)})
	if _is_hero(ao,"muhammad_ali") and bool(a.won): _effect_queue.append({"effect":{"kind":"flip_stance"},"ctx":a.duplicate(true)})
	if interactive: phase = "combat_report"
	else: _pump_effects()

func _raptor_bonus(attacker: int, defender: int) -> int:
	if not _valid_fighter(defender): return 0
	var bonus := 0
	for f in fighters:
		if _valid_fighter(int(f.id)) and f.hero and int(f.owner) == int(fighters[attacker].owner) and int(f.id) != attacker and fighters_adjacent(int(f.id),defender): bonus += 1
	return bonus

func scheme(fighter_id: int, card_index: int, target_id: int = -1) -> bool:
	if actions_left<=0 or not _can_act() or not _valid_fighter(fighter_id, active): return false
	if card_index < 0 or card_index >= players[active].hand.size(): return false
	var card: Dictionary = players[active].hand[card_index]
	if str(card.get("type", "")) != "scheme" or not _card_usable(card, fighter_id): return false
	if not _v31.mission_allowed(active,card):return false
	_v34.clear_free(active)
	var target := target_id if _valid_fighter(target_id) else _public_target(fighter_id)
	var ctx := {"owner": active, "self": fighter_id, "opponent": target, "opponent_owner": int(fighters[target].owner) if target >= 0 else -1, "card": card, "value": 0, "won": false, "prevent": false, "cancelled": false}
	players[active].hand.remove_at(card_index)
	players[active].scheme_turn=turn_number
	actions_left -= 1
	players[active].actions_taken = int(players[active].get("actions_taken", 0)) + 1
	_log("%s: %s." % [_player_name(active), card.get("name", "Приём")])
	_v14.begin_scheme(active,card)
	_flow = {"kind": "scheme", "stage": "effects", "owner": active, "fighter":fighter_id, "opponent_owner":int(ctx.opponent_owner), "card": card, "effect_logs": []}
	_effect_queue.clear()
	_v33.played(active,card)
	_queue_card_effects(card, "scheme", ctx)
	if _is_hero(active,"michelangelo"):_effect_queue.append({"effect":{"kind":"draw","amount":1,"intrinsic":true},"ctx":ctx.duplicate(true)})
	combat_report = {"kind": "scheme", "stage": "effects", "title": str(card.get("name", "Приём")), "card": card, "effect_logs": []}
	_pump_effects()
	changed.emit()
	return true

func continue_combat() -> bool:
	if phase != "combat_report" or _flow.is_empty(): return false
	if str(_flow.stage) == "finish":
		_complete_flow()
	else:
		_flow.stage = "effects"
		_pump_effects()
	changed.emit()
	return true

func _queue_card_effects(card: Dictionary, timing: String, ctx: Dictionary) -> void:
	for effect in card.get("effects", []):
		if str(effect.get("timing", "")) != timing: continue
		if bool(effect.get("if_win", false)) and not bool(ctx.won): continue
		_effect_queue.append({"effect": effect.duplicate(true), "ctx": ctx.duplicate(true)})

func _pump_effects() -> void:
	if winner >= 0:
		phase = "game_over"
		return
	pending_choice.clear()
	phase = "effects"
	while not _effect_queue.is_empty():
		var job: Dictionary = _effect_queue.pop_front()
		var effect: Dictionary = job.effect
		var ctx: Dictionary = job.ctx
		if str(_flow.get("kind", "")) == "combat_pre" and ctx.has("_combat_slot"):
			ctx = _combat_resolution[str(ctx._combat_slot)]
			if bool(ctx.get("cancelled", false)) and not bool(effect.get("intrinsic",false)): continue
		if not _v6.condition(effect,ctx) or not _v7.condition(effect,ctx) or not _v8.condition(effect,ctx) or not _v9.condition(effect,ctx): continue
		if _v8.guard_effect(effect,ctx):
			if phase == "effect_choice": changed.emit(); return
			continue
		var owner := int(ctx.owner)
		_v35.actor=owner
		if str(effect.get("kind",""))=="opponent_discard" and int(ctx.get("opponent_owner",-1))>=0 and _v35.shielded(int(ctx.opponent_owner),owner):continue
		var chooser := int(ctx.get("opponent_owner", -1)) if str(effect.get("kind", "")) == "opponent_discard" else owner
		if str(effect.get("kind","")) == "steal_from_the_rich" and int(ctx.get("opponent_owner",-1)) == 0: chooser = 0
		if interactive and chooser >= 0 and not players[chooser].bot:
			if _begin_manual_effect(effect, ctx):
				changed.emit()
				return
		if effect.get("fixed_opponent",false):
			effect=effect.duplicate(true);effect.fixed_fighter=int(ctx.opponent);effect.adjacent_to=int(ctx.self)
		var single: Dictionary = effect.duplicate(true)
		single.timing = "queued"
		_run_effects({"effects": [single]}, "queued", ctx)
		_v35.refresh_forms()
		if _check_winner():
			changed.emit()
			return
		if str(effect.get("kind","")) == "v9_bonus" and bool(ctx.get("bonus_started",false)): return
		if phase in ["effect_choice", "effect_move", "attack_notice", "defend", "combat_report"]:
			changed.emit()
			return
	if str(_flow.get("kind", "")) == "combat_pre":
		_finish_combat_values()
		return
	if _v17.after_scheme():
		_pump_effects();return
	if interactive:
		_flow.stage = "finish"
		combat_report.stage = "effects"
		combat_report.effect_logs = _flow.effect_logs.duplicate()
		last_combat = combat_report.duplicate(true) if str(_flow.kind) == "combat" else last_combat
		phase = "combat_report"
	else:
		_complete_flow()

func _complete_flow() -> void:
	if _flow.is_empty(): return
	if _v32.before_collect():_pump_effects();return
	if _v22.before_collect():_pump_effects();return
	var completion := str(_flow.get("completion", "action"))
	if str(_flow.kind) == "combat" and not _flow.get("cards_collected",false):
		_flow.cards_collected=true
		_v13.collect_combat()
		_v14.combat_complete()
		if not _effect_queue.is_empty():
			_pump_effects()
			return
	elif str(_flow.kind) == "scheme":
		if bool(_flow.get("return_card", false)): players[int(_flow.owner)].hand.append(_flow.card)
		elif _v33.collect(int(_flow.owner),_flow.card):pass
		elif _v32.collect(int(_flow.owner),_flow.card,int(_flow.get("trick_receiver",_flow.get("opponent_owner",-1)))):pass
		elif _v38.collect(int(_flow.owner),_flow.card):pass
		elif not _v14.collect_scheme(int(_flow.owner),_flow.card): _discard(int(_flow.owner), _flow.card,"played")
		_v13.scheme_complete(int(_flow.owner))
	var free_scheme=_flow.get("deck_scheme",{});var free_fighter=int(_flow.get("fighter",-1))
	pending_combat.clear()
	pending_choice.clear()
	_effect_queue.clear()
	_flow.clear()
	_combat_resolution.clear()
	_v35.actor=-1
	phase = "action"
	if not free_scheme.is_empty() and _valid_fighter(free_fighter,active):
		players[active].hand.append(free_scheme);actions_left+=1
		scheme(free_fighter,players[active].hand.size()-1);return
	if _v9.resume_parent(): return
	if completion == "maneuver":
		phase = "move"
		if _check_winner(): return
		return
	if completion == "v34_maneuver":phase="move";return
	if completion == "v33_maneuver":phase="move";return
	if completion == "v32_discard":
		phase="discard"
		if players[active].hand.size()<=_v33.limit(active):end_turn()
		return
	if completion == "end_turn":
		end_turn()
		return
	_after_action()

func _human_move_fighters(effect: Dictionary, ctx: Dictionary) -> Array:
	if effect.has("fixed_fighter"):
		var fixed=int(effect.fixed_fighter)
		return [fixed] if _valid_fighter(fixed) else []
	var ids: Array = []
	var target := str(effect.get("target", "self"))
	var owner := int(ctx.owner)
	match target:
		"self": ids = [int(ctx.self)]
		"opposing_combatant", "opponent": ids = [int(ctx.opponent)]
		"hero": ids = [hero_fighter(owner)]
		"either_combatant": ids = [int(ctx.self), int(ctx.opponent)]
		"both_combatants": ids = [int(ctx.self),int(ctx.opponent)]
		"all_enemies":
			for f in fighters:
				if _valid_fighter(int(f.id)) and is_enemy(owner,int(f.owner)): ids.append(int(f.id))
		"all_friendly", "all_sidekicks", "all_fighters":
			for f in fighters:
				if target != "all_fighters" and int(f.owner) != owner: continue
				if target == "all_sidekicks" and f.hero: continue
				ids.append(int(f.id))
	var living: Array = []
	for id in ids:
		if _valid_fighter(int(id)) and not living.has(int(id)): living.append(int(id))
	return living

func _begin_manual_effect(effect: Dictionary, ctx: Dictionary) -> bool:
	var kind := str(effect.get("kind", ""))
	if effect.get("fixed_opponent",false):
		effect=effect.duplicate(true);effect.fixed_fighter=int(ctx.opponent);effect.adjacent_to=int(ctx.self)
	if bool(effect.get("adjacent_to_opponent",false)):
		effect = effect.duplicate(true)
		effect.adjacent_to = int(ctx.opponent)
	var title := str(ctx.card.get("name", "Эффект карты"))
	var owner := int(ctx.owner)
	if kind == "reveal_hand":
		return _reveal_hand(owner, int(ctx.get("opponent_owner", -1)), ctx)
	if kind == "optional_draw":
		pending_choice = {"kind": "options", "title": title, "prompt": "В зоне нет врагов. Взять карту?", "legal": [], "fighter": -1, "allowed_fighters": [], "options": ["Взять 1 карту", "Пропустить"], "remaining_count": 1, "can_skip": true, "_options": [{"kind": "draw", "amount": int(effect.get("amount", 1))}, {"kind": "none"}], "_ctx": ctx}
		phase = "effect_choice"
		return true
	if kind in ["optional_boost", "retrieve_tag"]:
		var cards: Array = []
		var indices: Array = []
		var source := "hand" if kind == "optional_boost" else "discard"
		for i in range(players[owner][source].size()):
			var card: Dictionary = players[owner][source][i]
			if (kind == "optional_boost" and can_boost_card(card)) or (kind == "retrieve_tag" and _has_tag(card, str(effect.get("tag", "jeet_kune_do")))):
				cards.append(card.duplicate(true))
				indices.append(i)
		if cards.is_empty(): return false
		pending_choice = {"kind": "cards", "action": "combat_boost" if kind == "optional_boost" else "retrieve_tag", "title": title, "prompt": "Выберите карту усиления или пропустите" if kind == "optional_boost" else "Выберите карту Jeet Kune Do из сброса", "legal": [], "fighter": -1, "allowed_fighters": [], "cards": cards, "indices": indices, "remaining_count": 1, "can_skip": kind == "optional_boost", "_ctx": ctx}
		_refresh_card_options()
		phase = "effect_choice"
		return true
	if kind in ["bring_it_on", "coordinated_attack_pattern", "one_inch_punch"]:
		var target := "enemy_in_hero_zone" if kind == "bring_it_on" else "any_adjacent_to_self"
		var ids: Array = _living_heroes(owner) if kind == "coordinated_attack_pattern" else _damage_candidates({"target": target}, ctx)
		if ids.is_empty(): return false
		var labels: Array = []
		for id in ids: labels.append("%s · %d ОЗ" % [fighters[int(id)].name, int(fighters[int(id)].hp)])
		pending_choice = {"kind": "fighters", "action": kind, "title": title, "prompt": "Выберите бойца для эффекта карты", "legal": [], "fighter": -1, "allowed_fighters": ids, "options": labels, "can_skip": bool(effect.get("optional", false)), "_effect": effect, "_ctx": ctx}
		phase = "effect_choice"
		return true
	if kind == "swap_combatants":
		if not _valid_fighter(int(ctx.self)) or not _valid_fighter(int(ctx.opponent)): return false
		pending_choice = {"kind": "options", "title": title, "prompt": "Поменять Брюса Ли местами с противником?", "legal": [], "fighter": -1, "allowed_fighters": [], "options": ["Поменяться местами", "Остаться"], "remaining_count": 1, "can_skip": true, "_options": [{"kind": "execute_swap"}, {"kind": "none"}], "_ctx": ctx}
		phase = "effect_choice"
		return true
	if kind == "call_for_backup":
		return _begin_manual_effect({"kind": "choose_two", "options": [{"kind": "place_traps", "amount": 3, "anywhere": true}, {"kind": "revive_all"}, {"kind": "draw", "amount": 2}]}, ctx)
	if kind == "revive_all":
		var count := 0
		for f in fighters:
			if int(f.owner) == owner and not f.hero and not f.alive: count += 1
		for i in range(count): _effect_queue.push_front({"effect": {"kind": "revive_sidekick", "optional": false}, "ctx": ctx.duplicate(true)})
		if count == 0: _log("Все работники уже на поле; возвращать некого.")
		_pump_effects()
		return true
	if kind in ["place_traps", "remote_detonation"]:
		var anywhere = bool(effect.get("anywhere",false))
		var legal: Array = legal_trap_nodes(owner,anywhere) if kind == "place_traps" else _detonation_nodes(owner)
		if legal.is_empty():
			_log("Нет свободных клеток или жетонов для ловушек." if kind == "place_traps" else "Нет ловушки в зоне живого работника InGen.")
			return false
		var prompt = "Выберите любую свободную клетку без бойцов и жетонов" if anywhere else "Выберите свободную клетку в зоне Малдуна"
		pending_choice = {"kind": "spaces", "action": kind, "title": title, "prompt": prompt if kind == "place_traps" else "Выберите ловушку в зоне своего работника", "legal": legal, "fighter": int(ctx.self), "allowed_fighters": [], "can_skip": kind == "place_traps", "remaining_count": mini(int(effect.get("amount", 1)), trap_supply(owner)) if kind == "place_traps" else 1, "_effect": effect, "_ctx": ctx}
		if kind == "place_traps": pending_choice.prompt += "\n" + "Можно разместить ещё: %d. Жетонов в запасе: %d." % [int(pending_choice.remaining_count),trap_supply(owner)]
		phase = "effect_move"
		return true
	if kind == "decoy":
		var ids := _living_heroes(owner)
		ids.erase(int(ctx.self))
		if ids.is_empty() or not _valid_fighter(int(ctx.opponent)): return false
		pending_choice = {"kind": "decoy", "title": title, "prompt": "Выберите другого раптора и место рядом с атакующим", "legal": [], "fighter": -1, "allowed_fighters": ids, "remaining": ids.duplicate(), "can_skip": true, "mode": "one", "_effect": {"adjacent_to": int(ctx.opponent)}, "_ctx": ctx}
		phase = "effect_move"
		if ids.size() == 1: _select_effect_fighter(int(ids[0]))
		return true
	if kind == "steal_from_the_rich":
		_draw(int(ctx.owner),1)
		var enemies: Array = []
		var labels: Array = []
		for i in range(players.size()):
			if not is_dormant(i) and is_enemy(int(ctx.owner),i):
				enemies.append(i)
				labels.append(str(players[i].name))
		if int(ctx.owner) == 0 and enemies.size() > 1:
			pending_choice = {"kind":"players","action":"steal_target","title":title,"prompt":"Выберите противника","options":labels,"players":enemies,"_ctx":ctx,"legal":[],"allowed_fighters":[],"can_skip":false}
			phase = "effect_choice"
			return true
		var victim = int(ctx.opponent_owner) if int(ctx.opponent_owner) >= 0 else int(enemies[0]) if not enemies.is_empty() else -1
		if not _steal_response(ctx,victim): _pump_effects()
		return true
	if kind == "restless_spirits":
		var fid := int(ctx.self)
		if not _valid_fighter(fid): return false
		var legal: Array = []
		for node in nodes:
			if _same_zone(int(fighters[fid].node), int(node.id)): legal.append(int(node.id))
		pending_choice = {"kind": "spaces", "title": title, "prompt": "Выберите первую клетку в зоне Мерлина", "legal": legal, "fighter": fid, "allowed_fighters": [], "selected_spaces": [], "stage": "first", "can_skip": bool(effect.get("optional", false)), "_effect": effect, "_ctx": ctx}
		phase = "effect_move"
		return true
	if kind == "top_four_choose_two":
		var top: Array = []
		for n in range(mini(4, players[owner].deck.size())): top.append(players[owner].deck.pop_back())
		if top.is_empty():
			_log("Пророчество: в колоде нет карт.")
			return false
		pending_choice = {"kind": "cards", "action": "prophecy", "title": title, "prompt": "Выберите карты, которые возьмёте в руку", "legal": [], "fighter": -1, "allowed_fighters": [], "cards": top, "stage": "take", "remaining_count": mini(2, top.size()), "can_skip": false, "ordered": [], "_ctx": ctx}
		_refresh_card_options()
		phase = "effect_choice"
		return true
	if kind == "damage" and str(effect.get("target", "opposing_combatant")) in ["any_adjacent_to_self", "any_in_hero_zone", "enemy_in_hero_zone", "opponent_adjacent_to_self", "enemy_any"]:
		var ids := _damage_candidates(effect, ctx)
		if ids.is_empty(): return false
		var options: Array = []
		for id in ids: options.append("%s · %d ОЗ" % [fighters[int(id)].name, int(fighters[int(id)].hp)])
		pending_choice = {"kind": "fighters", "action": "damage", "title": title, "prompt": "Выберите бойца: нанести %d урона" % int(effect.get("amount", 0)), "options": options, "legal": [], "fighter": -1, "allowed_fighters": ids, "can_skip": bool(effect.get("optional", false)), "_effect": effect, "_ctx": ctx}
		phase = "effect_choice"
		return true
	if kind in ["opponent_discard", "reveal_choose_discard"]:
		var victim := int(ctx.opponent_owner)
		if _v14.owl_protected(victim): return _reveal_hand(owner,victim,ctx) if kind=="reveal_choose_discard" else false
		if not is_enemy(int(ctx.owner), victim) or is_dormant(victim) or players[victim].hand.is_empty(): return false
		var viewer := victim if kind == "opponent_discard" else owner
		var discard_count = int(effect.get("win_amount",effect.get("amount",1))) if bool(ctx.get("won",false)) else int(effect.get("amount",1))
		if _is_hero(victim,"liz_sherman")and discard_count>1:
			_v35.batch_discard(ctx,victim,mini(discard_count,players[victim].hand.size()),viewer);return true
		pending_choice = {"kind": "cards", "action": "discard", "title": title, "prompt": "Выберите карту для сброса" if kind == "opponent_discard" else "Посмотрите руку соперника и выберите карту для сброса", "legal": [], "fighter": -1, "allowed_fighters": [], "cards": players[victim].hand.duplicate(true), "remaining_count": mini(discard_count,players[victim].hand.size()), "can_skip": false, "owner": viewer, "viewer": viewer, "victim": victim, "_ctx": ctx}
		_refresh_card_options()
		phase = "effect_choice"
		return true
	if kind == "choose_two":
		if not _valid_fighter(hero_fighter(int(ctx.owner))): return false
		var options: Array = effect.get("options", []).duplicate(true)
		var labels: Array = []
		for option in options:
			match str(option.get("kind", "")):
				"draw": labels.append("Взять %d карты" % int(option.get("amount", 2)))
				"heal": labels.append("Вылечить %d здоровья" % int(option.get("amount", 3)))
				"place": labels.append("Перенести Алису на другую клетку")
				"place_traps": labels.append("Установить до 3 ловушек")
				"revive_all": labels.append("Вернуть всех поверженных работников")
				_: labels.append(str(option.get("kind", "Эффект")))
		pending_choice = {"kind": "options", "title": title, "prompt": "Выберите %d разных эффекта" % int(effect.get("remaining_count", 2)), "legal": [], "fighter": -1, "allowed_fighters": [], "options": labels, "remaining_count": int(effect.get("remaining_count", 2)), "selection_total": int(effect.get("remaining_count",2)), "selected_effects": [], "can_skip": false, "_options": options, "_ctx": ctx}
		phase = "effect_choice"
		return true
	if kind not in ["move", "place", "revive_sidekick"]: return false
	var ids: Array = []
	if kind == "revive_sidekick":
		var hero := hero_fighter(int(ctx.owner))
		if not _valid_fighter(hero): return false
		for f in fighters:
			if int(f.owner) == int(ctx.owner) and not f.hero and not f.alive:
				ids = [int(f.id)]
				break
	elif kind == "place":
		var id := int(effect.get("fixed_fighter", hero_fighter(int(ctx.owner)) if str(effect.get("target", "self")) == "hero" else int(ctx.self)))
		if _valid_fighter(id): ids = [id]
	else: ids = _human_move_fighters(effect, ctx)
	if ids.is_empty(): return false
	pending_choice = {"kind": kind, "title": title, "prompt": "Выберите бойца и клетку для перемещения" if kind == "move" else "Выберите свободную клетку", "legal": [], "fighter": -1, "allowed_fighters": ids, "remaining": ids.duplicate(), "spaces": int(effect.get("spaces", 0)), "can_skip": kind == "move" or bool(effect.get("optional", false)), "mode": "one" if str(effect.get("target", "")) == "either_combatant" or kind != "move" else "all", "_effect": effect, "_ctx": ctx}
	phase = "effect_move"
	if ids.size() == 1:
		_select_effect_fighter(int(ids[0]))
		if pending_choice.legal.is_empty():
			_log("Эффект перемещения: подходящих свободных клеток нет.")
			pending_choice.clear()
			phase = "effects"
			return false
	return true

func _select_effect_fighter(fighter_id: int) -> void:
	pending_choice.fighter = fighter_id
	var effect: Dictionary = pending_choice._effect
	var legal: Array = []
	var kind := str(pending_choice.kind)
	if kind == "move": legal = _effect_reachable(fighter_id, int(effect.get("spaces", 0)), bool(effect.get("through_enemies", false)),bool(effect.get("through_sidekicks",false)))
	else:
		for node in nodes:
			if int(fighters[fighter_id].get("locked_until",-1)) == turn_number and int(fighters[fighter_id].node) != int(node.id): continue
			var occupant := _occupant(int(node.id))
			if not _v31.can_end(fighter_id,int(node.id)) or (kind=="place" and occupant==fighter_id and bool(effect.get("other_space",false))): continue
			if _v19.large(fighter_id) and _v19.orientations(fighter_id,int(node.id)).is_empty():continue
			if effect.has("adjacent_to") and (not _valid_fighter(int(effect.adjacent_to)) or not nodes[int(fighters[int(effect.adjacent_to)].node)].neighbors.has(int(node.id))): continue
			if effect.has("zone_anchor") and (not _valid_fighter(int(effect.zone_anchor)) or not _same_zone(int(fighters[int(effect.zone_anchor)].node), int(node.id))): continue
			if kind == "revive_sidekick":
				var hero := hero_fighter(int(pending_choice._ctx.owner))
				if not _same_zone(int(fighters[hero].node), int(node.id)): continue
			if bool(effect.get("same_zone",false)) and not _same_zone(int(fighters[fighter_id].node),int(node.id)): continue
			if bool(effect.get("other_space", false)) and int(fighters[fighter_id].node) == int(node.id): continue
			legal.append(int(node.id))
	pending_choice.legal = legal
	pending_choice.prompt = "%s: %s" % [fighters[fighter_id].name, "до %d клеток; можно остаться" % int(effect.get("spaces", 0)) if kind == "move" else "выберите свободную клетку"]

func choose_effect_fighter(fighter_id: int) -> bool:
	if phase=="effect_choice" and str(pending_choice.get("action","")).begins_with("v18_"):
		return _v18.choose_option(pending_choice.get("ids",[]).map(func(id):return int(id)).find(fighter_id))
	if phase=="effect_choice" and str(pending_choice.get("action","")).begins_with("v15_"):
		return _v15.choose_option(pending_choice.get("ids",[]).map(func(id):return int(id)).find(fighter_id))
	if phase == "effect_choice" and str(pending_choice.get("kind", "")) == "fighters":
		if not pending_choice.allowed_fighters.has(fighter_id): return false
		var ctx: Dictionary = pending_choice._ctx
		var action := str(pending_choice.get("action", "damage"))
		if action == "bring_it_on":
			var effect := {"kind": "place", "fixed_fighter": fighter_id, "adjacent_to": hero_fighter(int(ctx.owner))}
			pending_choice.clear()
			if _begin_manual_effect(effect, ctx):
				changed.emit()
				return true
		elif action == "coordinated_attack_pattern":
			for id in _living_heroes(int(ctx.owner)):
				if int(id) != fighter_id: _effect_queue.push_front({"effect": {"kind": "place", "fixed_fighter": int(id), "zone_anchor": fighter_id, "optional": true}, "ctx": ctx.duplicate(true)})
		else:
			_resolve_chosen_damage(fighter_id, pending_choice._effect, ctx)
		pending_choice.clear()
		_pump_effects()
		changed.emit()
		return true
	if phase != "effect_move" or not pending_choice.get("allowed_fighters", []).has(fighter_id): return false
	_select_effect_fighter(fighter_id)
	changed.emit()
	return true

func choose_effect_node(node: int) -> bool:
	if str(pending_choice.get("action",""))=="v29_bag":return _v29.choose_option(pending_choice.nodes.map(func(v):return int(v)).find(node))
	if phase=="effect_choice" and str(pending_choice.get("action","")).begins_with("v18_"):return _v18.choose_node(node)
	if phase == "effect_move" and str(pending_choice.get("action", "")).begins_with("v9_"): return _v9.choose_node(node)
	if phase != "effect_move" or not pending_choice.get("legal", []).has(node): return false
	if str(pending_choice.get("action", "")).begins_with("v7_"): return _v7.choose_node(node)
	if str(pending_choice.get("action","")).begins_with("v6_"): return _v6.choose_node(node)
	if str(pending_choice.get("kind", "")) == "spaces":
		var action := str(pending_choice.get("action", "restless_spirits"))
		if action == "place_traps":
			var owner := int(pending_choice._ctx.owner)
			var anywhere = bool(pending_choice._effect.get("anywhere",false))
			if not _place_trap(owner,node,anywhere): return false
			pending_choice.remaining_count = int(pending_choice.remaining_count) - 1
			pending_choice.legal = legal_trap_nodes(owner,anywhere)
			if int(pending_choice.remaining_count) > 0 and not pending_choice.legal.is_empty():
				pending_choice.prompt = ("Выберите любую свободную клетку без бойцов и жетонов" if anywhere else "Выберите свободную клетку в зоне Малдуна") + "\n" + "Можно разместить ещё: %d. Жетонов в запасе: %d." % [int(pending_choice.remaining_count),trap_supply(owner)]
				changed.emit()
				return true
			pending_choice.clear()
			_pump_effects()
			changed.emit()
			return true
		if action == "remote_detonation":
			_detonate_trap(int(pending_choice._ctx.owner), node)
			pending_choice.clear()
			_pump_effects()
			changed.emit()
			return true
		pending_choice.selected_spaces.append(node)
		if str(pending_choice.stage) == "first":
			pending_choice.stage = "second"
			pending_choice.legal = nodes[node].neighbors.duplicate()
			pending_choice.prompt = "Выберите вторую клетку: рядом с клеткой %d" % (node + 1)
			changed.emit()
			return true
		_resolve_spirit_spaces(int(pending_choice._ctx.owner), pending_choice.selected_spaces)
		pending_choice.clear()
		_pump_effects()
		changed.emit()
		return true
	var fid := int(pending_choice.fighter)
	if fid < 0: return false
	var old := int(fighters[fid].node)
	if _v19.offer(fid,node,"effect",int(pending_choice.get("_effect",{}).get("spaces",0)),bool(pending_choice.get("_effect",{}).get("through_enemies",false))):return true
	if str(pending_choice.kind) == "revive_sidekick":
		fighters[fid].alive = true
		fighters[fid].hp = int(fighters[fid].max_hp)
	_enter_node(fid, node)
	_v19.moved(fid,old,str(pending_choice.kind)!="move")
	_log("Эффект «%s»: %s %s." % [pending_choice.title, fighters[fid].name, "остаётся на месте" if old == node else "переходит с %d на %d" % [old + 1, node + 1]])
	if str(pending_choice.kind)=="move" and _v12.stepwise(fid) and old != node and _valid_fighter(fid):
		pending_choice._effect.spaces=int(pending_choice._effect.spaces)-1
		pending_choice.spaces=int(pending_choice._effect.spaces)
		if pending_choice.spaces>0 and _enemy_trap_at(node,int(fighters[fid].owner))<0:
			_select_effect_fighter(fid);changed.emit();return true
	if str(pending_choice.mode) == "all":
		pending_choice.remaining.erase(fid)
		pending_choice.allowed_fighters = pending_choice.remaining.duplicate()
		if not pending_choice.remaining.is_empty():
			pending_choice.fighter = -1
			pending_choice.legal = []
			pending_choice.prompt = "Выберите следующего бойца или завершите перемещение"
			if pending_choice.remaining.size() == 1: _select_effect_fighter(int(pending_choice.remaining[0]))
			changed.emit()
			return true
	pending_choice.clear()
	_pump_effects()
	changed.emit()
	return true

func skip_effect() -> bool:
	if str(pending_choice.get("action", "")).begins_with("v38_"):return _v38.skip()
	if str(pending_choice.get("action", "")).begins_with("v36_"):return _v36.skip()
	if str(pending_choice.get("action", "")).begins_with("v35_"):return _v35.skip()
	if str(pending_choice.get("action", "")).begins_with("v34_"):return _v34.skip()
	if str(pending_choice.get("action", "")).begins_with("v33_"):return _v33.skip()
	if str(pending_choice.get("action", "")).begins_with("v32_"):return _v32.skip()
	if str(pending_choice.get("action", "")).begins_with("v31_"):return _v31.skip()
	if str(pending_choice.get("action", "")).begins_with("v29_"):return _v29.skip()
	if str(pending_choice.get("action", "")).begins_with("v24_"):return _v24.skip()
	if str(pending_choice.get("action", "")).begins_with("v22_"):return _v22.skip()
	if str(pending_choice.get("action", "")).begins_with("v21_"):return _v21.skip()
	if str(pending_choice.get("action", "")).begins_with("v19_"):return _v19.skip()
	if str(pending_choice.get("action", "")).begins_with("v18_"): return _v18.skip()
	if str(pending_choice.get("action", "")).begins_with("v17_"): return _v17.skip()
	if str(pending_choice.get("action", "")).begins_with("v16_"): return _v16.skip()
	if str(pending_choice.get("action", "")).begins_with("v15_"): return _v15.skip()
	if str(pending_choice.get("action", "")).begins_with("v14_"): return _v14.skip()
	if str(pending_choice.get("action", "")).begins_with("v13_"): return _v13.skip()
	if str(pending_choice.get("action", "")).begins_with("v12_"): return _v12.skip()
	if str(pending_choice.get("action", "")).begins_with("v10_"): return _v10.skip()
	if str(pending_choice.get("action", "")).begins_with("v9_"): return _v9.skip()
	if phase not in ["effect_move", "effect_choice"] or not bool(pending_choice.get("can_skip", false)): return false
	_log("Эффект «%s» пропущен; оставшиеся обязательные эффекты продолжаются." % pending_choice.get("title", "Карта"))
	pending_choice.clear()
	_pump_effects()
	changed.emit()
	return true

func choose_effect_option(option_index: int) -> bool:
	if str(pending_choice.get("action", "")).begins_with("v38_"):return _v38.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v36_"):return _v36.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v35_"):return _v35.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v34_"):return _v34.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v33_"):return _v33.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v32_"):return _v32.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v31_"):return _v31.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v29_"):return _v29.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v26_"):return _v26.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v24_"):return _v24.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v22_"):return _v22.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v21_"):return _v21.choose_option(option_index)
	if str(pending_choice.get("action", "")).begins_with("v19_"):return _v19.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v18_"): return _v18.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v17_"): return _v17.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v16_"): return _v16.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v15_"): return _v15.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v14_"): return _v14.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v13_"): return _v13.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v12_"): return _v12.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v10_"): return _v10.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v9_"): return _v9.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v8_"): return _v8.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action", "")).begins_with("v7_"): return _v7.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("kind", "")) == "hand_view":
		if option_index != 0: return false
		pending_choice.clear()
		_pump_effects()
		changed.emit()
		return true
	if phase == "effect_choice" and str(pending_choice.get("action","")).begins_with("v6_"): return _v6.choose_option(option_index)
	if phase == "effect_choice" and str(pending_choice.get("action","")) == "steal_target":
		if option_index < 0 or option_index >= pending_choice.players.size(): return false
		var victim = int(pending_choice.players[option_index])
		var ctx: Dictionary = pending_choice._ctx.duplicate(true)
		pending_choice.clear()
		if not _steal_response(ctx,victim): _pump_effects()
		changed.emit()
		return true
	if phase == "effect_choice" and str(pending_choice.get("action","")) == "steal_response":
		if option_index not in [0,1]: return false
		var ctx: Dictionary = pending_choice._ctx.duplicate(true)
		var victim = int(pending_choice.victim)
		if option_index == 0 and not players[victim].hand.is_empty():
			pending_choice = {"kind":"cards","action":"discard","title":ctx.card.name,"prompt":"Выберите карту для сброса","cards":players[victim].hand.duplicate(true),"remaining_count":1,"victim":victim,"forced_hand":false,"_ctx":ctx,"legal":[],"allowed_fighters":[],"can_skip":false}
			_refresh_card_options()
		else:
			_draw(int(ctx.owner),1)
			_log("Противник не сбрасывает карту: Робин берёт ещё 1 карту.")
			pending_choice.clear()
			_pump_effects()
		changed.emit()
		return true
	if phase == "effect_choice" and str(pending_choice.get("kind", "")) == "fighters":
		if option_index < 0 or option_index >= pending_choice.allowed_fighters.size(): return false
		return choose_effect_fighter(int(pending_choice.allowed_fighters[option_index]))
	if phase == "effect_choice" and str(pending_choice.get("kind", "")) == "cards": return _choose_card_option(option_index)
	if phase != "effect_choice" or str(pending_choice.get("kind", "")) != "options": return false
	var options: Array = pending_choice._options.duplicate(true)
	if option_index < 0 or option_index >= options.size(): return false
	var ctx: Dictionary = pending_choice._ctx
	var selected: Dictionary = options.pop_at(option_index)
	var left := int(pending_choice.remaining_count) - 1
	_log("Эффект «%s»: %s." % [pending_choice.title, pending_choice.options[option_index]])
	var selections: Array = pending_choice.get("selected_effects",[]).duplicate(true)
	selections.append(selected)
	if left > 0:
		pending_choice._options = options
		pending_choice.options.remove_at(option_index)
		pending_choice.remaining_count = left
		pending_choice.selected_effects = selections
		pending_choice.prompt = "Выбрано эффектов: %d. Выберите ещё: %d." % [selections.size(),left]
		changed.emit()
		return true
	for index in range(selections.size()-1,-1,-1): _effect_queue.push_front({"effect":selections[index],"ctx":ctx.duplicate(true)})
	pending_choice.clear()
	_pump_effects()
	changed.emit()
	return true

func _steal_response(ctx: Dictionary, victim: int) -> bool:
	if not is_enemy(int(ctx.owner), victim) or is_dormant(victim):
		_log("Украсть у богатых: подходящего противника нет.")
		return false
	if interactive and not players[victim].bot and not players[victim].hand.is_empty():
		pending_choice = {"kind":"options","action":"steal_response","title":str(ctx.card.name),"prompt":"Сбросьте карту или позвольте Робину взять ещё одну","options":["Сбросить 1 карту","Не сбрасывать: Робин берёт карту"],"victim":victim,"_ctx":ctx,"legal":[],"allowed_fighters":[],"can_skip":false}
		phase = "effect_choice"
		return true
	var discard = not players[victim].hand.is_empty() and _card_quality(players[victim].hand[_lowest_card(victim)]) <= 3.0
	if discard:
		_force_discard(victim,1,false,false,false)
	else:
		_draw(int(ctx.owner),1)
		_log("Противник не сбрасывает карту: Робин берёт ещё 1 карту.")
	return false

func _refresh_card_options() -> void:
	var labels: Array = []
	for card in pending_choice.cards: labels.append("%s · %s %d · BOOST %s" % [card.get("name", "Карта"), card.get("type", ""), int(card.get("value", 0)), "⚄"if card.get("dice_boost",false)else str(int(card.get("boost", 0)))])
	pending_choice.options = labels

func _choose_card_option(option_index: int) -> bool:
	if option_index < 0 or option_index >= pending_choice.cards.size(): return false
	if str(pending_choice.get("action",""))=="combat_boost":
		var ctx=pending_choice._ctx
		var index=int(pending_choice.indices[option_index])
		if _v36.boost_offer(index,ctx,"combat_boost"):
			if pending_choice.is_empty():_pump_effects();changed.emit()
			return true
	var card: Dictionary = pending_choice.cards.pop_at(option_index)
	var action := str(pending_choice.action)
	if action in ["combat_boost", "retrieve_tag"]:
		var ctx: Dictionary = pending_choice._ctx
		var owner := int(ctx.owner)
		var index := int(pending_choice.indices[option_index])
		if action == "combat_boost":
			if not can_boost_card(card): return false
			_v8.combat_boost(ctx,index)
			_log("Усиление раскрытой атаки: %s (+%d)." % [card.name, int(card.boost)])
		else:
			players[owner].hand.append(players[owner].discard.pop_at(index))
			_log("В руку возвращена карта Jeet Kune Do: %s." % card.name)
		pending_choice.remaining_count = 0
	elif action == "discard":
		var victim := int(pending_choice.victim)
		if not _discard_from_opponent(victim,players[victim].hand.pop_at(option_index),bool(pending_choice.get("forced_hand",true))):
			pending_choice.remaining_count=0
			pending_choice.clear();_pump_effects();changed.emit();return true
		_log("%s сбрасывает: %s." % [_player_name(victim), card.name])
		pending_choice.remaining_count = int(pending_choice.remaining_count) - 1
	elif action == "prophecy":
		var owner := int(pending_choice._ctx.owner)
		if str(pending_choice.stage) == "take":
			players[owner].hand.append(card)
			pending_choice.remaining_count = int(pending_choice.remaining_count) - 1
			_log("Пророчество: в руку взята карта «%s»." % card.name)
			if int(pending_choice.remaining_count) <= 0 and not pending_choice.cards.is_empty():
				pending_choice.stage = "order"
				pending_choice.remaining_count = pending_choice.cards.size()
				pending_choice.prompt = "Выберите карту, которая будет верхней в колоде"
		else:
			pending_choice.ordered.append(card)
			pending_choice.remaining_count = int(pending_choice.remaining_count) - 1
		if str(pending_choice.stage) == "order" and pending_choice.cards.size() <= 1:
			pending_choice.ordered.append_array(pending_choice.cards)
			for i in range(pending_choice.ordered.size() - 1, -1, -1): players[owner].deck.append(pending_choice.ordered[i])
			pending_choice.cards.clear()
			pending_choice.remaining_count = 0
			_log("Пророчество: порядок оставшихся карт выбран.")
	if int(pending_choice.remaining_count) > 0 and not pending_choice.cards.is_empty():
		if action == "discard": pending_choice.cards = players[int(pending_choice.victim)].hand.duplicate(true)
		_refresh_card_options()
		changed.emit()
		return true
	pending_choice.clear()
	_pump_effects()
	changed.emit()
	return true

func _run_effects(card: Dictionary, timing: String, ctx: Dictionary) -> void:
	for effect in card.get("effects", []):
		if str(effect.get("timing", "")) != timing: continue
		if bool(effect.get("if_win", false)) and not bool(ctx.won): continue
		var owner := int(ctx.owner)
		var fid := int(ctx.self)
		var opponent := int(ctx.opponent)
		var enemy_owner := int(ctx.opponent_owner)
		var amount := int(effect.get("win_amount", effect.get("amount", 0))) if bool(ctx.won) else int(effect.get("amount", 0))
		var kind := str(effect.get("kind", ""))
		if not _v6.condition(effect,ctx): continue
		if not _v7.condition(effect,ctx) or not _v8.condition(effect,ctx) or not _v9.condition(effect,ctx): continue
		if _v6.run(effect,ctx): continue
		if _v7.run(effect,ctx): continue
		if _v8.run(effect,ctx): continue
		if _v9.run(effect,ctx): continue
		if _v10.run(effect,ctx): continue
		if _v12.run(effect,ctx): continue
		if _v13.run(effect,ctx): continue
		if _v14.run(effect,ctx): continue
		if _v15.run(effect,ctx): continue
		if _v16.run(effect,ctx): continue
		if _v17.run(effect,ctx): continue
		if _v18.run(effect,ctx): continue
		if _v19.run(effect,ctx): continue
		if _v21.extras(effect,ctx) or _v21.run(effect,ctx):continue
		if _v22.extras(effect,ctx) or _v22.run(effect,ctx):continue
		if _v24.run(effect,ctx):continue
		if _v26.run(effect,ctx) or _v26.extras(effect,ctx):continue
		if _v29.run(effect,ctx):continue
		if _v31.run(effect,ctx) or _v31.extras(effect,ctx):continue
		if _v32.run(effect,ctx):continue
		if _v33.run(effect,ctx) or _v33.extras(effect,ctx):continue
		if _v34.run(effect,ctx):continue
		if _v38.run(effect,ctx):continue
		if _v36.run(effect,ctx):continue
		if _v35.run(effect,ctx):continue
		match kind:
			"spirits_finish": _finish_spirits(owner,effect.alive_before)
			"cancel":
				if ctx.has("_combat_slot") and not _combat_resolution.is_empty():
					var other := "d" if str(ctx._combat_slot) == "a" else "a"
					if not _card_uncancellable(int(_combat_resolution[other].owner),_combat_resolution[other].card):
						_combat_resolution[other].cancelled = true
						_log("Эффекты карты соперника отменены: %s." % ctx.card.get("name", "Финт"))
					else: _log("Эффекты этой карты нельзя отменить.")
			"optional_draw":
				if not players[owner].deck.is_empty():
					_draw(owner, amount)
					_log("Способность героя: взята 1 карта.")
				else: _log("Взятие по способности пропущено: колода пуста.")
			"gain_action":
				if gain_actions(owner,amount):
					_log("Дополнительное действие: +%d. Осталось действий: %d." % [amount, actions_left])
			"gain_action_if_raptor_adjacent":
				if _raptors_adjacent(owner, opponent) > 0:
					if gain_actions(owner,amount): _log("Раптор рядом с целью: дополнительное действие +%d." % amount)
				else: _log("Возле противника нет своих рапторов: дополнительного действия нет.")
			"set_value_if_hand_empty":
				if players[owner].hand.is_empty(): ctx.value = int(effect.get("value", 6))
			"set_value_if_either_moved":
				if (fid < turn_start_nodes.size() and changed_start_space(fid)) or (opponent >= 0 and opponent < turn_start_nodes.size() and changed_start_space(opponent)): ctx.value = int(effect.get("value", 5))
			"set_value_if_first_action":
				if int(players[owner].get("actions_taken", 0)) == 1: ctx.value = int(effect.get("value", 5))
			"draw_if_health_at_most":
				var hero := hero_fighter(owner)
				if _valid_fighter(hero) and int(fighters[hero].hp) <= int(effect.get("health", 5)):
					_draw(owner, amount)
					_log("Здоровья мало: взято %d карт." % amount)
				else: _log("Условие здоровья не выполнено: карты не взяты.")
			"retrieve_tag": _retrieve_tag(owner, str(effect.get("tag", "jeet_kune_do")))
			"turn_attack_bonus":
				players[owner].turn_attack_bonus = int(players[owner].get("turn_attack_bonus", 0)) + amount
				_log("Нунчаки: все атаки Брюса Ли в этот ход получают ещё +%d." % amount)
			"swap_combatants", "execute_swap": _swap_combatants(fid, opponent)
			"bring_it_on": _auto_bring_it_on(ctx)
			"one_inch_punch":
				var target := _effect_damage_target({"target": "any_adjacent_to_self"}, ctx)
				if target >= 0: _resolve_chosen_damage(target, effect, ctx)
				else: _log("Однодюймовый удар: рядом нет бойцов.")
			"place_traps":
				for i in range(amount):
					var legal := legal_trap_nodes(owner,bool(effect.get("anywhere",false)))
					if legal.is_empty(): break
					_place_trap(owner,_best_trap_node(owner,legal),bool(effect.get("anywhere",false)))
				if trap_supply(owner) == 0: _log("Запас ловушек исчерпан.")
			"trap_adjacency_bonus":
				var count := 0
				if _valid_fighter(opponent):
					for trap in traps:
						if node_adjacent_to_fighter(int(trap.node),opponent): count += 1
				ctx.value += count * maxi(1, amount)
				_log("Ловушки рядом с целью: сила атаки +%d." % count)
			"call_for_backup":
				var defeated := false
				for f in fighters:
					if int(f.owner) == owner and not f.hero and not f.alive: defeated = true
				if defeated: _run_effects({"effects": [{"kind": "revive_all", "timing": "queued"}]}, "queued", ctx)
				else: _run_effects({"effects": [{"kind": "place_traps", "amount": 3, "anywhere": true, "timing": "queued"}]}, "queued", ctx)
				_draw(owner, 2)
				_log("Подкрепление: выбраны возвращение работников или ловушки, затем 2 карты.")
			"revive_all":
				var count := 0
				for f in fighters:
					if int(f.owner) == owner and not f.hero and not f.alive: count += 1
				for i in range(count): _revive(owner)
				if count == 0: _log("Все работники уже на поле.")
			"remote_detonation":
				var legal := _detonation_nodes(owner)
				if legal.is_empty(): _log("Нет ловушки в зоне своего работника: подрыв не выполнен.")
				else: _detonate_trap(owner, int(legal[0]))
			"coordinated_attack_pattern": _auto_coordinate_raptors(owner)
			"raptor_pack_damage":
				var count := _raptors_adjacent(owner, opponent)
				_damage(opponent, count)
				_log("Стая наносит противнику %d дополнительного урона." % count)
			"decoy": _auto_decoy(ctx)
			"ambush":
				if is_enemy(owner, enemy_owner) and not players[enemy_owner].hand.is_empty() and not _v14.owl_protected(enemy_owner):
					var random_index = rng.randi_range(0,players[enemy_owner].hand.size()-1)
					var discarded: Dictionary = players[enemy_owner].hand.pop_at(random_index)
					_discard(enemy_owner,discarded)
					_v8.opponent_discarded(enemy_owner,discarded)
					ctx.value += int(discarded.boost)
					_log("Засада: сброшена %s, сила +%d." % [discarded.name,int(discarded.boost)])
				else: _log("Засада: рука противника пуста, усиление +0.")
			"ignore_defense": ctx.ignore_defense = true
			"draw_combat_damage":
				var count = int(ctx.get("damage_dealt",0))
				_draw(owner,count)
				_log("Разоружающий выстрел: взято %d карт." % count)
			"draw_if_adjacent":
				if _valid_fighter(fid) and _valid_fighter(opponent) and fighters_adjacent(fid,opponent):
					_draw(owner,amount)
					_log("Насмешка: взята 1 карта.")
				else: _log("Насмешка: бойцы больше не соседствуют, карта не взята.")
			"adjacent_damage":
				var center = hero_fighter(owner) if str(effect.get("target","")) == "all" else fid
				if _valid_fighter(center):
					var affected: Array = []
					for f in fighters:
						if _valid_fighter(int(f.id)) and fighters_adjacent(center,int(f.id)) and (str(effect.get("target","")) == "all" or is_enemy(owner,int(f.owner))): affected.append(int(f.id))
					_damage_many(affected,amount)
					for id in affected:
						_log("Эффект: %s получает %d урона." % [fighters[id].name,amount])
					if affected.is_empty(): _log("Эффект урона рядом: подходящих бойцов нет.")
				else: _log("Поверженный боец не имеет соседних клеток: урон рядом не нанесён.")
			"steal_from_the_rich":
				_draw(owner,1)
				_steal_response(ctx,enemy_owner)
			"set_value_against_hero":
				if _valid_fighter(opponent) and fighters[opponent].hero: ctx.value = int(effect.get("value", 5))
			"set_value_if_moved":
				if _valid_fighter(fid) and fid < turn_start_nodes.size() and changed_start_space(fid): ctx.value = int(effect.get("value", 5))
			"top_deck_boost":
				if not players[owner].deck.is_empty():
					var top: Dictionary = players[owner].deck.pop_back()
					ctx.value += int(top.get("boost", 0))
					_discard(owner, top,"deck")
					_log("Сброшена верхняя карта: %s (+%d)." % [top.name, int(top.get("boost", 0))])
			"optional_boost":
				# Optional effect choices use a visible, deterministic policy in this MVP.
				var index := _best_boost(owner)
				if index >= 0:
					var extra: Dictionary = players[owner].hand.pop_at(index)
					ctx.value += int(extra.get("boost", 0))
					if not _flow.has("boosts"): _flow.boosts = []
					_flow.boosts.append({"owner":owner,"card":extra.duplicate(true)})
					_v8.boosted(owner,extra)
					_log("Усиление эффекта: %s (+%d)." % [extra.name, int(extra.get("boost", 0))])
			"voyage_bonus":
				var count := _voyages(owner)
				ctx.value += count
				_log("Плавание: других плаваний в сбросе %d, сила карты +%d." % [count, count])
			"prevent_all_damage": ctx.prevent = true; ctx.prevent_all = true
			"draw":
				_draw(owner, amount)
				_log("%s: эффект взятия %d карт." % [_player_name(owner), amount])
			"heal":
				var heal_id := hero_fighter(owner) if str(effect.get("target", "self")) == "hero" else fid
				var before := int(fighters[heal_id].hp) if heal_id >= 0 else 0
				_heal(heal_id, amount)
				if heal_id >= 0: _log("%s восстанавливает %d здоровья." % [fighters[heal_id].name, int(fighters[heal_id].hp) - before])
			"grail":
				var hero := hero_fighter(owner)
				if _valid_fighter(hero) and int(fighters[hero].hp) <= int(effect.get("threshold", 4)):
					fighters[hero].hp = int(effect.get("health", 8))
					_log("Святой Грааль: здоровье Артура теперь %d." % int(fighters[hero].hp))
			"choose_two":
				var hero := hero_fighter(owner)
				if _valid_fighter(hero):
					# Two distinct choices: heal when injured, draw when available,
					# otherwise relocate. The UI explicitly labels this automatic policy.
					var choices := 0
					if int(fighters[hero].hp) <= int(fighters[hero].max_hp) - 2:
						_heal(hero, 3)
						choices += 1
					if not players[owner].deck.is_empty():
						_draw(owner, 2)
						choices += 1
					if choices < 2: _auto_place(hero, true)
			"change_size":
				alice_size[owner] = "small" if str(alice_size.get(owner, "big")) == "big" else "big"
				_log("Алиса теперь %s." % ("большая" if alice_size[owner] == "big" else "маленькая"))
			"move": _effect_move(effect, ctx)
			"place":
				var place_id := int(effect.get("fixed_fighter", hero_fighter(owner) if str(effect.get("target", "self")) == "hero" else fid))
				_auto_place(place_id, true, bool(effect.get("same_zone",false)), effect)
				if _valid_fighter(place_id): _log("%s перенесён на клетку %d." % [fighters[place_id].name, int(fighters[place_id].node) + 1])
			"damage":
				var target := _effect_damage_target(effect, ctx)
				if target >= 0:
					_damage(target, amount)
					_log("Эффект: %s получает %d урона." % [fighters[target].name, amount])
				else: _log("Эффект урона: подходящей цели нет.")
			"random_discard":
				if is_enemy(owner, enemy_owner): _force_discard(enemy_owner, amount, true)
			"opponent_discard":
				if is_enemy(owner, enemy_owner): _force_discard(enemy_owner, amount, false)
			"reveal_choose_discard":
				if is_enemy(owner, enemy_owner):
					_reveal_hand(owner, enemy_owner,ctx)
					_force_discard(enemy_owner, amount, false, true)
			"reveal_hand":
				if is_enemy(owner, enemy_owner): _reveal_hand(owner, enemy_owner, ctx)
			"retrieve": _retrieve(owner, str(effect.get("card", "excalibur")))
			"retrieve_voyages":
				for i in range(players[owner].discard.size() - 1, -1, -1):
					if bool(players[owner].discard[i].get("voyage", false)):
						players[owner].hand.append(players[owner].discard.pop_at(i))
				players[owner].voyages = _voyages(owner)
			"top_four_choose_two": _prophecy(owner)
			"restless_spirits": _restless_spirits(fid, owner)
			"revive_sidekick": _revive(owner)

func _has_tag(card: Dictionary, tag: String) -> bool:
	return card.get("tags", []).has(tag) or bool(card.get(tag, false))

func _retrieve_tag(owner: int, tag: String) -> void:
	var best := -1
	var quality := -INF
	for i in range(players[owner].discard.size()):
		var card: Dictionary = players[owner].discard[i]
		if _has_tag(card, tag) and _card_quality(card) > quality:
			best = i
			quality = _card_quality(card)
	if best < 0:
		_log("В сбросе нет подходящей карты Jeet Kune Do.")
		return
	var card: Dictionary = players[owner].discard.pop_at(best)
	players[owner].hand.append(card)
	_log("В руку возвращена карта Jeet Kune Do: %s." % card.name)

func _resolve_chosen_damage(fid: int, effect: Dictionary, ctx: Dictionary) -> void:
	var before := _valid_fighter(fid)
	var amount := int(effect.get("amount", 0))
	_damage(fid, amount)
	_log("Эффект «%s»: %s получает %d урона." % [ctx.card.get("name", "Карта"), fighters[fid].name, amount])
	if before and not fighters[fid].alive and bool(effect.get("return_on_defeat", false)):
		_flow.return_card = true
		_log("Однодюймовый удар возвращается в руку после поражения цели.")

func _swap_combatants(a: int, b: int) -> bool:
	if a >= 0 and b >= 0 and (int(fighters[a].get("locked_until",-1)) == turn_number or int(fighters[b].get("locked_until",-1)) == turn_number): return false
	if not _valid_fighter(a) or not _valid_fighter(b):
		_log("Поменяться местами нельзя: один из бойцов повержен.")
		return false
	var first := int(fighters[a].node)
	var second=int(fighters[b].node)
	var old_cells={a:_v19.spaces(a).duplicate(),b:_v19.spaces(b).duplicate()}
	var old_tails={a:int(fighters[a].get("tail",-1)),b:int(fighters[b].get("tail",-1))}
	var snapshot={a:first,b:second}
	for id in [a,b]:
		if _v19.large(id):fighters[id].tail=-1
	fighters[a].node = second
	fighters[b].node = first
	for id in [a,b]:
		if not _v19.large(id):continue
		var legal=_v19.orientations(id,int(fighters[id].node))
		if legal.is_empty():
			fighters[a].node=first;fighters[b].node=second
			for original in [a,b]:
				if _v19.large(original):fighters[original].tail=old_tails[original]
			return false
		fighters[id].tail=int(legal[0])
	fighters[a].left_space_turn=turn_number;fighters[b].left_space_turn=turn_number
	snapshot.old_cells=old_cells[a];_v12.departed(a,first,second,snapshot)
	snapshot.old_cells=old_cells[b];_v12.departed(b,second,first,snapshot)
	_log("%s и %s поменялись местами." % [fighters[a].name,fighters[b].name])
	_trigger_trap(a)
	_trigger_trap(b)
	return true

func _auto_bring_it_on(ctx: Dictionary) -> void:
	var owner := int(ctx.owner)
	var targets := _damage_candidates({"target": "enemy_in_hero_zone"}, ctx)
	var target := _best_public_target(targets)
	var hero := hero_fighter(owner)
	if target >= 0 and _valid_fighter(hero):
		for node in nodes[int(fighters[hero].node)].neighbors:
			if _occupant(int(node)) < 0:
				_enter_node(target, int(node))
				_log("Противник поставлен рядом с Брюсом Ли.")
				return
	_log("Нет подходящего противника или свободного места рядом с Брюсом Ли.")

func _raptors_adjacent(owner: int, target: int) -> int:
	if not _valid_fighter(target): return 0
	var count := 0
	for id in _living_heroes(owner):
		if fighters_adjacent(int(id),target): count += 1
	return count

func _auto_coordinate_raptors(owner: int) -> void:
	var ids := _living_heroes(owner)
	if ids.is_empty(): return
	var anchor := int(ids[0])
	for id in ids:
		if int(id) != anchor: _auto_place(int(id), false, false, {"zone_anchor": anchor})
	_log("Рапторы перегруппировались в зоне выбранного раптора.")

func _auto_decoy(ctx: Dictionary) -> void:
	if not _valid_fighter(int(ctx.opponent)): return
	for id in _living_heroes(int(ctx.owner)):
		if int(id) == int(ctx.self): continue
		for node in nodes[int(fighters[int(ctx.opponent)].node)].neighbors:
			if _occupant(int(node)) < 0:
				_enter_node(int(id), int(node))
				_log("Приманка: другой раптор поставлен рядом с атакующим.")
				return
	_log("Приманка: нет другого раптора или свободной соседней клетки.")

func _detonation_nodes(owner: int) -> Array[int]:
	var legal: Array[int] = []
	for trap in traps:
		for f in fighters:
			if _valid_fighter(int(f.id)) and int(f.owner) == owner and not f.hero and _same_zone(int(f.node), int(trap.node)):
				legal.append(int(trap.node))
				break
	return legal

func _detonate_trap(owner: int, node: int) -> void:
	var trap := _trap_at(node)
	if trap < 0 or not _detonation_nodes(owner).has(node): return
	var affected: Array = []
	for f in fighters:
		if _valid_fighter(int(f.id)) and is_enemy(owner, int(f.owner)) and node_adjacent_to_fighter(node,int(f.id)):
			affected.append(int(f.id))
			_log("Дистанционный подрыв: %s получает 1 урон." % f.name)
	_damage_many(affected,1)
	if affected.is_empty(): _log("Дистанционный подрыв: рядом с ловушкой нет врагов.")
	_return_trap(trap)

func _best_trap_node(owner: int, legal: Array) -> int:
	var target := _public_target(hero_fighter(owner))
	if target < 0: return int(legal[0])
	var best := int(legal[0])
	var distance := 999
	for node in legal:
		var current := _distance(int(node), int(fighters[target].node))
		if current < distance:
			best = int(node)
			distance = current
	return best

func _damage_candidates(effect: Dictionary, ctx: Dictionary) -> Array:
	var target := str(effect.get("target", "opposing_combatant"))
	var fid := int(ctx.self)
	var owner := int(ctx.owner)
	var opponent := int(ctx.opponent)
	if target == "opposing_combatant": return [opponent] if _valid_fighter(opponent) and is_enemy(owner, int(fighters[opponent].owner)) else []
	var candidates: Array = []
	var hero := hero_fighter(owner)
	if target in ["any_adjacent_to_self", "opponent_adjacent_to_self"] and not _valid_fighter(fid): return []
	if target in ["any_in_hero_zone", "enemy_in_hero_zone"] and not _valid_fighter(hero): return []
	for f in fighters:
		if not _valid_fighter(int(f.id)): continue
		if target == "enemy_any" and not is_enemy(owner,int(f.owner)): continue
		if target in ["any_adjacent_to_self", "opponent_adjacent_to_self"] and not fighters_adjacent(fid,int(f.id)): continue
		if target in ["any_in_hero_zone", "enemy_in_hero_zone"] and not _same_zone(int(fighters[hero].node), int(f.node)): continue
		if target in ["enemy_in_hero_zone", "opponent_adjacent_to_self"] and not is_enemy(owner, int(f.owner)): continue
		candidates.append(int(f.id))
	return candidates

func _effect_damage_target(effect: Dictionary, ctx: Dictionary) -> int:
	var owner := int(ctx.owner)
	var opponent := int(ctx.opponent)
	var candidates: Array = []
	var friendly_candidates: Array = []
	for id in _damage_candidates(effect, ctx):
		if are_allies(int(fighters[int(id)].owner), owner): friendly_candidates.append(int(id))
		else: candidates.append(int(id))
	if candidates.has(opponent): return opponent
	if friendly_candidates.has(opponent): return opponent
	if not candidates.is_empty(): return _best_public_target(candidates)
	# Mandatory effects still apply if only friendly fighters are eligible.
	var own_candidates: Array = []
	for id in friendly_candidates:
		if int(fighters[int(id)].owner) == owner: own_candidates.append(int(id))
	if not own_candidates.is_empty(): friendly_candidates = own_candidates
	var durable := -1
	var health := -1
	for id in friendly_candidates:
		if int(fighters[int(id)].hp) > health:
			durable = int(id)
			health = int(fighters[int(id)].hp)
	return durable

func _effect_move(effect: Dictionary, ctx: Dictionary) -> void:
	var target := str(effect.get("target", "self"))
	var owner := int(ctx.owner)
	var ids: Array = []
	var away := false
	match target:
		"self": ids = [int(ctx.self)]
		"opposing_combatant", "opponent": ids = [int(ctx.opponent)]
		"hero": ids = [hero_fighter(owner)]
		"either_combatant":
			# Keep agency predictable: move your own surviving combatant.
			ids = [int(ctx.self)]
			away = true
		"both_combatants": ids = [int(ctx.self),int(ctx.opponent)]
		"all_enemies":
			for f in fighters:
				if _valid_fighter(int(f.id)) and is_enemy(owner,int(f.owner)): ids.append(int(f.id))
		"all_friendly", "all_sidekicks", "all_fighters":
			for f in fighters:
				if not f.alive: continue
				if target != "all_fighters" and int(f.owner) != owner: continue
				if target == "all_sidekicks" and f.hero: continue
				ids.append(int(f.id))
	if effect.has("fixed_fighter"):ids=[int(effect.fixed_fighter)]
	for fid in ids:
		if _valid_fighter(fid):
			var before := int(fighters[int(fid)].node)
			_auto_move(int(fid), int(effect.get("spaces", 0)), away, bool(effect.get("through_enemies", false)), owner,bool(effect.get("through_sidekicks",false)))
			_log("%s: эффект перемещения с %d на %d." % [fighters[int(fid)].name, before + 1, int(fighters[int(fid)].node) + 1])

func _force_discard(owner: int, count: int, random_pick: bool, best: bool = false, forced_hand=true) -> void:
	if is_dormant(owner): return
	if forced_hand and (_v14.owl_protected(owner)or _v35.shielded(owner)):
		_log("Неясыть: сброс из руки проигнорирован.")
		return
	var batch=[]
	for n in range(count):
		if players[owner].hand.is_empty(): break
		var index := rng.randi_range(0, players[owner].hand.size() - 1) if random_pick else _lowest_card(owner, best)
		batch.append(players[owner].hand.pop_at(index))
	for card in batch:
		_discard(owner, card)
		_v8.opponent_discarded(owner,card)
		_log("%s сбрасывает: %s." % [_player_name(owner), card.name])

func _reveal_hand(viewer: int, owner: int, ctx: Dictionary = {}) -> bool:
	if viewer < 0 or viewer >= players.size() or owner < 0 or owner >= players.size() or is_dormant(owner): return false
	var peek_ctx = ctx.duplicate(true)
	peek_ctx.owner = viewer
	peek_ctx.opponent_owner = owner
	if not peek_ctx.has("card"): peek_ctx.card = {"name":"Рука противника"}
	if _v8.guard_effect({"kind":"reveal_hand"},peek_ctx): return phase == "effect_choice"
	# Hidden cards belong only to this suspended choice, never to public logs.
	_log("%s просматривает руку %s (%d карт)." % [_player_name(viewer), _player_name(owner), players[owner].hand.size()])
	if not interactive or players[viewer].bot: return false
	pending_choice = {"kind":"hand_view", "action":"view_hand", "title":str(ctx.get("card", {}).get("name", "Рука противника")), "prompt":"Посмотрите карты руки противника" if not players[owner].hand.is_empty() else "Рука противника пуста", "cards":players[owner].hand.duplicate(true), "owner":viewer, "viewer":viewer, "victim":owner, "options":["Продолжить"], "legal":[], "fighter":-1, "allowed_fighters":[], "can_skip":false, "_ctx":ctx.duplicate(true)}
	phase = "effect_choice"
	return true

func _retrieve(owner: int, card_id: String) -> void:
	for source in ["discard", "deck"]:
		for i in range(players[owner][source].size()):
			if str(players[owner][source][i].get("id", "")) == card_id:
				players[owner].hand.append(players[owner][source].pop_at(i))
				if source == "deck": _shuffle(players[owner].deck)
				_log("%s возвращает Экскалибур в руку." % _player_name(owner))
				return
	_log("Экскалибур не найден в колоде и сбросе; рука не изменена.")

func _prophecy(owner: int) -> void:
	var top: Array = []
	for n in range(mini(4, players[owner].deck.size())): top.append(players[owner].deck.pop_back())
	top.sort_custom(func(a, b): return _card_quality(a) > _card_quality(b))
	for n in range(mini(2, top.size())): players[owner].hand.append(top.pop_front())
	for card in top: players[owner].deck.append(card)
	_log("Пророчество: выбранные карты взяты, оставшиеся возвращены наверх.")

func _restless_spirits(fid: int, owner: int) -> void:
	if not _valid_fighter(fid): return
	var best_pair: Array = []
	var best_score := -1.0
	for node in nodes:
		if not _same_zone(int(fighters[fid].node), int(node.id)): continue
		for next in node.neighbors:
			var score := 0.0
			for f in fighters:
				if _valid_fighter(int(f.id)) and is_enemy(owner, int(f.owner)) and int(f.node) in [int(node.id), int(next)]:
					score += 2.0 + (2.0 if int(f.hp) <= 2 else 0.0)
			if score > best_score:
				best_score = score
				best_pair = [int(node.id), int(next)]
	_resolve_spirit_spaces(owner, best_pair)

func _resolve_spirit_spaces(owner: int, spaces: Array) -> void:
	var affected: Array = []
	var alive_before: Array = []
	var waits_for_assignment = false
	for f in fighters:
		if _valid_fighter(int(f.id)) and is_enemy(owner,int(f.owner)): alive_before.append(int(f.id))
		if _valid_fighter(int(f.id)) and is_enemy(owner, int(f.owner)) and _v19.spaces(int(f.id)).any(func(n):return spaces.has(int(n))):
			var id := int(f.id)
			affected.append(id)
			if interactive and not players[int(f.owner)].bot and not _v9.archers(id).is_empty(): waits_for_assignment = true
			_log("Неупокоенные духи: %s получает 2 урона." % fighters[id].name)
	if waits_for_assignment and not _flow.is_empty():
		_effect_queue.push_front({"effect":{"kind":"spirits_finish","alive_before":alive_before,"intrinsic":true},"ctx":{"owner":owner,"self":hero_fighter(owner),"opponent":-1,"opponent_owner":-1,"card":{},"won":false}})
	_damage_many(affected,2)
	if affected.is_empty(): _log("Неупокоенные духи: в выбранных клетках нет противников; урон не нанесён.")
	if not waits_for_assignment or _flow.is_empty(): _finish_spirits(owner,alive_before)

func _finish_spirits(owner: int, alive_before: Array) -> void:
	var defeated = 0
	for id in alive_before:
		if not fighters[int(id)].alive: defeated += 1
	if defeated > 0:
		_draw(owner)
		_log("Неупокоенные духи: повержено %d бойцов; взята 1 карта." % defeated)

func _revive(owner: int) -> void:
	var hero := hero_fighter(owner)
	if not _valid_fighter(hero):
		_log("Герой повержен: вернуть помощника в его зону нельзя.")
		return
	for f in fighters:
		if int(f.owner) != owner or f.hero or f.alive: continue
		for node in nodes:
			if _occupant(int(node.id)) < 0 and _same_zone(int(fighters[hero].node), int(node.id)):
				f.node = int(node.id)
				f.hp = int(f.max_hp)
				f.alive = true
				_log("%s возвращается на поле." % f.name)
				return
	_log("Нет поверженного помощника или свободной клетки в зоне героя.")

func _best_public_target(candidates: Array) -> int:
	var best := -1
	var score := -INF
	for fid in candidates:
		if not _valid_fighter(int(fid)): continue
		var f: Dictionary = fighters[int(fid)]
		var current := (5.0 if f.hero else 1.0) + 5.0 / maxf(1.0, float(f.hp))
		if int(f.hp) <= 2: current += 6.0
		if current > score:
			score = current
			best = int(fid)
	return best

func _public_target(fid: int, in_zone: bool = false) -> int:
	if not _valid_fighter(fid): return -1
	var candidates: Array = []
	for f in fighters:
		if _valid_fighter(int(f.id)) and is_enemy(int(fighters[fid].owner), int(f.owner)):
			if in_zone and not _same_zone(int(f.node), int(fighters[fid].node)): continue
			candidates.append(int(f.id))
	return _best_public_target(candidates)

func _effect_reachable(fid: int, distance: int, through: bool, through_sidekicks = false) -> Array[int]:
	return _reachable_options(fid, mini(distance,1) if _v12.stepwise(fid) else distance, through, through_sidekicks)

func _auto_move(fid: int, distance: int, away: bool = false, through: bool = false, controlling_owner: int = -1, through_sidekicks = false) -> void:
	if not _valid_fighter(fid): return
	var owner := int(fighters[fid].owner)
	var destinations := _effect_reachable(fid, distance, through,through_sidekicks)
	if destinations.is_empty(): return
	var best := int(fighters[fid].node)
	var best_score := -INF
	for destination in destinations:
		var score := _position_score(fid, int(destination), away)
		if controlling_owner >= 0 and is_enemy(controlling_owner, owner): score = -score
		if score > best_score:
			best_score = score
			best = int(destination)
	var insight_origin=int(fighters[fid].node)
	if _v19.large(fid):
		var states=_v19.candidates(fid,best,distance,through)
		if not states.is_empty():
			var choice=states[0]
			for candidate in states:
				if _v19.orientation_score(fid,candidate)>_v19.orientation_score(fid,choice):choice=candidate
			fighters[fid].chosen_tail=int(choice.tail)
	_enter_node(fid, best)
	_v19.moved(fid,insight_origin,false)

func _auto_place(fid: int, away: bool = false, same_zone: bool = false, effect: Dictionary = {}) -> void:
	if not _valid_fighter(fid): return
	var best := int(fighters[fid].node)
	var score := -INF
	for node in nodes:
		if not _v31.can_end(fid,int(node.id)): continue
		if effect.get("other_space",false) and int(node.id)==int(fighters[fid].node):continue
		if _v19.large(fid) and _v19.orientations(fid,int(node.id)).is_empty():continue
		if effect.has("adjacent_to") and (not _valid_fighter(int(effect.adjacent_to)) or not nodes[int(fighters[int(effect.adjacent_to)].node)].neighbors.has(int(node.id))): continue
		if effect.has("zone_anchor") and (not _valid_fighter(int(effect.zone_anchor)) or not _same_zone(int(fighters[int(effect.zone_anchor)].node), int(node.id))): continue
		if same_zone and not _same_zone(int(fighters[fid].node),int(node.id)): continue
		var current := _position_score(fid, int(node.id), away)
		if current > score:
			score = current
			best = int(node.id)
	if _v19.large(fid):
		var tails=_v19.orientations(fid,best)
		if not tails.is_empty():fighters[fid].chosen_tail=int(tails[0])
	_enter_node(fid, best)

func _distance(a: int, b: int) -> int:
	if a == b: return 0
	var queue: Array = [[a, 0]]
	var seen := {a: true}
	while not queue.is_empty():
		var entry: Array = queue.pop_front()
		for next in nodes[int(entry[0])].get("move_neighbors", nodes[int(entry[0])].neighbors):
			if int(next) == b: return int(entry[1]) + 1
			if not seen.has(int(next)):
				seen[int(next)] = true
				queue.append([int(next), int(entry[1]) + 1])
	return 999

func _position_score(fid: int, destination: int, away: bool = false) -> float:
	var owner := int(fighters[fid].owner)
	var best_enemy_distance := 99
	var enemies_in_reach := 0
	var danger := 0.0
	for enemy in fighters:
		if not _valid_fighter(int(enemy.id)) or are_allies(int(enemy.owner), owner): continue
		var dist := _distance(destination, int(enemy.node))
		best_enemy_distance = mini(best_enemy_distance, dist)
		if dist == 1 or (fighters[fid].ranged and _same_zone(destination, int(enemy.node))): enemies_in_reach += 1
		if dist <= 2: danger += 0.5
		if _is_hero(int(enemy.owner), "medusa") and enemy.hero and _same_zone(destination, int(enemy.node)): danger += 1.0
	var should_flee: bool = away or (fighters[fid].hero and int(fighters[fid].hp) <= 4 and players[owner].hand.size() < 3)
	if should_flee: return float(best_enemy_distance) * 1.4 - danger
	var score := -float(best_enemy_distance) + float(enemies_in_reach) * 2.0
	if _is_hero(owner,"invisible_man") and fog_at(destination,owner) >= 0: score += 2.5
	if difficulty >= 2: score -= danger * 0.4
	# Do not pointlessly move a useful ranged fighter into melee.
	if fighters[fid].ranged and enemies_in_reach > 0 and best_enemy_distance > 1: score += 1.5
	return score

func _card_quality(card: Dictionary) -> float:
	var score := float(card.get("value", 0)) + float(card.get("boost", 0)) * 0.15
	if _has_kind(card, "draw"): score += 0.6
	if _has_kind(card, "voyage_bonus"): score += 1.2
	if _has_kind(card, "cancel"): score += 0.7
	if str(card.get("type", "")) == "scheme": score += 1.8
	return score

func _lowest_card(owner: int, best: bool = false) -> int:
	var index := 0
	var score := -INF if best else INF
	for i in range(players[owner].hand.size()):
		var quality := _card_quality(players[owner].hand[i])
		if (best and quality > score) or (not best and quality < score):
			score = quality
			index = i
	return index

func _best_boost(owner: int, exclude: int = -1) -> int:
	var index := -1
	var score := 0.0
	for i in range(players[owner].hand.size()):
		if i == exclude: continue
		var card: Dictionary = players[owner].hand[i]
		var boost_value:=2.5 if card.get("dice_boost",false)else float(card.get("boost",0))
		var quality := boost_value - _card_quality(card) * 0.12
		if boost_value > 0 and quality > score:
			score = quality
			index = i
	return index

func _choose_defense(fid: int, attacker: int) -> int:
	var owner := int(fighters[fid].owner)
	var choices := legal_defenses()
	if choices.is_empty(): return -1
	var defense_skill=int(players[owner].get("ai_skill",difficulty))
	if defense_skill>=3:return _master.defense(fid,attacker,choices)
	if defense_skill == 0:
		return -1 if rng.randf() < 0.22 else int(choices[rng.randi_range(0, choices.size() - 1)])
	var best := -1
	var best_score := -INF
	# These estimates use the attacker's identity/public stats; never its facedown card.
	var expected := 4.0
	var enemy_owner := int(fighters[attacker].owner)
	if _is_hero(enemy_owner, "alice") and fighters[attacker].hero and str(alice_size.get(enemy_owner, "big")) == "big": expected += 2.0
	if _is_hero(enemy_owner, "sinbad"): expected = maxf(expected, 2.0 + _voyages(enemy_owner))
	if _is_hero(enemy_owner,"muhammad_ali") and stance_for(enemy_owner) == "bee": expected += 2.0
	expected += _v13.attack_bonus(attacker)+_v14.attack_bonus(attacker)
	for index in choices:
		var card: Dictionary = players[owner].hand[int(index)]
		var value := float(card.get("value", 0))
		if _has_kind(card, "set_value_if_moved") and fid < turn_start_nodes.size() and changed_start_space(fid): value = 5.0
		if _has_kind(card, "prevent_all_damage"): value = expected + 1.0
		if _has_kind(card, "cancel"): value += 1.5
		if _is_hero(owner, "alice") and fighters[fid].hero and str(alice_size.get(owner, "big")) == "small": value += 1.0
		if _is_hero(owner,"invisible_man") and fog_at(int(fighters[fid].node),owner) >= 0: value += 1.0
		if _has_kind(card,"duality_of_man") and form_for(owner) == "jekyll": value = 6.0
		if _has_kind(card,"impossible_to_see"): value += expected
		value += _v15.bonus(owner)
		value = _v18.estimate(card,fid,attacker,_v14.estimate(card,fid,attacker,_v13.estimate(card,fid,attacker,value)))
		value = _v35.estimate(card,fid,_v34.estimate(card,fid,_v32.estimate(card,fid,attacker,value,true),true),true)
		value = _v36.estimate(card,fid,attacker,value)
		value = _v38.estimate(card,fid,attacker,value,true)
		var score := minf(value, expected) * 1.6 - _card_quality(card) * 0.25
		if _has_kind(card, "draw"): score += 0.6
		if difficulty >= 2:
			if _has_kind(card, "cancel") and _is_hero(enemy_owner, "medusa"): score += 2.0
			if _has_kind(card, "grail") and int(fighters[fid].hp) <= 7: score += 1.2
			if int(fighters[fid].hp) <= int(expected): score += value
		if score > best_score:
			best_score = score
			best = int(index)
	return best

func bot_step() -> void:
	if _busy or players.is_empty() or winner != -1: return
	if not players[active].bot: return
	_busy = true
	if phase == "discard":
		discard_card(_lowest_card(active))
	elif phase == "move":
		for f in fighters:
			if _valid_fighter(int(f.id)) and int(f.owner) == active and not maneuver_moved.has(int(f.id)):
				for door in range(door_states.size()):
					if bool(door_states[door]) and _v8.door_adjacent(int(f.id),door): _v8.toggle_door(int(f.id),door)
				var legal = legal_moves(int(f.id))
				if not legal.is_empty():
					var best = int(legal[0])
					for n in legal:
						if _position_score(int(f.id),int(n)) > _position_score(int(f.id),best): best = int(n)
					move_fighter(int(f.id),best)
				maneuver_moved.append(int(f.id))
		finish_maneuver()
	elif phase == "action":
		_bot_action()
	_busy = false
	changed.emit()

func _estimated_attack(card: Dictionary, fid: int, target: int) -> float:
	var owner := int(fighters[fid].owner)
	var value := float(card.get("value", 0))
	if _has_kind(card, "set_value_against_hero") and fighters[target].hero: value = 5.0
	if _has_kind(card, "set_value_if_moved") and fid < turn_start_nodes.size() and changed_start_space(fid): value = 5.0
	if _has_kind(card, "voyage_bonus"): value += _voyages(owner)
	if _has_kind(card, "top_deck_boost"): value += 2.0
	if _has_kind(card, "ambush"): value += 1.5
	if _is_hero(owner, "alice") and fighters[fid].hero and str(alice_size.get(owner, "big")) == "big": value += 2.0
	if _is_hero(owner,"muhammad_ali") and stance_for(owner) == "bee": value += 2.0
	if _has_kind(card,"duality_of_man") and form_for(owner) == "hyde": value = 6.0
	if _has_kind(card,"forever_hyde"):
		for extra in players[owner].hand:
			if str(extra.get("fighter","")) == "jekyll": value += 2.0
	if _has_kind(card,"beastform"): value += maxf(0.0,float(players[owner].hand.size()-2))
	if _has_kind(card,"emerge_from_mist") and bool(players[owner].get("started_on_fog",false)): value = 5.0
	if _has_kind(card,"right_hand_man") and _valid_fighter(hero_fighter(owner)) and fighters_adjacent(hero_fighter(owner),fid): value = 6.0
	if _has_kind(card,"the_rush") and (shadow_at(int(fighters[fid].node)) >= 0 or shadow_at(int(fighters[target].node)) >= 0): value = 5.0
	if _has_kind(card,"always_surprising"): value += 4.0 if shadow_at(int(fighters[fid].node)) >= 0 else 2.0
	if _has_kind(card,"blind_boost") and willow_form_for(owner) == "dark": value += 2.0
	if bool(players[owner].get("fixed_four",false)): value = 4.0
	if _has_kind(card,"v8_war_king"): value += 2.0*_v8.rage(owner)
	if _has_kind(card,"v8_epic"): value += mini(3,_v8.rage(owner)+1)
	if _has_kind(card,"arrogance") and players[owner].hand.size() <= 2: value = 6.0
	var leshen_bonus=3 if _is_hero(owner,"ancient_leshen") and fighters[fid].hero and _v14.leshen_attacks(owner)>0 else 0
	return _v38.estimate(card,fid,target,_v36.estimate(card,fid,target,_v35.estimate(card,fid,_v34.estimate(card,fid,_v32.estimate(card,fid,target,_v18.estimate(card,fid,target,_v14.estimate(card,fid,target,_v13.estimate(card,fid,target,value))))))))+_v13.attack_bonus(fid)+leshen_bonus+_v15.bonus(owner)+_v38.bonus(fid,target)

func _bot_action() -> void:
	if is_dormant(active):end_turn();return
	var options: Array = []
	for f in fighters:
		if not _valid_fighter(int(f.id)) or int(f.owner) != active: continue
		var fid := int(f.id)
		for item_index in _v24.at(fid,"scheme"):
			var score=_v24.bot_score(fid,int(item_index))
			if score>0:options.append({"kind":"item","fighter":fid,"item":int(item_index),"score":score})
		for index in range(players[active].hand.size()):
			var card: Dictionary = players[active].hand[index]
			if not _card_usable(card, fid): continue
			if str(card.get("type", "")) == "scheme":
				var quality := _scheme_score(card, fid)
				if quality > 0: options.append({"kind": "scheme", "fighter": fid, "card": index, "score": quality})
			elif _attack_type(card):
				for target in legal_targets(fid, index):
					var self_cost=0
					for fx in card.get("effects",[]):
						if fx.get("kind","")=="v19_self_damage":self_cost+=int(fx.get("amount",0))
					if self_cost>=int(fighters[fid].hp):continue
					var power := _estimated_attack(card, fid, int(target))
					var score := power + (1.5 if fighters[int(target)].hero else 0.2)
					var target_owner := int(fighters[int(target)].owner)
					if power >= float(fighters[int(target)].hp) + 2.0: score += 3.0
					if players[target_owner].hand.is_empty(): score += 2.0
					if _has_kind(card, "damage"): score += 1.5
					if _has_kind(card, "ignore_defense"): score += 2.5
					if _has_kind(card, "draw"): score += 0.8
					if _has_kind(card, "voyage_bonus"): score += 0.8
					if difficulty >= 2:
						if _has_kind(card, "cancel") and _is_hero(target_owner, "medusa"): score += 1.0
						if int(fighters[int(target)].hp) <= 4 and fighters[int(target)].hero: score += 3.0
						if _defense_type(card) and players[active].hand.size() < 3: score -= 1.0
					options.append({"kind": "attack", "fighter": fid, "target": int(target), "card": index, "score": score})
	var free_options=options.filter(func(o):return o.kind=="attack"and int(players[active].get("free_target",-1))in[-1,int(o.target)]) if _v34.has_free(active)else []
	if not free_options.is_empty():options=free_options
	elif actions_left<=0:_v34.clear_free(active);_after_action();return
	if difficulty>=3:
		var decision=_master.choose(options)
		if not decision.is_empty():_master.apply(self,decision);return
	var must_draw: bool = free_options.is_empty()and players[active].hand.size() < 2 and not players[active].deck.is_empty()
	if options.is_empty() or must_draw:
		begin_maneuver()
		return
	var chosen: Dictionary
	if difficulty == 0:
		if free_options.is_empty()and rng.randf() < 0.23 and not players[active].deck.is_empty():
			begin_maneuver()
			return
		chosen = options[rng.randi_range(0, options.size() - 1)]
	else:
		options.sort_custom(func(a, b): return float(a.score) > float(b.score))
		chosen = options[0]
		if difficulty == 1 and options.size() > 1 and rng.randf() < 0.22: chosen = options[1]
	if chosen.kind == "item":
		_v24.use(int(chosen.fighter),int(chosen.item))
	elif chosen.kind == "scheme":
		scheme(int(chosen.fighter), int(chosen.card))
	else:
		var boost := -1
		if difficulty > 0 and _is_hero(active, "arthur") and fighters[int(chosen.fighter)].hero and players[active].hand.size() >= 3:
			boost = _best_boost(active, int(chosen.card))
		attack(int(chosen.fighter), int(chosen.target), int(chosen.card), boost)

func _scheme_score(card: Dictionary, fid: int) -> float:
	if not _v31.mission_allowed(int(fighters[fid].owner),card):return -100.0
	var score := 1.0
	for effect in card.get("effects", []):
		match str(effect.get("kind", "")):
			"draw":
				if players[active].deck.is_empty(): return -10.0
				score += float(effect.get("amount", 1)) * (2.0 if players[active].hand.size() < 5 else 0.5)
			"damage":
				var ctx := {"owner": active, "self": fid, "opponent": -1}
				var target := _effect_damage_target(effect, ctx)
				if target < 0 or not is_enemy(active, int(fighters[target].owner)):
					var can_reach_enemy := false
					for movement in card.get("effects", []):
						if str(movement.get("kind", "")) != "move": continue
						for destination in _effect_reachable(fid, int(movement.get("spaces", 0)), bool(movement.get("through_enemies", false))):
							for enemy in fighters:
								if _valid_fighter(int(enemy.id)) and is_enemy(active, int(enemy.owner)) and node_adjacent_to_fighter(int(destination),int(enemy.id)): can_reach_enemy = true
					if not can_reach_enemy: return -5.0
				score += 4.0
			"steal_from_the_rich":
				if players[active].deck.is_empty(): return -5.0
				score += 4.0
			"retrieve":
				var found := false
				for source in ["deck", "discard"]:
					for item in players[active][source]:
						if str(item.get("id", "")) == str(effect.get("card", "")): found = true
				if not found: return -5.0
				score += 4.0
			"revive_sidekick":
				for f in fighters:
					if int(f.owner) == active and not f.hero and not f.alive: score += 4.0
			"top_four_choose_two": score += 4.0 if players[active].deck.size() >= 2 else -2.0
			"insight", "the_sight": score += 4.0
			"seek_the_shadows": score += 4.0 if players[active].deck.size() >= 2 else -3.0
			"love_and_loss":
				if players[active].deck.is_empty(): return -5.0
				score += 3.0
				if willow_form_for(active) == "dark":
					for f in fighters:
						if _valid_fighter(int(f.id)) and not f.hero and _same_zone(int(fighters[fid].node),int(f.node)):
							score += 3.0 if is_enemy(active,int(f.owner)) else -5.0
			"resurrect":
				var has_target := false
				for f in fighters:
					if not f.alive and are_allies(active,int(f.owner)): has_target = true
				if not has_target: return -5.0
				score += 7.0
			"restless_spirits":
				if _public_target(fid, true) < 0: return -4.0
				score += 5.0
	return _v36.scheme_score(card,int(fighters[fid].owner),_v35.scheme_score(card,int(fighters[fid].owner),score))

func willow_form_for(owner: int) -> String:
	return str(willow_form.get(owner,"willow"))

func shadow_at(node: int, owner: int = -1) -> int:
	for i in range(shadow_tokens.size()):
		if int(shadow_tokens[i].node) == node and (owner < 0 or int(shadow_tokens[i].owner) == owner): return i
	return -1

func toggle_door(fighter_id: int, door: int) -> bool:
	return _v8.toggle_door(fighter_id,door)

func gain_actions(owner: int, amount: int) -> bool:
	if owner!=active or amount<=0:return false
	if _v14.action_blocked(owner)or _v35.action_blocked(owner):
		_log("Пурга: дополнительное действие запрещено.")
		return false
	actions_left+=amount
	return true
