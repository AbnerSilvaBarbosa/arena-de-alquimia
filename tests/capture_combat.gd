extends SceneTree

var main: Node

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	call_deferred("capture")

func capture() -> void:
	var mode := "effects"
	var output := ""
	var zoom := 1.5
	var scenario := "garden"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="): mode = argument.trim_prefix("--mode=")
		if argument.begins_with("--out="): output = argument.trim_prefix("--out=")
		if argument.begins_with("--scenario="): scenario = argument.trim_prefix("--scenario=")
		if argument.begins_with("--zoom="): zoom = float(argument.trim_prefix("--zoom="))
	if output.is_empty():
		push_error("Pass --out=/absolute/path.png")
		quit(1)
		return
	main.start_training()
	main.set_process(false)
	main.net.set_physics_process(false)
	var room: ArenaRoom = main.net.rooms.TREINO
	room.phase = "fight"
	room.timer = ArenaRoom.ROUND_TIME
	room.bot_id = 0
	room.reset_round()
	room.scenario = scenario
	room.fighters[1].pos = Vector2(900, 768)
	room.fighters[-1].pos = Vector2(1150, 768)
	room.set_input(1, Vector2.ZERO, Vector2.RIGHT, false)
	room.set_input(-1, Vector2.ZERO, Vector2.LEFT, false)
	if mode == "effects":
		room.action(1, "q")
		room.tick(0.43)
		room.tick(0.01)
		room.action(1, "e")
		room.action(-1, "e")
		room.tick(0.53)
	elif mode in ["wall", "hammer", "spear", "sword"]:
		room.action(1, "q", Vector2(1010, 768))
		room.tick(0.5)
		room.action(1, "e", room.walls[0].rect.get_center())
		room.fighters[-1].weapon = "hammer" if mode == "wall" else mode
		room.tick(0.1)
	elif mode == "carry":
		room.boxes[0].pos = room.fighters[1].pos + Vector2(35, 0)
		room.action(1, "interact")
		room.set_input(-1, Vector2.ZERO, Vector2.LEFT, true)
		room.tick(0.2)
	elif mode == "ko":
		room.fighters[-1].hp = 0
		room.tick(0.02)
	main.on_state(room.snapshot())
	main.arena.set_process(false)
	main.arena.camera = Vector2(1024, 768)
	main.arena.zoom_factor = zoom
	main.arena.update_view_transform()
	main.arena.shown = {1: room.fighters[1].pos, -1: room.fighters[-1].pos}
	for id in room.fighters:
		var state: String = "ko" if room.fighters[id].hp <= 0 else room.fighters[id].state
		if room.fighters[id].carrying != -1: state = "carry"
		main.arena.animation_clocks[id] = {"state": state, "elapsed": 0.32 if state == "ko" else 0.24, "aim": room.fighters[id].aim}
	main.arena.queue_redraw()
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output)
	print("COMBAT_CAPTURE ", mode, " ", error_string(error))
	main.quit_game()
