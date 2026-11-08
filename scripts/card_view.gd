extends Button
## A portrait card front with a short Russian label, suitable for a touch hand.
## The image is the original English card front from the bundled UmDb asset.

const SMALL_SIZE = Vector2(137, 202)
const I18n = preload("res://scripts/i18n.gd")
const LARGE_SIZE = Vector2(210, 300)
const TYPE_NAMES = {"attack": "АТАКА", "defense": "ЗАЩИТА", "versatile": "УНИВЕРСАЛ", "scheme": "ПРИЁМ"}
const COMPACT_TYPE_NAMES = {"attack": "АТК", "defense": "ЗАЩ", "versatile": "УН", "scheme": "ПРМ"}
const TYPE_COLORS = {
	"attack": Color("e99069"),
	"defense": Color("72bcdf"),
	"versatile": Color("c5a0e5"),
	"scheme": Color("e6c46b")
}

static var _image_catalog: Dictionary = {}
static var _catalog_loaded = false
var card_image_path = ""
var card_data: Dictionary = {}
var card_hero_id = ""
var is_large = false
var _front: TextureRect
var _footer: PanelContainer
var _title: Label
var _stats: Label
var _fallback: Label
var _basket_badge: Label

static func basket_label(card: Dictionary) -> String:
	if card.has("basket_symbols") and not card.has("basket_copy"): return I18n.text("Три символа")
	return I18n.text({"knife":"Нож","pelt":"Шкура","flower":"Цветок","wild":"Любой один"}.get(str(card.get("basket_symbol","wild")),"Любой один"))

static func trait_label(card: Dictionary) -> String:
	if card.get("source",false): return I18n.text("Источник")
	if card.has("gear_slot"): return I18n.text("Снаряжение")
	if card.has("syllables"): return I18n.text("Слогов: %d" % int(card.syllables))
	if card.has("ingredient"): return I18n.text({"snake":"Змея","bat":"Мышь","lizard":"Ящерица"}.get(str(card.ingredient),""))
	return basket_label(card)

func _init():
	set_meta("i18n_self_managed", true)
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = SMALL_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text = ""
	resized.connect(_update_text_width)

static func _load_catalog():
	if _catalog_loaded:
		return
	_catalog_loaded = true
	var catalog_path = "res://data/card_images.json"
	if FileAccess.file_exists(catalog_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
		if parsed is Dictionary:
			_image_catalog = parsed.get("cards", {})

static func boost_label(card: Dictionary) -> String:
	if card.get("dice_boost",false):return "⚄"
	var allowed = bool(card.get("can_boost", not (bool(card.get("voyage",false)) and int(card.get("boost",0)) == 0)))
	return str(int(card.get("boost",0))) if allowed else "—"

func image_path(card: Dictionary, hero_id: String) -> String:
	if card.get("trick",false):hero_id="loki"
	_load_catalog()
	var hero_images: Dictionary = _image_catalog.get(hero_id, {})
	var entry: Dictionary = hero_images.get(str(card.get("id", "")), {})
	return str(entry.get("path_ru",entry.get("path",""))) if I18n.language=="ru" else str(entry.get("path",""))

func set_card(card: Dictionary, hero_id: String, large: bool = false):
	if card.get("trick",false):hero_id="loki"
	card_data = card.duplicate(true)
	card_hero_id = hero_id
	is_large = large
	_ensure_layout()
	custom_minimum_size = LARGE_SIZE if large else SMALL_SIZE
	card_image_path = image_path(card, hero_id)
	_front.texture = load(card_image_path) if not card_image_path.is_empty() and ResourceLoader.exists(card_image_path) else null
	_fallback.visible = _front.texture == null
	_fallback.text = I18n.card_field(hero_id, str(card.get("id", "")), "text", str(card.get("text", "")))
	_title.text = _translated_title()
	_title.add_theme_font_size_override("font_size", 17 if large else 13)
	_title.custom_minimum_size.y = 46 if large else 34
	_stats.add_theme_font_size_override("font_size", 12 if large else 10)
	var card_type = str(card.get("type", "versatile"))
	var type_name = I18n.text(str(TYPE_NAMES.get(card_type, card_type.to_upper())))
	var tint: Color = TYPE_COLORS.get(card_type, Color("c5a0e5"))
	_stats.add_theme_color_override("font_color", tint)
	_footer.offset_top = -73 if large else -61
	_footer.add_theme_stylebox_override("panel", _footer_style(tint))
	_set_card_styles(tint)
	_basket_badge.visible = hero_id == "little_red" or card.has("syllables") or card.has("ingredient") or card.get("source",false) or card.has("gear_slot")
	_basket_badge.text = trait_label(card)
	_update_text_width()
	tooltip_text = "%s\n%s\nBOOST %s\n%s" % [_translated_title(), type_name, boost_label(card), _fallback.text]

func _translated_title() -> String:
	return I18n.card_field(card_hero_id, str(card_data.get("id", "")), "name", str(card_data.get("name", "Карта")))

func refresh_language():
	if _title == null: return
	_fallback.text = I18n.card_field(card_hero_id, str(card_data.get("id", "")), "text", str(card_data.get("text", "")))
	_update_text_width()
	_basket_badge.text = trait_label(card_data)
	tooltip_text = "%s\n%s\nBOOST %s\n%s" % [_translated_title(), I18n.text(str(TYPE_NAMES.get(str(card_data.get("type", "")), ""))), boost_label(card_data), _fallback.text]

func _update_text_width():
	if _title == null:
		return
	var card_width = size.x if size.x > 0 else custom_minimum_size.x
	var label_width = maxf(40, card_width - 20)
	_title.text = _two_line_title(_translated_title(), label_width)
	_fallback.custom_maximum_size.x = label_width
	_update_stats(card_width, label_width)

func _update_stats(card_width: float, label_width: float):
	var card_type = str(card_data.get("type", "versatile"))
	var type_name = str(TYPE_NAMES.get(card_type, card_type.to_upper()))
	if card_width < 130:
		type_name = str(COMPACT_TYPE_NAMES.get(card_type, type_name))
	elif not is_large and card_type == "versatile":
		type_name = "УНИВ."
	type_name = I18n.text(type_name)
	var value = "—" if card_type == "scheme" else str(int(card_data.get("value", 0)))
	var boost = boost_label(card_data)
	var line = "%s %s · BOOST%s" % [type_name, value, boost]
	var font = _stats.get_theme_font("font")
	var font_size = 12 if is_large else 10
	if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label_width:
		line = "%s %s · ↑%s" % [type_name, value, boost]
	_stats.text = line

func _two_line_title(value: String, width: float) -> String:
	var font = _title.get_theme_font("font")
	var font_size = 17 if is_large else 13
	if not value.contains(" ") and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		var split = 1
		while split < value.length() and font.get_string_size(value.left(split + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
			split += 1
		return value.left(split) + "\n" + _elide(value.substr(split), width, font, font_size)
	var words = value.split(" ", false)
	var first = ""
	var index = 0
	while index < words.size():
		var candidate = first + (" " if not first.is_empty() else "") + words[index]
		if not first.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			break
		first = candidate
		index += 1
	if index >= words.size():
		return _elide(first, width, font, font_size)
	var remaining = " ".join(words.slice(index))
	return _elide(first, width, font, font_size) + "\n" + _elide(remaining, width, font, font_size)

func _elide(value: String, width: float, font: Font, font_size: int) -> String:
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return value
	var shortened = value
	while not shortened.is_empty() and font.get_string_size(shortened + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		shortened = shortened.substr(0, shortened.length() - 1)
	return shortened.strip_edges() + "…"

func _ensure_layout():
	if _front != null:
		return
	_front = TextureRect.new()
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_front.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_front)
	_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_front.offset_left = 5
	_front.offset_top = 5
	_front.offset_right = -5
	_front.offset_bottom = -5

	_fallback = Label.new()
	_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback.add_theme_font_size_override("font_size", 12)
	_fallback.add_theme_color_override("font_color", Color("e9eee9"))
	add_child(_fallback)
	_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fallback.offset_left = 10
	_fallback.offset_top = 12
	_fallback.offset_right = -10
	_fallback.offset_bottom = -55

	_footer = PanelContainer.new()
	_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_footer)
	_footer.anchor_top = 1.0
	_footer.anchor_right = 1.0
	_footer.anchor_bottom = 1.0
	_footer.offset_left = 5
	_footer.offset_right = -5
	_footer.offset_bottom = -5
	_footer.offset_top = -61
	var labels = VBoxContainer.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_theme_constant_override("separation", 0)
	_footer.add_child(labels)
	_title = Label.new()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.max_lines_visible = 2
	_title.clip_text = true
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", Color("fff4db"))
	labels.add_child(_title)
	_stats = Label.new()
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_stats.clip_text = true
	labels.add_child(_stats)
	_basket_badge = Label.new()
	_basket_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_basket_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_basket_badge.add_theme_font_size_override("font_size",12)
	_basket_badge.add_theme_color_override("font_color",Color("fff0b5"))
	_basket_badge.add_theme_stylebox_override("normal",_footer_style(Color("e6c46b")))
	add_child(_basket_badge)
	_basket_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_basket_badge.offset_left=30
	_basket_badge.offset_top=7
	_basket_badge.offset_right=-7
	_basket_badge.offset_bottom=29

func _set_card_styles(tint: Color):
	add_theme_stylebox_override("normal", _card_style(Color("172b35"), tint.darkened(0.35), 1))
	add_theme_stylebox_override("hover", _card_style(Color("23424a"), Color("e8c38a"), 3))
	add_theme_stylebox_override("pressed", _card_style(Color("173c3b"), Color("61cfba"), 3))
	add_theme_stylebox_override("hover_pressed", _card_style(Color("234c49"), Color("96f0d9"), 3))
	add_theme_stylebox_override("disabled", _card_style(Color("13212a"), Color("45545b"), 1))
	var focus = _card_style(Color.TRANSPARENT, Color("e8c38a"), 2)
	focus.draw_center = false
	add_theme_stylebox_override("focus", focus)

func _card_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _footer_style(tint: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.075, 0.95)
	style.border_color = tint.darkened(0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style
