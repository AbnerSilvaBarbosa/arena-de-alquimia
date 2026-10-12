extends SceneTree
var net: ArenaNet
var mode := "create"
var code_path := ""
var port := 17007
var ready_sent := false
var tick := 0.0
var states := 0
var first_pos := Vector2.ZERO
var moved := false
var loaded := false
var ended := false
var invalid_version := false
var duel := false
var result_seen := false
var terrain_seen := false
var weapon_seen := false
var blocker := ArenaRoom.new()

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--duel": duel = true
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--code-file="):
			code_path = arg.trim_prefix("--code-file=")
		if arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	net = ArenaNet.new()
	net.name = "Net"
	main.add_child(net)
	net.lobby_changed.connect(on_lobby)
	net.state_received.connect(on_state)
	net.problem.connect(func(message): push_error("NETWORK_FAIL: " + message); quit(1))
	call_deferred("connect_peer")

func connect_peer() -> void:
	var code := ""
	if mode == "join":
		code = FileAccess.get_file_as_string(code_path).strip_edges()
	net.connect_game("127.0.0.1", port, mode, code, "Teste " + mode)

func on_lobby(data: Dictionary) -> void:
	if mode == "create" and not FileAccess.file_exists(code_path):
		var file := FileAccess.open(code_path, FileAccess.WRITE)
		file.store_string(data.code)
		file.close()
	if data.phase == "lobby" and data.members.size() == 2 and not ready_sent:
		ready_sent = true
		if mode == "join":
			net.select_character("Alphonse")
		get_ready.call_deferred()
	if data.phase == "loading" and not loaded:
		loaded = true
		net.confirm_loaded()

func get_ready() -> void:
	await create_timer(0.25).timeout
	net.toggle_ready()

func on_state(data: Dictionary) -> void:
	if duel and data.phase == "result" and not result_seen:
		var creator: int = net.local_id if mode == "create" else data.fighters.keys().filter(func(id): return id != net.local_id)[0]
		if data.scores[creator] != 2 or data.round != 2:
			push_error("NETWORK_FAIL: invalid best-of-three result")
			quit(1)
			return
		result_seen = true
		print("DUEL_PASS mode=%s round=%d score=2-0" % [mode, data.round])
		vote_rematch.call_deferred()
	if duel and result_seen and data.phase == "countdown" and not ended:
		if not data.scores.values().all(func(score): return score == 0) or not data.fighters.values().all(func(fighter): return fighter.hp == 100):
			push_error("NETWORK_FAIL: rematch did not reset the match")
			quit(1)
			return
		print("REMATCH_PASS mode=", mode)
		finish(data.fighters.size())
	if data.phase != "fight":
		return
	states += 1
	var f: Dictionary = data.fighters[net.local_id]
	if mode == "join" and f.character != "Alphonse":
		push_error("Character selection was not synchronized")
		quit(1)
	if states == 1:
		first_pos = f.pos
	if f.pos.distance_to(first_pos) > 25:
		moved = true
	if duel and states > 12:
		var rival: Dictionary = data.fighters[data.fighters.keys().filter(func(id): return id != net.local_id)[0]]
		var direction: Vector2 = rival.pos - f.pos
		var move := direction.normalized() if mode == "create" and direction.length() > 45 else Vector2.ZERO
		blocker.boxes = data.boxes
		blocker.walls = data.walls
		if move.length() > 0 and blocker.blocked(f.pos + move * 32):
			move = Vector2(move.y, -move.x)
		net.send_input(move, direction.normalized(), false)
		if mode == "create" and direction.length() < 65 and f.cooldowns.attack <= 0 and f.state_time <= 0:
			net.send_action("attack")
	else:
		net.send_input(Vector2(0, -1), Vector2.DOWN, false)
	if not duel:
		terrain_seen = terrain_seen or not data.walls.is_empty()
		weapon_seen = weapon_seen or data.fighters.values().any(func(actor): return actor.get("weapon", "") in ["spear", "hammer", "sword"])
		if states == 5:
			net.send_action("q", f.pos + Vector2(160, 0) if mode == "create" else Vector2.ZERO)
	if states == 3:
		net.send_action("not_a_valid_action")
	if not duel and states > 30 and moved and terrain_seen and weapon_seen and not ended:
		finish(data.fighters.size())

func vote_rematch() -> void:
	var marker := FileAccess.open(code_path + "." + mode + ".result", FileAccess.WRITE)
	marker.store_string("2-0")
	marker.close()
	var other := "join" if mode == "create" else "create"
	while not FileAccess.file_exists(code_path + "." + other + ".result"):
		await create_timer(0.1).timeout
	net.ask_rematch()

func finish(players: int) -> void:
	ended = true
	print("NETWORK_PASS mode=%s players=%d snapshots=%d moved=%s duel=%s" % [mode, players, states, moved, duel])
	var marker := FileAccess.open(code_path + "." + mode + ".done", FileAccess.WRITE)
	marker.store_string("done")
	marker.close()
	var other := "join" if mode == "create" else "create"
	while not FileAccess.file_exists(code_path + "." + other + ".done"):
		await create_timer(0.1).timeout
	await create_timer(0.5).timeout
	quit(0)

func _process(delta: float) -> bool:
	tick += delta
	if tick > (55 if duel else 12):
		push_error("NETWORK_FAIL: timed out")
		quit(1)
	return false
