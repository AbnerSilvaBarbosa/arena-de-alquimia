class_name ArenaScenery
extends RefCounted

# Both visual scenarios share this geometry. Gameplay never depends on random decoration.
const TREES := [Vector2(752, 728), Vector2(1296, 808), Vector2(912, 576), Vector2(1136, 960),
	Vector2(448, 368), Vector2(1600, 1168), Vector2(544, 832), Vector2(1504, 704),
	Vector2(704, 1168), Vector2(1344, 368), Vector2(320, 1344), Vector2(1728, 192),
	Vector2(256, 640), Vector2(1792, 896), Vector2(1024, 256), Vector2(1024, 1280),
	Vector2(256, 256), Vector2(1792, 1280), Vector2(384, 480), Vector2(1664, 1056)]
const ENCLOSURES := [Rect2(580, 920, 112, 80), Rect2(1356, 536, 112, 80)]
const GUARDS := [Vector2(1024, 136), Vector2(1024, 1400)]
const PONDS := [Rect2(384, 1120, 192, 192), Rect2(1472, 224, 192, 192)]
const ATLAS_PATH := "res://assets/third_party/woods/free_pixel_16_woods.png"
const REGIONS := {
	"grass": Rect2(48, 48, 16, 16),
	"tree": Rect2(272, 0, 64, 88),
	"sapling": Rect2(272, 88, 32, 40),
	"pine": Rect2(304, 88, 32, 40),
	"rock": Rect2(224, 32, 16, 16),
	"flower": Rect2(224, 64, 16, 16),
	"mushroom": Rect2(256, 32, 16, 16),
	"tuft": Rect2(96, 64, 16, 16),
	"stump": Rect2(240, 64, 16, 16),
	"lilies": Rect2(224, 128, 48, 16),
	"pond": Rect2(144, 96, 80, 80)
}
var atlas: Texture2D
var regions: Dictionary = {}
var decorations: Array = []
var actors: Dictionary = {}

static func solid_rects() -> Array:
	var result: Array = []
	for point in TREES:
		result.append(Rect2(point - Vector2(14, 10), Vector2(28, 20)))
	result.append_array(ENCLOSURES)
	result.append_array(PONDS)
	for point in GUARDS:
		result.append(Rect2(point - Vector2(12, 8), Vector2(24, 16)))
	return result

static func scenario_name(scenario: String) -> String:
	return "Bosque das Ruínas" if scenario == "forest" else "Jardins de Amestris"

static func grass_at(point: Vector2, scenario: String) -> bool:
	if scenario == "forest":
		# Cross-shaped old roads and the ritual circle stay walkable and visually distinct.
		return point.distance_to(Vector2(1024, 768)) > 160 and absf(point.x - 1024) > 52 and absf(point.y - 768) > 44
	for tree in TREES:
		if point.distance_to(tree) < 100:
			return true
	return point.x < 160 or point.x > 1888 or point.y < 160 or point.y > 1376

func _init() -> void:
	if ResourceLoader.exists(ATLAS_PATH):
		atlas = load(ATLAS_PATH)
		for key in REGIONS:
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = REGIONS[key]
			texture.filter_clip = true
			regions[key] = texture
	for key in ["knight", "demon", "blood"]:
		var path := "res://assets/third_party/ambient/%s-idle.png" % key
		if ResourceLoader.exists(path):
			actors[key] = load(path)
	var rng := RandomNumberGenerator.new()
	rng.seed = 417208
	for i in 420:
		var point := Vector2(rng.randi_range(96, 1952), rng.randi_range(96, 1440)).snapped(Vector2(4, 4))
		if point.distance_to(Vector2(832, 768)) < 60 or point.distance_to(Vector2(1216, 768)) < 60:
			continue
		var kind: String = ["tuft", "tuft", "flower", "rock", "mushroom"][rng.randi_range(0, 4)]
		decorations.append({"pos": point, "kind": kind, "variant": rng.randf()})

func texture(key: String) -> Texture2D:
	return regions.get(key)
