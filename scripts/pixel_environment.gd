class_name ArenaPixelEnvironment
extends RefCounted

var textures: Dictionary = {}
var stones: Dictionary = {}

func _init() -> void:
	for name in ["floor", "crate", "stone-atlas"]:
		var path := "res://assets/pixellab/environment/%s.png" % name
		if ResourceLoader.exists(path):
			textures[name] = load(path)
	if textures.has("stone-atlas"):
		for name in ["wall", "column"]:
			var atlas := AtlasTexture.new()
			atlas.atlas = textures["stone-atlas"]
			atlas.region = Rect2(0 if name == "wall" else 32, 0, 32, 32)
			atlas.filter_clip = true
			stones[name] = atlas

func texture(name: String) -> Texture2D:
	return stones.get(name, textures.get(name))
