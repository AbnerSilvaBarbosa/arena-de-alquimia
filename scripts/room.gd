class_name ArenaRoom
extends RefCounted

const SIZE := Vector2(2048, 1536)
const ROUND_TIME := 90.0
const PERMANENT := [Rect2(736, 448, 96, 192), Rect2(1216, 896, 96, 192), Rect2(352, 1024, 128, 64), Rect2(1536, 416, 128, 64)]
var code := ""
var members: Dictionary = {}
var fighters: Dictionary = {}
var inputs: Dictionary = {}
var phase := "lobby"
var timer := ROUND_TIME
var scores: Dictionary = {}
var boxes: Array = []
var walls: Array = []
var effects: Array = []
var message := ""
var revision := 0
var round_number := 1
var scenario := "garden"
var scenario_override := ""
var bot_id := 0
var bot_clock := 0.0
var action_clock := 0.0
var next_object := 0
var spears: Array = []
var weapon_rng := RandomNumberGenerator.new()

func _init() -> void:
	weapon_rng.randomize()

func add_player(id: int, nickname: String) -> void:
	members[id] = {"name": nickname.substr(0, 20), "character": "Edward", "ready": false, "loaded": false, "rematch": false}
	scores[id] = 0
	revision += 1

func remove_player(id: int) -> void:
	members.erase(id)
	fighters.erase(id)
	inputs.erase(id)
	scores.erase(id)
	phase = "lobby"
	message = "O outro jogador saiu. Aguardando um novo participante."
	for member in members.values():
		member.ready = false
		member.loaded = false
	revision += 1

func select(id: int, character: String) -> void:
	if phase != "lobby" or not members.has(id) or character not in ["Edward", "Alphonse"]:
		return
	members[id].character = character
	members[id].ready = false
	revision += 1

func ready_player(id: int) -> void:
	if phase != "lobby" or not members.has(id):
		return
	members[id].ready = not members[id].ready
	revision += 1
	if members.size() == 2 and members.values().all(func(m): return m.ready):
		phase = "loading"
		timer = 15.0
		message = "Carregando arena…"
		for member in members.values():
			member.loaded = false
		if bot_id != 0:
			members[bot_id].loaded = true

func loaded(id: int) -> void:
	if phase != "loading" or not members.has(id):
		return
	members[id].loaded = true
	if members.values().all(func(m): return m.loaded):
		for key in scores:
			scores[key] = 0
		round_number = 1
		reset_round()
		phase = "countdown"
		timer = 3.0
		message = "Prepare-se"
		revision += 1

func reset_round() -> void:
	scenario = scenario_override if scenario_override in ["garden", "forest"] else ("garden" if round_number % 2 == 1 else "forest")
	fighters.clear()
	inputs.clear()
	walls.clear()
	effects.clear()
	boxes.clear()
	spears.clear()
	next_object = 0
	for pos in [Vector2(864, 688), Vector2(1184, 848), Vector2(512, 640), Vector2(1472, 896), Vector2(1024, 448), Vector2(1024, 1088)]:
		boxes.append({"id": next_object, "pos": pos, "vel": Vector2.ZERO, "owner": 0, "life": 0.0})
		next_object += 1
	var index := 0
	for id in members:
		var side := (index + round_number - 1) % 2
		fighters[id] = {"id": id, "name": members[id].name, "character": members[id].character,
			"pos": Vector2(832 if side == 0 else 1216, 768), "aim": Vector2.RIGHT if side == 0 else Vector2.LEFT,
			"hp": 100.0, "stamina": 100.0, "state": "idle", "state_time": 0.0, "invulnerable": 0.0,
			"dash": Vector2.ZERO, "carrying": -1, "weapon": "", "forge_left": 0.0, "cooldowns": {"attack": 0.0, "q": 0.0, "e": 0.0, "grab": 0.0, "interact": 0.0, "dash": 0.0}}
		inputs[id] = {"move": Vector2.ZERO, "aim": fighters[id].aim, "guard": false, "age": 0.0}
		index += 1

func set_input(id: int, move: Vector2, aim: Vector2, guard: bool) -> void:
	if phase != "fight" or not fighters.has(id) or not move.is_finite() or not aim.is_finite():
		return
	inputs[id] = {"move": move.limit_length(), "aim": aim.normalized() if aim.length() > 0.1 else fighters[id].aim, "guard": guard, "age": 0.0}

func obstacle_rects() -> Array:
	var rects: Array = PERMANENT.duplicate()
	rects.append_array(ArenaScenery.solid_rects())
	for wall in walls:
		rects.append(wall.rect)
	for box in boxes:
		if box.owner == 0 and box.vel.length() < 1:
			rects.append(Rect2(box.pos - Vector2(14, 14), Vector2(28, 28)))
	return rects

func blocked(pos: Vector2, radius: float = 13.0) -> bool:
	if pos.x < 64 + radius or pos.y < 64 + radius or pos.x > SIZE.x - 64 - radius or pos.y > SIZE.y - 64 - radius:
		return true
	for rect in obstacle_rects():
		var closest: Vector2 = pos.clamp(rect.position, rect.end)
		if closest.distance_squared_to(pos) < radius * radius:
			return true
	return false

func move_fighter(f: Dictionary, offset: Vector2) -> void:
	# Substeps avoid crossing narrow obstacles during a dash.
	var steps := maxi(1, int(ceil(offset.length() / 8.0)))
	var step := offset / steps
	for i in steps:
		var candidate: Vector2 = f.pos + Vector2(step.x, 0)
		if not blocked(candidate):
			f.pos = candidate
		candidate = f.pos + Vector2(0, step.y)
		if not blocked(candidate):
			f.pos = candidate

func action(id: int, key: String, target: Vector2 = Vector2.ZERO) -> void:
	if phase != "fight" or not fighters.has(id):
		return
	var f: Dictionary = fighters[id]
	if key not in ["attack", "q", "e", "grab", "interact", "dash"] or f.cooldowns[key] > 0 or f.state_time > 0:
		return
	if key == "dash":
		if f.stamina < 25 or f.carrying != -1:
			return
		f.stamina -= 25
		f.state = "dash"
		f.state_time = 0.16
		f.invulnerable = 0.12
		f.dash = inputs[id].move if inputs[id].move.length() > 0.1 else f.aim
		f.cooldowns.dash = 0.65
		add_effect("dash", f.pos, f.dash, 0.22, id)
		return
	if key == "interact":
		f.cooldowns.interact = 0.3
		if f.carrying != -1:
			for box in boxes:
				if box.id == f.carrying:
					box.owner = 0
					box.pos = f.pos + f.aim * 34
					box.vel = f.aim * 620
					box.life = 1.3
					box.thrower = id
			f.carrying = -1
			f.state = "throw"
			f.state_time = 0.2
		else:
			for spear in spears:
				if spear.owner == id and spear.vel == Vector2.ZERO and f.pos.distance_to(spear.pos) < 58 and clear_path(f.pos, spear.pos):
					f.weapon = "spear"
					spears.erase(spear)
					add_effect("alchemy", f.pos, f.aim, 0.4, id)
					return
			var nearest = null
			var distance := 58.0
			for box in boxes:
				if box.owner == 0 and box.vel.length() < 1 and f.pos.distance_to(box.pos) < distance:
					nearest = box
					distance = f.pos.distance_to(box.pos)
			if nearest != null:
				nearest.owner = id
				f.carrying = nearest.id
		return
	if f.carrying != -1:
		return
	f.state = key
	f.state_time = 0.28 if key == "attack" else 0.42
	if key == "attack":
		f.cooldowns.attack = 0.45
		add_effect("slash", f.pos + f.aim * 27, f.aim, 0.16, id)
		var weapon: String = f.get("weapon", "")
		var reach := 120.0 if weapon == "spear" else (85.0 if weapon != "" else 68.0)
		var amount := 34.0 if weapon == "hammer" else (18.0 if weapon == "sword" else (16.0 if weapon == "spear" else (11.0 if f.character == "Edward" else 14.0)))
		f.cooldowns.attack = 0.95 if weapon == "hammer" else (0.33 if weapon == "sword" else 0.45)
		if weapon == "hammer":
			f.heavy_left = 0.32
			f.state_time = 0.55
		else:
			melee(id, reach, amount, 45)
	elif key == "grab":
		f.cooldowns.grab = 1.1
		add_effect("grab", f.pos + f.aim * 22, f.aim, 0.25, id)
		melee(id, 49, 9, 130, true)
	elif key == "q":
		if f.stamina < 18:
			f.state_time = 0
			return
		f.stamina -= 18
		f.cooldowns.q = 5.0
		if f.character == "Edward":
			if not target.is_finite():
				f.stamina += 18
				f.cooldowns.q = 0.5
				f.state_time = 0
				return
			var center: Vector2 = target if target != Vector2.ZERO else f.pos + f.aim * 100
			center = center.snapped(Vector2(16, 16))
			var horizontal: bool = abs(f.aim.x) < abs(f.aim.y)
			var dims := Vector2(160, 28) if horizontal else Vector2(28, 160)
			var rect := Rect2(center - dims / 2, dims)
			if center.is_finite() and center.distance_to(f.pos) <= 240 and valid_wall(rect) and walls.filter(func(w): return w.owner == id).size() < 3:
				walls.append({"rect": rect, "hp": 80.0, "max_hp": 80.0, "rise": 0.0, "spiked": false, "contact": 0.0, "owner": id})
				add_effect("alchemy", center, f.aim, 0.6, id)
			else:
				f.cooldowns.q = 0.5
				f.stamina += 18
				f.state_time = 0
		else:
			if spears.any(func(item): return item.owner == id):
				f.stamina += 18
				f.cooldowns.q = 0.5
				f.state_time = 0
				return
			f.forge_left = 0.42
			add_effect("alchemy", f.pos, f.aim, 0.6, id)

	elif key == "e":
		if f.stamina < 22:
			f.state_time = 0
			return
		f.stamina -= 22
		f.cooldowns.e = 4.0
		if f.character == "Edward":
			var point: Vector2 = target if target != Vector2.ZERO else f.pos + f.aim * 110
			if not point.is_finite() or point.distance_to(f.pos) > 240:
				f.stamina += 22
				f.cooldowns.e = 0.5
				return
			for wall in walls:
				if wall.owner == id and wall.rect.grow(24).has_point(point):
					wall.spiked = true
					wall.max_hp = 120.0
					wall.hp = minf(120, wall.hp + 40)
					add_effect("spikes", wall.rect.get_center(), f.aim, 0.72, id)
					return
			add_effect("spikes", point, f.aim, 0.72, id, true)
		elif f.weapon == "spear":
			f.weapon = ""
			f.state = "throw"
			spears.append({"owner": id, "pos": f.pos, "vel": f.aim * 700, "aim": f.aim, "life": 0.9})
		elif f.weapon == "sword":
			add_effect("slash", f.pos + f.aim * 40, f.aim, 0.3, id)
			melee(id, 100, 24, 70)
		else:
			add_effect("slam", f.pos, f.aim, 0.85 if f.weapon == "hammer" else 0.72, id, true)

func valid_wall(rect: Rect2) -> bool:
	if rect.position.x < 64 or rect.position.y < 64 or rect.end.x > SIZE.x - 64 or rect.end.y > SIZE.y - 64:
		return false
	for obstacle in obstacle_rects():
		if rect.intersects(obstacle):
			return false
	for other in fighters.values():
		if rect.grow(18).has_point(other.pos):
			return false
	return true

func add_effect(kind: String, pos: Vector2, aim: Vector2, life: float, owner: int, pending: bool = false) -> void:
	effects.append({"kind": kind, "pos": pos, "aim": aim, "life": life, "total": life, "owner": owner, "pending": pending})

func melee(id: int, reach: float, amount: float, push: float, grab: bool = false) -> void:
	var f: Dictionary = fighters[id]
	for other_id in fighters:
		if other_id == id:
			continue
		var target: Dictionary = fighters[other_id]
		var delta: Vector2 = target.pos - f.pos
		if delta.length() <= reach and (delta.length() < 8 or delta.normalized().dot(f.aim) > 0.3) and clear_path(f.pos, target.pos):
			damage(other_id, amount, f.pos, push, grab)
	if not grab:
		for wall in walls:
			if segment_hits_rect(f.pos, f.pos + f.aim * reach, wall.rect):
				wall.hp -= amount
		for i in range(boxes.size() - 1, -1, -1):
			var box: Dictionary = boxes[i]
			if box.owner == 0 and box.pos.distance_to(f.pos + f.aim * 35) < 28:
				add_effect("dust", box.pos, Vector2.UP, 0.3, id)
				boxes.remove_at(i)

func segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b):
		return true
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false

func clear_path(a: Vector2, b: Vector2) -> bool:
	for rect in PERMANENT + ArenaScenery.solid_rects():
		if Geometry2D.segment_intersects_segment(a, b, rect.position, Vector2(rect.end.x, rect.position.y)) != null or Geometry2D.segment_intersects_segment(a, b, rect.position, Vector2(rect.position.x, rect.end.y)) != null or Geometry2D.segment_intersects_segment(a, b, rect.end, Vector2(rect.end.x, rect.position.y)) != null or Geometry2D.segment_intersects_segment(a, b, rect.end, Vector2(rect.position.x, rect.end.y)) != null:
			return false
	for wall in walls:
		for t in range(1, 10):
			if wall.rect.has_point(a.lerp(b, t / 10.0)):
				return false
	return true

func damage(id: int, amount: float, origin: Vector2, push: float, grab: bool = false) -> void:
	var f: Dictionary = fighters[id]
	if f.invulnerable > 0 and not grab:
		return
	var defended: bool = inputs[id].guard and f.state_time <= 0 and f.carrying == -1 and f.stamina >= 12 and f.aim.dot((origin - f.pos).normalized()) > 0.25
	if defended and not grab:
		f.stamina = maxf(0, f.stamina - 16)
		amount *= 0.25
		push *= 0.25
		add_effect("block", f.pos, f.aim, 0.2, id)
	else:
		f.state = "hurt"
		f.state_time = 0.18
		add_effect("hit", f.pos, f.aim, 0.18, id)
	f.hp = maxf(0, f.hp - amount)
	move_fighter(f, (f.pos - origin).normalized() * push)

func tick(delta: float) -> void:
	action_clock += delta
	if phase in ["lobby", "result"]:
		return
	timer -= delta
	if phase == "loading":
		if timer <= 0:
			phase = "lobby"
			message = "Carregamento excedeu 15 segundos. Tente novamente."
			for member in members.values():
				member.ready = false
			revision += 1
		return
	if phase == "countdown":
		if timer <= 0:
			phase = "fight"
			timer = ROUND_TIME
			message = ""
			revision += 1
		return
	if phase == "intermission":
		if timer <= 0:
			reset_round()
			phase = "countdown"
			timer = 3.0
			revision += 1
		return
	if bot_id != 0:
		update_bot(delta)
	for id in fighters:
		var f: Dictionary = fighters[id]
		if f.forge_left > 0:
			f.forge_left = maxf(0, f.forge_left - delta)
			if f.forge_left == 0:
				f.weapon = ["spear", "hammer", "sword"][weapon_rng.randi_range(0, 2)]
		if f.get("heavy_left", 0.0) > 0:
			f.heavy_left = maxf(0, f.heavy_left - delta)
			if f.heavy_left == 0:
				melee(id, 85, 34, 80)
		var input: Dictionary = inputs[id]
		input.age += delta
		if input.age > 0.35:
			input.move = Vector2.ZERO
			input.guard = false
		f.invulnerable = maxf(0, f.invulnerable - delta)
		for key in f.cooldowns:
			f.cooldowns[key] = maxf(0, f.cooldowns[key] - delta)
		f.stamina = minf(100, f.stamina + (7 if input.guard else 18) * delta)
		f.aim = input.aim
		if f.state_time > 0:
			if f.state in ["dash", "charge"]:
				move_fighter(f, f.dash * (720 if f.state == "dash" else 520) * delta)
				if f.state == "charge" and not f.get("charge_hit", false):
					for other_id in fighters:
						if other_id == id:
							continue
						var target: Vector2 = fighters[other_id].pos - f.pos
						if target.length() < 55 and target.normalized().dot(f.aim) > 0.35 and clear_path(f.pos, fighters[other_id].pos):
							f.charge_hit = true
							melee(id, 55, 17, 100)
							break
			f.state_time = maxf(0, f.state_time - delta)
		else:
			var speed := 220.0 if f.character == "Edward" else 200.0
			if f.carrying != -1:
				speed *= 0.68
			elif input.guard:
				speed *= 0.45
			move_fighter(f, input.move * speed * delta)
			f.state = "guard" if input.guard else ("walk" if input.move.length() > 0.1 else "idle")
		# Body separation, without allowing pushes through scenery.
	for id in fighters:
		for other_id in fighters:
			if id >= other_id:
				continue
			var a: Dictionary = fighters[id]
			var b: Dictionary = fighters[other_id]
			var diff: Vector2 = a.pos - b.pos
			if diff.length() < 28:
				var normal := diff.normalized() if diff.length() > 0.01 else Vector2.RIGHT
				move_fighter(a, normal * (28 - diff.length()) / 2)
				move_fighter(b, -normal * (28 - diff.length()) / 2)
	for i in range(walls.size() - 1, -1, -1):
		walls[i].rise = minf(1, walls[i].get("rise", 1.0) + delta / 0.45)
		walls[i].contact = maxf(0, walls[i].get("contact", 0.0) - delta)
		if walls[i].get("spiked", false) and walls[i].contact == 0:
			for id in fighters:
				if id != walls[i].owner and walls[i].rect.grow(23).has_point(fighters[id].pos):
					damage(id, 10, walls[i].rect.get_center(), 25)
					walls[i].contact = 0.6
		if walls[i].hp <= 0:
			add_effect("dust", walls[i].rect.get_center(), Vector2.UP, 0.4, walls[i].owner)
			walls.remove_at(i)
	for i in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[i]
		effect.life -= delta
		if effect.pending and effect.life <= 0.35:
			effect.pending = false
			for id in fighters:
				if id == effect.owner:
					continue
				var f: Dictionary = fighters[id]
				var relative: Vector2 = f.pos - effect.pos
				var hit: bool = relative.length() < 100 if effect.kind == "slam" else absf(relative.dot(effect.aim.orthogonal())) < 34 and absf(relative.dot(effect.aim)) < 115
				if hit and clear_path(effect.pos, f.pos):
					damage(id, 42 if effect.kind == "slam" and fighters[effect.owner].weapon == "hammer" else 22, effect.pos - effect.aim * 50, 60)
		if effect.life <= 0:
			effects.remove_at(i)
	for i in range(boxes.size() - 1, -1, -1):
		var box: Dictionary = boxes[i]
		if box.owner != 0:
			if fighters.has(box.owner):
				box.pos = fighters[box.owner].pos + Vector2(0, -30)
			continue
		if box.vel.length() < 1:
			continue
		box.life -= delta
		var broken: bool = box.life <= 0
		var steps := maxi(1, int(ceil(box.vel.length() * delta / 8)))
		for step in steps:
			box.pos += box.vel * delta / steps
			if box.pos.x < 64 or box.pos.y < 64 or box.pos.x > SIZE.x - 64 or box.pos.y > SIZE.y - 64:
				broken = true
			for rect in PERMANENT + ArenaScenery.solid_rects():
				if rect.grow(10).has_point(box.pos):
					broken = true
			for wall in walls:
				if wall.rect.grow(10).has_point(box.pos):
					wall.hp -= 22
					broken = true
			for id in fighters:
				if id != box.get("thrower", 0) and fighters[id].pos.distance_to(box.pos) < 27:
					damage(id, 20, box.pos - box.vel.normalized() * 30, 65)
					broken = true
			if broken:
				break
		if broken:
			add_effect("dust", box.pos, Vector2.UP, 0.4, box.get("thrower", 0))
			boxes.remove_at(i)
	for spear in spears:
		if spear.vel == Vector2.ZERO:
			continue
		spear.life -= delta
		var steps := maxi(1, int(ceil(spear.vel.length() * delta / 8)))
		for step in steps:
			var next: Vector2 = spear.pos + spear.vel * delta / steps
			var stop: bool = next.x < 70 or next.y < 70 or next.x > SIZE.x - 70 or next.y > SIZE.y - 70
			for rect in PERMANENT + ArenaScenery.solid_rects():
				stop = stop or rect.grow(6).has_point(next)
			for wall in walls:
				if wall.rect.grow(6).has_point(next):
					wall.hp -= 24
					stop = true
			if stop:
				spear.vel = Vector2.ZERO
				break
			spear.pos = next
			for id in fighters:
				if id != spear.owner and fighters[id].pos.distance_to(next) < 25:
					damage(id, 24, next - spear.aim * 30, 45)
					spear.vel = Vector2.ZERO
			if spear.vel == Vector2.ZERO:
				break
		if spear.life <= 0:
			spear.vel = Vector2.ZERO
	var dead: Array = fighters.keys().filter(func(id): return fighters[id].hp <= 0)
	if not dead.is_empty() or timer <= 0:
		finish_round()

func finish_round() -> void:
	var ids := fighters.keys()
	if ids.size() != 2:
		return
	var a: float = fighters[ids[0]].hp
	var b: float = fighters[ids[1]].hp
	if is_equal_approx(a, b):
		message = "Empate! Vamos repetir o round."
	else:
		var winner: int = ids[0] if a > b else ids[1]
		scores[winner] += 1
		message = "%s venceu o round" % members[winner].name
		if scores[winner] >= 2:
			phase = "result"
			message = "%s venceu a partida!" % members[winner].name
			for member in members.values():
				member.rematch = false
			revision += 1
			return
		round_number += 1
	phase = "intermission"
	timer = 3.0
	revision += 1

func rematch(id: int) -> void:
	if phase != "result" or not members.has(id):
		return
	members[id].rematch = not members[id].rematch
	if bot_id != 0:
		members[bot_id].rematch = true
	if members.values().all(func(m): return m.rematch):
		for key in scores:
			scores[key] = 0
		round_number = 1
		reset_round()
		phase = "countdown"
		timer = 3.0
		message = "Revanche"
	revision += 1

func update_bot(delta: float) -> void:
	if not fighters.has(bot_id):
		return
	bot_clock += delta
	var other: int = fighters.keys().filter(func(id): return id != bot_id)[0]
	var f: Dictionary = fighters[bot_id]
	for spear in spears:
		if spear.owner == bot_id and spear.vel == Vector2.ZERO:
			var retrieval: Vector2 = spear.pos - f.pos
			set_input(bot_id, retrieval.normalized() if retrieval.length() > 40 else Vector2.ZERO, retrieval, false)
			if retrieval.length() < 58:
				action(bot_id, "interact")
			return
	var direction: Vector2 = fighters[other].pos - f.pos
	var move := direction.normalized() if direction.length() > 50 else Vector2.ZERO
	if blocked(f.pos + move * 30):
		move = move.orthogonal() * (1 if sin(action_clock) > 0 else -1)
	set_input(bot_id, move, direction, false)
	if bot_clock > 0.6:
		bot_clock = 0
		if direction.length() < 75:
			action(bot_id, "attack")
		elif direction.length() < 150:
			action(bot_id, "e")
		elif direction.length() < 240:
			action(bot_id, "q")

func lobby_data() -> Dictionary:
	return {"code": code, "members": members.duplicate(true), "phase": phase, "message": message, "scores": scores.duplicate(), "revision": revision}

func snapshot() -> Dictionary:
	return {"code": code, "fighters": fighters.duplicate(true), "boxes": boxes.duplicate(true), "spears": spears.duplicate(true), "walls": walls.duplicate(true), "effects": effects.duplicate(true), "phase": phase, "timer": timer, "scores": scores.duplicate(), "round": round_number, "scenario": scenario, "message": message, "revision": revision}
