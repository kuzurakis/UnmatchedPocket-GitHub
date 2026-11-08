extends Control
## Artwork, highlights and hit testing share one aspect-preserving transform.

signal node_pressed(node_id: int)
signal item_pressed(index: int)
var _item_textures: Dictionary = {}
var engine
var selected: int = -1
var highlighted: Array = []
var targets: Array = []
var content_insets: Vector2 = Vector2.ZERO
var font: Font = ThemeDB.fallback_font
var zone_colors: Array[Color] = [Color("467c88"), Color("7b638e"), Color("a07b4d"), Color("4c836b")]
var _texture_path: String = ""
var _texture: Texture2D
var avatars: Dictionary = {}
var _avatar_textures: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	custom_minimum_size = Vector2(450, 260)
	if FileAccess.file_exists("res://data/avatars.json"):
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/avatars.json"))
		if data is Dictionary: avatars = data

func _board_data() -> Dictionary:
	if engine == null: return {}
	return engine.board_data

func _refresh_texture() -> void:
	var path := str(_board_data().get("image", ""))
	if path == _texture_path: return
	_texture_path = path
	_texture = null
	if not path.is_empty() and ResourceLoader.exists(path):
		_texture = load(path) as Texture2D
	zone_colors.clear()
	for color in _board_data().get("zone_colors", ["#467c88", "#7b638e", "#a07b4d", "#4c836b"]):
		zone_colors.append(Color(str(color)))

func image_rect() -> Rect2:
	var board := _board_data()
	var native_size := Vector2(float(board.get("width", 1337)), float(board.get("height", 866)))
	var available := Vector2(maxf(1.0, size.x - 8 - content_insets.x - content_insets.y), maxf(1.0, size.y - 8))
	var fit := minf(available.x / native_size.x, available.y / native_size.y)
	var fitted := native_size * fit
	return Rect2(Vector2(4 + content_insets.x + (available.x - fitted.x) / 2.0, 4 + (available.y - fitted.y) / 2.0), fitted)

func point(node_id: int) -> Vector2:
	var pos: Vector2 = engine.nodes[node_id].pos
	var rect := image_rect()
	return rect.position + pos * rect.size

func _node_radius() -> float:
	var board := _board_data()
	if board.is_empty(): return minf(image_rect().size.x / 13.5, image_rect().size.y / 8.5)
	return float(board.get("node_radius", 62)) * image_rect().size.x / float(board.get("width", 1337))

func _draw() -> void:
	if engine == null or engine.nodes.is_empty(): return
	_refresh_texture()
	draw_style_box(_panel(), Rect2(Vector2(1, 1), size - Vector2(2, 2)))
	var rect := image_rect()
	if _texture != null:
		draw_texture_rect(_texture, rect, false)
	else:
		_draw_schematic()
	var radius := _node_radius()
	for i in range(engine.door_states.size()):
		var edge = engine.board_data.doors[i].edges[0]
		var a = point(int(edge[0]))
		var b = Vector2.ZERO
		for link in engine.board_data.doors[i].edges: b += point(int(link[1]))
		b /= float(engine.board_data.doors[i].edges.size())
		var center = a.lerp(b,0.50)
		var axis = (b-a).normalized().orthogonal()*radius*0.66
		draw_line(center-axis,center+axis,Color("ef7257") if engine.door_states[i] else Color("81c2ac"),maxf(3,radius*0.2))
		draw_string(font,center+Vector2(-4,-5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	for n in engine.nodes:
		var p := point(int(n.id))
		if n.id in highlighted:
			draw_circle(p, radius * 0.90, Color(0.18, 1.0, 0.78, 0.27))
			draw_circle(p, radius * 0.93, Color("48f3c3"), false, maxf(2.0, radius * 0.10), true)
		if n.id in targets:
			draw_circle(p, radius * 0.93, Color(1.0, 0.28, 0.20, 0.20))
			draw_circle(p, radius * 0.98, Color("ff8d65"), false, maxf(2.0, radius * 0.12), true)
	for owner in range(engine.players.size()):
		for edge in engine._v36.feet(owner):
			var center=point(int(edge[0])).lerp(point(int(edge[1])),0.5)
			draw_circle(center,radius*0.32,Color("654591"))
			draw_circle(center,radius*0.32,Color("e4bbff"),false,1.4,true)
			draw_line(center+Vector2(-radius*0.19,0),center+Vector2(radius*0.19,0),Color("20152f"),maxf(3,radius*0.14))
			draw_circle(center+Vector2(-radius*0.09,0),maxf(1,radius*0.035),Color.WHITE)
			draw_circle(center+Vector2(radius*0.09,0),maxf(1,radius*0.035),Color.WHITE)
	var fog_tokens = engine.get("fog_tokens")
	if fog_tokens is Array:
		for token in fog_tokens: _draw_fog(token,radius)
	var shadow_tokens = engine.get("shadow_tokens")
	if shadow_tokens is Array:
		for token in shadow_tokens: _draw_shadow(token,radius)
	var trap_tokens = engine.get("traps")
	if trap_tokens is Array:
		for trap in trap_tokens:
			_draw_trap(trap, radius)
	for player in engine.players:
		var pouch=int(player.get("pouch_node",-1))
		if pouch>=0:_badge("⊗",point(pouch)+Vector2(radius*0.6,radius*0.6),clampi(int(radius*0.7),15,24),Color("315a42"),Color("efd69b"))
		for node in player.get("insight",[]):
			draw_circle(point(int(node))+Vector2(radius*0.55,-radius*0.55),radius*0.18,Color("67d8a8"))
	for i in range(engine.battlefield_items.size()):
		var token=engine.battlefield_items[i];var d=engine._v24.definition(token);var item_rect=item_bounds(i)
		var path=str(d.get("image_back",d.image))
		if not _item_textures.has(path):_item_textures[path]=load(path)
		draw_texture_rect(_item_textures[path],item_rect,false,Color(0.35,0.35,0.35,0.85) if token.used else Color.WHITE)
		draw_rect(item_rect,Color("717a82") if token.used else Color("f2cd7f"),false,2.0)
		if token.used:draw_line(item_rect.position,item_rect.end,Color("f17b68"),3.0)
	for fighter in engine.fighters:
		if fighter.alive and bool(fighter.get("placed", true)) and not bool(fighter.get("offboard",false)): _draw_fighter(fighter, radius)
	for player in engine.players:
		for rail in player.get("tracks",[]):_badge("═",point(int(rail))+Vector2(0.62,0.56)*radius,maxi(16,int(radius*0.8)),Color("715335"),Color("ffe5a0"))
	# Cell IDs in all prompts are one-based. Draw last so figures and tokens
	# never cover the number, using the same transform as artwork and hit tests.
	for node in engine.nodes:
		_badge(space_number(int(node.id)),number_center(int(node.id)),clampi(int(radius*0.48),12,18),Color("10212cf2"),Color("ffe5af"))

func item_bounds(index: int) -> Rect2:
	var token=engine.battlefield_items[index];var image=image_rect();var marker=engine.board_data.get("item_markers",{}).get(str(int(token.node)),[])
	var center=point(int(token.node))+Vector2(0.7,-0.7)*_node_radius() if marker.is_empty() else image.position+Vector2(float(marker[0]),float(marker[1]))*image.size
	var edge=maxf(28.0,82.0*image.size.x/float(engine.board_data.get("width",1337)))
	return Rect2(center-Vector2.ONE*edge/2.0,Vector2.ONE*edge)

func space_number(node_id: int) -> String:
	return str(node_id+1)

func number_center(node_id: int) -> Vector2:
	return point(node_id)+Vector2(-0.60,-0.63)*_node_radius()

func _draw_fog(token: Dictionary, node_radius: float) -> void:
	var node := int(token.get("node",-1))
	if node < 0 or node >= engine.nodes.size(): return
	var center := point(node)
	var radius := node_radius*0.81
	var owner_color := _player_color(int(token.get("owner",0)))
	draw_circle(center,radius,Color(0.74,0.91,0.97,0.44))
	draw_circle(center+Vector2(-radius*0.28,-radius*0.14),radius*0.55,Color(0.86,0.96,1,0.35))
	draw_circle(center+Vector2(radius*0.28,radius*0.12),radius*0.50,Color(0.89,0.97,1,0.42))
	draw_arc(center,radius*1.09,0,TAU,32,owner_color,maxf(1.6,node_radius*0.065),true)
	_badge("≈%d" % (int(token.get("id",0))+1),center+Vector2(-radius*0.78,radius*0.60),maxi(10,int(node_radius*0.42)),Color("b8dce9"),Color("102b3b"))

func _draw_shadow(token: Dictionary, node_radius: float) -> void:
	var node := int(token.get("node",-1))
	if node < 0 or node >= engine.nodes.size(): return
	var center := point(node)
	var radius := node_radius*0.86
	draw_circle(center,radius,Color(0.16,0.05,0.25,0.70))
	draw_arc(center,radius,0,TAU,32,Color("d7a4f5"),maxf(1.8,node_radius*0.07),true)
	_badge("☾%d" % (int(token.get("id",0))+1),center+Vector2(-radius*0.67,radius*0.64),maxi(10,int(node_radius*0.42)),Color("482c5b"),Color("f5e4ff"))

func _draw_trap(trap: Dictionary, node_radius: float) -> void:
	var node := int(trap.get("node",-1))
	if node < 0 or node >= engine.nodes.size(): return
	var center := point(node)
	var radius := node_radius * 0.54
	var color := _player_color(int(trap.get("owner",0)))
	draw_circle(center, radius + 2, Color("07121a"))
	draw_circle(center, radius, Color("5d3026"))
	draw_circle(center, radius, color, false, maxf(2,node_radius*0.08), true)
	var teeth := PackedVector2Array()
	for i in range(7):
		teeth.append(center + Vector2((i/6.0-0.5)*radius*1.5, (-0.38 if i%2==0 else 0.30)*radius))
	draw_polyline(teeth, Color("ffe0aa"), maxf(1.5,node_radius*0.08),true)
	draw_arc(center,radius*0.72,0,PI,16,Color("ffe0aa"),maxf(1.5,node_radius*0.07),true)

func _draw_schematic() -> void:
	var radius := _node_radius()
	for node in engine.nodes:
		for neighbor in node.neighbors:
			if int(neighbor) > int(node.id):
				draw_line(point(int(node.id)), point(int(neighbor)), Color("49606b"), 2, true)
	for node in engine.nodes:
		var p := point(int(node.id))
		draw_circle(p, radius, Color("142731"))
		var count := maxi(1, node.zones.size())
		for z in range(node.zones.size()):
			var angle := -PI / 2 + TAU * z / count
			draw_arc(p, radius, angle, angle + TAU / count - 0.06, 24, zone_colors[int(node.zones[z]) % zone_colors.size()], 3, true)

func _draw_fighter(fighter: Dictionary, node_radius: float) -> void:
	var p := point(int(fighter.node))
	if engine._v31.small(int(fighter.id)):
		var group=engine._v31.occupants(int(fighter.node)).filter(func(id):return engine._v31.small(int(id)))
		var index=group.find(int(fighter.id));var angle=-PI/2+TAU*float(index)/maxi(4,group.size())
		p+=Vector2(cos(angle),sin(angle))*node_radius*0.67
	if engine._v19.large(int(fighter.id)) and int(fighter.get("tail",-1))>=0:
		var back=point(int(fighter.tail))
		draw_line(p,back,Color("9b73ae"),node_radius*0.65)
		draw_circle(back,node_radius*0.46,Color("79528c"))
	var radius := node_radius * (0.30 if engine._v31.small(int(fighter.id)) else 0.75 if fighter.hero else 0.68)
	var color := _player_color(int(fighter.owner))
	var selected_fighter := int(fighter.id) == selected
	draw_circle(p + Vector2(0, radius * 0.16), radius * 1.16, Color(0, 0, 0, 0.65))
	if selected_fighter:
		draw_circle(p, node_radius * 1.05, Color("fff3b0"), false, maxf(2.5, node_radius * 0.1), true)
	var vertices := _token_shape(p, radius, bool(fighter.hero))
	draw_colored_polygon(_token_shape(p, radius + 3.0, bool(fighter.hero)), Color("061119"))
	draw_colored_polygon(vertices, color)
	var portrait := avatar_entry(int(fighter.owner), bool(fighter.hero))
	var has_portrait := _draw_avatar(portrait, p, radius - 2.3, bool(fighter.hero))
	if not has_portrait:
		_draw_centered(str(fighter.name).left(1).to_upper(), p + Vector2(0, radius * 0.35), maxi(12, int(radius)), Color("08252d"))
	if not fighter.hero and int(fighter.max_hp) == 1 and not engine._v31.small(int(fighter.id)):
		var order := 0
		for other in engine.fighters:
			if int(other.owner) == int(fighter.owner) and not other.hero:
				order += 1
				if int(other.id) == int(fighter.id): break
		_badge("#%d" % order, p + Vector2(radius * 0.66, radius * 0.62), maxi(10, int(radius * 0.58)), color, Color("061119"))
	if int(fighter.max_hp) > 1:
		_badge(str(int(fighter.hp)), p + Vector2(0, radius * 0.90), maxi(11, int(radius * 0.63)), Color("0a1a25"), Color("fff6dc"))
	var owner := int(fighter.owner)
	var hero_id := str(engine.players[owner].hero_id)
	if fighter.hero and hero_id == "raptors":
		var order := 0
		for other in engine.fighters:
			if int(other.owner) == owner and other.hero:
				order += 1
				if int(other.id) == int(fighter.id): break
		_badge("#%d" % order,p+Vector2(radius*0.70,-radius*0.65),maxi(10,int(radius*0.48)),color,Color("061119"))
	if fighter.hero and hero_id == "alice":
		var is_big := str(engine.alice_size.get(owner, "big")) == "big"
		_badge("↑ +2" if is_big else "↓ +1", p + Vector2(0, -radius * 0.93), maxi(10, int(radius * 0.49)), Color("f4d292") if is_big else Color("9fd8f1"), Color("102330"))
	elif fighter.hero and hero_id == "sinbad":
		var voyages := 0
		for card in engine.players[owner].discard:
			if bool(card.get("voyage", false)): voyages += 1
		_badge("V %d" % voyages, p + Vector2(0, -radius * 0.93), maxi(10, int(radius * 0.49)), Color("efd29a"), Color("102330"))
	elif fighter.hero and hero_id == "muhammad_ali" and engine.has_method("stance_for"):
		var butterfly := str(engine.stance_for(owner)) == "butterfly"
		_badge("↔2" if butterfly else "+2",p+Vector2(0,-radius*0.93),maxi(10,int(radius*0.49)),Color("a7d6ed") if butterfly else Color("f4d175"),Color("102330"))
	elif fighter.hero and hero_id == "jekyll_hyde" and engine.has_method("form_for"):
		var hyde := str(engine.form_for(owner)) == "hyde"
		_badge("H" if hyde else "J",p+Vector2(0,-radius*0.93),maxi(10,int(radius*0.52)),Color("d1a9df") if hyde else Color("aacfd1"),Color("102330"))
	elif fighter.hero and hero_id == "willow" and engine.has_method("willow_form_for"):
		var dark := str(engine.willow_form_for(owner)) == "dark"
		_badge("☾" if dark else "☀",p+Vector2(0,-radius*0.93),maxi(10,int(radius*0.55)),Color("d3a0eb") if dark else Color("e9d789"),Color("102330"))
	elif fighter.hero and hero_id == "beowulf":
		_badge("%d/3" % engine._v8.rage(owner),p+Vector2(0,-radius*0.93),maxi(10,int(radius*0.49)),Color("e9b05e"),Color("102330"))
	if owner != 0 and engine.has_method("are_allies") and engine.are_allies(owner, 0):
		_badge("+", p + Vector2(-radius * 0.85, radius * 0.45), maxi(10, int(radius * 0.54)), Color("69e29d"), Color("0b2616"))
	if int(fighter.get("locked_until",-1)) == engine.turn_number:
		_badge("×",p+Vector2(radius*0.85,radius*0.15),12,Color("a14532"),Color.WHITE)

func _token_shape(center: Vector2, radius: float, hero: bool) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	var sides := 48 if hero else 6
	for n in range(sides):
		vertices.append(center + Vector2.from_angle(TAU * n / float(sides) - PI / 2) * radius)
	return vertices

func avatar_entry(owner: int, hero: bool = true) -> Dictionary:
	if engine == null or owner < 0 or owner >= engine.players.size(): return {}
	var key := str(engine.players[owner].hero_id)
	var entry: Dictionary = avatars.get(key, {}).get("hero" if hero else "sidekick", {})
	if key=="yennefer_triss" and engine._v17.main_for(owner)=="triss":entry=avatars[key]["sidekick" if hero else "hero"]
	if hero and key == "jekyll_hyde" and engine.has_method("form_for") and engine.form_for(owner) == "hyde":
		entry = avatars.get(key,{}).get("hero_hyde",entry)
	if not hero and key == "buffy" and str(engine.players[owner].get("buffy_sidekick","giles")) == "xander":
		entry = avatars.get(key,{}).get("sidekick_xander",entry)
	if hero and key == "willow" and engine.has_method("willow_form_for") and engine.willow_form_for(owner) == "dark":
		entry = avatars.get(key,{}).get("hero_dark",entry)
	return entry

func _draw_avatar(entry: Dictionary, center: Vector2, radius: float, hero: bool) -> bool:
	var path := str(entry.get("path", ""))
	if path.is_empty(): return false
	if not _avatar_textures.has(path):
		if not ResourceLoader.exists(path): return false
		_avatar_textures[path] = load(path) as Texture2D
	var texture: Texture2D = _avatar_textures[path]
	if texture == null: return false
	var region: Array = entry.get("region", [0, 0, texture.get_width(), texture.get_height()])
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	var vertices := _token_shape(center, radius, hero)
	var uvs := PackedVector2Array()
	for vertex in vertices:
		var unit := ((vertex - center) / radius + Vector2.ONE) * 0.5
		uvs.append((Vector2(float(region[0]), float(region[1])) + unit * Vector2(float(region[2]), float(region[3]))) / texture_size)
	draw_polygon(vertices, PackedColorArray([Color.WHITE]), uvs, texture)
	return true

func _badge(text: String, center: Vector2, font_size: int, background: Color, ink: Color) -> void:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var badge_size := Vector2(maxf(font_size + 5, text_width + 8), font_size + 5)
	var box := _hp_panel()
	box.bg_color = background
	draw_style_box(box, Rect2(center - badge_size * 0.5, badge_size))
	_draw_centered(text, center + Vector2(0, font_size * 0.34), font_size, ink)

func _draw_centered(text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, baseline - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_legend() -> void:
	var board := _board_data()
	var label := str(board.get("name", "Учебная арена"))
	var info := "%s · %d клеток · %d зон" % [label, engine.nodes.size(), zone_colors.size()]
	draw_string(font, Vector2(12, size.y - 10), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b7cad0"))
	var x := size.x - 12.0 - zone_colors.size() * 13.0
	for color in zone_colors:
		draw_circle(Vector2(x, size.y - 14), 4.2, color)
		x += 13.0

func _player_color(owner: int) -> Color:
	if owner != 0 and engine != null and engine.has_method("are_allies") and engine.are_allies(owner, 0):
		return Color("67dea0")
	var colors := [Color("67c7ff"), Color("ffb66e"), Color("c7a6ff"), Color("f4e276")]
	return colors[owner % 4]

func _panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("101f2a")
	box.border_color = Color("2c414b")
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	return box

func _hp_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("08151e")
	box.border_color = Color("829594")
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box

func _gui_input(event: InputEvent) -> void:
	if engine == null: return
	var location: Vector2
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		location = event.position
	else:
		return
	for i in range(engine.battlefield_items.size()-1,-1,-1):
		if item_bounds(i).has_point(location):item_pressed.emit(i);accept_event();return
	if not image_rect().has_point(location): return
	var nearest := -1
	var best_distance := maxf(15.0, _node_radius() * 1.05)
	for node in engine.nodes:
		var distance := point(int(node.id)).distance_to(location)
		if distance < best_distance:
			best_distance = distance
			nearest = int(node.id)
	if nearest >= 0:
		node_pressed.emit(nearest)
		accept_event()
