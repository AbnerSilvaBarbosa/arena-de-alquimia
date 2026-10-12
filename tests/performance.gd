extends SceneTree
var main: Node
var clock := 0.0
var action_clock := 0.0
var frames: Array = []
var process_times: Array = []
var finished := false
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	call_deferred("begin")
func begin() -> void:
	if "--forest" in OS.get_cmdline_user_args():
		main.training_scenario = "forest"
	main.start_training()
	main.set_process(false)
func _process(delta: float) -> bool:
	clock += delta
	if main.net.training and main.net.rooms.has("TREINO"):
		var room: ArenaRoom = main.net.rooms.TREINO
		if room.phase == "fight":
			var direction: Vector2 = room.fighters[-1].pos - room.fighters[1].pos
			main.net.send_input(direction.normalized() if direction.length() > 55 else Vector2.ZERO, direction, false)
			action_clock += delta
			if action_clock > 0.5:
				action_clock = 0
				main.net.send_action("attack")
			if room.fighters[1].cooldowns.e <= 0:
				main.net.send_action("e")
	if clock > 4:
		frames.append(Engine.get_frames_per_second())
		process_times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
	if clock > 18 and not finished:
		finished = true
		var mean := 0.0
		var frame_mean := 0.0
		for value in process_times: mean += value
		for value in frames: frame_mean += value
		print("PERFORMANCE_RESULT samples=%d fps_min=%s fps_avg=%.1f cpu_frame_ms_avg=%.3f" % [frames.size(), frames.min(), frame_mean / frames.size(), mean / process_times.size()])
		main.quit_game()
	return false
