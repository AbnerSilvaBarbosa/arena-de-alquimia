extends "res://tools/capture_media.gd"

func choose_weapon(kind: String) -> void:
	# A prepared showcase chooses RNG seeds; live players cannot choose their result.
	for seed_value in 100:
		room.weapon_rng.seed = seed_value
		if ["spear", "hammer", "sword"][room.weapon_rng.randi_range(0, 2)] == kind:
			room.weapon_rng.seed = seed_value
			break
	room.action(-1, "q")

func _process(delta: float) -> bool:
	if not prepared:
		return false
	match frame_index:
		18: choose_weapon("hammer")
		45: room.action(1, "q", Vector2(1008, 768))
		75: room.action(1, "e", room.walls[0].rect.get_center())
		95: room.action(-1, "attack")
		120: room.action(-1, "e")
		150: reset_scene(Vector2(950, 768), Vector2(1030, 768))
		160: choose_weapon("sword")
		190: room.action(-1, "attack")
		220: room.action(-1, "e")
		260: reset_scene(Vector2(900, 768), Vector2(1150, 768))
		270: choose_weapon("spear")
		300: room.action(-1, "e")
		410: room.action(-1, "interact")
	if frame_index > 330 and frame_index < 410 and not room.spears.is_empty():
		var toward: Vector2 = room.spears[0].pos - room.fighters[-1].pos
		room.set_input(-1, toward.normalized() if toward.length() > 40 else Vector2.ZERO, Vector2.LEFT, false)
	room.tick(delta)
	main.on_state(room.snapshot())
	main.arena._process(delta)
	main.arena.camera = Vector2(1024, 768)
	main.arena.shown = {1: room.fighters[1].pos, -1: room.fighters[-1].pos}
	frame_index += 1
	if frame_index >= 450:
		main.quit_game()
	return false
