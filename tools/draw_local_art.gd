extends SceneTree

## Run against the installed Pixelorama.pck. Native Project/PixelCel/save APIs
## retain editable layers; these are authored pixel commands, not an AI upscale.
var api: Node
var workspace: String

func _initialize() -> void:
	var app = load("res://src/Main.tscn").instantiate()
	var host := GDScript.new()
	host.source_code = FileAccess.get_file_as_string(get_script().resource_path.get_base_dir().path_join("pixelorama_art_host.gd.txt"))
	assert(host.reload() == OK)
	app.set_script(host)
	root.add_child(app)
	current_scene = app
	call_deferred("draw_projects")

func new_project(title: String, size: Vector2i):
	var frames = Array([], TYPE_OBJECT, "RefCounted", load("res://src/Classes/Frame.gd"))
	var project = api.project.new_project(frames, title, size)
	api.project.current_project = project
	return project

func layer(project, title: String, first := false) -> Raster:
	if not first:
		api.project.add_new_layer(project.layers.size() - 1, title)
	project.layers[-1].name = title
	return Raster.new(project.frames[0].cels[-1].get_image())

func save(project, source: String, export_path: String) -> Image:
	for cel in project.frames[0].cels: cel.update_texture()
	var ok: bool = root.get_node("OpenSave").save_pxo_file(workspace.path_join(source), false, false, project)
	assert(ok, "Pixelorama could not save " + source)
	var blended: Image = project.new_empty_image()
	root.get_node("DrawingAlgos").blend_layers(blended, project.frames[0], Vector2i.ZERO, project)
	assert(blended.save_png(workspace.path_join(export_path)) == OK)
	print("PIXELORAMA_ART_SAVED ", source, " size=", project.size, " layers=", project.layers.size())
	return blended

func draw_projects() -> void:
	api = root.get_node("ExtensionsApi")
	workspace = OS.get_environment("ARENA_ART_ROOT")
	if workspace.is_empty(): workspace = DirAccess.open(".").get_current_dir()
	if FileAccess.file_exists(workspace.path_join("art/source/characters/edward_idle_128_study.pxo")) and OS.get_environment("ARENA_ART_REBUILD") != "1":
		print("ART_SOURCES_EXIST: edit the pxo files; set ARENA_ART_REBUILD=1 only to recreate the initial study.")
		quit()
		return
	for folder in ["art/source/characters", "art/source/environment", "assets/local/characters/edward", "assets/local/environment"]:
		DirAccess.make_dir_recursive_absolute(workspace.path_join(folder))
	draw_edward()
	draw_courtyard()
	quit()

func draw_edward() -> void:
	var p = new_project("edward_idle_128_study", Vector2i(128, 128))
	var r := layer(p, "01 / Casaco e tranca", true)
	# Long red coat and braid behind the body, with a deliberate broken hem.
	r.poly([49,46, 66,48, 82,54, 87,71, 81,94, 87,106, 68,104, 57,99, 42,105, 29,100, 32,84, 39,70, 41,56], "6c2935", 2)
	r.poly([45,52, 59,54, 68,71, 59,92, 48,99, 33,96, 37,80], "af3b43")
	r.poly([41,59, 47,57, 44,80, 37,93, 40,79], "df6752")
	r.poly([65,57, 77,54, 83,68, 77,91, 78,100, 67,98], "c64943")
	r.line(48,76,40,96,"802d38",2)
	for index in 7:
		var bx := 42 - index / 3
		var by := 38 + index * 5
		r.poly([bx,by, bx+7,by+1, bx+5,by+6, bx-1,by+5], "bf883c", 1)
		r.line(bx+1,by+1,bx+4,by+3,"efc36b",2)
	r.rect(39,72,5,3,"20282e")
	r.poly([40,75,45,75,45,80,41,83,39,80],"d4a14a",1)
	r = layer(p, "02 / Calcas e botas")
	r.poly([58,77, 76,79, 78,93, 69,109, 69,118, 53,118, 51,111, 55,95], "30333e", 2)
	r.poly([76,79, 88,80, 96,99, 92,115, 97,120, 81,121, 77,115, 79,99, 70,94], "262d36", 2)
	r.poly([60,82, 67,82, 65,98, 59,109, 56,108], "4d4851")
	r.poly([81,86, 87,86, 92,100, 88,113, 84,111], "43414a")
	r.line(69,93,65,102,"1c252e",2)
	r.poly([53,111, 68,110, 70,115, 67,121, 49,121, 49,117], "27303a", 2)
	r.rect(50,116,15,3,"46505b")
	r.line(51,121,68,121,"121d29",2)
	r.poly([82,112, 92,113, 99,118, 99,122, 80,122, 78,119], "252e38", 2)
	r.line(82,116,92,118,"4c525d",2)
	r.line(81,122,98,122,"14202a",2)
	r = layer(p, "03 / Torso e gola")
	r.poly([54,50, 69,47, 84,53, 87,65, 82,85, 62,87, 52,74], "242c34", 2)
	r.poly([61,53, 75,52, 82,57, 77,79, 63,81], "45444c")
	r.poly([62,53, 69,59, 72,74, 68,79, 65,61], "65606a")
	r.poly([50,50, 58,48, 64,57, 60,67, 55,78, 46,78, 48,62], "bb4146", 2)
	r.poly([80,49, 88,54, 95,63, 89,79, 83,83, 77,78, 82,67], "a63841", 2)
	r.line(51,53,53,63,"e17059",2)
	r.line(86,54,90,62,"df6653",2)
	r.poly([54,48,62,44,73,47,78,51,71,55,62,55],"7a2d39",1)
	r.line(57,49,63,51,"f08b67",2)
	r.rect(64,82,19,4,"786d62")
	r.rect(74,81,6,6,"bfae87")
	r.rect(76,83,2,2,"514b4b")
	r = layer(p, "04 / Automail - lado direito anatomico")
	# Front three-quarter view: anatomical right arm appears on image left.
	r.poly([48,57, 54,61, 55,72, 48,77, 42,73, 40,65], "829ba3", 2)
	r.poly([42,64,48,60,51,65,48,71,43,72],"cad8ce")
	r.line(42,66,51,67,"5b7382",2)
	r.poly([44,72, 50,75, 46,81, 40,81, 35,76, 38,72], "647d8c", 2)
	r.rect(40,74,5,4,"a6bac0")
	r.poly([37,75, 44,80, 39,88, 31,91, 23,86, 26,80], "95acb3", 2)
	r.poly([29,80, 35,79, 38,82, 34,86, 28,85], "dde5d6")
	r.line(27,86,34,88,"587589",2)
	r.poly([24,85,31,89,29,95,23,96,19,92,19,88],"b6c6c5",1)
	r.rect(21,88,2,4,"ecede0")
	r.line(23,92,28,94,"607b8b",1)
	r.rect(45,66,2,2,"eff0dd")
	r = layer(p, "05 / Braco e luva esquerda")
	r.poly([89,63,96,67,98,79,91,85,85,80,87,71],"ac3a42",2)
	r.poly([92,67,95,69,96,77,91,80,90,76],"dc6250")
	r.poly([91,81,97,79,101,84,99,91,93,92,88,87],"c8cfbf",2)
	r.rect(95,83,4,4,"efecda")
	r.line(90,87,94,90,"899691",1)
	r = layer(p, "06 / Rosto")
	r.poly([55,26,72,22,83,30,84,40,88,43,83,46,81,53,72,57,61,53,55,44],"bc865e",2)
	r.poly([59,29,72,27,80,32,81,39,85,43,80,45,78,51,71,53,62,49,58,41],"e5b982")
	r.poly([62,31,70,30,72,39,78,42,76,49,69,49,63,45],"f4d49a")
	r.line(76,37,81,38,"76533b",2)
	r.rect(77,39,3,3,"fcf2d5")
	r.rect(79,39,2,3,"947835")
	r.rect(80,39,1,3,"27323b")
	r.line(79,47,83,47,"926448",1)
	r.rect(75,50,4,1,"a16a4d")
	r = layer(p, "07 / Cabelo - mechas desenhadas")
	r.poly([44,30,48,21,56,17,66,14,70,12,77,16,82,17,85,23,89,30,85,36,80,34,75,29,73,38,67,35,63,29,61,39,56,42,51,38,48,45,44,39],"a97837",2)
	r.poly([48,28,54,21,65,18,71,17,79,20,81,26,76,28,70,24,66,26,62,24,55,30,51,38,48,36],"dba844")
	r.poly([54,23,63,19,68,19,64,24,60,26,56,33,53,32],"f7d778")
	r.poly([70,19,76,21,79,26,77,29,72,26,70,24],"f3ca66")
	r.poly([64,25,70,24,70,31,73,37,68,33],"efc467")
	r.poly([49,32,54,29,54,38,50,42,48,39],"e7b552")
	r.line(80,25,84,31,"e4b454",2)
	r.line(62,17,69,14,"c6923d",1)
	r = layer(p, "08 / Expressao - olho dourado")
	r.line(75,39,82,40,"5c4639",1)
	r.rect(77,41,5,3,"f8eed0")
	r.rect(79,41,2,3,"b59242")
	r.rect(81,41,1,3,"25343b")
	r.rect(77,40,4,1,"382e2b")
	r.line(77,46,80,47,"af7950",1)
	save(p, "art/source/characters/edward_idle_128_study.pxo", "assets/local/characters/edward/idle-study.png")

func draw_courtyard() -> void:
	var p = new_project("amestris_tiles_64_study", Vector2i(256, 256))
	var r := layer(p, "01 / Pedra base", true)
	for tile in 4:
		r.origin = Vector2i(tile * 64, 0)
		floor_tile(r, tile)
	r.origin = Vector2i(192, 64)
	floor_tile(r, 0)
	r.origin = Vector2i(0, 128)
	floor_tile(r, 1)
	r.origin = Vector2i(64, 128)
	floor_tile(r, 0)
	r.origin = Vector2i(128, 128)
	floor_tile(r, 0)
	r.origin = Vector2i(192, 128)
	r.rect(0,0,64,64,"786a52")
	for i in 32:
		var x := (i * 29 + 7) % 64
		var y := (i * 17 + 13) % 64
		r.rect(x,y,2,1,"958269" if i % 2 == 0 else "625b4b")
	r = layer(p, "02 / Juntas - rachaduras - musgo")
	r.origin = Vector2i(64, 0)
	crack(r)
	r.origin = Vector2i(128, 0)
	for i in 12:
		var x := (i * 7) % 20
		var y := (i * 11) % 32
		r.rect(x,y,4,2,"68755c")
		r.rect(x+1,y,2,1,"95a27a")
	r.origin = Vector2i(128, 128)
	crack(r)
	r.poly([13,27,27,14,45,17,52,33,39,48,21,44],"605c51",1)
	r.poly([19,28,29,20,39,22,42,34,35,41,24,37],"81735a")
	r = layer(p, "03 / Arquitetura")
	for tile in [0,1]:
		r.origin = Vector2i(tile*64,64)
		r.rect(0,8,64,47,"535651")
		r.rect(0,5,64,10,"b7ae91")
		r.line(0,5,63,5,"d4cbae",2)
		for row in 3:
			for col in 3:
				var x := col * 24 - (12 if row % 2 == 1 else 0)
				r.rect(maxi(0,x+1),16+row*12,mini(22,63-maxi(0,x+1)),10,"97957f")
				r.line(maxi(0,x+2),17+row*12,mini(62,x+21),17+row*12,"b6b29b",1)
		r.rect(0,52,64,5,"62695f")
		if tile==1:
			r.rect(46,2,15,54,"858a78")
			r.rect(47,4,12,9,"c4bca1")
			r.line(48,15,58,15,"545e55",2)
			r.line(48,29,58,29,"545e55",2)
			r.line(48,43,58,43,"545e55",2)
	r.origin = Vector2i(128,64)
	r.poly([9,43,49,43,58,49,57,57,14,58,7,51],"353f40")
	r.rect(12,17,40,37,"787f72")
	r.rect(10,12,44,10,"c0baa0")
	r.rect(16,4,32,10,"a4a58e")
	r.line(17,4,47,4,"ded6b5",2)
	for y in [25,39]:
		r.line(13,y,50,y,"4f5e55",2)
	r.rect(42,22,10,30,"697767")
	r.line(14,53,50,53,"c1bca4",2)
	r.origin = Vector2i(192,64)
	for row in 4:
		r.rect(5,9+row*12,54,10,"8c9181")
		r.line(6,10+row*12,57,10+row*12,"c5bea2",2)
		r.line(6,18+row*12,57,18+row*12,"606b5f",2)
	r = layer(p, "04 / Metal - detalhes de solo")
	for tile in [0,1]:
		r.origin = Vector2i(tile*64,128)
		r.rect(10,13,44,37,"3b484b")
		r.rect(11,14,42,3,"a5aa96")
		r.rect(11,46,42,3,"68776c")
		for i in range(0,7):
			r.rect(14+i*6,18,3,27,"76897f")
			r.rect(15+i*6,19,1,25,"a6b09a")
		if tile==0:
			for y in [23,34,43]: r.line(13,y,51,y,"637769",2)
	r = layer(p, "05 / Objetos e bandeira")
	r.origin = Vector2i(0,192)
	r.poly([7,49,45,48,57,54,49,58,11,57],"303b3c")
	r.poly([10,18,42,18,53,27,53,51,19,51,10,42],"6e4838",2)
	r.poly([11,18,42,18,51,26,20,26],"c79859",1)
	r.poly([20,27,51,27,51,49,20,49],"987044")
	r.poly([11,21,18,28,18,48,11,41],"7d563c")
	for x in [24,34,44]: r.line(x,29,x,46,"bf935a",2)
	r.line(21,29,50,48,"dfb579",3)
	r.line(50,29,21,48,"765239",2)
	r.origin = Vector2i(64,192)
	r.poly([13,48,46,48,51,54,46,58,13,56],"35403d")
	r.poly([18,13,43,13,49,22,49,44,43,52,18,52,12,44,12,22],"7d583c",2)
	r.poly([20,15,29,14,25,49,18,47,17,23],"b0804b")
	r.poly([32,14,41,16,45,25,44,47,33,50],"986f42")
	for y in [22,40]:
		r.rect(13,y,35,5,"596d6b")
		r.line(15,y,46,y,"b4b59b",1)
	r.line(28,17,27,47,"604831",1)
	r.origin = Vector2i(128,192)
	r.rect(10,4,3,54,"6e766c")
	r.rect(11,4,1,52,"cfbea0")
	r.poly([15,10,48,10,48,42,42,40,37,48,29,43,21,47,15,43],"223d51",2)
	r.line(16,12,46,12,"9aafaa",2)
	r.line(46,14,46,38,"465f71",2)
	r.poly([29,20,35,18,39,23,36,29,39,34,33,33,29,38,27,31,23,27],"c1bfa0")
	r.rect(28,23,5,4,"e1d9b7")
	r.origin = Vector2i(192,192)
	for pos in [Vector2i(6,33),Vector2i(32,39),Vector2i(22,19)]:
		r.poly([pos.x,pos.y+11,pos.x+18,pos.y+11,pos.x+23,pos.y+16,pos.x+3,pos.y+17],"435048")
		r.poly([pos.x,pos.y+5,pos.x+6,pos.y,pos.x+18,pos.y+2,pos.x+20,pos.y+11,pos.x+4,pos.y+12],"a1a28b",1)
		r.line(pos.x+6,pos.y+1,pos.x+16,pos.y+3,"d4c8a4",2)
	var atlas := save(p, "art/source/environment/amestris_tiles_64_study.pxo", "assets/local/environment/amestris-atlas.png")
	for tile in 16:
		var image := atlas.get_region(Rect2i(Vector2i(tile%4,tile/4)*64,Vector2i(64,64)))
		image.save_png(workspace.path_join("assets/local/environment/tile-%02d.png" % tile))

func floor_tile(r: Raster, variant: int) -> void:
	r.rect(0,0,64,64,"797d70")
	for row in 2:
		for col in 2:
			var shades := ["a3a28c","a9a58d","9ca08b","a5a38c"]
			var x := col*32
			var y := row*32
			r.rect(x+1,y+1,30,30,shades[(row*2+col+variant)%4])
			r.line(x+2,y+2,x+28,y+2,"c0b99b",1)
			r.line(x+2,y+3,x+2,y+28,"b5b298",1)
			r.line(x+2,y+30,x+29,y+30,"858c77",1)
			r.rect(x+8,y+8,3,1,"aead95")
			r.rect(x+23,y+24,2,1,"959b84")

func crack(r: Raster) -> void:
	var points := [[8,12,17,20],[17,20,14,28],[14,28,25,34],[25,34,24,43],[24,43,33,51],[25,34,36,30],[36,30,41,22]]
	for point in points:
		r.line(point[0]+1,point[1],point[2]+1,point[3],"c4b599",1)
		r.line(point[0],point[1],point[2],point[3],"646c60",1)

class Raster:
	extends RefCounted
	var image: Image
	var origin := Vector2i.ZERO
	func _init(target: Image) -> void: image = target
	func dot(x: int, y: int, color: String) -> void:
		x += origin.x
		y += origin.y
		if x>=0 and y>=0 and x<image.get_width() and y<image.get_height(): image.set_pixel(x,y,Color(color))
	func rect(x: int, y: int, width: int, height: int, color: String) -> void:
		for yy in range(y,y+height):
			for xx in range(x,x+width): dot(xx,yy,color)
	func line(x0: int, y0: int, x1: int, y1: int, color: String, width := 1) -> void:
		var dx: int = absi(x1-x0)
		var dy: int = -absi(y1-y0)
		var sx := 1 if x0<x1 else -1
		var sy := 1 if y0<y1 else -1
		var error: int = dx+dy
		while true:
			rect(x0,y0,width,width,color)
			if x0==x1 and y0==y1: break
			var twice: int = 2*error
			if twice>=dy:
				error+=dy
				x0+=sx
			if twice<=dx:
				error+=dx
				y0+=sy
	func poly(vertices: Array, color: String, outline := 0) -> void:
		var points := PackedVector2Array()
		var lo := Vector2(INF,INF)
		var hi := Vector2.ZERO
		for index in range(0,vertices.size(),2):
			var point := Vector2(vertices[index],vertices[index+1])
			points.append(point)
			lo=lo.min(point)
			hi=hi.max(point)
		for y in range(int(lo.y),int(hi.y)+1):
			for x in range(int(lo.x),int(hi.x)+1):
				if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),points): dot(x,y,color)
		if outline>0:
			for index in points.size():
				var a := points[index]
				var b := points[(index+1)%points.size()]
				line(int(a.x),int(a.y),int(b.x),int(b.y),"202d34",outline)
