extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view := ArenaView.new()
	root.add_child(view)
	view.preview = false
	view.set_process(false)
	for zoom in [1.0, 1.5, 2.0]:
		view.zoom_factor = zoom
		view.camera = Vector2(1024, 768)
		view.update_view_transform()
		var center := view.get_viewport_rect().size / 2
		check(view.world_to_screen(view.camera).distance_to(center) < 0.001, "Camera stays at screen center")
		for world in [Vector2(900, 730), Vector2(1150, 768), Vector2(100, 1400)]:
			var screen := view.world_to_screen(world)
			check(view.screen_to_world(screen).distance_to(world) < 0.001, "Aim projection roundtrip at %s" % zoom)
			check(view.to_global(view._world_to_canvas(world)).distance_to(screen) <= 1.5, "Draw transform agrees with aim projection")
		for point in [Vector2(832, 768), Vector2(1216, 768)]:
			check(view.get_viewport_rect().has_point(view.world_to_screen(point)), "Both opening fighters fit in centered view")
	view.preview = true
	view.update_view_transform()
	check(view.scale == Vector2.ONE, "Menus keep original preview scale")
	check(view.position == Vector2.ZERO, "Menus keep original preview origin")
	print("VIEW_RESULT checks=%d failures=%d" % [checks, failures])
	view.queue_free()
	await process_frame
	quit(1 if failures else 0)
