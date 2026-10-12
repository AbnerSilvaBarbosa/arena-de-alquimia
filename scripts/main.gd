extends Node

var net: ArenaNet
var arena: ArenaView
var sound: ArenaSound
var layer: CanvasLayer
var ui: Control
var hud: Control
var overlay: Control
var screen := "menu"
var lobby: Dictionary = {}
var state: Dictionary = {}
var nickname := "Alquimista"
var address := "127.0.0.1"
var port := 7000
var input_code := ""
var character := "Edward"
var training_scenario := "garden"
var notice := ""
var input_clock := 0.0
var last_phase := ""
var local_server_pid := -1
var volume := 0.7
var effects_volume := 0.65
var music_volume := 0.18
var arena_zoom := 1.5
var previous_hp: Dictionary = {}
var captured := false
var capture_path := ""
var capture_mode := ""
var elapsed := 0.0
var connection_busy := false
var quitting := false
var status_label: Label
var health_labels: Array[Label] = []
var health_character_labels: Array[Label] = []
var health_portraits: Array[TextureRect] = []
var hp_bars: Array[ProgressBar] = []
var stamina_bars: Array[ProgressBar] = []
var scenario_label: Label
var timer_label: Label
var banner_label: Label
var ability_labels: Array[Label] = []
var ability_icons: Array[TextureRect] = []
const TEXT := Color("f0e4ce")
const MUTED := Color("c0b79f")
const CYAN := Color("6ee6e1")

func _ready() -> void:
	install_inputs()
	net = ArenaNet.new()
	net.name = "Net"
	add_child(net)
	var args := OS.get_cmdline_user_args()
	if "--server" in args or OS.has_feature("dedicated_server"):
		var listen_port := port
		for arg in args:
			if arg.begins_with("--port="):
				listen_port = int(arg.trim_prefix("--port="))
		var err := net.serve(listen_port)
		if err != OK:
			push_error("Não foi possível iniciar o servidor: %s" % error_string(err))
			get_tree().quit(1)
		return
	load_settings()
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_min_size(Vector2i(960, 540))
	arena = ArenaView.new()
	arena.zoom_factor = arena_zoom
	add_child(arena)
	sound = ArenaSound.new()
	add_child(sound)
	sound.volume = effects_volume
	sound.music_volume = music_volume
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	layer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = make_theme()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	net.lobby_changed.connect(on_lobby)
	net.state_received.connect(on_state)
	net.problem.connect(on_error)
	net.connection_changed.connect(func(text):
		notice = text
		if is_instance_valid(status_label):
			status_label.text = text)
	show_menu()
	for arg in args:
		if arg.begins_with("--training-scenario="):
			var requested := arg.trim_prefix("--training-scenario=")
			if requested in ["garden", "forest"]:
				training_scenario = requested
		if arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--capture-mode="):
			capture_mode = arg.trim_prefix("--capture-mode=")
	if "--train" in args or capture_mode in ["arena", "result"]:
		start_training()
	elif capture_mode == "training":
		show_training()
	elif capture_mode == "connect":
		show_connect()
	elif capture_mode == "options":
		show_options()
	elif capture_mode == "lobby":
		var demo := ArenaRoom.new()
		demo.code = "DEMO42"
		demo.add_player(1, "Alquimista")
		demo.add_player(2, "Seu amigo")
		demo.select(2, "Alphonse")
		demo.ready_player(2)
		on_lobby(demo.lobby_data())
	if "--capture-wide-names" in args:
		if screen == "lobby":
			for member in lobby.members.values():
				member.name = "WWWWWWWWWWWWWWWWWWWW"
			show_lobby()
		elif net.training:
			for fighter in net.rooms[net.current_code].fighters.values():
				fighter.name = "WWWWWWWWWWWWWWWWWWWW"

func install_inputs() -> void:
	var keys := {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S, "dash": KEY_SPACE, "q": KEY_Q, "e": KEY_E, "grab": KEY_R, "interact": KEY_F, "menu": KEY_ESCAPE}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for action in ["attack", "guard"]:
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if action == "attack" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, event)

func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", CYAN)
	theme.set_color("font_disabled_color", "Button", Color("77796e"))
	for pair in [["normal", "262e33", "8e7852"], ["hover", "334448", "6ee6e1"], ["pressed", "1a3337", "6ee6e1"], ["disabled", "25292b", "4d514f"], ["focus", "263c40", "6ee6e1"]]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(pair[1])
		box.border_color = Color(pair[2])
		box.set_border_width_all(1)
		box.content_margin_left = 18
		box.content_margin_right = 18
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		if pair[0] == "focus":
			box.bg_color = Color(0, 0, 0, 0)
			box.set_border_width_all(2)
		theme.set_stylebox(pair[0], "Button", box)
	var edit := StyleBoxFlat.new()
	edit.bg_color = Color("171f24")
	edit.border_color = Color("82775f")
	edit.set_border_width_all(1)
	edit.content_margin_left = 12
	edit.content_margin_top = 10
	edit.content_margin_bottom = 10
	theme.set_stylebox("normal", "LineEdit", edit)
	if ResourceLoader.exists(ArenaPixelUI.ATLAS):
		theme.set_stylebox("normal", "Button", ArenaPixelUI.frame(true))
		theme.set_stylebox("hover", "Button", ArenaPixelUI.frame(true, true))
		theme.set_stylebox("pressed", "Button", ArenaPixelUI.frame(true, true))
	var focused: StyleBoxFlat = edit.duplicate()
	focused.border_color = CYAN
	theme.set_stylebox("focus", "LineEdit", focused)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("caret_color", "LineEdit", CYAN)
	return theme

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	hud = null
	overlay = null
	status_label = null

func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	if size >= 28:
		node.add_theme_font_override("font", preload("res://assets/fonts/Silkscreen-Regular.ttf"))
		node.add_theme_font_size_override("font_size", 32 if size >= 40 else 24)
	node.add_theme_color_override("font_color", color)
	return node

func button(text: String, callback: Callable, width: float = 0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(width, 44)
	node.pressed.connect(func():
		sound.play("ui")
		callback.call())
	return node

func panel(parent: Node, pos: Vector2, size: Vector2, alpha: float = 0.96) -> PanelContainer:
	var node := PanelContainer.new()
	node.position = pos
	node.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.12, alpha)
	style.border_color = Color("857454")
	style.set_border_width_all(1)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	node.add_theme_stylebox_override("panel", style)
	if ResourceLoader.exists(ArenaPixelUI.ATLAS):
		node.add_theme_stylebox_override("panel", ArenaPixelUI.frame())
	parent.add_child(node)
	return node

func column(parent: Node, separation: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node

func veil(alpha: float = 0.65) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.045, 0.055, alpha)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)

func show_menu() -> void:
	screen = "menu"
	sound.set_scene("menu")
	arena.preview = true
	clear_ui()
	veil(0.42)
	var box := column(panel(ui, Vector2(54, 62), Vector2(430, 422), 0.93), 12)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	box.add_child(title_row)
	var emblem := TextureRect.new()
	emblem.texture = ArenaPixelUI.region(Rect2(184, 0, 64, 64))
	emblem.custom_minimum_size = Vector2(64, 64)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(emblem)
	title_row.add_child(label("ARENA DE\nALQUIMIA", 40))
	box.add_child(label("Transforme o chão. Mude a luta.", 18, CYAN))
	box.add_child(label("Duelo 1 × 1 · Melhor de três", 16, MUTED))
	box.add_child(button("Iniciar · jogar com um amigo", show_connect))
	box.add_child(button("Treino · experimentar o combate", show_training))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	row.add_child(button("Opções", show_options, 180))
	row.add_child(button("Sair", quit_game, 180))
	var footer := label("PROTÓTIPO %s  /  ARTE E ÁUDIO PROVISÓRIOS" % ProjectSettings.get_setting("application/config/version", "0.1"), 12, TEXT)
	footer.position = Vector2(54, 514)
	ui.add_child(footer)

func field(parent: Node, title: String, value: String, changed: Callable, max_length: int = 0) -> LineEdit:
	parent.add_child(label(title, 14, MUTED))
	var edit := LineEdit.new()
	edit.text = value
	edit.max_length = max_length
	edit.custom_minimum_size.y = 40
	edit.text_changed.connect(changed)
	parent.add_child(edit)
	return edit

func show_connect() -> void:
	screen = "connect"
	connection_busy = false
	clear_ui()
	veil()
	var box := column(panel(ui, Vector2(130, 36), Vector2(700, 468)), 8)
	box.add_child(label("Jogue com um amigo", 30))
	box.add_child(label("Os dois conectam ao mesmo servidor.", 16, MUTED))
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 16)
	box.add_child(identity)
	var player_col := column(identity, 4)
	player_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field(player_col, "Seu apelido", nickname, func(value): nickname = value, 20)
	var code_col := column(identity, 4)
	code_col.custom_minimum_size.x = 220
	field(code_col, "Código · apenas para entrar", input_code, func(value): input_code = value.to_upper(), 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var left := column(row, 4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field(left, "Endereço do servidor", address, func(value): address = value, 128)
	var right := column(row, 4)
	right.custom_minimum_size.x = 120
	field(right, "Porta UDP", str(port), func(value): port = int(value), 5)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	buttons.add_child(button("Criar sala", func(): connect_session("create"), 320))
	buttons.add_child(button("Entrar com código", func(): connect_session("join"), 320))
	status_label = label(notice if not notice.is_empty() else "Na VPS, use o endereço público do servidor.", 14, CYAN)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(500, 50)
	box.add_child(status_label)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	box.add_child(bottom)
	bottom.add_child(button("Voltar", leave_menu, 130))
	bottom.add_child(button("Ligar servidor local para testes", start_local_server, 510))

func connect_session(mode: String) -> void:
	if connection_busy:
		return
	if port < 1024 or port > 65535 or address.strip_edges().is_empty():
		on_error("Informe um endereço e uma porta entre 1024 e 65535.")
		return
	if mode == "join" and input_code.length() != 6:
		on_error("O código tem seis caracteres. Confira com seu amigo.")
		return
	connection_busy = true
	save_settings()
	net.connect_game(address, port, mode, input_code, nickname)

func start_local_server() -> void:
	if local_server_pid > 0 and OS.is_process_running(local_server_pid):
		notice = "Servidor local já está ligado em 127.0.0.1:%d." % port
	else:
		var args := PackedStringArray(["--headless"])
		if OS.has_feature("editor"):
			args.append_array(["--path", ProjectSettings.globalize_path("res://")])
		args.append_array(["--", "--server", "--port=%d" % port])
		local_server_pid = OS.create_process(OS.get_executable_path(), args)
		notice = "Servidor local iniciado. Crie uma sala e abra outro cliente." if local_server_pid > 0 else "Não foi possível iniciar o processo de servidor."
	address = "127.0.0.1"
	show_connect()

func show_training() -> void:
	screen = "training"
	clear_ui()
	veil()
	var box := column(panel(ui, Vector2(230, 66), Vector2(500, 408)), 12)
	box.add_child(label("Escolha seu alquimista", 30))
	box.add_child(label("Edward · mobilidade, parede e espinhos\nAlphonse · lança, martelo e espada", 17, MUTED))
	box.add_child(label("Cenário", 14, MUTED))
	var choice := OptionButton.new()
	choice.add_item("Jardins de Amestris")
	choice.add_item("Bosque das Ruínas")
	choice.select(1 if training_scenario == "forest" else 0)
	choice.custom_minimum_size.y = 38
	choice.item_selected.connect(func(index): training_scenario = "forest" if index == 1 else "garden")
	box.add_child(choice)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(button("Edward", func(): character = "Edward"; start_training(), 218))
	row.add_child(button("Alphonse", func(): character = "Alphonse"; start_training(), 218))
	box.add_child(label("Bot simples para testar. Não é IA competitiva.", 14, CYAN))
	box.add_child(button("Voltar", show_menu))

func start_training() -> void:
	net.train(character, training_scenario)

func on_lobby(data: Dictionary) -> void:
	connection_busy = false
	lobby = data
	arena.local_id = net.local_id
	if data.phase == "lobby":
		show_lobby()
	elif data.phase == "loading":
		show_game()
		# Local PixelLab textures were prepared before entering the lobby.
		net.confirm_loaded()
	elif screen != "game":
		show_game()
	if data.phase == "result" and not state.is_empty():
		state.message = data.message
		state.scores = data.scores
		show_result()

func show_lobby() -> void:
	screen = "lobby"
	arena.preview = true
	clear_ui()
	veil(0.6)
	var box := column(panel(ui, Vector2(120, 20), Vector2(720, 500)), 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	row.add_child(label("Sala " + lobby.code, 30))
	row.add_child(button("Copiar código", func(): DisplayServer.clipboard_set(lobby.code)))
	box.add_child(label("Compartilhe o código com seu amigo para começar.", 16, MUTED))
	var members_row := HBoxContainer.new()
	members_row.add_theme_constant_override("separation", 40)
	box.add_child(members_row)
	for id in lobby.members:
		var member: Dictionary = lobby.members[id]
		var card := HBoxContainer.new()
		card.custom_minimum_size = Vector2(300, 64)
		card.add_theme_constant_override("separation", 10)
		members_row.add_child(card)
		card.add_child(ArenaPixelUI.portrait(member.character, 56))
		var col := column(card, 7)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size = Vector2(230, 64)
		var player_title := label(member.name + (" · você" if id == net.local_id else ""), 21)
		player_title.clip_text = true
		player_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(player_title)
		col.add_child(label(member.character + (" · PRONTO" if member.ready else " · Escolhendo"), 15, CYAN if member.ready else MUTED))
	if lobby.members.size() == 1:
		var col := column(members_row)
		col.add_child(label("Aguardando seu amigo…", 22, MUTED))
	box.add_child(label("Seu personagem", 14, MUTED))
	var selection := HBoxContainer.new()
	selection.add_theme_constant_override("separation", 12)
	box.add_child(selection)
	selection.add_child(button("Edward · terreno", func(): net.select_character("Edward"), 320))
	selection.add_child(button("Alphonse · impacto", func(): net.select_character("Alphonse"), 320))
	var local: Dictionary = lobby.members.get(net.local_id, {})
	box.add_child(button("Cancelar Ready" if local.get("ready", false) else "Ready · estou pronto", func(): sound.play("ready"); net.toggle_ready()))
	box.add_child(label(lobby.message if not lobby.message.is_empty() else "A partida começa quando os dois estiverem prontos.", 14, MUTED))
	box.add_child(button("Sair da sala", leave_menu))

func show_game() -> void:
	screen = "game"
	sound.set_scene("battle")
	arena.preview = false
	arena.local_id = net.local_id
	clear_ui()
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(hud)
	health_labels.clear()
	health_character_labels.clear()
	health_portraits.clear()
	hp_bars.clear()
	stamina_bars.clear()
	for i in 2:
		var p := panel(hud, Vector2(18 if i == 0 else 680, 14), Vector2(262, 76), 0.9)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style: StyleBox = p.get_theme_stylebox("panel").duplicate()
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.content_margin_left = 12
		style.content_margin_right = 12
		p.add_theme_stylebox_override("panel", style)
		var card := HBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		p.add_child(card)
		var portrait := ArenaPixelUI.portrait("Edward" if i == 0 else "Alphonse", 42)
		card.add_child(portrait)
		health_portraits.append(portrait)
		var col := column(card, 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := label("Carregando…", 16)
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(title)
		health_labels.append(title)
		var character_label := label("", 12, MUTED)
		col.add_child(character_label)
		health_character_labels.append(character_label)
		var hp := progress(Color("c65353"), 10)
		col.add_child(hp)
		hp_bars.append(hp)
		var stamina := progress(CYAN, 4)
		col.add_child(stamina)
		stamina_bars.append(stamina)
	var timer_panel := panel(hud, Vector2(365, 14), Vector2(230, 76), 0.94)
	var timer_style: StyleBox = timer_panel.get_theme_stylebox("panel").duplicate()
	timer_style.content_margin_top = 5
	timer_style.content_margin_bottom = 5
	timer_panel.add_theme_stylebox_override("panel", timer_style)
	timer_label = label("", 22)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_panel.add_child(timer_label)
	scenario_label = label("", 12, TEXT)
	scenario_label.position = Vector2(365, 92)
	scenario_label.size = Vector2(230, 24)
	scenario_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scenario_label.add_theme_color_override("font_shadow_color", Color("121a21"))
	scenario_label.add_theme_constant_override("shadow_offset_x", 2)
	scenario_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(scenario_label)
	banner_label = label("", 32)
	banner_label.position = Vector2(100, 150)
	banner_label.size = Vector2(760, 110)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_label.add_theme_color_override("font_shadow_color", Color("121a21"))
	banner_label.add_theme_constant_override("shadow_offset_x", 2)
	banner_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(banner_label)
	var help := panel(hud, Vector2(90, 470), Vector2(748, 56), 0.94)
	var style: StyleBox = help.get_theme_stylebox("panel").duplicate()
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	help.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	help.add_child(row)
	ability_labels.clear()
	ability_icons.clear()
	var icon_indices := [0, 1, 2, 4, 5]
	var texts := ["Q  Parede", "E  Espinhos", "R  Agarrão", "F  Caixa", "ESPAÇO  Esquiva"]
	for i in texts.size():
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		row.add_child(item)
		var art := ArenaPixelUI.icon(icon_indices[i], 20)
		item.add_child(art)
		ability_icons.append(art)
		var text: String = texts[i]
		var node := label(text, 14, TEXT)
		item.add_child(node)
		ability_labels.append(node)
	var controls := label("WASD mover  ·  Mouse mirar  ·  Clique atacar  ·  Direito defender  ·  Esc menu", 12, TEXT)
	var control_back := panel(hud, Vector2(175, 434), Vector2(620, 28), 0.94)
	var control_style: StyleBox = control_back.get_theme_stylebox("panel").duplicate()
	control_style.content_margin_left = 10
	control_style.content_margin_right = 10
	control_style.content_margin_top = 4
	control_style.content_margin_bottom = 4
	control_back.add_theme_stylebox_override("panel", control_style)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_back.add_child(controls)
	var exit_button := button("Menu", show_game_menu)
	exit_button.position = Vector2(866, 488)
	exit_button.size = Vector2(76, 36)
	exit_button.custom_minimum_size.y = 32
	ui.add_child(exit_button)

func progress(color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(1, height)
	bar.value = 100
	var background := StyleBoxFlat.new()
	background.bg_color = Color("30373a")
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar

func on_state(data: Dictionary) -> void:
	state = data
	arena.receive(data)
	if screen != "game":
		return
	var ids: Array = data.fighters.keys()
	ids.sort_custom(func(a, b): return a == net.local_id and b != net.local_id)
	for i in mini(ids.size(), 2):
		var f: Dictionary = data.fighters[ids[i]]
		health_portraits[i].texture = ArenaPixelUI.portrait_texture(f.character)
		if f.hp < previous_hp.get(ids[i], 100.0):
			sound.play("hit")
		previous_hp[ids[i]] = f.hp
		health_labels[i].text = f.name
		var rounds: int = data.scores.get(ids[i], 0)
		health_character_labels[i].text = "%s  ·  %d %s%s" % [f.character, rounds, "round" if rounds == 1 else "rounds", " · " + {"spear": "Lança", "hammer": "Martelo", "sword": "Espada"}.get(f.get("weapon", ""), "") if f.get("weapon", "") != "" else ""]
		hp_bars[i].value = f.hp
		stamina_bars[i].value = f.stamina
	scenario_label.text = ArenaScenery.scenario_name(data.get("scenario", "garden"))
	timer_label.text = "%02d:%02d\nROUND %d" % [int(maxf(0, data.timer)) / 60, int(maxf(0, data.timer)) % 60, data.round]
	banner_label.text = ""
	if data.phase == "loading":
		banner_label.text = "Carregando…"
	elif data.phase == "countdown":
		banner_label.text = str(int(ceil(data.timer)))
	elif data.phase == "intermission":
		banner_label.text = data.message
	elif data.phase == "result":
		if not is_instance_valid(overlay):
			show_result()
	if data.fighters.has(net.local_id):
		var f: Dictionary = data.fighters[net.local_id]
		var names: Array = ["Parede", "Espinhos"] if f.character == "Edward" else ["Forjar", {"spear": "Lançar lança", "hammer": "Impacto pesado", "sword": "Corte", "": "Impacto"}.get(f.get("weapon", ""), "Impacto")]
		ability_icons[0].texture = ArenaPixelUI.region(Rect2(0 if f.character == "Edward" else 96, 96, 32, 32))
		ability_icons[1].texture = ArenaPixelUI.region(Rect2(32 if f.character == "Edward" else 160, 96, 32, 32))
		for i in 2:
			var key: String = "q" if i == 0 else "e"
			var cooldown: float = f.cooldowns[key]
			ability_labels[i].text = "%s  %s%s" % [key.to_upper(), names[i], " %.1fs" % cooldown if cooldown > 0 else ""]
			ability_labels[i].modulate = Color("9a9e91") if cooldown > 0 else Color.WHITE
		ability_labels[3].text = "F  Jogar" if f.carrying != -1 else "F  Recuperar" if data.get("spears", []).any(func(item): return item.owner == net.local_id) else "F  Caixa"
	if data.phase != last_phase:
		if data.phase in ["fight", "intermission", "result"]:
			sound.play("round")
		if data.phase == "countdown" and is_instance_valid(overlay):
			overlay.queue_free()
			overlay = null
		last_phase = data.phase

func make_overlay(title: String) -> VBoxContainer:
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.06, 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var col := column(panel(overlay, Vector2(260, 126), Vector2(440, 288)), 14)
	var title_node := label(title, 28)
	title_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title_node)
	return col

func show_result() -> void:
	var col := make_overlay(state.get("message", lobby.get("message", "Fim da partida")))
	var result_scores: Dictionary = state.get("scores", {})
	var opponent_score := 0
	for id in result_scores:
		if id != net.local_id:
			opponent_score = result_scores[id]
	col.add_child(label("PLACAR  %d × %d" % [result_scores.get(net.local_id, 0), opponent_score], 24, CYAN))
	var local: Dictionary = lobby.get("members", {}).get(net.local_id, {})
	col.add_child(button("Revanche · aguardando confirmação" if local.get("rematch", false) else "Quero revanche", func(): net.ask_rematch()))
	if not net.training:
		col.add_child(button("Voltar ao lobby", func(): net.back_to_lobby()))
	col.add_child(button("Sair da partida", leave_menu))

func show_game_menu() -> void:
	if is_instance_valid(overlay) or state.get("phase", "") == "result":
		return
	var col := make_overlay("A partida continua")
	col.add_child(label("O menu não pausa o duelo.", 17, MUTED))
	col.add_child(button("Continuar", func(): overlay.queue_free(); overlay = null))
	col.add_child(button("Sair da partida", leave_menu))

func show_options() -> void:
	screen = "options"
	clear_ui()
	veil()
	var col := column(panel(ui, Vector2(230, 28), Vector2(500, 484)), 10)
	col.add_child(label("Opções", 32))
	for item in [["Volume geral", volume, "master"], ["Música", music_volume, "music"], ["Efeitos", effects_volume, "effects"]]:
		col.add_child(label(item[0], 16, MUTED))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = item[1]
		slider.custom_minimum_size.y = 26
		var kind: String = item[2]
		slider.value_changed.connect(func(value):
			if kind == "master":
				volume = value
				AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))
			elif kind == "music":
				music_volume = value
				sound.music_volume = value
				sound.update_music_volume()
			else:
				effects_volume = value
				sound.volume = value
				sound.play("ui")
			save_settings())
		col.add_child(slider)
	var zoom_label := label("Escala da arena: %d%%" % roundi(arena_zoom * 100), 16, MUTED)
	col.add_child(zoom_label)
	var zoom_slider := HSlider.new()
	zoom_slider.min_value = 1.0
	zoom_slider.max_value = 2.0
	zoom_slider.step = 0.25
	zoom_slider.value = arena_zoom
	zoom_slider.custom_minimum_size.y = 26
	zoom_slider.tooltip_text = "Aumenta personagens e cenário; a interface mantém seu tamanho."
	zoom_slider.value_changed.connect(func(value):
		arena_zoom = value
		arena.zoom_factor = value
		zoom_label.text = "Escala da arena: %d%%" % roundi(value * 100)
		save_settings())
	col.add_child(zoom_slider)
	var full := CheckButton.new()
	full.text = "Tela cheia"
	full.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	full.toggled.connect(func(enabled): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	col.add_child(full)
	col.add_child(button("Voltar", show_menu))

func on_error(text: String) -> void:
	connection_busy = false
	notice = text
	if screen == "connect" and is_instance_valid(status_label):
		status_label.text = text
		status_label.add_theme_color_override("font_color", Color("f0a48b"))
	elif screen in ["game", "lobby"]:
		var col := make_overlay("Conexão interrompida")
		var error_label := label(text, 17, MUTED)
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(error_label)
		col.add_child(button("Voltar ao menu", leave_menu))

func leave_menu() -> void:
	net.close_connection()
	state.clear()
	lobby.clear()
	last_phase = ""
	previous_hp.clear()
	show_menu()

func _process(delta: float) -> void:
	if net == null or net.dedicated:
		return
	elapsed += delta
	if screen == "game":
		var active: bool = not is_instance_valid(overlay) and state.get("phase", "") == "fight" and DisplayServer.window_is_focused()
		var move := Input.get_vector("left", "right", "up", "down") if active else Vector2.ZERO
		var aim := Vector2.RIGHT
		if arena.shown.has(net.local_id):
			aim = (arena.screen_to_world(arena.get_global_mouse_position()) - arena.shown[net.local_id]).normalized()
		arena.input_move = move
		arena.input_guard = active and Input.is_action_pressed("guard")
		input_clock += delta
		if input_clock >= 1.0 / 30:
			input_clock = 0
			net.send_input(move, aim, arena.input_guard)
		if not active:
			arena.placing_wall = false
		if active:
			if Input.is_action_just_pressed("q") and state.get("fighters", {}).get(net.local_id, {}).get("character", "") == "Edward":
				arena.placing_wall = not arena.placing_wall
			if arena.placing_wall and Input.is_action_just_pressed("guard"):
				arena.placing_wall = false
			for key in ["attack", "q", "e", "dash", "grab", "interact"]:
				if Input.is_action_just_pressed(key) and (key != "attack" or get_viewport().gui_get_hovered_control() == null):
					if key == "q" and state.get("fighters", {}).get(net.local_id, {}).get("character", "") == "Edward":
						continue
					if key == "attack" and arena.placing_wall:
						if not arena.placement_valid:
							continue
						net.send_action("q", arena.screen_to_world(arena.get_global_mouse_position()))
						sound.play("alchemy")
						arena.placing_wall = false
						continue
					net.send_action(key, arena.screen_to_world(arena.get_global_mouse_position()) if key in ["q", "e"] else Vector2.ZERO)
					sound.play("alchemy" if key in ["q", "e"] else "attack")
		if Input.is_action_just_pressed("menu") and arena.placing_wall:
			arena.placing_wall = false
		elif Input.is_action_just_pressed("menu"):
			if is_instance_valid(overlay) and state.get("phase", "") != "result":
				overlay.queue_free()
				overlay = null
			else:
				show_game_menu()
	if capture_mode == "result" and elapsed > 1 and net.training and net.rooms[net.current_code].phase != "result":
		var demo: ArenaRoom = net.rooms[net.current_code]
		demo.phase = "fight"
		demo.scores[1] = 1
		demo.fighters[-1].hp = 0
		demo.tick(0.02)
		net.broadcast_lobby(demo)
	if not capture_path.is_empty() and elapsed > (4.5 if capture_mode == "arena" else 2.0) and not captured:
		captured = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_path)
		quit_game()

func quit_game() -> void:
	if quitting:
		return
	quitting = true
	set_process(false)
	if sound != null:
		sound.stop_all()
		# Let the audio mixer release its playback references before engine shutdown.
		await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		nickname = str(config.get_value("player", "name", nickname))
		address = str(config.get_value("server", "address", address))
		port = int(config.get_value("server", "port", port))
		volume = float(config.get_value("audio", "volume", volume))
		effects_volume = float(config.get_value("audio", "effects", effects_volume))
		music_volume = float(config.get_value("audio", "music", music_volume))
		arena_zoom = clampf(float(config.get_value("video", "arena_zoom", arena_zoom)), 1.0, 2.0)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "name", nickname)
	config.set_value("server", "address", address)
	config.set_value("server", "port", port)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("video", "arena_zoom", arena_zoom)
	config.save("user://settings.cfg")

func _exit_tree() -> void:
	if local_server_pid > 0 and OS.is_process_running(local_server_pid):
		OS.kill(local_server_pid)
