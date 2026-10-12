extends SceneTree

## Build an editable Godot TileMapLayer scene from the native Pixelorama exports.
func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var scene := Node2D.new()
	scene.name = "LocalArtStudy"
	scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(scene)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/local/environment/amestris-atlas.png")
	atlas.texture_region_size = Vector2i(64,64)
	for y in 4:
		for x in 4: atlas.create_tile(Vector2i(x,y))
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(64,64)
	tiles.add_source(atlas,0)
	var ground := TileMapLayer.new()
	ground.name = "CourtyardGround"
	ground.tile_set = tiles
	ground.position = Vector2(96,14)
	scene.add_child(ground)
	ground.owner = scene
	for y in 8:
		for x in 12:
			var variant := 1 if (x==4 and y==5) or (x==8 and y==2) else (2 if x==0 and y>3 else 0)
			ground.set_cell(Vector2i(x,y),0,Vector2i(variant,0))
	var objects := TileMapLayer.new()
	objects.name = "CourtyardArchitecture"
	objects.tile_set = tiles
	objects.position = ground.position
	scene.add_child(objects)
	objects.owner = scene
	for x in 12: objects.set_cell(Vector2i(x,0),0,Vector2i(1 if x in [0,11] else 0,1))
	for point in [Vector2i(0,3),Vector2i(11,3),Vector2i(0,6),Vector2i(11,6)]: objects.set_cell(point,0,Vector2i(2,1))
	for point in [Vector2i(2,1),Vector2i(9,1)]: objects.set_cell(point,0,Vector2i(2,3))
	for point in [Vector2i(5,1),Vector2i(6,1)]: objects.set_cell(point,0,Vector2i(3,1))
	for point in [Vector2i(3,5),Vector2i(9,3)]: objects.set_cell(point,0,Vector2i(0,3))
	objects.set_cell(Vector2i(2,2),0,Vector2i(1,3))
	objects.set_cell(Vector2i(5,6),0,Vector2i(0,2))
	objects.set_cell(Vector2i(9,6),0,Vector2i(3,3))
	var character := Sprite2D.new()
	character.name = "Edward128StaticStudy"
	character.texture = load("res://assets/local/characters/edward/idle-study.png")
	character.position = Vector2(490,300)
	scene.add_child(character)
	character.owner = scene
	var heading := Label.new()
	heading.name = "StudyCaption"
	heading.text = "ARTE LOCAL / PIXELORAMA / POSE ESTÁTICA E TILESET DE ESTUDO"
	heading.position = Vector2(128,492)
	heading.add_theme_font_size_override("font_size",14)
	heading.add_theme_color_override("font_color",Color("f0e4ce"))
	heading.add_theme_color_override("font_shadow_color",Color("18272e"))
	heading.add_theme_constant_override("shadow_offset_x",2)
	heading.add_theme_constant_override("shadow_offset_y",2)
	scene.add_child(heading)
	heading.owner = scene
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/local_preview.tscn")==OK)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/media/local-art-study.png")
	print("LOCAL_ART_PREVIEW_SAVED")
	scene.queue_free()
	await process_frame
	quit()
