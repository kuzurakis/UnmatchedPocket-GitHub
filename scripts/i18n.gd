class_name ArenaI18n
extends RefCounted
## Source strings stay Russian; IDs, metadata, save data and scan images stay stable.

const LANGUAGE_CODES = ["ru", "en", "nb", "es"]
const LANGUAGE_NAMES = {"ru": "Русский", "en": "English", "nb": "Norsk bokmål", "es": "Español"}
static var language = "ru"
static var _loaded = false
static var _catalog: Dictionary = {}
static var _maps: Dictionary = {}
static var _reverse: Dictionary = {}
static var _rules: Dictionary = {}
static var _reverse_rules: Array = []
static var _chunks: Dictionary = {}
static var _source_letters = RegEx.new()

static func _load_catalog():
	if _loaded:
		return
	_loaded = true
	_source_letters.compile("[А-Яа-яЁё]")
	var path = "res://data/locales.json"
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			_catalog = parsed
	_maps = _catalog.get("translations", {})
	var source_names = _name_pattern("ru")
	for code in ["en", "nb", "es"]:
		var translated_names = _name_pattern(code)
		var mapping: Dictionary = _maps.get(code, {})
		var rules: Array = []
		var chunks: Array = []
		for source in mapping:
			var translated = str(mapping[source])
			if translated.is_empty():
				continue
			_reverse[translated] = str(source)
			if str(source).contains("%"):
				var rule = _format_rule(str(source), translated, source_names)
				if not rule.is_empty():
					rules.append(rule)
				var reverse_rule = _format_rule(translated, str(source), translated_names)
				if not reverse_rule.is_empty():
					_reverse_rules.append(reverse_rule)
			else:
				chunks.append({"source": str(source), "target": translated})
		rules.sort_custom(func(a, b): return a.source.length() > b.source.length())
		chunks.sort_custom(func(a, b): return a.source.length() > b.source.length())
		_rules[code] = rules
		_chunks[code] = chunks
	_reverse_rules.sort_custom(func(a, b): return a.source.length() > b.source.length())

static func set_language(code: String):
	_load_catalog()
	var requested = code.to_lower().replace("_", "-")
	if requested == "no" or requested.begins_with("nb-"):
		requested = "nb"
	language = requested if requested in LANGUAGE_CODES else "ru"

static func text(source: String) -> String:
	_load_catalog()
	return _translate(source, 0)

static func _translate(source: String, depth: int) -> String:
	if language == "ru" or source.is_empty() or depth > 6:
		return source
	var mapping: Dictionary = _maps.get(language, {})
	if mapping.has(source):
		return str(mapping[source])
	for rule in _rules.get(language, []):
		var matched: RegExMatch = rule.regex.search(source)
		if matched != null:
			var rendered = _render_rule(rule, matched, depth, false)
			# A generic log template can also match the tail of a complete card
			# rule inside a label, such as "Hero. [full Rope-a-dope rules]".
			# Retain the full translated rule when it covers more source text.
			var remaining = _source_letters.search_all(rendered).size()
			if remaining > 0:
				var chunked = _replace_chunks(source)
				if _source_letters.search_all(chunked).size() < remaining:
					return chunked
			return rendered
	if source.contains("\n"):
		var lines = source.split("\n", true)
		for i in range(lines.size()):
			lines[i] = _translate(lines[i], depth + 1)
		return "\n".join(lines)
	return _replace_chunks(source)

static func _replace_chunks(source: String) -> String:
	var result = source
	for chunk in _chunks.get(language, []):
		if result.contains(str(chunk.source)):
			result = result.replace(str(chunk.source), str(chunk.target))
	return result

static func hero_name(hero_id: String) -> String:
	return hero_field(hero_id, "name", hero_id)

static func hero_field(hero_id: String, field: String, fallback: String = "") -> String:
	_load_catalog()
	var by_language: Dictionary = _catalog.get("heroes", {})
	var table: Dictionary = by_language.get(language, {})
	var hero: Dictionary = table.get(hero_id, {})
	return str(hero[field]) if hero.has(field) else text(fallback)

static func card_field(hero_id: String, card_id: String, field: String, fallback: String = "") -> String:
	_load_catalog()
	var by_language: Dictionary = _catalog.get("cards", {})
	var table: Dictionary = by_language.get(language, {})
	var hero: Dictionary = table.get(hero_id, {})
	var card: Dictionary = hero.get(card_id, {})
	return str(card[field]) if card.has(field) else text(fallback)

static func _regex_escape(value: String) -> String:
	var result = ""
	for character in value:
		if character in "\\.^$|?*+()[]{}":
			result += "\\"
		result += character
	return result

static func _name_pattern(code: String) -> String:
	var names: Array = []
	for hero in _catalog.get("heroes", {}).get(code, {}).values():
		for field in ["name", "sidekick_name"]:
			var value = str(hero.get(field, ""))
			if not value.is_empty() and value != "—" and not value in names:
				names.append(value)
		for value in hero.get("fighter_names", []):
			if not str(value).is_empty() and not str(value) in names:
				names.append(str(value))
		if int(hero.get("sidekick_count", 0)) > 1:
			for number in range(1, int(hero.sidekick_count) + 1):
				var value = str(hero.get("sidekick_name", "")) + " " + str(number)
				if not value in names:
					names.append(value)
	for deck in _catalog.get("cards", {}).get(code, {}).values():
		for card in deck.values():
			var value = str(card.get("name", ""))
			if not value.is_empty() and not value in names:
				names.append(value)
	names.sort_custom(func(a, b): return a.length() > b.length())
	var alternatives: Array = []
	for value in names:
		alternatives.append(_regex_escape(str(value)))
	return "(?:" + "|".join(alternatives) + ")(?![\\p{L}\\p{N}_])" if not alternatives.is_empty() else ""

static func _format_rule(source: String, target: String, names: String = "") -> Dictionary:
	var placeholders = RegEx.new()
	placeholders.compile("%[-+0 #]*[0-9]*(?:\\.[0-9]+)?[sdf]")
	var matches = placeholders.search_all(source)
	if matches.is_empty() or matches.size() != placeholders.search_all(target).size():
		return {}
	var pattern = "(?s)^"
	var types: Array = []
	var previous = 0
	for index in range(matches.size()):
		var item = matches[index]
		pattern += _regex_escape(source.substr(previous, item.get_start() - previous))
		var type = item.get_string().right(1)
		types.append(type)
		var value_pattern = "([-+]?[0-9]+)" if type == "d" else "([-+]?[0-9]+(?:[.,][0-9]+)?)" if type == "f" else "(.*?)"
		# Separators such as spaces and "and" also occur inside fighter names.
		# Prefer a complete known name and forbid backtracking into its words.
		# Otherwise a longer three-field template can shadow a two-field one.
		if type == "s" and not names.is_empty() and index + 1 < matches.size() and matches[index + 1].get_string().right(1) == "s":
			var separator = source.substr(item.get_end(), matches[index + 1].get_start() - item.get_end())
			if not separator.is_empty():
				value_pattern = "((?>" + names + ")|(?!(?:" + names + ")).*?)"
		pattern += value_pattern
		previous = item.get_end()
	pattern += _regex_escape(source.substr(previous)) + "$"
	var regex = RegEx.new()
	if regex.compile(pattern) != OK:
		return {}
	return {"source": source, "target": target, "types": types, "regex": regex}

static func _render_rule(rule: Dictionary, matched: RegExMatch, depth: int, reverse: bool) -> String:
	var values: Array = []
	for i in range(rule.types.size()):
		var captured = matched.get_string(i + 1)
		if str(rule.types[i]) == "d":
			values.append(captured.to_int())
		elif str(rule.types[i]) == "f":
			values.append(captured.replace(",", ".").to_float())
		else:
			values.append(_canonical(captured, depth + 1) if reverse else _translate(captured, depth + 1))
	return str(rule.target) % values

static func _canonical(value: String, depth: int = 0) -> String:
	if depth > 6:
		return value
	if _reverse.has(value):
		return str(_reverse[value])
	for rule in _reverse_rules:
		var matched: RegExMatch = rule.regex.search(value)
		if matched != null:
			return _render_rule(rule, matched, depth, true)
	return value

static func set_text(node: Object, source: String):
	_load_catalog()
	var canonical = _canonical(source)
	var rendered = text(canonical)
	node.set_meta("i18n_source_text", canonical)
	node.set_meta("i18n_rendered_text", rendered)
	node.set("text", rendered)

static func _translate_property(node: Object, property: String):
	var current = str(node.get(property))
	var source_key = "i18n_source_" + property
	var rendered_key = "i18n_rendered_" + property
	var source = str(node.get_meta(source_key, ""))
	if not node.has_meta(source_key) or current != str(node.get_meta(rendered_key, "")):
		source = _canonical(current)
		node.set_meta(source_key, source)
	var rendered = text(source)
	node.set(property, rendered)
	node.set_meta(rendered_key, rendered)

static func _translate_items(node: Object):
	for i in range(node.get_item_count()):
		var current = str(node.get_item_text(i))
		var source_key = "i18n_item_source_" + str(i)
		var rendered_key = "i18n_item_rendered_" + str(i)
		var source = str(node.get_meta(source_key, ""))
		if not node.has_meta(source_key) or current != str(node.get_meta(rendered_key, "")):
			source = _canonical(current)
			node.set_meta(source_key, source)
		var rendered = text(source)
		node.set_item_text(i, rendered)
		node.set_meta(rendered_key, rendered)

static func translate_tree(node: Node):
	_load_catalog()
	if node.get_meta("i18n_self_managed", false) and node.has_method("refresh_language"):
		node.call("refresh_language")
		return
	if node is OptionButton or node is PopupMenu:
		_translate_items(node)
	elif node is Label or node is Button or node is RichTextLabel:
		_translate_property(node, "text")
	if node is Control:
		_translate_property(node, "tooltip_text")
	if node is TabContainer:
		for i in range(node.get_tab_count()):
			var current = node.get_tab_title(i)
			var source_key = "i18n_tab_source_" + str(i)
			var rendered_key = "i18n_tab_rendered_" + str(i)
			var source = str(node.get_meta(source_key, ""))
			if not node.has_meta(source_key) or current != str(node.get_meta(rendered_key, "")):
				source = _canonical(current)
				node.set_meta(source_key, source)
			var rendered = text(source)
			node.set_tab_title(i, rendered)
			node.set_meta(rendered_key, rendered)
	for child in node.get_children():
		translate_tree(child)
