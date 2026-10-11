extends SceneTree

var failures := 0
var checks := 0
var asset_paths: Dictionary = {}
const CARDINALS := ["south", "east", "north", "west"]
const STATES := ["idle", "walk", "attack", "guard", "dash", "grab", "cast", "pickup", "carry", "carry_walk", "throw", "hurt", "ko"]

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("ASSET_FAIL ", label)

func check_texture(path: String) -> Texture2D:
	if not asset_paths.has(path):
		verify(ResourceLoader.exists(path), "resource included: " + path)
		asset_paths[path] = load(path) if ResourceLoader.exists(path) else null
	return asset_paths[path]

func _initialize() -> void:
	var assets := ArenaPixelAssets.new()
	for name in ["Edward", "Alphonse"]:
		verify(assets.characters.has(name), "character " + name)
		var animations: Dictionary = assets.characters.get(name, {}).get("animations", {})
		for state in STATES:
			verify(animations.has(state), "%s complete state %s" % [name, state])
			var clips: Dictionary = animations.get(state, {})
			for direction in CARDINALS:
				verify(clips.has(direction), "%s %s %s" % [name, state, direction])
			for direction in clips:
				var clip: Dictionary = clips[direction]
				var anchor := Vector2(clip.anchor[0], clip.anchor[1])
				if clip.has("sheet"):
					var texture := check_texture(clip.sheet)
					if texture == null: continue
					var size := Vector2(clip.frame_size[0], clip.frame_size[1])
					verify(texture.get_width() == int(size.x) * int(clip.columns), "sheet columns " + clip.sheet)
					verify(texture.get_height() % int(size.y) == 0, "sheet rows " + clip.sheet)
					verify(clip.frame_count <= clip.columns * texture.get_height() / int(size.y), "frame bounds " + clip.sheet)
					verify(Rect2(Vector2.ZERO, size).has_point(anchor), "foot anchor " + clip.sheet)
				else:
					verify(clip.frames.size() >= 4, "four or more frames " + name + " " + state)
					verify(not clip.has("frame_anchors") or clip.frame_anchors.size() == clip.frames.size(), "per-frame anchors " + name + " " + state)
					for index in clip.frames.size():
						var path: String = clip.frames[index]
						var frame_anchor := Vector2(clip.frame_anchors[index][0], clip.frame_anchors[index][1]) if clip.has("frame_anchors") else anchor
						var texture := check_texture(path)
						if texture != null:
							verify(Rect2(Vector2.ZERO, texture.get_size()).has_point(frame_anchor), "foot anchor " + path)
		for direction in ArenaPixelAssets.DIRECTIONS:
			verify(animations.get("idle", {}).has(direction), name + " idle eight directions " + direction)
		# Short gameplay states must show the end of their animation, not truncate it at its authored FPS.
		for pair in [["attack", 0.28], ["grab", 0.42], ["q", 0.42], ["e", 0.42], ["dash", 0.16], ["hurt", 0.18], ["throw", 0.2], ["pickup", 0.18], ["ko", 0.3]]:
			var start := assets.frame(name, pair[0], Vector2.DOWN, 0)
			var end := assets.frame(name, pair[0], Vector2.DOWN, float(pair[1]) * 0.99)
			verify(not start.is_empty() and not end.is_empty(), name + " action endpoint " + pair[0])
			if not start.is_empty() and not end.is_empty():
				verify(start.texture != end.texture, name + " full action progression " + pair[0])
	var fx := ArenaPixelFX.new()
	for name in ["alchemy", "slam", "slash", "dash", "spikes", "hit", "block"]:
		verify(fx.has_effect(name), "effect " + name)
		verify(not fx.frame(name, 0.5).is_empty(), "effect midpoint " + name)
		for clip in fx.effects.get(name, {}).get("clips", []):
			for sheet in clip.sheets:
				var texture := check_texture("res://assets/pixellab/effects/%s/%s" % [name, sheet.file])
				if texture == null: continue
				verify(texture.get_width() == clip.frame.w * sheet.columns and texture.get_height() == clip.frame.h * sheet.rows, "effect grid " + name + " " + clip.name)
	for name in ["atlas", "emblem", "edward-portrait", "alphonse-portrait"]:
		check_texture("res://assets/pixellab/ui/%s.png" % name)
	for name in ["floor", "crate", "stone-atlas"]:
		check_texture("res://assets/pixellab/environment/%s.png" % name)
	print("ASSET_RESULT checks=%d textures=%d failures=%d" % [checks, asset_paths.size(), failures])
	quit(1 if failures else 0)
