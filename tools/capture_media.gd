extends SceneTree

## Scripted documentation footage: uses the actual simulation and local assets.
var main: Node
var room: ArenaRoom
var frame_index := 0
var prepared := false
var assets_mode := false
var gallery: SpriteGallery

func _initialize() -> void:
	assets_mode = "--assets" in OS.get_cmdline_user_args()
	if assets_mode:
		gallery = SpriteGallery.new()
		root.add_child(gallery)
		prepared = true
	else:
		main = load("res://main.tscn").instantiate()
		root.add_child(main)
		call_deferred("prepare")

func prepare() -> void:
	main.start_training()
	main.set_process(false)
	main.net.set_physics_process(false)
	main.arena.set_process(false)
	room = main.net.rooms.TREINO
	room.bot_id = 0
	reset_scene(Vector2(900, 768), Vector2(1150, 768))
	prepared = true

func reset_scene(a: Vector2, b: Vector2) -> void:
	room.phase = "fight"
	room.timer = ArenaRoom.ROUND_TIME
	room.reset_round()
	room.fighters[1].pos = a
	room.fighters[-1].pos = b
	room.fighters[1].name = "Edward"
	room.fighters[-1].name = "Alphonse"
	room.set_input(1, Vector2.ZERO, Vector2.RIGHT, false)
	room.set_input(-1, Vector2.ZERO, Vector2.LEFT, false)

func _process(delta: float) -> bool:
	if not prepared: return false
	if assets_mode:
		gallery.clock = frame_index / 30.0
		gallery.queue_redraw()
	else:
		match frame_index:
			18: room.set_input(1, Vector2.UP, Vector2.RIGHT, false)
			36: room.set_input(1, Vector2.ZERO, Vector2.RIGHT, false)
			45: room.action(1, "q")
			75:
				room.action(1, "e", room.walls[0].rect.get_center())
				room.action(-1, "e")
			120: reset_scene(Vector2(930, 768), Vector2(990, 768))
			130: room.action(1, "attack")
			143: room.set_input(-1, Vector2.ZERO, Vector2.LEFT, true)
			160: room.action(1, "attack")
			182: room.action(1, "grab")
			204:
				room.set_input(-1, Vector2.ZERO, Vector2.LEFT, false)
				room.action(-1, "q")
			220: room.action(1, "dash")
			240:
				reset_scene(Vector2(900, 768), Vector2(1150, 768))
				room.boxes[0].pos = Vector2(935, 768)
			252: room.action(1, "interact")
			270: room.set_input(1, Vector2.RIGHT, Vector2.RIGHT, false)
			294:
				room.set_input(1, Vector2.ZERO, Vector2.RIGHT, false)
				room.action(1, "interact")
			330: room.action(-1, "dash")
			345: room.action(-1, "e")
		room.tick(delta)
		main.on_state(room.snapshot())
		main.arena._process(delta)
		main.arena.camera = Vector2(1024, 768)
		main.arena.shown = {1: room.fighters[1].pos, -1: room.fighters[-1].pos}
	frame_index += 1
	if frame_index >= 390:
		if assets_mode: quit()
		else: main.quit_game()
	return false

class SpriteGallery extends Node2D:
	var clock := 0.0
	var sprites := ArenaPixelAssets.new()
	var effects := ArenaPixelFX.new()
	var font: Font = ThemeDB.fallback_font
	var title_font: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
	const STATES := ["idle", "walk", "attack", "q", "guard", "grab", "pickup", "carry", "carry_walk", "throw", "dash", "hurt", "ko"]
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 540), Color("18272e"))
		draw_string(title_font, Vector2(48, 48), "PIXELLAB / ASSETS DO MVP", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f0e4ce"))
		draw_string(font, Vector2(48, 78), "Exports locais ampliados / sequencias desaceleradas para inspecao", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c0b79f"))
		var phase := mini(int(clock), STATES.size() - 1)
		var state: String = STATES[phase]
		var duration: float = {"attack": 0.28, "q": 0.42, "grab": 0.42, "hurt": 0.18, "throw": 0.2, "dash": 0.16, "ko": 0.3, "pickup": 0.18}.get(state, 1.0)
		draw_string(font, Vector2(48, 116), "Estado: " + state + " / 13 estados por personagem", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("6ee6e1"))
		for index in 2:
			var character: String = ["Edward", "Alphonse"][index]
			var position := Vector2(300 + index * 360, 330)
			var aim := Vector2.RIGHT if index == 0 else Vector2.LEFT
			var art := sprites.frame(character, state, aim, fmod(clock, 1.0) * duration)
			if not art.is_empty():
				var scale_factor: float = art.scale * 3.0
				draw_texture_rect(art.texture, Rect2(position - art.anchor * scale_factor, art.texture.get_size() * scale_factor), false)
			draw_string(font, position + Vector2(-45, 34), character, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f0e4ce"))
		for index in 7:
			var name: String = ["alchemy", "slam", "slash", "dash", "spikes", "hit", "block"][index]
			var art := effects.frame(name, fmod(clock * 1.5, 1.0))
			var position := Vector2(85 + index * 130, 442)
			if not art.is_empty():
				draw_texture_rect_region(art.texture, Rect2(position + art.offset * 0.7, art.size * 0.7), art.region)
			draw_string(font, position + Vector2(-30, 60), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c0b79f"))
