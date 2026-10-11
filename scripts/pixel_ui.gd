class_name ArenaPixelUI
extends RefCounted

const ATLAS := "res://assets/pixellab/ui/atlas.png"
static var regions: Dictionary = {}

static func region(rect: Rect2) -> Texture2D:
	if regions.has(rect):
		return regions[rect]
	if not ResourceLoader.exists(ATLAS):
		return null
	var texture := AtlasTexture.new()
	texture.atlas = load(ATLAS)
	texture.region = rect
	texture.filter_clip = true
	regions[rect] = texture
	return texture

static func portrait_texture(character: String) -> Texture2D:
	var path := "res://assets/pixellab/ui/%s-portrait.png" % character.to_lower()
	if ResourceLoader.exists(path):
		return load(path)
	var fallback := "res://assets/pixellab/%s/Idle/rotations/south.png" % character.to_lower()
	return load(fallback) if ResourceLoader.exists(fallback) else null

static func portrait(character: String, size: int = 56) -> TextureRect:
	var node := TextureRect.new()
	node.texture = portrait_texture(character)
	node.custom_minimum_size = Vector2(size, size)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func frame(button: bool = false, highlight: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = region(Rect2(68, 32 if highlight else 0, 92, 32) if button else Rect2(0, 0, 64, 64))
	style.texture_margin_left = 12 if not button else 8
	style.texture_margin_right = 12 if not button else 8
	style.texture_margin_top = 12 if not button else 8
	style.texture_margin_bottom = 12 if not button else 8
	style.content_margin_left = 18 if button else 24
	style.content_margin_right = 18 if button else 24
	style.content_margin_top = 10 if button else 22
	style.content_margin_bottom = 10 if button else 22
	return style

static func icon(index: int, size: int = 24) -> TextureRect:
	var node := TextureRect.new()
	node.texture = region(Rect2(index * 32, 96, 32, 32))
	node.custom_minimum_size = Vector2(size, size)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
