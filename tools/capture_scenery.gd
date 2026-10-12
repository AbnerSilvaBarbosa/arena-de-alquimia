extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var scenario := "forest"
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="): scenario = arg.trim_prefix("--scenario=")
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	if output.is_empty():
		push_error("Pass --out=/absolute/path.png")
		quit(1)
		return
	var canvas := SubViewport.new()
	canvas.size = Vector2i(2048, 1536)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var arena := ArenaView.new()
	canvas.add_child(arena)
	arena.set_process(false)
	arena.preview = false
	arena.zoom_factor = 1.0
	arena.camera = ArenaRoom.SIZE / 2
	arena.update_view_transform()
	var room := ArenaRoom.new()
	room.add_player(1, "Edward")
	room.add_player(2, "Alphonse")
	room.select(2, "Alphonse")
	room.reset_round()
	room.phase = "fight"
	room.scenario = scenario
	room.fighters[2].weapon = "spear"
	arena.receive(room.snapshot())
	arena.time = 0.5
	arena.queue_redraw()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var error := canvas.get_texture().get_image().save_png(output)
	print("SCENERY_CAPTURE ", scenario, " ", error_string(error))
	quit(0 if error == OK else 1)
