extends Control

const EngineScript = preload("res://scripts/game_engine.gd")
const BoardScript = preload("res://scripts/board_view.gd")
const CardScript = preload("res://scripts/card_view.gd")
const ScrollScript = preload("res://scripts/touch_scroll.gd")
const I18n = preload("res://scripts/i18n.gd")
const SAVE_PATH = "user://match.json"
const GOLD = Color("e8c38a")
const INK = Color("e9eee9")
const MUTED = Color("9fb1b7")
const TEAL = Color("61cfba")
var engine
var heroes: Array = []
var boards: Array = []
var card_images: Dictionary = {}
var avatars: Dictionary = {}
var sets: Array = []
var chosen_set = "bol1"
var sorceress_hero="yennefer"
var deadpool_conditions={"food":false,"owns_set":false,"mirror":false,"sleeved":false,"explosion":false}
var player_real_names={"0":"","1":"","2":"","3":""}
var geralt_gear={"sword":"steel","armor":"medallion","potion":"owl"}
var set_option: OptionButton
var language_option: OptionButton
var hero_row: HBoxContainer
var hud_left: VBoxContainer
var hud_right: VBoxContainer
var _hud_layout_pending = false
var game_ui: VBoxContainer
var game_outer: MarginContainer
var menu_outer: MarginContainer
var sidebar_panel: PanelContainer
var left_column: VBoxContainer
var hand_section: VBoxContainer
var hand_toggle_button: Button
var state_label: Label
var menu_ui: Control
var board
var hand_box: HBoxContainer
var hand_scroll: ScrollContainer
var detail_scroll: ScrollContainer
var zoom_button: Button
var status_label: Label
var hint_label: Label
var detail_title: Label
var detail_text: Label
var player_box: Control
var maneuver_button: Button
var play_button: Button
var boost_button: Button
var move_finish_button: Button
var items_button: Button
var doors_button: Button
var selected_card = -1
var selected_fighter = -1
var attack_mode = false
var boost_card = -1
var chosen_hero = "alice"
var count_option: OptionButton
var level_option: OptionButton
var size_option: OptionButton
var buffy_sidekick_option: OptionButton
var speed_option: OptionButton
var map_option: OptionButton
var start_slot_option: OptionButton
var placement_option: OptionButton
var opponent_options: Array = []
var opponent_labels: Array = []
var bot_timer: Timer
var popup_layer: Control
var hero_buttons: Array = []
var started = false
var result_shown = false
var toast = ""
var bot_delay = 0.75
var _hand_signature = ""
var _detail_signature = ""
var _interaction_scheduled = false
var _modal_key = ""
var popup_kind = ""
var popup_close_button: Button
var popup_outer: MarginContainer
var enlarged_board
var hand_collapsed = false
var _saved_hand_collapsed = false
var _layout_phase = ""
var _hand_card_size = Vector2(116, 168)
var _return_discard_owner = -1
var _return_effect_choice = false
var _return_effect_scroll = 0
var effect_scroll: ScrollContainer
var popup_hidden = false
var popup_inspector: Control
var inspector_board
var inspector_zoom_button: Button
var popup_hide_button: Button

func _ready():
	_setup_theme()
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	if raw is Array:
		heroes = raw
	elif raw is Dictionary:
		heroes = raw.get("heroes", [])
	if FileAccess.file_exists("res://data/boards.json"):
		var board_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/boards.json"))
		if board_data is Array:
			boards = board_data
	if FileAccess.file_exists("res://data/card_images.json"):
		var image_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/card_images.json"))
		if image_data is Dictionary:
			card_images = image_data.get("cards", {})
	if FileAccess.file_exists("res://data/avatars.json"):
		var avatar_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/avatars.json"))
		if avatar_data is Dictionary:
			avatars = avatar_data
	if FileAccess.file_exists("res://data/sets.json"):
		var set_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/sets.json"))
		if set_data is Array: sets = set_data
	if sets.is_empty(): sets = [{"id":"bol1","name":"Битва легенд. Том 1","hero_ids":["alice","king_arthur","medusa","sinbad"]}]
	for entry in sets:
		entry.fan=bool(entry.get("fan",false)) or str(entry.name).begins_with("FAN")
	var fan_sets=sets.filter(func(entry):return entry.get("fan",false)).map(func(entry):return str(entry.id))
	for entry in heroes:
		entry.fan=bool(entry.get("fan",false)) or str(entry.name).begins_with("FAN") or str(entry.get("set_id","")) in fan_sets
	sets=sets.filter(func(x):return not x.get("fan",false))+sets.filter(func(x):return x.get("fan",false))
	heroes=heroes.filter(func(x):return not x.get("fan",false))+heroes.filter(func(x):return x.get("fan",false))
	for x in sets+heroes:
		if x.get("fan",false) and not str(x.name).begins_with("FAN"):x.name="FAN · "+str(x.name)
	var settings = ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		I18n.set_language(str(settings.get_value("ui","language","ru")))
		chosen_set = str(settings.get_value("ui","set","bol1"))
	engine = EngineScript.new()
	engine.interactive = true
	engine.changed.connect(_refresh)
	_build_menu()
	bot_timer = Timer.new()
	bot_timer.wait_time = bot_delay
	bot_timer.timeout.connect(_bot_tick)
	add_child(bot_timer)
	bot_timer.start()
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout.call_deferred()
	if "--smoke-ui" in OS.get_cmdline_user_args():
		_smoke_ui.call_deferred()

func _setup_theme():
	var t = Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEAL)
	t.set_color("font_disabled_color", "Button", Color("63767d"))
	t.set_constant("h_separation", "HBoxContainer", 10)
	t.set_constant("v_separation", "VBoxContainer", 8)
	for type_name in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type_name, _box(Color("1b303b"), Color("3b5159"), 10, 12))
		t.set_stylebox("hover", type_name, _box(Color("28424a"), TEAL, 10, 12))
		t.set_stylebox("pressed", type_name, _box(Color("163d3d"), TEAL, 10, 12))
		t.set_stylebox("focus", type_name, _box(Color(0,0,0,0), GOLD, 10, 12))
		t.set_stylebox("disabled", type_name, _box(Color("101e28"), Color("243740"), 10, 12))
		t.set_color("font_color", type_name, INK)
		t.set_color("font_disabled_color", type_name, Color("63767d"))
	t.set_stylebox("panel", "PanelContainer", _box(Color("12232d"), Color("2d424a"), 14, 14))
	t.set_stylebox("panel", "PopupMenu", _box(Color("162c36"), Color("4b6b70"), 8, 12))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	theme = t

func _box(bg: Color, border: Color, radius = 12, padding = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

func _label(value: String, font_size = 20, color = INK) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _wrap_label(value: String, font_size = 20, color = INK) -> Label:
	var l = _label(value, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _button(value: String, callback: Callable, width = 0) -> Button:
	var b = Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(width, 48)
	b.pressed.connect(callback)
	return b

func _margin(parent: Node, margin = 20) -> MarginContainer:
	var m = MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin)
	parent.add_child(m)
	return m

func _build_menu():
	menu_ui = Control.new()
	menu_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_ui)
	menu_outer = _margin(menu_ui, 16)
	var scroll = ScrollScript.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_outer.add_child(scroll)
	var main = VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(main)
	var title_row = HBoxContainer.new()
	main.add_child(title_row)
	var title = _label("Карманная арена", 32, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	title_row.add_child(_label("UNMATCHED / 0.38 / OFFLINE", 17, TEAL))
	var catalog_row = HBoxContainer.new()
	main.add_child(catalog_row)
	var names: Array = []
	for box in sets: names.append(str(box.name))
	set_option = _option(catalog_row,"Набор",names)
	for i in range(sets.size()):
		if str(sets[i].id) == chosen_set: set_option.select(i)
	set_option.item_selected.connect(_set_changed)
	language_option = _option(catalog_row,"Язык",["Русский","English","Norsk (bokmål)","Español"])
	language_option.select(["ru","en","nb","es"].find(I18n.language))
	language_option.item_selected.connect(_language_changed)
	main.add_child(_button("Условия Дэдпула",_show_deadpool_setup,230))
	main.add_child(_label("ТВОЙ ГЕРОЙ · нажми для полной способности", 15, MUTED))
	hero_row = HBoxContainer.new()
	main.add_child(hero_row)
	hero_buttons.clear()
	opponent_options.clear()
	opponent_labels.clear()
	_render_hero_cards()
	var options = HBoxContainer.new()
	main.add_child(options)
	count_option = _option(options,"Режим",["1 на 1","Трое: каждый за себя","Четверо: каждый за себя","2 на 2 · союзник-бот"])
	level_option = _option(options,"Навык ботов",["Начинающий","Опытный","Профессионал","Мастер"])
	level_option.select(1)
	map_option = _option(options,"Поле",[])
	map_option.item_selected.connect(_map_changed)
	var map_column = map_option.get_parent()
	var map_label = map_column.get_child(0)
	map_column.remove_child(map_label)
	map_label.queue_free()
	var map_rules_button = Button.new()
	map_rules_button.text = "Поле · правила ⓘ"
	map_rules_button.add_theme_font_size_override("font_size",16)
	map_rules_button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	map_rules_button.pressed.connect(_show_map_rules.bind(false))
	map_column.add_child(map_rules_button)
	map_column.move_child(map_rules_button,0)
	var second = HBoxContainer.new()
	main.add_child(second)
	size_option = _option(second,"Размер Алисы",["Большая","Маленькая"])
	buffy_sidekick_option = _option(second,"Помощник Баффи",["Джайлз","Ксандер"])
	speed_option = _option(second,"Темп ботов",["Обычный","Быстрый"])
	start_slot_option = _option(second,"Твой старт героя",[])
	placement_option = _option(second,"Расстановка помощников",["Выбрать клетки вручную","Автоматически"])
	var opponents = HBoxContainer.new()
	main.add_child(opponents)
	for i in range(3):
		var option = _option(opponents,"Противник %d" % (i+1),["Случайный"])
		option.set_item_metadata(0, "")
		for hero in heroes:
			option.add_item(str(hero.name))
			option.set_item_metadata(option.item_count-1,str(hero.id))
		option.item_selected.connect(_opponent_changed)
		opponent_options.append(option)
		opponent_labels.append(option.get_parent().get_child(0))
	count_option.item_selected.connect(_opponent_changed)
	var actions = HBoxContainer.new()
	main.add_child(actions)
	actions.add_child(_button("Начать игру →", _start_match, 240))
	var resume = _button("Продолжить", _resume_match, 180)
	resume.disabled = not FileAccess.file_exists(SAVE_PATH)
	resume.name = "ResumeButton"
	actions.add_child(resume)
	actions.add_child(_button("Колоды", _show_library, 130))
	actions.add_child(_button("Как играть", _show_help, 150))
	main.add_child(_label("%d героев · %d карт · %d полей · без сети и рекламы" % [heroes.size(),_playable_card_total(),boards.size()],16,MUTED))
	_populate_maps(true)
	_choose_hero(chosen_hero)
	_apply_responsive_layout.call_deferred()
	_localize.call_deferred()

func _render_hero_cards():
	_clear_children(hero_row)
	hero_buttons.clear()
	var subset: Array = []
	for hero in heroes:
		if str(hero.get("set_id","bol1")) == chosen_set: subset.append(hero)
	if not subset.is_empty() and not chosen_hero in subset.map(func(h): return str(h.id)):
		chosen_hero = str(subset[0].id)
	for hero in subset:
		var panel = Button.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.toggle_mode = true
		panel.custom_minimum_size = Vector2(190, 218)
		panel.pressed.connect(_hero_card_pressed.bind(str(hero.id)))
		panel.tooltip_text = str(hero.ability)
		hero_row.add_child(panel)
		var pm = _margin(panel, 12)
		pm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vb = VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pm.add_child(vb)
		var heading = HBoxContainer.new()
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(heading)
		var portrait = _avatar_control(str(hero.id), true, 42)
		heading.add_child(portrait)
		var name_label = _wrap_label(str(hero.name), 24, GOLD)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heading.add_child(name_label)
		var stats = _wrap_label(_hero_stats(hero),17,TEAL)
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(stats)
		var description = _wrap_label(str(hero.ability), 17, MUTED)
		description.max_lines_visible = 3
		description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_child(description)
		var helper = hero.sidekick
		var sub = _label("%s × %d" % [helper.name,int(helper.count)] if int(helper.get("count",0)) > 0 else "Без помощников", 16, INK)
		if str(hero.id) == "buffy": sub.text = "Джайлз или Ксандер"
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(sub)
		hero_buttons.append({"id":str(hero.id),"button":panel})

func _playable_card_total() -> int:
	var total=0
	for hero in heroes:
		for card in hero.cards:
			if card.has("sidekick_variant") and card.sidekick_variant!="giles":continue
			if card.has("gear_slot") and card.gear_option!=geralt_gear.get(str(card.gear_slot),""):continue
			total+=int(card.count)
	return total
func _hero_stats(hero: Dictionary, full = false) -> String:
	var range_name = ("Дальний бой" if hero.ranged else "Ближний бой") if full else ("дальний" if hero.ranged else "ближний")
	var terms={"ru":["ОЗ","шаг"],"en":["HP","move"],"nb":["liv","bevegelse"],"es":["PV","movimiento"]}[I18n.language]
	if int(hero.get("hero_count",1)) > 1:
		return "%d × %d %s · %s %d · %s" % [int(hero.hero_count),int(hero.health),terms[0],terms[1],int(hero.move),I18n.text(range_name)]
	return "%d %s · %s %d · %s" % [int(hero.health),terms[0],terms[1],int(hero.move),I18n.text(range_name)]
func _option(parent: Node, title: String, values: Array) -> OptionButton:
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(vb)
	vb.add_child(_label(title, 16, MUTED))
	var option = OptionButton.new()
	option.custom_minimum_size.y = 42
	option.add_theme_font_size_override("font_size", 18)
	option.add_theme_stylebox_override("normal", _box(Color("1b303b"), Color("3b5159"), 8, 8))
	for value in values:
		option.add_item(value)
	vb.add_child(option)
	return option

func _choose_hero(id: String):
	chosen_hero = id
	for entry in hero_buttons:
		entry.button.set_pressed_no_signal(entry.id == id)
		entry.button.add_theme_stylebox_override("normal", _box(Color("20433f") if entry.id == id else Color("152a35"), TEAL if entry.id == id else Color("354b56"), 14, 12))
	if size_option != null:
		size_option.disabled = id != "alice"
	if buffy_sidekick_option != null:
		buffy_sidekick_option.disabled = id != "buffy"
	_update_opponents()

func _opponent_changed(_index: int):
	_update_opponents()
	_populate_maps()
	_localize.call_deferred()

func _set_changed(index: int):
	chosen_set = str(sets[index].id)
	_render_hero_cards()
	_choose_hero(chosen_hero)
	_populate_maps(true)
	_save_ui_settings()
	_localize.call_deferred()

func _language_changed(index: int):
	I18n.set_language(["ru","en","nb","es"][index])
	_save_ui_settings()
	_localize()
	if started: board.queue_redraw()

func _save_ui_settings():
	var config = ConfigFile.new()
	config.set_value("ui","language",I18n.language)
	config.set_value("ui","set",chosen_set)
	config.save("user://settings.cfg")

func _localize():
	I18n.translate_tree(self)

func _populate_maps(prefer_set = false):
	if map_option == null or count_option == null: return
	var old = str(map_option.get_selected_metadata()) if map_option.item_count else ""
	var total = 4 if count_option.selected == 3 else count_option.selected+2
	map_option.clear()
	var chosen = 0
	for b in boards:
		if int(b.get("max_players",b.starts.size())) < total: continue
		map_option.add_item(str(b.name))
		var index = map_option.item_count-1
		map_option.set_item_metadata(index,str(b.id))
		if str(b.id) == old: chosen = index
		if prefer_set and str(b.get("set_id","bol1")) == chosen_set:
			chosen = index
			prefer_set = false
	if map_option.item_count: map_option.select(chosen)
	_map_changed(0)

func _selected_map() -> Dictionary:
	var id = str(map_option.get_selected_metadata()) if map_option.item_count else "training"
	for b in boards:
		if str(b.id) == id: return b
	return {"id":"training","starts":[0,4,24,20]}

func _map_changed(_index: int):
	if start_slot_option == null: return
	var old = start_slot_option.selected
	var count = _selected_map().starts.size()
	start_slot_option.clear()
	for i in range(count): start_slot_option.add_item("Позиция %d" % (i+1))
	start_slot_option.select(clampi(old,0,maxi(0,count-1)))
	map_option.tooltip_text = str(_selected_map().get("rules_text",""))
	_localize.call_deferred()

func _show_map_rules(in_game = true):
	var data = engine.board_data if in_game and started else _selected_map()
	_show_text("Правила поля · %s" % str(data.get("name","Учебная арена")),str(data.get("rules_text","Особых правил поля нет. Связанные линией клетки соседствуют; одинаковые цвета образуют зоны.")))

func _hero_card_pressed(id: String):
	_choose_hero(id)
	_show_hero_info(id)

func _show_hero_info(id: String):
	var hero = _hero_data(id)
	var main = _popup(str(hero.name) + " · правила героя")
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(row)
	row.add_child(_avatar_control(id,true,170))
	var scroll = ScrollScript.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var text = _hero_stats(hero,true) + "\n\n" + str(hero.ability)
	if not str(hero.get("quote","")).is_empty():text+="\n\n“"+I18n.hero_field(id,"quote",str(hero.quote))+"”"
	if int(hero.sidekick.get("count",0)) > 0:
		var variants: Dictionary = hero.get("sidekick_variants",{})
		if not variants.is_empty():
			text += "\n\nВыбери одного помощника перед партией. В колоде будут 25 общих карт и 5 карт выбранного помощника."
			for helper in variants.values():
				text += "\n\n%s × %d · %d ОЗ\n%s" % [helper.name,int(helper.count),int(helper.health),"Дальний бой" if helper.ranged else "Ближний бой"]
		else:
			text += "\n\n%s × %d · %d ОЗ\n%s" % [hero.sidekick.name,int(hero.sidekick.count),int(hero.sidekick.health),"Дальний бой" if hero.sidekick.ranged else "Ближний бой"]
	else:
		text += "\n\nБез помощников"
	scroll.add_child(_wrap_label(text,26,INK))
	_localize.call_deferred()
	if id=="pandora":main.add_child(_button("Все карты ящика Пандоры",_show_misery_reference,320))
	if id=="yennefer_triss" and not started:main.add_child(_button("Выбрать главную героиню",_show_sorceress_choice,320))
	if id=="geralt_of_rivia" and not started: main.add_child(_button("Выбрать снаряжение Геральта",_show_geralt_gear,320))

func _update_opponents():
	if count_option == null or opponent_options.is_empty():
		return
	var total = 4 if count_option.selected == 3 else count_option.selected + 2
	for i in range(opponent_options.size()):
		var option = opponent_options[i]
		option.get_parent().visible = i < total - 1
		if str(option.get_selected_metadata()) == chosen_hero:
			option.select(0)
		var label = "Противник %d" % (i + 1)
		if count_option.selected == 3:
			label = ["Противник 1", "Твой союзник-бот", "Противник 2"][i]
		opponent_labels[i].text = label
	for i in range(opponent_options.size()):
		var used: Array = [chosen_hero]
		for j in range(total-1):
			if i != j:
				used.append(str(opponent_options[j].get_selected_metadata()))
		var option = opponent_options[i]
		for index in range(1, option.item_count):
			option.get_popup().set_item_disabled(index, str(option.get_item_metadata(index)) in used)

func _avatar_control(hero_id: String, hero: bool, pixels: int) -> TextureRect:
	var image = TextureRect.new()
	image.custom_minimum_size = Vector2(pixels,pixels)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var entry = avatars.get(hero_id, {}).get("hero" if hero else "sidekick", {})
	if hero_id=="yennefer_triss":
		var main_choice=sorceress_hero
		if started:
			for player in engine.players:
				if player.hero_id==hero_id:main_choice=engine._v17.main_for(int(engine.players.find(player)))
		if main_choice=="triss":entry=avatars[hero_id]["sidekick" if hero else "hero"]
	if started and hero and hero_id == "jekyll_hyde" and engine.has_method("form_for"):
		for i in range(engine.players.size()):
			if str(engine.players[i].hero_id) == hero_id and engine.form_for(i) == "hyde":
				entry = avatars.get(hero_id,{}).get("hero_hyde",entry)
	if hero_id == "buffy" and not hero:
		var variant = "xander" if is_instance_valid(buffy_sidekick_option) and buffy_sidekick_option.selected == 1 else "giles"
		if started:
			for player in engine.players:
				if str(player.hero_id) == hero_id: variant = str(player.get("buffy_sidekick","giles"))
		if variant == "xander": entry = avatars.get(hero_id,{}).get("sidekick_xander",entry)
	if started and hero and hero_id == "willow" and engine.has_method("willow_form_for"):
		for i in range(engine.players.size()):
			if str(engine.players[i].hero_id) == hero_id and engine.willow_form_for(i) == "dark":
				entry = avatars.get(hero_id,{}).get("hero_dark",entry)
	var path = str(entry.get("path_ru",entry.get("path",""))) if I18n.language=="ru" else str(entry.get("path",""))
	if path != "" and ResourceLoader.exists(path):
		var texture = load(path)
		var region = entry.get("region", [])
		if region.size() == 4:
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(float(region[0]),float(region[1]),float(region[2]),float(region[3]))
			image.texture = atlas
		else:
			image.texture = texture
	return image

func _apply_responsive_layout():
	var logical = get_viewport_rect().size
	var insets = Vector4(8,8,8,8)
	if OS.has_feature("android"):
		var safe = DisplayServer.get_display_safe_area()
		var window_pixels = Vector2(DisplayServer.window_get_size())
		if window_pixels.x > 0 and window_pixels.y > 0 and safe.size.x > 0 and safe.size.y > 0:
			var scale = logical / window_pixels
			insets.x = maxf(8,float(safe.position.x)*scale.x)
			insets.y = maxf(8,float(safe.position.y)*scale.y)
			insets.z = maxf(8,(window_pixels.x-float(safe.end.x))*scale.x)
			insets.w = maxf(8,(window_pixels.y-float(safe.end.y))*scale.y)
	for outer in [game_outer, menu_outer, popup_outer]:
		if is_instance_valid(outer):
			var padding = 20 if outer == popup_outer else 8
			outer.add_theme_constant_override("margin_left",maxi(padding,int(insets.x)))
			outer.add_theme_constant_override("margin_top",maxi(padding,int(insets.y)))
			outer.add_theme_constant_override("margin_right",maxi(padding,int(insets.z)))
			outer.add_theme_constant_override("margin_bottom",maxi(padding,int(insets.w)))
	if not is_instance_valid(sidebar_panel):
		return
	sidebar_panel.custom_minimum_size.x = clampf(logical.x * 0.225, 274, 330)
	var height = clampf(logical.y * 0.35, 166, 220)
	hand_scroll.custom_minimum_size.y = height
	_hand_card_size = Vector2(roundf((height-18)*0.70),height-18)
	for child in hand_box.get_children():
		child.custom_minimum_size = _hand_card_size

func _toggle_hand():
	hand_collapsed = not hand_collapsed
	_update_hand_visibility(str(engine.phase))

func _update_hand_visibility(phase: String):
	var expanded_map = phase in ["setup","effect_move"]
	var previous_expanded = _layout_phase in ["setup","effect_move"]
	if expanded_map and not previous_expanded:
		_saved_hand_collapsed = hand_collapsed
		hand_collapsed = true
	elif not expanded_map and previous_expanded:
		hand_collapsed = _saved_hand_collapsed
	_layout_phase = phase
	hand_section.visible = not hand_collapsed and phase != "setup" and not engine.players[0].hand.is_empty()
	hand_toggle_button.visible = phase != "setup"
	hand_toggle_button.text = "Рука ▴" if hand_collapsed else "Рука ▾"

func _winner_text() -> String:
	if engine.match_mode == "teams":
		return "Ваша команда победила!" if engine.are_allies(engine.winner,0) else "Победила команда соперников"
	return "Победитель — %s" % str(engine.players[engine.winner].name)

func _start_match():
	var ids: Array = [chosen_hero]
	var count = 4 if count_option.selected == 3 else count_option.selected + 2
	var requested: Array = []
	for i in range(count - 1):
		var value = str(opponent_options[i].get_selected_metadata())
		if value != "" and value in ids:
			_show_text("Выбор героев", "Каждый герой может участвовать в партии один раз.")
			return
		if value != "": ids.append(value)
		requested.append(value)
	var available: Array = []
	for hero in heroes:
		if not str(hero.id) in ids: available.append(str(hero.id))
	available.shuffle()
	ids = [chosen_hero]
	for value in requested:
		ids.append(available.pop_back() if value == "" else value)
	var own_slot = start_slot_option.selected
	var slots: Array = []
	var map_data = _selected_map()
	for i in range(count): slots.append((own_slot+i)%map_data.starts.size())
	var config = {"mode":"teams" if count_option.selected == 3 else "ffa", "start_slots":slots, "human_placement":placement_option.selected == 0}
	config.buffy_sidekick = "xander" if buffy_sidekick_option.selected == 1 else "giles"
	config.sorceress_hero=sorceress_hero
	config.geralt_gear=geralt_gear.duplicate(true)
	config.deadpool_conditions=deadpool_conditions.duplicate(true)
	config.real_names=player_real_names.duplicate(true)
	started = false
	var map_id = str(map_data.id)
	engine.interactive = true
	engine.setup(ids, level_option.selected, 0, map_id, config)
	engine.interactive = true
	if chosen_hero == "alice":
		engine.alice_size[0] = "big" if size_option.selected == 0 else "small"
	bot_delay = 0.3 if speed_option.selected == 1 else 0.75
	bot_timer.wait_time = bot_delay
	_open_match()

func _resume_match():
	started = false
	var state = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not state is Dictionary or not engine.load_state(state):
		_show_text("Сохранение не прочитано", "Начни новую игру. Формат сохранения мог измениться после обновления.")
		return
	engine.interactive = true
	_open_match()

func _open_match():
	menu_ui.hide()
	if game_ui != null:
		game_ui.get_parent().queue_free()
	selected_card = -1
	selected_fighter = _human_hero()
	attack_mode = false
	boost_card = -1
	result_shown = false
	hand_collapsed = false
	_layout_phase = ""
	_hand_signature = ""
	_detail_signature = ""
	_modal_key = ""
	_build_game()
	started = true
	_refresh()

func _build_game():
	game_outer = _margin(self, 8)
	game_ui = VBoxContainer.new()
	game_ui.add_theme_constant_override("separation",6)
	game_outer.add_child(game_ui)
	var header = HBoxContainer.new()
	game_ui.add_child(header)
	header.add_child(_label("АРЕНА / 0.38", 19, GOLD))
	status_label = _label("", 19, TEAL)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(status_label)
	header.add_child(_button("Сбросы",_show_discards,95))
	header.add_child(_button("Журнал", _show_log, 105))
	hand_toggle_button = _button("Рука ▾",_toggle_hand,88)
	header.add_child(hand_toggle_button)
	header.add_child(_button("Поле ⤢", _show_board_zoom, 95))
	header.add_child(_button("?", _show_help, 48))
	header.add_child(_button("Меню", _return_menu, 90))
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_ui.add_child(body)
	left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation",5)
	body.add_child(left_column)
	board = BoardScript.new()
	board.engine = engine
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.node_pressed.connect(_on_node)
	board.item_pressed.connect(_zoom_board_item)
	left_column.add_child(board)
	hud_left = VBoxContainer.new()
	hud_right = VBoxContainer.new()
	board.add_child(hud_left)
	player_box = hud_left
	board.add_child(hud_right)
	board.resized.connect(_position_huds)
	hand_section = VBoxContainer.new()
	hand_section.add_theme_constant_override("separation",3)
	left_column.add_child(hand_section)
	var hand_header = HBoxContainer.new()
	hand_section.add_child(hand_header)
	var hand_title = _label("ТВОЯ РУКА · листай в стороны", 14, TEAL)
	hand_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_header.add_child(hand_title)
	hand_header.add_child(_label("Нажми карту → описание справа",14,MUTED))
	hand_scroll = ScrollContainer.new()
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_section.add_child(hand_scroll)
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation",6)
	hand_scroll.add_child(hand_box)
	sidebar_panel = PanelContainer.new()
	sidebar_panel.custom_minimum_size.x = 282
	body.add_child(sidebar_panel)
	var detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation",6)
	sidebar_panel.add_child(detail)
	detail_title = _wrap_label("Выбери бойца",23,GOLD)
	detail.add_child(detail_title)
	state_label = _wrap_label("",16,TEAL)
	detail.add_child(state_label)
	detail_scroll = ScrollScript.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail.add_child(detail_scroll)
	detail_text = _wrap_label("",19,INK)
	detail_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_scroll.add_child(detail_text)
	hint_label = _wrap_label("",16,MUTED)
	detail.add_child(hint_label)
	zoom_button = _button("Карта крупно ⤢",_zoom_selected)
	detail.add_child(zoom_button)
	maneuver_button = _button("Манёвр · взять карту",_begin_move)
	detail.add_child(maneuver_button)
	boost_button = _button("BOOST: выбранная карта",_toggle_boost)
	detail.add_child(boost_button)
	play_button = _button("Разыграть карту",_play_selected)
	detail.add_child(play_button)
	move_finish_button = _button("Завершить перемещение",_finish_move)
	detail.add_child(move_finish_button)
	doors_button = _button("Двери Хеорота",_show_doors)
	detail.add_child(doors_button)
	items_button=_button("Предметы поля",_show_board_items)
	detail.add_child(items_button)
	_apply_responsive_layout()
	_position_huds.call_deferred()

func _refresh():
	if not started or game_ui == null:
		return
	if selected_fighter < 0 or selected_fighter >= engine.fighters.size() or not engine.fighters[selected_fighter].alive:
		selected_fighter = _human_hero()
	var hand: Array = engine.players[0].hand
	if selected_card >= hand.size():
		selected_card = -1
	if boost_card >= hand.size():
		boost_card = -1
	var your_turn = engine.active == 0 and engine.winner < 0
	var phase = str(engine.phase)
	if not your_turn or phase != "action":
		attack_mode = false
	if phase != "action":
		boost_card = -1
	var current = engine.players[engine.active]
	status_label.text = "%s · %s" % [current.name, "защита" if phase == "defend" else "%s действия" % engine.actions_left]
	if engine.winner >= 0:
		status_label.text = _winner_text()
	if phase == "setup":
		status_label.text = "Расстановка своих бойцов"
	_refresh_player_buttons()
	items_button.visible=not engine.battlefield_items.is_empty()
	doors_button.visible = not engine.door_states.is_empty()
	doors_button.disabled = engine.phase != "move" or engine.active != 0
	_update_hand_visibility(phase)
	_build_hand(hand, phase)
	board.selected = selected_fighter
	board.highlighted = engine.legal_moves(selected_fighter) if phase == "move" and your_turn else []
	board.targets = []
	if phase == "setup":
		selected_fighter = engine.setup_fighter
		board.selected = engine.setup_fighter
		board.highlighted = engine.legal_setup_nodes(engine.setup_fighter) if engine.setup_fighter >= 0 else []
	if phase == "effect_move":
		board.highlighted = engine.pending_choice.get("legal", [])
		if str(engine.pending_choice.get("kind", "")) == "spaces":
			board.targets = engine.pending_choice.get("selected_spaces", []).duplicate()
		var effect_fighter = int(engine.pending_choice.get("fighter", -1))
		if effect_fighter >= 0:
			board.selected = effect_fighter
		for fighter_id in engine.pending_choice.get("allowed_fighters", []):
			if int(fighter_id) >= 0 and int(fighter_id) < engine.fighters.size():
				board.targets.append(engine.fighters[int(fighter_id)].node)
	if attack_mode and selected_card >= 0:
		for id in engine.legal_targets(selected_fighter, selected_card):
			board.targets.append(engine.fighters[id].node)
	board.queue_redraw()
	if is_instance_valid(enlarged_board):
		enlarged_board.selected = board.selected
		enlarged_board.highlighted = board.highlighted
		enlarged_board.targets = board.targets
		enlarged_board.queue_redraw()
	maneuver_button.visible = phase in ["action", "move"]
	maneuver_button.disabled = not your_turn or phase != "action"or engine.actions_left<=0
	maneuver_button.text = "Манёвр · взять карту" if boost_card < 0 else "Манёвр + BOOST %s" % CardScript.boost_label(hand[boost_card])
	boost_button.visible = your_turn and phase in ["action","move"]
	var boost_allowed = selected_card >= 0 and engine.can_boost_card(hand[selected_card])
	boost_button.disabled = not boost_allowed and boost_card < 0
	boost_button.text = "BOOST: отменить" if boost_card >= 0 else "BOOST: выбранная карта"
	if selected_card >= 0 and not boost_allowed and boost_card < 0: boost_button.text = "У карты нет BOOST"
	if phase == "move":
		boost_button.disabled = not boost_allowed or engine.maneuver_boosted or not engine.maneuver_moved.is_empty()
		boost_button.text = "Манёвр уже усилен" if engine.maneuver_boosted else "Усилить манёвр · BOOST"
	move_finish_button.visible = (your_turn and phase == "move") or phase == "effect_move"or(your_turn and phase=="action"and engine._v34.has_free(engine.active))
	move_finish_button.text = "Остаться / завершить" if phase == "effect_move" else "Завершить перемещение"
	if phase == "effect_move" and str(engine.pending_choice.get("action","")) == "place_traps":
		move_finish_button.text = "Завершить ловушки"
	move_finish_button.disabled = phase == "effect_move" and not engine.pending_choice.get("can_skip", false)
	if your_turn and phase=="action"and engine._v34.has_free(engine.active):move_finish_button.text="Пропустить бесплатную атаку"
	if phase == "setup":
		move_finish_button.visible = true
		move_finish_button.text = "Начать бой →"
		move_finish_button.disabled = engine.setup_fighter >= 0
	play_button.visible = phase in ["action","defend","discard"]
	play_button.disabled = selected_card < 0 or (not your_turn and phase != "defend")
	if selected_card>=0 and phase=="action" and not engine._v31.mission_allowed(0,hand[selected_card]):play_button.disabled=true
	if phase == "defend":
		play_button.text = "Защититься картой" if selected_card >= 0 else "Пропустить защиту"
		play_button.disabled = selected_card >= 0 and not engine.legal_defenses().has(selected_card)
	elif phase == "discard":
		play_button.text = "Сбросить выбранную"
	else:
		play_button.text = "Выбрать цель атаки" if selected_card >= 0 and hand[selected_card].type != "scheme" else "Разыграть приём"
		if selected_card>=0 and phase=="action"and engine.actions_left<=0 and hand[selected_card].type=="scheme":play_button.disabled=true
		if selected_card >= 0 and hand[selected_card].type == "defense":
			play_button.text = "Только для защиты"
			play_button.disabled = true
	_update_detail()
	var state_owner = int(engine.fighters[selected_fighter].owner) if selected_fighter >= 0 else 0
	state_label.text = engine.state_summary(state_owner)
	state_label.visible = state_label.text != ""
	zoom_button.visible = selected_card >= 0
	if engine.winner >= 0:
		hint_label.text = "Игра завершена. Новую партию можно начать из меню."
	elif phase == "defend":
		var attacker = engine.fighters[engine.pending_combat.attacker]
		var target = engine.fighters[engine.pending_combat.target]
		hint_label.text = "%s атакует: %s. Выбери защиту или пропусти её." % [attacker.name, target.name]
	elif phase == "setup":
		hint_label.text = "Нажми подсвеченную клетку, чтобы поставить бойца." if engine.setup_fighter >= 0 else "Все твои бойцы расставлены. Нажми «Начать бой»."
	elif phase == "discard":
		hint_label.text = "Лимит руки — %d. Выбери и сбрось %d карт(ы)." % [engine._v33.limit(engine.active),hand.size() - engine._v33.limit(engine.active)]
	elif phase=="action"and engine._v34.has_free(engine.active):
		hint_label.text="Бесплатная атака: используйте следующим действием или пропустите её."
	elif phase == "effect_move":
		hint_label.text = str(engine.pending_choice.get("prompt", "Выбери бойца и подсвеченную клетку для эффекта карты."))
	elif phase == "effect_choice":
		hint_label.text = "Выбери вариант эффекта карты в окне."
	elif phase in ["attack_notice", "combat_report"]:
		hint_label.text = "Игра приостановлена. Прочитай уведомление и нажми «Далее»."
	elif not your_turn:
		hint_label.text = "Бот обдумывает ход… Твоя рука остаётся скрыта от него."
	elif phase == "move":
		hint_label.text = "Перемести своих бойцов: выбери фигуру → подсвеченный круг. Затем заверши манёвр."
	elif attack_mode:
		hint_label.text = "Нажми на подсвеченного противника. Повторный выбор карты отменяет атаку."
	elif toast != "":
		hint_label.text = toast
	else:
		hint_label.text = "Выбери своего бойца на поле. Манёвр берёт карту; атака и приём расходуют действие."
	_save_match()
	_localize()
	if not _interaction_scheduled:
		_interaction_scheduled = true
		_sync_interaction.call_deferred()

func _build_hand(hand: Array, phase: String):
	var signature = "%s:%s:%s:" % [selected_card, boost_card, phase]
	for c in hand:
		signature += str(c.id) + ";"
	if signature == _hand_signature:
		return
	_hand_signature = signature
	var offset = hand_scroll.scroll_horizontal
	_clear_children(hand_box)
	for i in range(hand.size()):
		var card = CardScript.new()
		card.set_card(hand[i], str(engine.players[0].hero_id))
		card.custom_minimum_size = _hand_card_size
		card.toggle_mode = true
		card.set_pressed_no_signal(i == selected_card)
		card.pressed.connect(_select_card.bind(i))
		if i == boost_card:
			card.tooltip_text += "\nВыбрана для BOOST"
		hand_box.add_child(card)
	hand_scroll.set_deferred("scroll_horizontal", offset)

func _refresh_player_buttons():
	_clear_children(hud_left)
	_clear_children(hud_right)
	for i in range(engine.players.size()):
		var p = engine.players[i]
		var hero = _fighter_for_player(i)
		var allied = engine.match_mode == "teams" and i != 0 and engine.are_allies(i,0)
		var button = Button.new()
		button.custom_minimum_size = Vector2(0,112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "%s · Рука %d · колода %d · сброс %d\n%s" % [p.name,p.hand.size(),p.deck.size(),p.discard.size(),engine.state_summary(i)]
		button.add_theme_stylebox_override("normal",_box(Color("203b40") if i == engine.active else Color("142630"),TEAL if i == engine.active else Color("70a27f") if allied else Color("3d4f59"),8,4))
		button.pressed.connect(_show_player_info.bind(i))
		(hud_left if i%2 == 0 else hud_right).add_child(button)
		var margin = _margin(button,6)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var content = VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation",3)
		margin.add_child(content)
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation",4)
		content.add_child(row)
		row.add_child(_avatar_control(str(p.hero_id),true,30))
		var label = _wrap_label(str(p.name),12 if str(p.hero_id) == "invisible_man" else 14,TEAL if i == 0 else INK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		var role = "ТЫ" if i == 0 else "СОЮЗНИК" if allied else ""
		var healths = PackedStringArray()
		for f in engine.fighters:
			if int(f.owner) == i and f.hero: healths.append(str(maxi(0,int(f.hp))))
		var info = "%s %s ОЗ\nР %d · К %d · С %d" % [role," / ".join(healths),p.hand.size(),p.deck.size(),p.discard.size()]
		if str(p.hero_id) == "ingen" and engine.has_method("trap_supply"):
			info += "\nЛовушки: %d" % engine.trap_supply(i)
		if not p.alive: info = "Выбыл\nСброс %d карт" % p.discard.size()
		var stats = _wrap_label(info,13,Color("b5c7ca"))
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(stats)
	_position_huds.call_deferred()

func _position_huds():
	if not is_instance_valid(board) or not is_instance_valid(hud_left): return
	var width = clampf(board.size.x*0.22,120,170)
	board.content_insets = Vector2(width+10,width+10)
	hud_left.position = Vector2(6,8)
	hud_right.position = Vector2(board.size.x-width-6,8)
	hud_left.size = Vector2(width,board.size.y-16)
	hud_right.size = Vector2(width,board.size.y-16)
	board.queue_redraw()

func _update_detail():
	var hand: Array = engine.players[0].hand
	var signature = "%s:%s:%s" % [selected_card, selected_fighter, engine.phase]
	if signature != _detail_signature:
		detail_scroll.scroll_vertical = 0
		_detail_signature = signature
	if engine.phase == "setup":
		if engine.setup_fighter >= 0:
			var f = engine.fighters[engine.setup_fighter]
			detail_title.text = "Поставь: " + str(f.name)
			var first_hero = int(f.id) == int(engine.hero_fighter(0))
			detail_text.text = "Герой начинает на выбранной в меню стартовой позиции. Нажми подсвеченный круг." if f.hero and first_hero else "Выбери любую свободную клетку в зоне твоего героя. Подходящие клетки подсвечены."
		else:
			detail_title.text = "Готово к бою"
			detail_text.text = "Позиции героя и помощников выбраны. Нажми «Начать бой», чтобы взять управление первым ходом."
	elif engine.phase == "effect_move":
		detail_title.text = str(engine.pending_choice.get("title", "Перемещение по эффекту"))
		detail_text.text = str(engine.pending_choice.get("prompt", "Выбери бойца и клетку на поле."))
		if str(engine.pending_choice.get("action","")) == "place_traps":
			detail_text.text += "\n\nМожно завершить размещение раньше. Неиспользованные жетоны остаются в запасе."
		elif str(engine.pending_choice.get("_effect", {}).get("kind", "")) == "restless_spirits":
			detail_text.text += "\n\nВыбери две соседние клетки. Каждый враг на этих клетках получит 2 урона."
		elif engine.pending_choice.get("can_skip", false):
			detail_text.text += "\n\nПодсвеченные клетки доступны для эффекта. Чтобы пропустить необязательное перемещение, нажми «Остаться / завершить»."
	elif selected_card >= 0 and selected_card < hand.size():
		var c = hand[selected_card]
		detail_title.text = str(c.name)
		detail_text.text = "%s · сила %s\n%s · BOOST %s\n\n%s" % [_type_name(c.type),int(c.value),_card_fighter_name(c),CardScript.boost_label(c),I18n.card_field(str(engine.players[0].hero_id),str(c.id),"text",str(c.text))]
		if engine._is_hero(0,"black_widow") and c.type=="scheme":detail_text.text += "\n\n"+("Условие миссии выполнено"if engine._v31.mission_allowed(0,c)else"Условие миссии ещё не выполнено")
		if str(engine.players[0].hero_id) == "little_red":
			detail_text.text += "\n\n" + engine.basket_description(0) + "\n" + "Символ этой карты: %s" % CardScript.basket_label(c)
		if boost_card == selected_card:
			detail_text.text += "\n\nЭта карта выбрана для BOOST и будет сброшена при манёвре."
		if engine.phase == "defend" and not engine.legal_defenses().has(selected_card):
			detail_text.text += "\n\nЭта карта не подходит для защиты атакованного бойца."
	elif selected_fighter >= 0:
		var f = engine.fighters[selected_fighter]
		detail_title.text = str(f.name)
		var data = _hero_data(engine.players[f.owner].hero_id)
		if str(data.get("id","")) == "jekyll_hyde" and f.hero and engine.has_method("form_for"):
			detail_title.text = "Мистер Хайд" if engine.form_for(int(f.owner)) == "hyde" else "Доктор Джекилл"
		if str(data.get("id","")) == "willow" and f.hero and engine.has_method("willow_form_for"):
			detail_title.text = "Тёмная Уиллоу" if engine.willow_form_for(int(f.owner)) == "dark" else str(f.name)
		var range_name = "Дальний бой" if f.ranged else "Ближний бой"
		if str(data.get("id","")) == "muhammad_ali" and engine.has_method("stance_for") and engine.stance_for(int(f.owner)) == "butterfly": range_name = "Атака на 2 клетки"
		detail_text.text = "%s / %s ОЗ\n%s\n\n%s" % [int(f.hp), int(f.max_hp),range_name,data.get("ability", "")]
		if str(data.get("id", "")) == "alice":
			detail_text.text += "\n\nРазмер: " + ("большая" if engine.alice_size.get(f.owner, "big") == "big" else "маленькая")
		if str(data.get("id", "")) == "sinbad":
			detail_text.text += "\n\nПутешествий в сбросе: " + str(int(engine.players[f.owner].get("voyages", 0)))
		if str(data.get("id","")) in ["blackbeard","loki","chupacabra","pandora","black_panther","black_widow","squirrel_girl","deadpool","little_red","beowulf","genie","achilles","bloody_mary","sun_wukong","yennenga","nikola_tesla","dr_jill_trent","annie_christmas","golden_bat"]:
			detail_text.text += "\n\n" + engine.state_summary(int(f.owner))
	else:
		detail_title.text = "Выбери карту"
		detail_text.text = "Нажми на карту в руке, чтобы прочитать её эффект."

func _select_card(index: int):
	selected_card = index if selected_card != index else -1
	if selected_card >= 0 and engine.phase == "action":
		_ensure_card_fighter(engine.players[0].hand[selected_card])
	attack_mode = false
	_refresh()

func _ensure_card_fighter(card: Dictionary) -> bool:
	var candidates: Array = []
	for f in engine.fighters:
		if int(f.owner) != 0 or not f.alive or not f.get("placed",true): continue
		if not engine.can_use_card(card,int(f.id)): continue
		candidates.append(int(f.id))
	if selected_fighter in candidates: return true
	if candidates.size() == 1:
		selected_fighter = int(candidates[0])
		return true
	toast = "У этой карты нет подходящего бойца." if candidates.is_empty() else "Для этой карты выбери подходящего бойца на поле."
	if candidates.is_empty() and str(card.get("fighter","")) in ["jekyll","hyde"]:
		toast = "Эта карта требует формы Джекилла." if str(card.fighter) == "jekyll" else "Эта карта требует формы Хайда."
	return false

func _begin_move():
	attack_mode = false
	var boost = boost_card
	boost_card = -1
	selected_card = -1
	toast = ""
	if not engine.begin_maneuver(boost):
		toast = "Сейчас нельзя выполнить манёвр."
	_refresh()

func _show_board_items():
	var main=_popup("Предметы поля")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	body.add_child(_wrap_label("Выберите своего бойца на клетке предмета. Предмет-действие расходует 1 действие. Боевой предмет предлагается при атаке или защите до раскрытия карт.",19,INK))
	for i in range(engine.battlefield_items.size()):
		var token=engine.battlefield_items[i];var d=engine._v24.definition(token)
		var box=VBoxContainer.new();body.add_child(box)
		box.add_child(_wrap_label("%s · клетка %d"%[I18n.text(str(d.name)),int(token.node)+1],23,GOLD))
		box.add_child(_wrap_label(I18n.text(str(d.text)),20,INK))
		if token.used:box.add_child(_wrap_label("Использован",18,MUTED))
		else:
			var use=_button("Использовать предмет",_use_board_item.bind(i));use.disabled=engine.phase!="action" or engine.active!=0 or not engine._v24.at(selected_fighter,"scheme").has(i);box.add_child(use)
		box.add_child(_button("Посмотреть жетон",_zoom_board_item.bind(i)))
func _use_board_item(index: int):
	_clear_popup();attack_mode=false;selected_card=-1;boost_card=-1;engine._v24.use(selected_fighter,index);_refresh()
func _zoom_board_item(index: int):
	var d=engine._v24.definition(engine.battlefield_items[index]);var main=_popup(I18n.text(str(d.name)))
	var image=TextureRect.new();image.texture=load(str(d.image));image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.custom_minimum_size=Vector2(120,120);main.add_child(image)
	main.add_child(_wrap_label(I18n.text(str(d.text)),22,INK));main.add_child(_button("Предметы поля",_show_board_items))

func _show_doors():
	var main = _popup("Двери Хеорота")
	main.add_child(_wrap_label("Выберите своего бойца на поле. Закрытие соседней двери бесплатно, открытие расходует 1 клетку его перемещения. Двери меняются только во время манёвра.",19,INK))
	for node in engine.legal_friendly_transits(selected_fighter):
		main.add_child(_button("Пройти через союзника: клетка %d"%(int(node)+1),_enter_friendly_transit.bind(int(node))))
	for i in range(engine.door_states.size()):
		var text = "Дверь %d · %s" % [i+1,"открыть за 1 перемещение" if bool(engine.door_states[i]) else "закрыть бесплатно"]
		var b = _button(text,_toggle_door.bind(i))
		b.disabled = engine.phase != "move" or engine.active != 0 or not engine._v8.door_adjacent(selected_fighter,i)
		main.add_child(b)

func _enter_friendly_transit(node: int):
	_clear_popup();engine.enter_friendly_transit(selected_fighter,node);_refresh();_show_doors()

func _toggle_door(index: int):
	_clear_popup()
	if not engine.toggle_door(selected_fighter,index): toast = "Не хватает перемещения или выбранный боец не рядом с дверью."
	_refresh()

func _toggle_boost():
	if boost_card < 0 and (selected_card < 0 or not engine.can_boost_card(engine.players[0].hand[selected_card])):
		return
	if engine.phase == "move":
		if selected_card >= 0 and engine.boost_maneuver(selected_card):
			selected_card = -1
		_refresh()
		return
	boost_card = selected_card if boost_card < 0 else -1
	attack_mode = false
	_refresh()

func _finish_move():
	if engine.phase=="action"and engine._v34.has_free(engine.active):engine._v34.clear_free(engine.active);engine._after_action()
	elif engine.phase == "setup":
		engine.finish_setup()
	elif engine.phase == "effect_move":
		engine.skip_effect()
	else:
		engine.finish_maneuver()
	selected_card = -1
	toast = ""
	_refresh()

func _play_selected():
	if engine.phase == "defend":
		if not engine.defend(selected_card):
			toast = "Эта карта не подходит для защиты выбранного бойца."
		else:
			selected_card = -1
	elif engine.phase == "discard":
		if selected_card >= 0:
			engine.discard_card(selected_card)
			selected_card = -1
	elif engine.active == 0 and engine.phase == "action" and selected_card >= 0:
		var card = engine.players[0].hand[selected_card]
		if not _ensure_card_fighter(card):
			_refresh()
			return
		if card.type == "scheme":
			if engine.scheme(selected_fighter, selected_card):
				selected_card = -1
				boost_card = -1
				toast = ""
			else:
				toast = "Выбери подходящего бойца для этой карты."
		elif engine._attack_type(card):
			attack_mode = true
			if engine.legal_targets(selected_fighter, selected_card).is_empty():
				attack_mode = false
				toast = "Нет доступной цели. Проверь бойца и дальность."
		else:
			toast = "Карту защиты можно играть только в ответ на атаку."
	_refresh()

func _on_node(node_id: int):
	if popup_hidden: return
	if engine.phase == "game_over":
		return
	if engine.phase == "setup":
		if engine.setup_fighter >= 0:
			engine.place_setup_fighter(engine.setup_fighter,node_id)
		_refresh()
		return
	if engine.phase == "effect_move":
		if node_id in engine.pending_choice.get("legal", []):
			engine.choose_effect_node(node_id)
		else:
			for fid in engine.pending_choice.get("allowed_fighters", []):
				if int(engine.fighters[int(fid)].node) == node_id:
					engine.choose_effect_fighter(int(fid))
					break
		_refresh()
		return
	var group=engine._v31.occupants(node_id)
	if group.size()>1 or (group.size()==1 and engine._v31.small(int(group[0]))):
		_show_space_fighters(group);return
	var occupant=int(group[0]) if not group.is_empty() else -1
	if attack_mode and occupant >= 0 and engine.active == 0:
		if occupant in engine.legal_targets(selected_fighter, selected_card):
			var can_attack_boost = engine.players[0].hero_id == "king_arthur" and engine.fighters[selected_fighter].hero
			var boost = boost_card if can_attack_boost and boost_card != selected_card else -1
			if engine.attack(selected_fighter, occupant, selected_card, boost):
				selected_card = -1
				boost_card = -1
				attack_mode = false
				toast = ""
	elif occupant >= 0 and engine.fighters[occupant].owner == 0:
		selected_fighter = occupant
		toast = ""
	elif engine.phase == "move" and engine.active == 0:
		if engine.move_fighter(selected_fighter, node_id):
			toast = ""
	_refresh()

func _bot_tick():
	if not started or popup_layer != null or engine.winner >= 0:
		return
	if engine.active != 0 and engine.phase in ["action","move","discard"]:
		selected_card = -1
		boost_card = -1
		engine.bot_step()
		_refresh()

func _save_match():
	if not started:
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(engine.save_state()))

func _return_menu():
	_save_match()
	_clear_popup()
	started = false
	if game_ui != null:
		game_ui.get_parent().queue_free()
		game_ui = null
	menu_ui.queue_free()
	_build_menu()

func _human_hero() -> int:
	for f in engine.fighters:
		if f.owner == 0 and f.alive:
			return f.id
	return -1

func _fighter_for_player(owner: int) -> Dictionary:
	for f in engine.fighters:
		if f.owner == owner and f.hero:
			return f
	return {}

func _show_player_info(owner: int):
	if not started or owner < 0 or owner >= engine.players.size(): return
	var player = engine.players[owner]
	var hero = _hero_data(str(player.hero_id))
	var main = _popup("Персонаж · %s" % player.name)
	var scroll = ScrollScript.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	var body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var row = HBoxContainer.new()
	body.add_child(row)
	row.add_child(_avatar_control(str(player.hero_id),true,150))
	var stats = VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stats)
	stats.add_child(_wrap_label(str(player.name),30,GOLD))
	stats.add_child(_wrap_label(_hero_stats(hero,true),22,TEAL))
	var states = engine.state_summary(owner)
	if states != "": stats.add_child(_wrap_label(states,21,TEAL))
	body.add_child(_wrap_label(str(hero.ability),24,INK))
	if not str(hero.get("quote","")).is_empty():body.add_child(_wrap_label("“"+I18n.hero_field(str(player.hero_id),"quote",str(hero.quote))+"”",21,GOLD))
	for fighter in engine.fighters:
		if int(fighter.owner) != owner: continue
		var line = "%s · %d / %d ОЗ" % [fighter.name,maxi(0,int(fighter.hp)),int(fighter.max_hp)]
		if bool(fighter.get("reserve",false)): line += " · в запасе"
		elif not fighter.alive: line += " · повержен"
		elif bool(fighter.get("offboard",false)): line += " · вне поля"
		line += " · " + ("Дальний бой" if fighter.ranged else "Ближний бой")
		body.add_child(_wrap_label(line,23,INK))
	if str(player.hero_id) in ["william_shakespeare","hamlet","titania","the_wayward_sisters","geralt_of_rivia","ciri","ancient_leshen","eredin","philippa","yennefer_triss"]: main.add_child(_button("Способность и особые карты",_show_special_state.bind(owner),320))
	if str(player.hero_id) in ["blackbeard","loki","chupacabra","pandora"]:main.add_child(_button("Способность и особые карты",_show_legends_state.bind(owner),320))
	if str(player.hero_id)in["hellboy","abe_sapien","liz_sherman","baba_yaga"]:main.add_child(_button("Способность и особые карты",_show_hellboy_state.bind(owner),320))
	if str(player.hero_id)=="godzilla":main.add_child(_button("Посмотреть заряд",_show_nature_state.bind(owner),320))
	if str(player.hero_id)=="rosie_the_riveter":main.add_child(_button("Улучшения мехкостюма",_show_rosie_upgrades.bind(owner),320))
	if str(player.hero_id)=="black_panther":main.add_child(_button("Вибраниумовый костюм",_show_suit.bind(owner),320))
	if str(player.hero_id)=="deadpool":main.add_child(_button("Условия Дэдпула",_show_deadpool_match.bind(owner),320))
	main.add_child(_button("Посмотреть сброс этого игрока",_show_discards.bind(owner),320))
	_localize.call_deferred()

func _hero_data(id: String) -> Dictionary:
	for hero in heroes:
		if str(hero.id) == id:
			if id=="yennefer_triss":
				var selected=sorceress_hero
				if started:
					for player in engine.players:
						if player.hero_id==id:selected=str(player.get("sorceress","yennefer"))
				return engine._v17.definition(selected)
			return hero
	return {}

func _clear_children(parent: Node):
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _type_color(type: String) -> Color:
	return {"attack":Color("e79670"),"defense":Color("7fb9e4"),"versatile":Color("b49cd7"),"scheme":Color("dec271")}.get(type, TEAL)

func _type_name(type: String) -> String:
	return {"attack":"АТАКА","defense":"ЗАЩИТА","versatile":"УНИВЕРС.","scheme":"ПРИЁМ"}.get(type, type)

func _fighter_name(fighter: String) -> String:
	return {"any":"Любой","hero":"Герой","sidekick":"Помощник","jekyll":"Джекилл","hyde":"Хайд"}.get(fighter, fighter)

func _card_fighter_name(card: Dictionary) -> String:
	var variant = str(card.get("sidekick_variant",""))
	if variant in ["giles","xander"]:
		return str(_hero_data("buffy").get("sidekick_variants",{}).get(variant,{}).get("name","Джайлз" if variant == "giles" else "Ксандер"))
	return _fighter_name(str(card.get("fighter","any")))

func _popup(title: String, mandatory = false) -> VBoxContainer:
	_clear_popup()
	popup_kind = "info"
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(popup_layer)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.add_child(dim)
	var margin = _margin(popup_layer, 20)
	popup_outer = margin
	_apply_responsive_layout()
	var panel = PanelContainer.new()
	margin.add_child(panel)
	var main = VBoxContainer.new()
	panel.add_child(main)
	var header = HBoxContainer.new()
	main.add_child(header)
	var title_label = _label(title, 28, GOLD)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	popup_hide_button = _button("Скрыть",_hide_popup,110)
	popup_hide_button.visible = started
	header.add_child(popup_hide_button)
	popup_close_button = _button("Закрыть  ×", _close_popup, 150)
	popup_close_button.visible = not mandatory
	header.add_child(popup_close_button)
	_localize.call_deferred()
	return main

func _close_popup():
	if popup_hidden:
		_restore_popup()
		return
	if popup_kind in ["attack", "report", "choice"]:
		return
	var return_owner = _return_discard_owner
	var return_choice = _return_effect_choice
	var return_scroll = _return_effect_scroll
	_clear_popup()
	if return_choice and started and engine.phase == "effect_choice":
		_show_effect_choice()
		_modal_key = "choice:" + JSON.stringify(engine.pending_choice)
		if is_instance_valid(effect_scroll): effect_scroll.set_deferred("scroll_vertical",return_scroll)
		return
	if return_owner >= 0:
		_show_discards(return_owner)
		return
	if started:
		_refresh()

func _clear_popup():
	popup_hidden = false
	inspector_board = null
	if is_instance_valid(popup_inspector): popup_inspector.queue_free()
	popup_inspector = null
	enlarged_board = null
	_return_discard_owner = -1
	_return_effect_choice = false
	_return_effect_scroll = 0
	effect_scroll = null
	if popup_layer != null:
		popup_layer.queue_free()
		popup_layer = null
	popup_kind = ""
	_modal_key = ""

func _hide_popup():
	if not started or not is_instance_valid(popup_layer) or popup_hidden: return
	popup_hidden = true
	popup_layer.hide()
	popup_inspector = Control.new()
	popup_inspector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_inspector.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_inspector.z_index = 200
	add_child(popup_inspector)
	var controls = HBoxContainer.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(-500,8)
	controls.size = Vector2(490,48)
	popup_inspector.add_child(controls)
	controls.add_child(_button("Показать окно",_restore_popup,230))
	inspector_zoom_button = _button("Поле крупно",_toggle_inspector_zoom,230)
	controls.add_child(inspector_zoom_button)
	inspector_board = BoardScript.new()
	inspector_board.engine = engine
	inspector_board.selected = board.selected
	inspector_board.highlighted = board.highlighted.duplicate()
	inspector_board.targets = board.targets.duplicate()
	inspector_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspector_board.offset_top = 64
	inspector_board.offset_left = 8
	inspector_board.offset_right = -8
	inspector_board.offset_bottom = -8
	inspector_board.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_inspector.add_child(inspector_board)
	popup_inspector.move_child(inspector_board,0)
	inspector_board.hide()
	_localize()

func _toggle_inspector_zoom():
	if not popup_hidden or not is_instance_valid(inspector_board): return
	inspector_board.visible = not inspector_board.visible
	inspector_zoom_button.text = "Обычное поле" if inspector_board.visible else "Поле крупно"
	_localize()

func _restore_popup():
	if not popup_hidden: return
	popup_hidden = false
	inspector_board = null
	if is_instance_valid(popup_inspector): popup_inspector.queue_free()
	popup_inspector = null
	if is_instance_valid(popup_layer): popup_layer.show()
	_localize()

func _show_text(title: String, body: String):
	var main = _popup(title)
	var scroll = ScrollScript.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	scroll.add_child(_wrap_label(body, 21, INK))

func _show_help():
	_show_text("Как играть · версия 0.38", """НОВАЯ ПАРТИЯ. Переключай наборы, выбери героя, режим, соперников, навык ботов и поле. Нажатие на карточку героя открывает полную способность. Язык интерфейса: русский, английский, норвежский букмол или испанский. Выбор языка сохраняется.

ПОЛЯ. Мармореаль, Сарпедон, Сохо и поместье Баскервилей рассчитаны на 2–4 игроков. Шервудский лес, Юкон, Загон рапторов, Манила и монастырь Цин-Шань — на двоих. Для больших партий неподходящие поля скрыты. Оранжевые стрелки Загона ограничивают направление движения. Тайные проходы поместья связывают отмеченные клетки для перемещения, но не для атак. Герои разных наборов могут играть вместе.

РАССТАНОВКА. Выбери старт героя по печатной метке поля. При ручной расстановке подтверди старт, затем поставь каждого помощника на свободную клетку в общей зоне с героем. Нажми «Начать бой».

ЭКРАН. Рука находится под полем и листается в стороны. Описание справа прокручивается. Плашки игроков находятся по краям поля; нажми плашку или «Сбросы», чтобы смотреть открытые сбросы. «Рука» скрывает карты, «Поле ⤢» увеличивает поле. Последние события журнала находятся сверху.

СОСТОЯНИЯ. ↑ +2 у Алисы: большой размер и +2 к атаке. ↓ +1: маленький размер и +1 к защите. V у Синдбада: число плаваний в сбросе. Зелёный + обозначает союзника. Рядом с фишками показано целое здоровье, у одноочковых помощников — порядковые номера.

ХОД. Выполни два действия: манёвр, атаку или приём. Манёвр сначала берёт карту, затем позволяет передвинуть каждого своего бойца один раз. Выбери фигуру и подсвеченную клетку. До первого движения можно усилить манёвр картой с напечатанным BOOST. У шести плаваний Синдбада BOOST отсутствует: ими усиливать нельзя. После движения нажми «Завершить перемещение».

БОЙ. Выбери бойца, карту атаки или универсальную карту, затем цель. Объявление атаки ждёт подтверждения. При защите выбери карту либо сними выбор повторным нажатием, чтобы пропустить защиту. Карта атаки противника скрыта до выбора защиты. Для усиления Артура сначала выбери отдельную карту BOOST, затем карту атаки.

ЭФФЕКТЫ. Окно боя показывает карты, силу и урон. «К эффектам» запускает выбор клетки, цели или карты. Необязательное движение можно пропустить. У «Неупокоенных духов» Мерлина выбери клетку в его зоне, затем соседнюю: враги на них получат 2 урона. «Пророчество» позволяет взять две из четырёх карт и выбрать порядок оставшихся. Отдельное окно показывает результат эффектов, включая отсутствие подходящей цели.

ПРОСМОТР РУКИ. Карты, позволяющие посмотреть руку соперника, открывают отдельное окно со всеми её картами. Нажми изображение для увеличения и полного описания. Вернись к открытой руке и нажми «Закончить просмотр», чтобы продолжить бой. Если эффект требует выбрать карту для сброса или замешивания, нажми кнопку выбора рядом с ней. Сам просмотр карты ничего не сбрасывает. «Трудно быть скромным» Али раскрывает руку только в стойке бабочки, во время боя, если эффект не отменён.

СПОСОБНОСТИ. В начале хода Медузы выбери одного врага в её зоне для 1 урона или пропусти способность. Результат показан отдельным окном. У Синдбада каждое плавание в сбросе даёт +1 к манёвру всех его бойцов. Атаки усиливаются только у карт плаваний; Финт отменяет их эффект. BOOST картой «Плавание домой» даёт и напечатанное усиление, и дополнительный шаг за новое плавание в сбросе.

НОВЫЕ ГЕРОИ. После своей атаки Робин Гуд может передвинуть атаковавшего бойца до двух клеток, включая разбойника. Бигфут без врагов в своей зоне может взять карту в конце хода. Брюс Ли может отойти на одну клетку в конце хода, а карты Jeet Kune Do дают дополнительные действия.

JURASSIC PARK. Малдун начинает с восемью ловушками на всю партию. В начале хода можно поставить ловушку на свободную клетку его зоны. Враг, вошедший в неё, останавливается и получает 1 урон; ловушка убирается, а Малдун берёт карту. Союзники проходят свободно. Рапторы — три героя по 7 ОЗ: поражение одного не завершает партию. Каждый другой твой раптор рядом с целью даёт +1 к атаке. В плашке игрока видно здоровье всех троих.

ЛОВУШКИ МАЛДУНА. У «Вызвать подкрепление» сначала выбери два разных эффекта. Размещение ловушек этой картой доступно на любом поле, вне зоны Малдуна тоже. Нажми до трёх свободных клеток без бойцов и любых жетонов. Можно остановиться раньше. Карта расходует оставшиеся ловушки из запаса и не возвращает использованные. Обычная способность в начале хода по-прежнему ограничена зоной Малдуна. «Дистанционный подрыв» требует ловушку в зоне живого работника InGen; удаление ловушки даёт карту.

МУХАММЕД АЛИ. Начинает в стойке «Бабочка»: может атаковать на расстоянии до двух клеток. Стойка «Пчела» даёт +2 к атаке после эффектов карт во время боя. После выигранной атаки Али меняет стойку; текущая стойка показана у фишки и в описании.

ТУМАН НАД МОСТОВОЙ. Дракула в начале хода может нанести 1 урон любому соседнему бойцу и взять карту. Именные карты Холмса и Ватсона нельзя отменить. Джекилл выбирает форму в начале хода; Хайд получает 1 урон при манёвре, а карты форм доступны только соответствующей форме. Человек-невидимка выставляет три жетона тумана: на тумане он получает +1 к защите и может перемещаться между жетонами. Выборы необычных эффектов показаны отдельными окнами.

БАФФИ. В меню выбери одного помощника Баффи — Джайлза или Ксандера. Его пять карт войдут в колоду; второй помощник в этой партии не участвует. Баффи проходит сквозь врагов. После проигранной атаки Ангела или Фэйт возьмите карту. Спайк размещает жетоны тени, а Уиллоу может стать Тёмной Уиллоу. Тени, облик и выбранный помощник сохраняются вместе с партией. Поля школы Саннидейла и клуба «Бронза» доступны для 2–4 игроков.

КОМАНДЫ. В режиме 2 на 2 ты играешь с ботом против двух ботов. Ходы чередуются: ты → враг → союзник → враг. Помощники продолжают играть после поражения своего героя. Побеждает команда, победившая обоих вражеских героев.

КОНЕЦ ХОДА. Сбрось лишние карты до семи. Сброс не перемешивается. Каждый недостающий добор из пустой колоды наносит 2 урона всем твоим бойцам. В режиме каждый за себя побеждает последний герой.

Окна уведомлений ждут подтверждения, а боты ждут закрытия журнала, сброса и просмотра карт. Автосохранение включает текущий шаг выбора. Усиление по эффекту карты выбирается после её раскрытия. Некоторые поиски карт автоматизированы. Боты используют эвристики трёх уровней.

Неофициальная фанатская игра для личного использования. Оригинальные изображения карт английские; переведённые описания показаны отдельно. Unmatched и изображения компонентов принадлежат правообладателям.""")

func _show_log():
	var lines = PackedStringArray()
	for i in range(engine.logs.size() - 1, -1, -1):
		lines.append(str(engine.logs[i]))
	_show_text("Журнал · последние действия сверху", "\n\n".join(lines))

func _show_nature_state(owner: int):
	var body=_popup("Заряд Годзиллы")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
	var grid=GridContainer.new();grid.columns=maxi(2,int((get_viewport_rect().size.x-100)/190));scroll.add_child(grid)
	for c in engine._v38.charge(owner):
		var original=int(c.get("charge_owner",owner));var hid=str(engine.players[original].hero_id);var item=CardScript.new();item.set_card(c,hid);item.pressed.connect(_zoom_effect_card.bind(c,hid));grid.add_child(item)
	_localize()

func _show_discards(owner: int = 0):
	if not started:
		return
	var main = _popup("Сбросы игроков · последние карты сверху")
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(tabs)
	for player_index in range(engine.players.size()):
		var p = engine.players[player_index]
		var page = ScrollScript.new()
		page.name = ("Ты · " if player_index == 0 else "") + str(p.name)
		page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(page)
		var list = VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_child(list)
		list.add_child(_label("%d карт в сбросе" % p.discard.size(),21,TEAL))
		if str(p.hero_id) == "little_red": list.add_child(_wrap_label(engine.basket_description(player_index),21,GOLD))
		if p.discard.is_empty():
			list.add_child(_wrap_label("Пока ни одной карты. Разыгранные и сброшенные карты появятся здесь.",21,MUTED))
		else:
			var grid = GridContainer.new()
			grid.columns = maxi(3,int((get_viewport_rect().size.x - 140)/155))
			grid.add_theme_constant_override("h_separation",10)
			grid.add_theme_constant_override("v_separation",10)
			list.add_child(grid)
			for index in range(p.discard.size()-1,-1,-1):
				var c = p.discard[index]
				var item = CardScript.new()
				item.set_card(c,str(p.hero_id))
				item.pressed.connect(_zoom_discard_card.bind(c,str(p.hero_id),player_index))
				grid.add_child(item)
	tabs.current_tab = clampi(owner,0,engine.players.size()-1)

func _zoom_discard_card(card: Dictionary, hero_id: String, owner: int):
	_zoom_card(card,hero_id)
	_return_discard_owner = owner
	popup_close_button.text = "К сбросу ←"

func _show_library():
	var main = _popup("Колоды · %d героев · %d карт" % [heroes.size(), _playable_card_total()])
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(tabs)
	for hero in heroes:
		var scroll = ScrollScript.new()
		scroll.name = str(hero.name)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(scroll)
		var list = VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		list.add_child(_wrap_label(str(hero.ability), 20, TEAL))
		for card in hero.cards:
			var panel = PanelContainer.new()
			list.add_child(panel)
			var row = HBoxContainer.new()
			panel.add_child(row)
			var art = CardScript.new()
			art.set_card(card, str(hero.id))
			art.pressed.connect(_zoom_card.bind(card, str(hero.id)))
			row.add_child(art)
			var vb = VBoxContainer.new()
			vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(vb)
			vb.add_child(_wrap_label("%s ×%s · %s %s · BOOST %s" % [card.name,int(card.count),_type_name(card.type),int(card.value),CardScript.boost_label(card)],22,_type_color(card.type)))
			vb.add_child(_wrap_label("%s. %s" % [_card_fighter_name(card),I18n.card_field(str(hero.id),str(card.id),"text",str(card.text))],20,INK))

func _zoom_selected():
	if selected_card >= 0 and selected_card < engine.players[0].hand.size():
		_zoom_card(engine.players[0].hand[selected_card], str(engine.players[0].hero_id))

func _show_board_zoom():
	if not started:
		return
	var main = _popup("Поле крупно · нажимай на клетки")
	main.add_child(_button("Правила этого поля",_show_map_rules.bind(true)))
	if not engine.battlefield_items.is_empty():main.add_child(_button("Предметы поля",_show_board_items))
	popup_kind = "board"
	enlarged_board = BoardScript.new()
	enlarged_board.engine = engine
	enlarged_board.selected = board.selected
	enlarged_board.highlighted = board.highlighted
	enlarged_board.targets = board.targets
	enlarged_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enlarged_board.node_pressed.connect(_on_node)
	enlarged_board.item_pressed.connect(_zoom_board_item)
	main.add_child(enlarged_board)
	if engine.phase in ["move", "effect_move"]:
		var finish = _button("Завершить ловушки" if str(engine.pending_choice.get("action","")) == "place_traps" else "Завершить перемещение", _finish_move, 300)
		finish.disabled = engine.phase == "effect_move" and not engine.pending_choice.get("can_skip", false)
		main.add_child(finish)

func _zoom_card(card: Dictionary, hero_id: String):
	if card.get("trick",false):hero_id="loki"
	var main = _popup(str(card.get("name", "Карта")))
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(row)
	var entry = card_images.get(hero_id, {}).get(str(card.get("id", "")), {})
	var path = str(entry.get("path_ru",entry.get("path",""))) if I18n.language=="ru" else str(entry.get("path",""))
	if path != "" and ResourceLoader.exists(path):
		var image = TextureRect.new()
		image.texture = load(path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(340, 0)
		image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(image)
	var scroll = ScrollScript.new()
	scroll.custom_minimum_size.x = 380
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var body = "%s · сила %s · BOOST %s\n%s\n\n%s\n\nОригинальное изображение карты показано рядом. Описание на русском — здесь." % [_type_name(str(card.type)),int(card.value),CardScript.boost_label(card),_card_fighter_name(card),str(card.text)]
	if hero_id == "little_red": body += "\n\n" + "Символ этой карты: %s" % CardScript.basket_label(card)
	scroll.add_child(_wrap_label(body, 25, INK))

func _sync_interaction():
	_interaction_scheduled = false
	if popup_hidden: return
	if not started:
		return
	if popup_layer != null and popup_kind == "info":
		return
	var phase = str(engine.phase)
	if phase == "attack_notice":
		var key = "attack:" + JSON.stringify(engine.pending_combat)
		if key != _modal_key or popup_layer == null:
			_show_attack_notice()
			_modal_key = key
	elif phase == "combat_report":
		var key = "report:" + JSON.stringify(engine.combat_report)
		if key != _modal_key or popup_layer == null:
			_show_combat_report()
			_modal_key = key
	elif phase == "effect_choice":
		var key = "choice:" + JSON.stringify(engine.pending_choice)
		if key != _modal_key or popup_layer == null:
			_show_effect_choice()
			_modal_key = key
	else:
		if popup_kind in ["attack", "report", "choice"]:
			_clear_popup()
		if phase == "game_over" and not result_shown:
			result_shown = true
			_show_text("Партия завершена", _winner_text() + ".\n\nПолный ход партии можно посмотреть в журнале.")

func _show_attack_notice():
	var pending = engine.pending_combat
	var attacker = engine.fighters[int(pending.attacker)]
	var target = engine.fighters[int(pending.target)]
	var main = _popup("Объявлена атака", true)
	if engine._is_hero(int(engine.fighters[int(pending.target)].owner),"spider_man"):
		main.add_child(_wrap_label("Напечатанная сила атаки: %d" % int(pending.attack_card.get("value",0)),26,GOLD))
	if str(pending.attack_card.get("id",""))=="witness_my_last_battle" or pending.get("face_up",false):
		var front=CardScript.new();front.set_card(pending.attack_card,str(engine.players[int(attacker.owner)].hero_id));main.add_child(front)
	popup_kind = "attack"
	var space = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(space)
	main.add_child(_wrap_label("%s  →  %s" % [attacker.name, target.name], 42, GOLD))
	main.add_child(_wrap_label(("%s атакует бойца игрока %s.\nКарта атаки раскрыта." if pending.get("face_up",false) else "%s атакует бойца игрока %s.\nКарта атаки остаётся закрытой до выбора защиты.") % [str(engine.players[int(attacker.owner)].name),str(engine.players[int(target.owner)].name)], 25, INK))
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(spacer)
	var next = _button("К выбору защиты  →" if int(target.owner) == 0 else "Открыть карты и разыграть бой  →", _continue_attack, 400)
	main.add_child(next)

func _continue_attack():
	_clear_popup()
	selected_card = -1
	engine.continue_attack()
	_refresh()

func _report_card(parent: Node, title: String, card: Dictionary, owner: int):
	var group = VBoxContainer.new()
	group.custom_minimum_size.x = 202
	parent.add_child(group)
	group.add_child(_wrap_label(title, 18, TEAL))
	if card.is_empty():
		group.add_child(_wrap_label("Без защиты", 27, MUTED))
		return
	var image = CardScript.new()
	image.set_card(card, str(engine.players[owner].hero_id), true)
	image.custom_minimum_size = Vector2(192, 276)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(image)
	group.add_child(_wrap_label(str(card.get("name", "")), 20, GOLD))

func _show_combat_report():
	var report = engine.combat_report
	var is_effects = str(report.get("stage", "")) == "effects"
	var is_ability = str(report.get("kind", "")) == "ability"
	var main = _popup("Способность героя · итог" if is_ability else "Эффекты карт · итог" if is_effects else "Бой · вскрытие карт и результат", true)
	popup_kind = "report"
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(row)
	if str(report.get("kind", "")) == "combat":
		var af = engine.fighters[int(report.attacker)]
		var df = engine.fighters[int(report.target)]
		_report_card(row, str(af.name) + " · атака", report.attack_card, int(af.owner))
		_report_card(row, str(df.name) + " · защита", report.defense_card, int(report.get("defense_card_owner",df.owner)))
	elif is_ability:
		var owner = clampi(int(report.get("owner", engine.active)),0,engine.players.size()-1)
		var portrait = _avatar_control(str(engine.players[owner].hero_id),true,170)
		row.add_child(portrait)
	elif report.has("card"):
		_report_card(row, "Разыгран приём", report.card, engine.active)
	var scroll = ScrollScript.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var body = ""
	if is_ability: body = str(report.get("title", "Способность героя")) + "\n\n"
	if str(report.get("kind", "")) == "combat":
		body = "%s\n\nАтака %s  −  защита %s\nУрон от боя: %s\n\n" % [report.get("outcome", ""),int(report.get("attack_value",0)),int(report.get("defense_value",0)),int(report.get("damage",0))]
		if report.get("attack_cancelled", false):
			body += "Эффекты карты атаки отменены.\n\n"
		if report.get("defense_cancelled", false):
			body += "Эффекты карты защиты отменены.\n\n"
	for modifier in report.get("modifier_logs", []): body += str(modifier) + "\n\n"
	if is_effects or is_ability:
		var entries = PackedStringArray()
		for line in report.get("effect_logs", []):
			entries.append(str(line))
		body += "РЕЗУЛЬТАТ ЭФФЕКТОВ\n\n" + ("\n\n".join(entries) if not entries.is_empty() else "Дополнительные эффекты завершены.")
	else:
		body += "ЭФФЕКТЫ КАРТ\n\n"
		var defense: Dictionary = report.get("defense_card", {})
		var attack: Dictionary = report.get("attack_card", {})
		if not defense.is_empty():
			body += "%s:\n%s\n\n" % [defense.get("name", "Защита"),defense.get("text", "")]
		body += "%s:\n%s\n\nНажми «К эффектам». Если карта позволяет переместить бойца, выбери клетку на поле." % [attack.get("name", "Атака"),attack.get("text", "")]
	scroll.add_child(_wrap_label(body, 23, INK))
	main.add_child(_button("Продолжить партию  →" if is_effects or is_ability else "К эффектам карт  →", _continue_combat, 320))

func _continue_combat():
	_clear_popup()
	selected_card = -1
	engine.continue_combat()
	_refresh()

func _show_effect_choice():
	var choice = engine.pending_choice
	if str(choice.get("kind","")) == "hand_view":
		_show_hand_view(choice)
		return
	var main = _popup(str(choice.get("title", "Выбор эффекта")), true)
	popup_kind = "choice"
	main.add_child(_wrap_label(str(choice.get("prompt", "Выбери эффект")), 26, GOLD))
	var scroll = ScrollScript.new()
	effect_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	var options = VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options)
	var cards: Array = choice.get("cards", [])
	for i in range(choice.get("options", []).size()):
		var row = HBoxContainer.new()
		options.add_child(row)
		if i < cards.size():
			var preview = CardScript.new()
			var owner = int(choice.get("victim", choice.get("_ctx", {}).get("owner", 0)))
			owner=int(cards[i].get("_suit_owner",owner))
			preview.set_card(cards[i], str(engine.players[owner].hero_id))
			preview.pressed.connect(_zoom_effect_card.bind(cards[i],str(engine.players[owner].hero_id)))
			row.add_child(preview)
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var action_text = str(choice.options[i])
		if i < cards.size() and str(choice.get("kind","")) == "cards":
			action_text = "%s · %s %d · BOOST %s" % [cards[i].get("name", "Карта"), _type_name(str(cards[i].get("type", ""))), int(cards[i].get("value", 0)), CardScript.boost_label(cards[i])]
		elif choice.get("allowed_fighters",[]).size() == choice.options.size():
			var fid = int(choice.allowed_fighters[i])
			if fid >= 0 and fid < engine.fighters.size():
				var f = engine.fighters[fid]
				var ordinal = 0
				for other in engine.fighters:
					if int(other.owner) == int(f.owner) and bool(other.hero) == bool(f.hero):
						ordinal += 1
						if int(other.id) == fid: break
				action_text += "\n" + ("№%d · %d ОЗ · клетка %d" % [ordinal,int(f.hp),int(f.node)+1] if not f.hero or int(engine.heroes[engine.players[f.owner].hero_id].get("hero_count",1)) > 1 else "%d ОЗ · клетка %d" % [int(f.hp),int(f.node)+1])
		var action = _button(action_text, _choose_effect_option.bind(i))
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(action)
		if i < cards.size():
			column.add_child(_wrap_label(str(cards[i].get("text", "")), 20, INK))
	if choice.get("can_skip", false):
		main.add_child(_button("Пропустить способность", _skip_ability, 320))

func _show_hand_view(choice: Dictionary):
	var victim = int(choice.get("victim",0))
	var cards: Array = choice.get("cards",[])
	var main = _popup(str(choice.get("title","Просмотр руки противника")),true)
	popup_kind = "choice"
	main.add_child(_wrap_label(str(choice.get("prompt","")) if bool(choice.get("deck_view",false)) else "Открыта рука: %s · карт: %d" % [engine.players[victim].name,cards.size()],25,GOLD))
	main.add_child(_wrap_label("Нажми карту, чтобы увеличить и прочитать её. Просмотр не сбрасывает карты.",18,MUTED))
	var scroll = ScrollScript.new()
	effect_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	if cards.is_empty():
		scroll.add_child(_wrap_label("В руке противника нет карт.",26,INK))
	else:
		var grid = GridContainer.new()
		grid.columns = clampi(int((get_viewport_rect().size.x-100)/180),2,6)
		grid.add_theme_constant_override("h_separation",12)
		grid.add_theme_constant_override("v_separation",12)
		scroll.add_child(grid)
		for index in range(cards.size()):
			var card = cards[index]
			var card_owner = int(choice.get("card_owners",[])[index]) if choice.has("card_owners") else victim
			var preview = CardScript.new()
			preview.set_card(card,str(engine.players[card_owner].hero_id))
			preview.custom_minimum_size = Vector2(160,228)
			preview.pressed.connect(_zoom_effect_card.bind(card,str(engine.players[card_owner].hero_id)))
			grid.add_child(preview)
	main.add_child(_button("Закончить просмотр →",_choose_effect_option.bind(0),320))

func _zoom_effect_card(card: Dictionary, hero_id: String):
	var offset = effect_scroll.scroll_vertical if is_instance_valid(effect_scroll) else 0
	var viewing_hand = str(engine.pending_choice.get("kind","")) == "hand_view"
	_zoom_card(card,hero_id)
	_return_effect_choice = true
	_return_effect_scroll = offset
	popup_close_button.text = "К открытой руке ←" if viewing_hand else "К выбору эффекта ←"

func _skip_ability():
	_clear_popup()
	engine.skip_effect()
	_refresh()

func _choose_effect_option(index: int):
	_clear_popup()
	engine.choose_effect_option(index)
	_refresh()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_match()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if popup_layer != null:
			_close_popup()
		elif started:
			_return_menu()

func _smoke_ui():
	count_option.select(2)
	_start_match()
	for step in range(8):
		if engine.phase != "setup": break
		if engine.setup_fighter < 0:
			engine.finish_setup()
			break
		var legal = engine.legal_setup_nodes(engine.setup_fighter)
		if legal.is_empty(): break
		engine.place_setup_fighter(engine.setup_fighter,int(legal[0]))
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("res://../preview.png")
	print("UI_SMOKE_OK ", engine.players.size(), " players, ", engine.fighters.size(), " fighters")
	get_tree().quit()

func _show_special_state(owner: int):
	if owner<0 or owner>=engine.players.size(): return
	var p=engine.players[owner]
	var main=_popup("Особые карты · %s" % str(p.name))
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	body.add_child(_wrap_label(engine.state_summary(owner),24,TEAL))
	body.add_child(_wrap_label(str(_hero_data(str(p.hero_id)).ability),23,INK))
	if p.hero_id=="titania":
		for id in ["greed","invisibility","jealousy","love","rhyme","sleep"]:
			var c=engine._v13.special_cards().glamours[id]
			var row=HBoxContainer.new();body.add_child(row)
			var art=TextureRect.new();art.custom_minimum_size=Vector2(180,118);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture=load(str(c.path));row.add_child(art)
			var state="Открыты сейчас" if str(p.glamour)==id else "Сброшены" if p.glamour_discard.has(id) else "В колоде чар"
			row.add_child(_wrap_label("%s · %s\n%s" % [str(c.name),state,str(c.text)],23,TEAL if str(p.glamour)==id else INK))
	if p.hero_id=="the_wayward_sisters":
		body.add_child(_wrap_label("Заклинания · после атаки выбирается одно, затем весь котёл сбрасывается",25,GOLD))
		for label in engine._v13.spell_labels(): body.add_child(_wrap_label(str(label),23,INK))
	if p.hero_id=="geralt_of_rivia":
		body.add_child(_wrap_label("Выбранное снаряжение",25,GOLD))
		for option in p.get("gear",{}).values(): body.add_child(_wrap_label(str(engine._v14.gear_names().get(str(option),str(option))),23,INK))
		if owner==0:
			var toggle=CheckButton.new();toggle.text="Неясыть: игнорировать сброс от эффектов";toggle.button_pressed=bool(p.get("owl_ignore",true));toggle.add_theme_font_size_override("font_size",23);toggle.toggled.connect(_toggle_owl.bind(owner));body.add_child(toggle)
			body.add_child(_wrap_label("Настройка действует только при активной Неясыти. Добровольная оплата, усиление и лимит руки сохраняются.",21,INK))
	if p.hero_id=="ciri":
		body.add_child(_wrap_label("Карты Источника · применяется наибольший достигнутый порог",25,GOLD))
		for c in _hero_data("ciri").cards:
			if c.get("source",false):body.add_child(_wrap_label(str(c.name)+"\n"+str(c.text),23,INK))
	if not p.get("ongoing",{}).is_empty():
		body.add_child(_wrap_label("Активный постоянный приём",25,GOLD))
		var row=HBoxContainer.new();body.add_child(row)
		var item=CardScript.new();item.set_card(p.ongoing,str(p.hero_id));item.pressed.connect(_zoom_special_card.bind(p.ongoing,str(p.hero_id),owner));row.add_child(item)
		row.add_child(_wrap_label(str(p.ongoing.name)+"\n"+str(p.ongoing.text),23,INK))
	var pile=p.get("line",[]) if p.hero_id=="william_shakespeare" else p.get("cauldron",[])
	if p.hero_id in ["william_shakespeare","the_wayward_sisters"]:
		body.add_child(_wrap_label("Строка слева направо" if p.hero_id=="william_shakespeare" else "Карты в котле",25,GOLD))
		if pile.is_empty(): body.add_child(_wrap_label("Пока нет карт",22,INK))
		for c in pile:
			var row=HBoxContainer.new();body.add_child(row)
			var item=CardScript.new();item.set_card(c,str(p.hero_id));item.pressed.connect(_zoom_special_card.bind(c,str(p.hero_id),owner));row.add_child(item)
			row.add_child(_wrap_label(str(c.name)+"\n"+str(c.text),23,INK))
	main.add_child(_button("Назад к персонажу",_show_player_info.bind(owner),320))
	_localize.call_deferred()

func _zoom_special_card(card: Dictionary, hero_id: String, owner: int):
	_zoom_card(card,hero_id)
	var close=popup_close_button
	close.text="Закрыть ×"

func _toggle_owl(enabled: bool, owner: int):
	engine.players[owner].owl_ignore=enabled
	_save_match()

func _show_geralt_gear():
	var main=_popup("Снаряжение Геральта")
	main.add_child(_wrap_label("Выберите по одной карте каждого вида. В колоду войдут две её копии; остальные карты снаряжения останутся вне партии.",23,INK))
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	for slot in ["sword","armor","potion"]:
		body.add_child(_wrap_label({"sword":"Меч","armor":"Доспех","potion":"Зелье"}[slot],25,GOLD))
		var row=HBoxContainer.new();body.add_child(row);var group=ButtonGroup.new()
		var column_width=maxf(250.0,(get_viewport_rect().size.x-112.0)*0.5)
		for c in _hero_data("geralt_of_rivia").cards:
			if str(c.get("gear_slot",""))!=slot:continue
			var cell=HBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.custom_maximum_size.x=column_width;row.add_child(cell)
			var item=CardScript.new();item.set_card(c,"geralt_of_rivia");item.button_group=group;item.set_meta("gear_slot",slot);item.set_meta("gear_option",str(c.gear_option));item.button_pressed=str(geralt_gear[slot])==str(c.gear_option);item.pressed.connect(_choose_geralt_gear.bind(slot,str(c.gear_option)));cell.add_child(item)
			var description=_wrap_label(str(c.name)+"\n"+str(c.text),21,INK);description.custom_maximum_size.x=column_width-CardScript.SMALL_SIZE.x-12;cell.add_child(description)
	main.add_child(_button("Готово",_show_hero_info.bind("geralt_of_rivia"),320))
	_localize.call_deferred()

func _choose_geralt_gear(slot: String, value: String):
	geralt_gear[slot]=value

func _show_sorceress_choice():
	var body=_popup("Выбрать главную героиню")
	body.add_child(_wrap_label("Героиня: 14 ОЗ · помощница: 6 ОЗ",26,TEAL))
	body.add_child(_wrap_label(str(_hero_data("yennefer_triss").ability),23,INK))
	body.add_child(_button("Йеннифэр",_select_sorceress.bind("yennefer"),320))
	body.add_child(_button("Трисс",_select_sorceress.bind("triss"),320))
	_localize.call_deferred()
func _select_sorceress(value: String):
	sorceress_hero=value;_close_popup();_show_hero_info("yennefer_triss")

func _show_space_fighters(ids: Array):
	var body=_popup("Бойцы на клетке")
	var node=int(engine.fighters[int(ids[0])].node)
	if engine.phase=="move" and engine.active==0 and selected_fighter>=0 and node in engine.legal_moves(selected_fighter):body.add_child(_button("Переместить выбранного бойца сюда",_space_move.bind(node),360))
	for id in ids:
		var fid=int(id);var f=engine.fighters[fid];var label="%s · %s · %d ОЗ"%[engine._player_name(int(f.owner)),f.name,int(f.hp)]
		if engine._v31.small(fid):label="%s · %s №%d · %d ОЗ"%[engine._player_name(int(f.owner)),f.name,fid-engine.hero_fighter(int(f.owner)),int(f.hp)]
		if attack_mode and fid in engine.legal_targets(selected_fighter,selected_card):body.add_child(_button("Атаковать · "+label,_space_attack.bind(fid),360))
		elif int(f.owner)==0:body.add_child(_button("Выбрать · "+label,_space_select.bind(fid),360))
		else:body.add_child(_wrap_label(label,21,INK))
func _space_select(fid: int):
	_clear_popup();selected_fighter=fid;_refresh()
func _space_move(node: int):
	_clear_popup();engine.move_fighter(selected_fighter,node);_refresh()
func _space_attack(fid: int):
	_clear_popup()
	if engine.attack(selected_fighter,fid,selected_card):selected_card=-1;attack_mode=false;boost_card=-1
	_refresh()
func _show_suit(owner: int):
	var body=_popup("Вибраниумовый костюм")
	body.add_child(_wrap_label("Эти карты можно использовать только для BOOST. После усиления карта идёт в сброс владельца, Пантера берёт карту.",21,INK))
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	var pile=engine.players[owner].get("suit",[])
	for i in range(pile.size()):
		var c=pile[i];var owner_id=int(c.get("_suit_owner",owner));var card_view=CardScript.new();card_view.set_card(c,str(engine.players[owner_id].hero_id));card_view.custom_minimum_size=Vector2(220,300);list.add_child(card_view)
		if owner==0 and engine.active==0 and engine.phase in ["action","move"] and engine.can_boost_card(c):list.add_child(_button("Усилить манёвр · BOOST %d"%int(c.boost),_suit_move.bind(i),300))
	if pile.is_empty():list.add_child(_wrap_label("Костюм пока пуст.",22,MUTED))
func _suit_move(index: int):
	_clear_popup();engine._v31.suit_maneuver(0,index);_refresh()
func _show_deadpool_setup():
	var main=_popup("Условия Дэдпула")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	body.add_child(_wrap_label("Задаются до новой партии. По умолчанию внешние условия выключены, цифровые карты без протекторов. Звук взрыва игрок подтверждает при розыгрыше. Имена нужны для Логана и карты Call Me.",20,INK))
	for pair in [["food","На столе есть еда"],["owns_set","Есть физический набор Дэдпула"],["mirror","У соперников есть зеркало"],["sleeved","Карты Дэдпула в протекторах"],["explosion","Бот произносит звук взрыва"]]:
		var box=CheckButton.new();box.text=str(pair[1]);box.button_pressed=bool(deadpool_conditions[pair[0]]);box.toggled.connect(func(value):deadpool_conditions[str(pair[0])]=value);body.add_child(box)
	for i in range(4):
		var line=LineEdit.new();line.placeholder_text=I18n.text("Настоящее имя игрока %d (необязательно)"%(i+1));line.text=str(player_real_names[str(i)]);line.text_changed.connect(func(value):player_real_names[str(i)]=value);body.add_child(line)
	body.add_child(_button("Готово",_clear_popup,220))
func _show_deadpool_match(owner: int):
	var body=_popup("Условия Дэдпула · текущая партия")
	var c=engine.players[owner].get("deadpool_conditions",{})
	var yesno={"ru":["нет","да"],"en":["no","yes"],"nb":["nei","ja"],"es":["no","sí"]}[I18n.language]
	for pair in [["food","Еда на столе"],["owns_set","Физический набор"],["mirror","Зеркало"],["sleeved","Протекторы"],["explosion","Звук взрыва у бота"]]:body.add_child(_wrap_label(I18n.text(str(pair[1]))+": "+str(yesno[int(bool(c.get(pair[0],false)))]),22,INK))
	body.add_child(_wrap_label("Подписи на Call Me: "+str(engine.players[owner].get("signed_names",[])),22,INK))

func _misery_view(parent: Node,id: String):
	var special=engine._v13.special_cards().miseries.get(id,{})
	var row=HBoxContainer.new();parent.add_child(row)
	var art=TextureRect.new();art.custom_minimum_size=Vector2(245,160);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture=load(str(special.path));row.add_child(art)
	var texts={"hope":"Посмотрите только следующую карту ящика перед решением, раскрывать ли её.","pain":"Нанесите 1 урон каждому врагу рядом с Пандорой.","misfortune":"Эффекта нет; два пера.","woe":"Призовите какодемона в зоне Пандоры.","toil":"Атаки Пандоры получают +1 к силе до конца её хода.","greed":"Возьмите 1 карту.","confusion":"Передвиньте Пандору до 1 клетки."}
	row.add_child(_wrap_label("%s · перьев: %d\n%s"%[engine._v32.misery_name(id),int(special.feathers),str(texts[id])],22,INK))
func _show_misery_reference():
	var main=_popup("Все карты ящика Пандоры")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	list.add_child(_wrap_label("Справочник показывает все семь карт, без порядка в закрытом ящике. При трёх перьях Пандора получает урон по числу раскрытых бед. Все беды замешиваются обратно в конце её хода.",21,TEAL))
	for id in ["hope","pain","misfortune","woe","toil","greed","confusion"]:_misery_view(list,id)
func _show_legends_state(owner: int):
	var p=engine.players[owner];var main=_popup("Способность и особые карты")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	list.add_child(_wrap_label(engine.state_summary(owner),24,TEAL))
	list.add_child(_wrap_label(str(_hero_data(str(p.hero_id)).ability),22,INK))
	if p.hero_id=="pandora":
		for id in p.get("miseries",[]):_misery_view(list,str(id))
		main.add_child(_button("Все карты ящика Пандоры",_show_misery_reference,320))
	if p.hero_id=="loki":
		for victim in range(engine.players.size()):
			for c in engine.players[victim].hand:
				if engine._v32.origin(c)!=owner or victim==owner:continue
				list.add_child(_wrap_label("Уловка в руке: "+engine._player_name(victim),22,GOLD))
				var preview=CardScript.new();preview.set_card(c,"loki");list.add_child(preview)
	if p.hero_id=="blackbeard":list.add_child(_wrap_label("Дублоны всегда перемещаются между Чёрной Бородой и общей казной. При оплате выкупа золотой эффект не выполняется. В партии с несколькими противниками выкуп может оплатить любой из них.",22,INK))

func _show_rosie_upgrades(owner: int):
	var panel=_popup("Улучшения мехкостюма")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;panel.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	body.add_child(_wrap_label("Улучшения действуют только на Рози. Отключённое улучшение перемещается в конец очереди. При четырёх активных в конце хода отключаются все.",23,TEAL))
	var active=engine._v34.active_upgrades(owner)
	for id in engine._int_array(engine.players[owner].get("upgrades",[0,1,2,3])):
		var row=HBoxContainer.new();body.add_child(row)
		var art=TextureRect.new();art.custom_minimum_size=Vector2(160,200);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture=load("res://assets/heroes/rosie-upgrade-%d-%d.webp"%[id,1 if active.has(id)else 0]);row.add_child(art)
		row.add_child(_wrap_label(["Двигатель Merlin: при манёвре Рози может пройти на 1 клетку больше.","Магнетрон: после атаки Рози можно взять 1 карту.","Кулак Sedgley: атаки Рози получают +1.","Ракеты Whizbang: Рози становится бойцом дальнего боя."][id]+(" Активно"if active.has(id)else" Неактивно"),23,INK))

func _show_hellboy_state(owner: int):
	var p=engine.players[owner];var main=_popup("Способность и особые карты")
	var scroll=ScrollScript.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	body.add_child(_wrap_label(engine.state_summary(owner),24,TEAL))
	body.add_child(_wrap_label(str(_hero_data(str(p.hero_id)).ability),23,INK))
	if p.hero_id=="hellboy":
		for form in["occult","anung"]:
			var art=TextureRect.new();art.custom_minimum_size=Vector2(460,260);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture=load("res://assets/heroes/hellboy-"+form+".webp");body.add_child(art)
	if p.hero_id=="abe_sapien":
		var row=HBoxContainer.new();body.add_child(row)
		for i in range(2):
			var art=TextureRect.new();art.custom_minimum_size=Vector2(150,90);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture=load("res://assets/heroes/abe-"+("active"if i<int(p.get("intuition",0))else"inactive")+".webp");row.add_child(art)
	var ongoing=p.get("ongoing",{})
	if not ongoing.is_empty():
		body.add_child(_wrap_label("Действующий постоянный приём",24,GOLD))
		body.add_child(_wrap_label(I18n.card_field(str(p.hero_id),str(ongoing.get("id","")),"text",str(ongoing.get("text",""))),23,INK))
		body.add_child(_button("Открыть карту крупно",_zoom_card.bind(ongoing,str(p.hero_id)),320))
