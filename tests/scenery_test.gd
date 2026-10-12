extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(title)
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room := ArenaRoom.new()
	room.add_player(1, "Ed")
	room.add_player(2, "Al")
	room.select(2, "Alphonse")
	room.reset_round()
	room.phase = "fight"
	for f in room.fighters.values():
		check(not room.blocked(f.pos), "Spawn stays clear of environmental obstacles")
	for point in ArenaScenery.TREES:
		check(room.blocked(point), "Tree trunk has collision at " + str(point))
		check(not ArenaScenery.PONDS.any(func(pond): return pond.has_point(point)), "Tree does not float inside a pond")
	var tree: Vector2 = ArenaScenery.TREES[0]
	var fighter: Dictionary = room.fighters[1]
	fighter.pos = tree - Vector2(60, 0)
	room.move_fighter(fighter, Vector2(120, 0))
	check(fighter.pos.x < tree.x - 14, "Dash-size movement cannot cross a tree")
	check(not room.clear_path(tree - Vector2(60, 0), tree + Vector2(60, 0)), "Tree blocks attacks through trunk")
	check(not room.valid_wall(Rect2(tree - Vector2(16, 16), Vector2(32, 32))), "Wall cannot overlap a tree")
	for rect in ArenaScenery.PONDS + ArenaScenery.ENCLOSURES:
		check(room.blocked(rect.get_center()), "Pond or enclosure is solid")
	room.round_number = 2
	room.reset_round()
	check(room.scenario == "forest" and room.snapshot().scenario == "forest", "Second online round switches synchronized scenery")
	room.scenario_override = "garden"
	room.reset_round()
	check(room.scenario == "garden", "Training scenario stays selected across rounds")
	var net := ArenaNet.new()
	root.add_child(net)
	net.set_physics_process(false)
	net.train("Edward", "forest")
	check(net.rooms.TREINO.scenario == "forest", "Training launches selected forest")
	net.free()
	var a := ArenaScenery.new()
	var b := ArenaScenery.new()
	check(a.decorations == b.decorations, "Decoration positions are deterministic")
	check(a.atlas != null and a.actors.size() == 3, "All four local sheets are loaded")
	if a.atlas != null:
		for region in ArenaScenery.REGIONS.values():
			check(Rect2(Vector2.ZERO, a.atlas.get_size()).encloses(region), "Atlas region fits original sheet")
	for key in a.actors:
		var size: Vector2 = a.actors[key].get_size()
		check(size == (Vector2(1920, 1024) if key == "knight" else Vector2(600, 100)), "Ambient animation sheet is intact")
	print("SCENERY_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
