class_name ArenaPixelFX
extends RefCounted

var effects: Dictionary = {}
var textures: Dictionary = {}

func _init() -> void:
	for name in ["alchemy", "slam", "slash", "dash", "spikes", "hit", "block"]:
		var path := "res://assets/pixellab/effects/%s/manifest.json" % name
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary:
				effects[name] = data
				for clip in data.clips:
					for sheet in clip.sheets:
						var texture_path: String = "res://assets/pixellab/effects/%s/%s" % [name, sheet.file]
						if ResourceLoader.exists(texture_path) and not textures.has(texture_path):
							textures[texture_path] = load(texture_path)

func has_effect(name: String) -> bool:
	return effects.has(name)

func parts_for_depth(name: String, depth: String) -> Array[String]:
	var names: Array[String] = []
	if not effects.has(name):
		return names
	for clip in effects[name].clips:
		if clip.name == "whole":
			continue
		var actual: String = clip.depth
		if actual == "both":
			actual = "behind" if clip.name in ["part-shockwave_ring", "part-speed_lines"] else "front"
		if actual == depth:
			names.append(clip.name)
	return names

func frame(name: String, progress: float, part: String = "whole") -> Dictionary:
	if not effects.has(name):
		return {}
	var metadata: Dictionary = effects[name]
	var index := mini(int(clampf(progress, 0, 1) * metadata.frames), int(metadata.frames) - 1)
	for clip in metadata.clips:
		if clip.name != part:
			continue
		var local: int = index - int(clip.start_frame)
		if local < 0 or local >= int(clip.frames):
			return {}
		for sheet in clip.sheets:
			var frame_index: int = local - int(sheet.first_frame)
			if frame_index < 0 or frame_index >= int(sheet.frames):
				continue
			var path: String = "res://assets/pixellab/effects/%s/%s" % [name, sheet.file]
			if not textures.has(path):
				if not ResourceLoader.exists(path):
					return {}
				textures[path] = load(path)
			var size := Vector2(clip.frame.w, clip.frame.h)
			var cell := Vector2(frame_index % int(sheet.columns), frame_index / int(sheet.columns))
			return {"texture": textures[path], "region": Rect2(cell * size, size), "offset": Vector2(clip.offset.x, clip.offset.y), "size": size}
	return {}
