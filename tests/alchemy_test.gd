extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(title)
func match_room() -> ArenaRoom:
	var r := ArenaRoom.new()
	r.add_player(1, "Ed")
	r.add_player(2, "Al")
	r.select(2, "Alphonse")
	r.reset_round()
	r.phase = "fight"
	r.fighters[1].pos = Vector2(950, 768)
	r.fighters[2].pos = Vector2(1350, 768)
	return r
func advance(r: ArenaRoom, seconds: float) -> void:
	for i in int(ceil(seconds * 60)):
		r.tick(1.0 / 60)
func _initialize() -> void:
	var r := match_room()
	r.action(1, "q", Vector2(1056, 752))
	check(r.walls.size() == 1 and r.walls[0].rect.get_center() == Vector2(1056, 752), "Wall respects cursor and snapping")
	check(r.walls[0].rise == 0 and r.walls[0].hp == 80, "Wall starts underground with HP")
	advance(r, 0.5)
	check(r.walls[0].rise == 1, "Wall finishes rising")
	r.action(1, "e", r.walls[0].rect.get_center())
	check(r.walls[0].spiked and r.walls[0].hp == 120, "Spikes upgrade own wall")
	advance(r, 8)
	check(r.walls.size() == 1, "Upgraded terrain persists")
	r.fighters[2].pos = Vector2(1080, 752)
	var health: float = r.fighters[2].hp
	r.tick(0.02)
	check(r.fighters[2].hp == health - 10, "Spiked wall damages enemy contact")
	health = r.fighters[2].hp
	r.tick(0.02)
	check(r.fighters[2].hp == health, "Contact damage has cooldown")
	r.walls[0].hp = 0
	r.tick(0.02)
	check(r.walls.is_empty(), "Destroyed wall leaves terrain")
	r = match_room()
	r.action(1, "q", Vector2(1600, 700))
	check(r.walls.is_empty() and r.fighters[1].stamina == 100, "Reject distant placement and refund")
	r.fighters[1].cooldowns.q = 0
	r.action(1, "q", Vector2(NAN, 1))
	check(r.walls.is_empty() and r.fighters[1].stamina == 100, "Reject nonfinite placement")
	var seen := {}
	for seed_value in 40:
		r = match_room()
		r.weapon_rng.seed = seed_value
		r.action(2, "q")
		check(r.fighters[2].weapon == "", "Forge does not equip early")
		advance(r, 0.5)
		seen[r.fighters[2].weapon] = true
	check(seen.size() == 3, "Random forge can generate all three weapons")
	for weapon in ["spear", "sword", "hammer"]:
		r = match_room()
		r.fighters[2].weapon = weapon
		r.fighters[1].pos = Vector2(1280, 768)
		r.fighters[2].aim = Vector2.LEFT
		r.inputs[2].aim = Vector2.LEFT
		r.action(2, "attack")
		if weapon == "hammer":
			check(r.fighters[1].hp == 100, "Hammer attack has windup")
			advance(r, 0.4)
		check(r.fighters[1].hp == {"spear": 84, "sword": 82, "hammer": 66}[weapon], "Weapon has distinct melee damage: " + weapon)
	r = match_room()
	r.fighters[2].weapon = "hammer"
	r.fighters[1].pos = Vector2(1280, 768)
	r.action(2, "e")
	check(r.fighters[1].hp == 100, "Heavy slam warns before impact")
	advance(r, 0.55)
	check(r.fighters[1].hp == 58, "Heavy slam does 42 damage")
	r = match_room()
	r.fighters[2].weapon = "spear"
	r.fighters[2].aim = Vector2.LEFT
	r.inputs[2].aim = Vector2.LEFT
	r.fighters[1].pos = Vector2(1220, 768)
	r.action(2, "e")
	check(r.spears.size() == 1 and r.fighters[2].weapon == "", "Throw consumes held spear")
	advance(r, 0.3)
	check(r.fighters[1].hp == 76 and r.spears[0].vel == Vector2.ZERO, "Spear hits once and drops")
	advance(r, 0.3)
	r.fighters[2].pos = r.spears[0].pos + Vector2(40, 0)
	r.action(2, "interact")
	check(r.fighters[2].weapon == "spear" and r.spears.is_empty(), "F retrieves owned spear")
	r.reset_round()
	check(r.spears.is_empty() and r.fighters[2].weapon == "", "Round resets generated weapons")
	print("ALCHEMY_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
