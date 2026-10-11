class_name ArenaView
extends Node2D

const INK := Color("20262d")
const CYAN := Color("6ee6e1")
var snapshot: Dictionary = {}
var shown: Dictionary = {}
var local_id := 1
var camera := Vector2(1024, 768)
var time := 0.0
var preview := true
var input_move := Vector2.ZERO
var input_guard := false
var blocker := ArenaRoom.new()
var font: Font = ThemeDB.fallback_font
var last_snapshot := 0.0
var pixel_assets := ArenaPixelAssets.new()
var animation_clocks: Dictionary = {}
var carry_visuals: Dictionary = {}
var pixel_fx := ArenaPixelFX.new()
var pixel_environment := ArenaPixelEnvironment.new()

func receive(data: Dictionary) -> void:
	var phase_changed: bool = snapshot.get("phase", "") != data.phase
	snapshot = data
	last_snapshot = time
	blocker.walls = data.walls
	blocker.boxes = data.boxes
	for id in data.fighters:
		var p: Vector2 = data.fighters[id].pos
		if not shown.has(id) or phase_changed or shown[id].distance_to(p) > 130:
			shown[id] = p
		elif id == local_id:
			shown[id] = shown[id].lerp(p, 0.3)
	for id in shown.keys():
		if not data.fighters.has(id):
			shown.erase(id)

func screen_to_world(point: Vector2) -> Vector2:
	return point + camera - get_viewport_rect().size / 2

func world_to_screen(point: Vector2) -> Vector2:
	return (point - camera + get_viewport_rect().size / 2).round()

func _process(delta: float) -> void:
	time += delta
	for id in snapshot.get("fighters", {}):
		var fighter: Dictionary = snapshot.fighters[id]
		var carry: Dictionary = carry_visuals.get(id, {"owner": -1, "pickup_left": 0.0})
		if fighter.carrying != -1 and carry.owner != fighter.carrying:
			carry.pickup_left = 0.18
		else:
			carry.pickup_left = maxf(0, carry.pickup_left - delta)
		carry.owner = fighter.carrying
		carry_visuals[id] = carry
		var state: String = "ko" if fighter.hp <= 0 else fighter.state
		if fighter.carrying != -1 and state in ["idle", "walk", "guard"]:
			state = "pickup" if carry.pickup_left > 0 else ("carry_walk" if state == "walk" else "carry")
		if not animation_clocks.has(id) or animation_clocks[id].state != state:
			animation_clocks[id] = {"state": state, "elapsed": 0.0, "aim": snapshot.fighters[id].aim}
		else:
			animation_clocks[id].elapsed += delta
	if preview:
		camera = Vector2(1024 + sin(time * 0.1) * 100, 768 + cos(time * 0.13) * 65)
	else:
		for id in snapshot.get("fighters", {}):
			var f: Dictionary = snapshot.fighters[id]
			if id == local_id and snapshot.phase == "fight" and time - last_snapshot < 0.3:
				var speed := 220.0 if f.character == "Edward" else 200.0
				if f.carrying != -1:
					speed *= 0.68
				elif input_guard:
					speed *= 0.45
				if f.state_time <= 0 or f.state in ["walk", "idle", "guard"]:
					var local_f := {"pos": shown.get(id, f.pos)}
					blocker.move_fighter(local_f, input_move * speed * delta)
					shown[id] = local_f.pos
			elif id != local_id:
				shown[id] = shown.get(id, f.pos).lerp(f.pos, minf(1, delta * 18))
		if shown.has(local_id):
			camera = camera.lerp(shown[local_id], minf(1, delta * 12))
		var half := get_viewport_rect().size / 2
		camera = camera.clamp(half, ArenaRoom.SIZE - half)
	queue_redraw()

func _draw() -> void:
	var viewport := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), Color("625b50"))
	var origin := camera - viewport / 2
	var first := (origin / 32).floor()
	var count := (viewport / 32).ceil() + Vector2(2, 2)
	for y in range(int(first.y), int(first.y + count.y)):
		for x in range(int(first.x), int(first.x + count.x)):
			var p := world_to_screen(Vector2(x * 32, y * 32))
			var n := posmod(x * 73 + y * 137 + x * y * 11, 17)
			var shade := Color("8b8170").lightened(n / 170.0)
			if x < 2 or y < 2 or x >= 62 or y >= 46:
				shade = Color("3e4244")
			var floor_art := pixel_environment.texture("floor")
			if floor_art != null:
				var tint := Color("697377") if x < 2 or y < 2 or x >= 62 or y >= 46 else Color.WHITE.darkened(n / 300.0)
				draw_texture_rect(floor_art, Rect2(p, Vector2(32, 32)), false, tint)
				continue
			draw_rect(Rect2(p, Vector2(31, 31)), shade)
			draw_line(p + Vector2(1, 1), p + Vector2(29, 1), shade.lightened(0.13), 1)
			if n < 3:
				draw_line(p + Vector2(6, 8), p + Vector2(11, 14), shade.darkened(0.2), 1)
				draw_line(p + Vector2(11, 14), p + Vector2(8, 21), shade.darkened(0.2), 1)
			if n == 9:
				draw_rect(Rect2(p + Vector2(24, 23), Vector2(3, 2)), shade.darkened(0.25))
	# Alchemical pattern in the central courtyard.
	var center := world_to_screen(Vector2(1024, 768))
	draw_arc(center, 210, 0, TAU, 64, Color(0.25, 0.26, 0.25, 0.22), 2)
	draw_arc(center, 202, 0, TAU, 64, Color(0.25, 0.26, 0.25, 0.22), 1)
	for i in 6:
		var a := Vector2.from_angle(i * TAU / 6)
		var b := Vector2.from_angle((i + 2) * TAU / 6)
		draw_line(center + a * 202, center + b * 202, Color(0.25, 0.26, 0.25, 0.15), 1)
	for rect in ArenaRoom.PERMANENT:
		draw_column(rect)
	if preview:
		draw_box(Vector2(850, 700), false)
		draw_box(Vector2(1180, 880), false)
		draw_wall({"rect": Rect2(1000, 685, 28, 160), "hp": 35.0, "life": 7.0})
		draw_fighter({"pos": Vector2(885, 800), "character": "Edward", "state": "idle", "aim": Vector2.RIGHT, "invulnerable": 0.0, "name": "", "carrying": -1}, 0)
		draw_fighter({"pos": Vector2(1160, 740), "character": "Alphonse", "state": "idle", "aim": Vector2.LEFT, "invulnerable": 0.0, "name": "", "carrying": -1}, 0)
		return
	for wall in snapshot.get("walls", []):
		draw_wall(wall)
	for effect in snapshot.get("effects", []):
		if effect.pending:
			draw_effect(effect)
		elif pixel_fx.has_effect(effect.kind):
			draw_effect(effect, "behind")
	var objects: Array = []
	for box in snapshot.get("boxes", []):
		if box.owner == 0:
			objects.append({"y": box.pos.y, "box": box})
	for id in snapshot.get("fighters", {}):
		var f: Dictionary = snapshot.fighters[id].duplicate()
		f.pos = shown.get(id, f.pos)
		objects.append({"y": f.pos.y, "fighter": f, "id": id})
	objects.sort_custom(func(a, b): return a.y < b.y)
	for object in objects:
		if object.has("box"):
			draw_box(object.box.pos, object.box.vel.length() > 0)
		else:
			draw_fighter(object.fighter, object.id)
	for effect in snapshot.get("effects", []):
		if not effect.pending:
			draw_effect(effect)
	if snapshot.get("fighters", {}).has(local_id):
		var f: Dictionary = snapshot.fighters[local_id]
		var p := world_to_screen(shown.get(local_id, f.pos))
		var aim: Vector2 = f.aim
		for i in range(3, 9):
			draw_rect(Rect2((p + aim * i * 9).round(), Vector2(2, 2)), Color(0.6, 1, 0.95, 0.35))
		var cursor := get_global_mouse_position().round()
		draw_arc(cursor, 7, 0, TAU, 16, CYAN, 1)
		draw_line(cursor - Vector2(11, 0), cursor - Vector2(5, 0), CYAN, 1)
		draw_line(cursor + Vector2(5, 0), cursor + Vector2(11, 0), CYAN, 1)
		# Offscreen rival direction marker.
		for id in snapshot.fighters:
			if id == local_id:
				continue
			var enemy := world_to_screen(shown.get(id, snapshot.fighters[id].pos))
			if not Rect2(Vector2(24, 80), viewport - Vector2(48, 160)).has_point(enemy):
				var direction := (enemy - viewport / 2).normalized()
				var tip := enemy.clamp(Vector2(26, 94), viewport - Vector2(26, 90))
				draw_colored_polygon(PackedVector2Array([tip + direction * 9, tip - direction * 7 + direction.orthogonal() * 6, tip - direction * 7 - direction.orthogonal() * 6]), Color("e9b56d"))
				draw_string(font, tip + Vector2(-25, 22), "RIVAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f0dbc0"))

func pixel_rect(pos: Vector2, size: Vector2, color: Color, outline: bool = true) -> void:
	if outline:
		draw_rect(Rect2(pos - Vector2.ONE, size + Vector2(2, 2)), INK)
	draw_rect(Rect2(pos, size), color)

func draw_column(rect: Rect2) -> void:
	var p := world_to_screen(rect.position)
	draw_rect(Rect2(p + Vector2(8, 10), rect.size), Color(0.1, 0.13, 0.16, 0.3))
	var column_art := pixel_environment.texture("column")
	if column_art != null:
		for y in range(0, int(rect.size.y), 32):
			for x in range(0, int(rect.size.x), 32):
				draw_texture_rect(column_art, Rect2(p + Vector2(x, y), Vector2(mini(32, int(rect.size.x) - x), mini(32, int(rect.size.y) - y))), false)
		return
	pixel_rect(p, rect.size, Color("5e6468"))
	for y in range(0, int(rect.size.y), 32):
		for x in range(0, int(rect.size.x), 32):
			draw_rect(Rect2(p + Vector2(x + 1, y + 1), Vector2(30, 30)), Color("a39b86"))
			draw_line(p + Vector2(x + 3, y + 3), p + Vector2(x + 28, y + 3), Color("c2bba6"), 2)
	draw_rect(Rect2(p + Vector2(0, rect.size.y - 7), Vector2(rect.size.x, 7)), Color("676a64"))

func draw_wall(wall: Dictionary) -> void:
	var rect: Rect2 = wall.rect
	var p := world_to_screen(rect.position)
	draw_rect(Rect2(p + Vector2(5, 8), rect.size), Color(0.1, 0.15, 0.18, 0.3))
	var wall_art := pixel_environment.texture("wall")
	if wall_art != null:
		for y in range(0, int(rect.size.y), 16):
			for x in range(0, int(rect.size.x), 16):
				var width := mini(16, int(rect.size.x) - x)
				draw_texture_rect(wall_art, Rect2(p + Vector2(x, y - 8), Vector2(width, 24)), false)
		if wall.hp < 35:
			draw_rect(Rect2(p + Vector2(0, -15), Vector2(rect.size.x * wall.hp / 35, 2)), CYAN)
		return
	pixel_rect(p, rect.size, Color("746f62"))
	for y in range(0, int(rect.size.y), 16):
		for x in range(0, int(rect.size.x), 16):
			var h := posmod(x * 3 + y * 7, 8)
			pixel_rect(p + Vector2(x + 2, y - 7 - h), Vector2(12, 18 + h), Color("b1a68c"))
			if wall.life > 6:
				draw_line(p + Vector2(x + 8, y), p + Vector2(x + 3, y - 10), CYAN, 2)
	if wall.hp < 35:
		draw_rect(Rect2(p + Vector2(0, -15), Vector2(rect.size.x * wall.hp / 35, 2)), CYAN)

func draw_box(world: Vector2, flying: bool) -> void:
	var p := world_to_screen(world) - Vector2(14, 22)
	draw_rect(Rect2(p + Vector2(4, 18), Vector2(29, 15)), Color(0.1, 0.12, 0.14, 0.27))
	var crate_art := pixel_environment.texture("crate")
	if crate_art != null:
		draw_texture_rect(crate_art, Rect2(p - Vector2(2, 4), Vector2(32, 32)), false)
		if flying:
			draw_line(p + Vector2(-12, 10), p + Vector2(-4, 10), Color("e9d3ad"), 2)
		return
	pixel_rect(p, Vector2(28, 28), Color("a27442"))
	pixel_rect(p + Vector2(3, 3), Vector2(22, 22), Color("755038"))
	for x in [5, 13, 21]:
		draw_line(p + Vector2(x, 4), p + Vector2(x, 24), Color("bb8950"), 2)
	draw_line(p + Vector2(3, 3), p + Vector2(24, 24), Color("c39a5d"), 4)
	if flying:
		draw_line(p + Vector2(-12, 10), p + Vector2(-4, 10), Color("e9d3ad"), 2)

func draw_fighter(f: Dictionary, id: int) -> void:
	var p := world_to_screen(f.pos)
	var moving: bool = f.state in ["walk", "dash", "charge"]
	var step := int(sin(time * (22 if moving else 3)) * (3 if moving else 0.7))
	var facing: float = -1.0 if f.aim.x < 0 else 1.0
	var hurt: bool = f.state == "hurt"
	draw_set_transform(p)
	draw_rect(Rect2(Vector2(-16, -3), Vector2(32, 9)), Color(0.08, 0.1, 0.12, 0.32))
	if id == local_id and not preview:
		draw_arc(Vector2(0, 1), 19, 0, TAU, 20, Color(0.4, 0.95, 0.9, 0.65), 1)
	var clock: Dictionary = animation_clocks.get(id, {"elapsed": time, "aim": f.aim})
	var art_state: String = clock.get("state", f.state)
	var art_aim: Vector2 = f.aim if art_state in ["idle", "walk", "guard", "carry", "carry_walk"] else clock.aim
	var art := pixel_assets.frame(f.character, art_state, art_aim, clock.elapsed)
	if not art.is_empty():
		var texture: Texture2D = art.texture
		var tint := Color("ffe9cd") if hurt else Color.WHITE
		draw_texture_rect(texture, Rect2(-art.anchor * art.scale, Vector2(texture.get_size()) * art.scale), false, tint)
	elif f.character == "Edward":
		var red := Color("bc393d") if not hurt else Color("f4e4be")
		pixel_rect(Vector2(-12, -24 + step), Vector2(24, 22), red)
		pixel_rect(Vector2(-15 - facing * 3, -18 + step), Vector2(7, 20), red.darkened(0.18))
		pixel_rect(Vector2(9 - facing * 3, -18 + step), Vector2(7, 20), red.darkened(0.18))
		pixel_rect(Vector2(-7, -24 + step), Vector2(14, 15), Color("383d46"))
		pixel_rect(Vector2(-9, -9), Vector2(7, 13 + step), Color("32353e"))
		pixel_rect(Vector2(3, -9), Vector2(7, 13 - step), Color("32353e"))
		pixel_rect(Vector2(-11, 2 + step), Vector2(10, 4), Color("20262d"))
		pixel_rect(Vector2(2, 2 - step), Vector2(11, 4), Color("20262d"))
		pixel_rect(Vector2(-8, -38 + step), Vector2(17, 15), Color("e4b887"))
		pixel_rect(Vector2(-10, -40 + step), Vector2(20, 7), Color("eac75e"))
		pixel_rect(Vector2(-10, -34 + step), Vector2(5, 9), Color("d5ac46"))
		for i in 4:
			pixel_rect(Vector2(-10 - facing * 3, -25 + i * 5 + step), Vector2(4, 5), Color("cfa746"))
		draw_rect(Rect2(Vector2(4 * facing, -31 + step), Vector2(2, 2)), INK)
		var reach := 11.0 if f.state in ["attack", "grab", "q", "e"] else 0.0
		pixel_rect(Vector2(10 * facing + reach * facing - 4, -23 + step), Vector2(8, 16), Color("a6c0c5"))
		draw_rect(Rect2(Vector2(10 * facing + reach * facing - 2, -21 + step), Vector2(3, 10)), Color("e1ece5"))
		if f.state == "attack":
			pixel_rect(Vector2(18 * facing - 2, -22 + step), Vector2(17, 4), Color("d2e3e2"))
	else:
		var steel := Color("8babb4") if not hurt else Color("f4e4be")
		pixel_rect(Vector2(-10, -13), Vector2(8, 18 + step), steel.darkened(0.3))
		pixel_rect(Vector2(3, -13), Vector2(8, 18 - step), steel.darkened(0.3))
		pixel_rect(Vector2(-13, 1 + step), Vector2(12, 6), Color("566c79"))
		pixel_rect(Vector2(2, 1 - step), Vector2(13, 6), Color("566c79"))
		pixel_rect(Vector2(-13, -33 + step), Vector2(27, 25), steel)
		pixel_rect(Vector2(-17, -32 + step), Vector2(10, 12), steel.lightened(0.18))
		pixel_rect(Vector2(9, -32 + step), Vector2(10, 12), steel.lightened(0.18))
		pixel_rect(Vector2(-17, -19 + step), Vector2(8, 13), steel.darkened(0.12))
		pixel_rect(Vector2(12 + (7 if f.state == "attack" else 0) * facing, -19 + step), Vector2(8, 13), steel.darkened(0.12))
		pixel_rect(Vector2(-10, -45 + step), Vector2(21, 15), steel.darkened(0.15))
		pixel_rect(Vector2(-7, -48 + step), Vector2(15, 5), steel)
		pixel_rect(Vector2(-2, -54 + step), Vector2(4, 8), Color("b5c8c9"))
		draw_rect(Rect2(Vector2(-7, -39 + step), Vector2(16, 3)), INK)
		draw_rect(Rect2(Vector2(2 * facing, -39 + step), Vector2(3, 2)), Color("f58974"))
		draw_line(Vector2(-7, -22 + step), Vector2(8, -22 + step), steel.darkened(0.35), 2)
		for i in 3:
			draw_rect(Rect2(Vector2(-6, -27 + i * 6 + step), Vector2(2, 2)), Color("d1dcce"))
	if f.state == "guard":
		draw_arc(Vector2(0, -17), 27, f.aim.angle() - 0.8, f.aim.angle() + 0.8, 10, CYAN, 3)
	if f.invulnerable > 0:
		draw_line(Vector2(-30 * facing, -25), Vector2(-18 * facing, -25), CYAN, 2)
	if f.carrying != -1:
		var crate_art := pixel_environment.texture("crate")
		if crate_art != null:
			draw_texture_rect(crate_art, Rect2(Vector2(-16, -73), Vector2(32, 32)), false)
		else:
			pixel_rect(Vector2(-15, -69), Vector2(30, 26), Color("a27442"))
			draw_line(Vector2(-12, -66), Vector2(12, -46), Color("dfb879"), 3)
	if not f.name.is_empty():
		var display_name: String = f.name
		while font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > 96:
			display_name = display_name.trim_suffix("…").left(display_name.trim_suffix("…").length() - 1) + "…"
		var width := font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var label_top := -96 if f.carrying != -1 else -84
		if id != local_id and snapshot.get("fighters", {}).has(local_id):
			var own: Dictionary = snapshot.fighters[local_id]
			var own_pos := world_to_screen(shown.get(local_id, own.pos))
			var own_top := -96 if own.carrying != -1 else -84
			if absf(p.x - own_pos.x) < 108 and absf(p.y + label_top - own_pos.y - own_top) < 20:
				label_top = int(own_pos.y + own_top - p.y - 22)
		draw_rect(Rect2(Vector2(-width / 2 - 4, label_top), Vector2(width + 8, 17)), Color(0.08, 0.1, 0.12, 0.85))
		draw_string(font, Vector2(-width / 2, label_top + 13), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CYAN if id == local_id else Color("f5dfbe"))
	draw_set_transform(Vector2.ZERO)

func draw_effect(effect: Dictionary, depth: String = "front") -> void:
	var p := world_to_screen(effect.pos)
	var local_life: float = maxf(0, effect.life - minf(time - last_snapshot, 0.15))
	var alpha: float = clampf(local_life / effect.total, 0, 1)
	var aim: Vector2 = effect.aim
	var color := CYAN
	color.a = alpha
	if not effect.pending and pixel_fx.has_effect(effect.kind):
		# Telegraphs and impact have separate timing; advance between snapshots.
		var progress: float = 1 - clampf(local_life / (0.35 if effect.kind in ["slam", "spikes"] else effect.total), 0, 1)
		if effect.kind == "spikes":
			for i in range(-3, 4):
				draw_pixel_effect("spikes", p + aim * i * 30, progress, 0, 0.85, depth)
		else:
			var rotation: float = aim.angle() if effect.kind in ["slash", "dash"] else 0.0
			var origin: Vector2 = p - aim * 27 + Vector2(0, -17) if effect.kind == "slash" else p
			if effect.kind in ["hit", "block"]:
				origin -= Vector2(0, 24)
			draw_pixel_effect(effect.kind, origin, progress, rotation, 0.8 if effect.kind == "alchemy" else 1.0, depth)
		return
	match effect.kind:
		"spikes":
			if effect.pending:
				var corners := PackedVector2Array([p - aim * 110 - aim.orthogonal() * 32, p + aim * 110 - aim.orthogonal() * 32, p + aim * 110 + aim.orthogonal() * 32, p - aim * 110 + aim.orthogonal() * 32])
				draw_colored_polygon(corners, Color(0.8, 0.3, 0.2, 0.22 + sin(time * 30) * 0.08))
				draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]]), Color("f1bb80"), 2)
			else:
				for i in range(-3, 4):
					var base := p + aim * i * 30
					draw_colored_polygon(PackedVector2Array([base + Vector2(-12, 8), base + Vector2(1, -35), base + Vector2(12, 8)]), Color("b9b89b"))
					draw_line(base + Vector2(1, -35), base + Vector2(12, 8), color, 2)
		"slam":
			draw_arc(p, 100 if effect.pending else 100 * (1 - alpha), 0, TAU, 32, Color("e9b56d") if effect.pending else color, 2)
			if effect.pending:
				draw_circle(p, 100, Color(0.9, 0.5, 0.2, 0.08))
		"slash", "grab":
			draw_arc(p, 27, aim.angle() - 1, aim.angle() + 1, 9, color if effect.kind == "slash" else Color("e9b56d"), 3)
		"alchemy":
			draw_arc(p, 45 * (1 - alpha), 0, TAU, 24, color, 2)
			for i in 6:
				var point := p + Vector2.from_angle(i * TAU / 6) * 34
				draw_line(p, point, color, 1)
		"hit", "block", "dust":
			for i in 7:
				var point := p + Vector2.from_angle(i * TAU / 7) * (12 + 23 * (1 - alpha))
				draw_rect(Rect2(point.round(), Vector2(3, 3)), Color(0.95, 0.8, 0.55, alpha) if effect.kind != "block" else color)

func draw_pixel_effect(kind: String, position: Vector2, progress: float, rotation: float = 0.0, opacity: float = 1.0, depth: String = "front") -> void:
	for part in pixel_fx.parts_for_depth(kind, depth):
		var art := pixel_fx.frame(kind, progress, part)
		if art.is_empty():
			continue
		draw_set_transform(position.round(), rotation)
		draw_texture_rect_region(art.texture, Rect2(art.offset, art.size), art.region, Color(1, 1, 1, opacity))
		draw_set_transform(Vector2.ZERO)
