class_name ArenaPixelAssets
extends RefCounted

## Local exports from PixelLab. No API calls or credentials ship with the game.
const MANIFEST := "res://assets/pixellab/manifest.json"
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
var characters: Dictionary = {}
var textures: Dictionary = {}
var atlas_frames: Dictionary = {}

func _init() -> void:
	if FileAccess.file_exists(MANIFEST):
		var data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if data is Dictionary:
			characters = data.get("characters", {})
	# Prepare tiny character textures before the player enters a room.
	for character in characters.values():
		for views in character.get("animations", {}).values():
			for clip in views.values():
				var paths: Array = [clip.sheet] if clip.has("sheet") else clip.get("frames", [])
				for path in paths:
					if ResourceLoader.exists(path) and not textures.has(path):
						textures[path] = load(path)

func frame(character: String, state: String, aim: Vector2, elapsed: float) -> Dictionary:
	if not characters.has(character):
		return {}
	var entry: Dictionary = characters[character]
	var animation := "idle"
	match state:
		"walk": animation = "walk"
		"dash", "charge": animation = "dash"
		"attack": animation = "attack"
		"grab": animation = "grab"
		"q", "e": animation = "cast"
		"hurt": animation = "hurt"
		"throw": animation = "throw"
		"guard": animation = "guard"
		"ko": animation = "ko"
		"pickup": animation = "pickup"
		"carry": animation = "carry"
		"carry_walk": animation = "carry_walk"
	var clips: Dictionary = entry.get("animations", {})
	if not clips.has(animation):
		animation = "walk" if animation == "dash" and clips.has("walk") else ("attack" if animation in ["cast", "throw"] and clips.has("attack") else "idle")
	var direction: String = DIRECTIONS[posmod(int(round(aim.angle() / (PI / 4))), 8)]
	var clip: Dictionary = clips.get(animation, {}).get(direction, {})
	if clip.is_empty() and animation != "idle":
		var cardinal: String = ["east", "south", "west", "north"][posmod(int(round(aim.angle() / (PI / 2))), 4)]
		clip = clips.get(animation, {}).get(cardinal, {})
	if clip.is_empty():
		clip = clips.get("idle", {}).get(direction, {})
	var frames: Array = clip.get("frames", [])
	var count := int(clip.get("frame_count", frames.size()))
	if count == 0:
		return {}
	var index := int(elapsed * float(clip.get("fps", 10)))
	if animation in ["idle", "walk", "guard", "carry", "carry_walk"]:
		index = posmod(index, count)
	else:
		var duration: float = {"attack": 0.28, "grab": 0.42, "q": 0.42, "e": 0.42, "hurt": 0.18, "throw": 0.2, "dash": 0.16, "charge": 0.22, "ko": 0.3, "pickup": 0.18}.get(state, 0.42)
		index = mini(int(elapsed / duration * count), count - 1)
	var path: String = clip.sheet if clip.has("sheet") else frames[index]
	if not textures.has(path):
		if not ResourceLoader.exists(path):
			return {}
		textures[path] = load(path)
	var anchor: Array = clip.get("anchor", [32, 58])
	if clip.has("frame_anchors"):
		anchor = clip.frame_anchors[index]
	var texture: Texture2D = textures[path]
	if clip.has("sheet"):
		var key := "%s:%d" % [path, index]
		if not atlas_frames.has(key):
			var cell := Vector2(clip.frame_size[0], clip.frame_size[1])
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(index % int(clip.columns), index / int(clip.columns)) * cell, cell)
			atlas.filter_clip = true
			atlas_frames[key] = atlas
		texture = atlas_frames[key]
	return {"texture": texture, "anchor": Vector2(anchor[0], anchor[1]), "scale": float(entry.get("scale", 1.0))}
