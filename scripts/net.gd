class_name ArenaNet
extends Node

signal lobby_changed(data: Dictionary)
signal state_received(data: Dictionary)
signal problem(message: String)
signal connection_changed(message: String)
const PROTOCOL := 3
const PORT := 7000
const MAX_ROOMS := 4
var dedicated := false
var training := false
var rooms: Dictionary = {}
var membership: Dictionary = {}
var rates: Dictionary = {}
var snapshot_clock := 0.0
var connection_clock := 0.0
var pending_mode := ""
var pending_code := ""
var nickname := "Jogador"
var local_id := 1
var current_code := ""
var latest_revision := 0

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): problem.emit("Não foi possível conectar. Confira o endereço e a porta."))
	multiplayer.server_disconnected.connect(func():
		current_code = ""
		problem.emit("A conexão com o servidor foi encerrada. Volte e conecte novamente."))

func serve(port: int = PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_ROOMS * 2 + 8)
	if err != OK:
		return err
	multiplayer.server_relay = false
	multiplayer.multiplayer_peer = peer
	dedicated = true
	print("ARENA_SERVER_READY port=%d protocol=%d" % [port, PROTOCOL])
	return OK

func connect_game(address: String, port: int, mode: String, code: String, player_name: String) -> void:
	close_connection()
	pending_mode = mode
	pending_code = code.strip_edges().to_upper()
	nickname = player_name.strip_edges().substr(0, 20)
	if nickname.is_empty():
		nickname = "Jogador"
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		problem.emit("Endereço ou porta inválidos. Corrija e tente novamente.")
		return
	multiplayer.multiplayer_peer = peer
	connection_clock = 8.0
	connection_changed.emit("Conectando ao servidor…")

func _connected() -> void:
	connection_clock = 0
	local_id = multiplayer.get_unique_id()
	connection_changed.emit("Conectado")
	if pending_mode == "create":
		request_create.rpc_id(1, nickname, PROTOCOL)
	else:
		request_join.rpc_id(1, pending_code, nickname, PROTOCOL)

func close_connection() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	training = false
	dedicated = false
	current_code = ""
	latest_revision = 0
	rooms.clear()
	membership.clear()
	rates.clear()
	connection_clock = 0

func train(character: String, scenario: String = "garden") -> void:
	close_connection()
	training = true
	local_id = 1
	var room := ArenaRoom.new()
	room.code = "TREINO"
	room.scenario_override = scenario if scenario in ["garden", "forest"] else "garden"
	room.add_player(1, "Você")
	room.add_player(-1, "Treino · CPU")
	room.bot_id = -1
	room.members[1].character = character
	room.members[-1].character = "Alphonse" if character == "Edward" else "Edward"
	rooms[room.code] = room
	membership[1] = room.code
	room.ready_player(1)
	room.ready_player(-1)
	room.loaded(1)
	current_code = room.code
	lobby_changed.emit(room.lobby_data())
	state_received.emit(room.snapshot())

func _physics_process(delta: float) -> void:
	if connection_clock > 0:
		connection_clock -= delta
		if connection_clock <= 0:
			close_connection()
			problem.emit("O servidor não respondeu em 8 segundos. Confira endereço, porta e se ele está ligado.")
	if not dedicated and not training:
		return
	for room in rooms.values():
		var before: int = room.revision
		room.tick(delta)
		if room.revision != before:
			broadcast_lobby(room)
	snapshot_clock += delta
	if snapshot_clock < 1.0 / 25:
		return
	snapshot_clock -= 1.0 / 25
	for room in rooms.values():
		if training:
			state_received.emit(room.snapshot())
		elif room.phase != "lobby":
			var packet: PackedByteArray = var_to_bytes(room.snapshot()).compress(FileAccess.COMPRESSION_DEFLATE)
			for id in room.members:
				if peer_alive(id):
					receive_state.rpc_id(id, packet)

func valid_request(id: int, interval: float = 0.1, kind: String = "lobby") -> bool:
	if not dedicated or id <= 1:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var peer_rates: Dictionary = rates.get(id, {})
	var last: float = peer_rates.get(kind, -100.0)
	if now - last < interval:
		return false
	peer_rates[kind] = now
	rates[id] = peer_rates
	return true

func peer_alive(id: int) -> bool:
	if id not in multiplayer.get_peers():
		return false
	var peer: ENetMultiplayerPeer = multiplayer.multiplayer_peer
	return peer.get_peer(id).get_state() == ENetPacketPeer.STATE_CONNECTED

func room_for(id: int) -> ArenaRoom:
	return rooms.get(membership.get(id, ""))

func reject(id: int, text: String) -> void:
	receive_error.rpc_id(id, text)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_create(player_name: String, version: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.1, "create"):
		return
	if version != PROTOCOL:
		reject(id, "Versão incompatível. Os dois precisam da mesma versão do jogo.")
		return
	if membership.has(id):
		return
	if rooms.size() >= MAX_ROOMS:
		reject(id, "Servidor cheio. Tente novamente mais tarde.")
		return
	var code := ""
	var letters := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	while code.is_empty() or rooms.has(code):
		code = ""
		for i in 6:
			code += letters[randi() % letters.length()]
	var room := ArenaRoom.new()
	room.code = code
	room.add_player(id, clean_name(player_name))
	rooms[code] = room
	membership[id] = code
	broadcast_lobby(room)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_join(code: String, player_name: String, version: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.1, "join"):
		return
	if version != PROTOCOL:
		reject(id, "Versão incompatível. Atualize o jogo.")
		return
	if membership.has(id):
		return
	code = code.substr(0, 6).to_upper()
	if not rooms.has(code):
		reject(id, "Sala não encontrada. Confira o código com seu amigo.")
		return
	var room: ArenaRoom = rooms[code]
	if room.members.size() >= 2:
		reject(id, "Essa sala já tem dois jogadores.")
		return
	if room.phase != "lobby":
		reject(id, "A partida já começou.")
		return
	room.add_player(id, clean_name(player_name))
	room.message = ""
	membership[id] = code
	broadcast_lobby(room)

func clean_name(value: String) -> String:
	var result := value.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges().substr(0, 20)
	return "Jogador" if result.is_empty() else result

func select_character(character: String) -> void:
	if training:
		return
	request_select.rpc_id(1, character)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_select(character: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.1, "select"):
		return
	var room := room_for(id)
	if room != null:
		room.select(id, character)
		broadcast_lobby(room)

func toggle_ready() -> void:
	request_player_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_player_ready() -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.1, "ready"):
		return
	var room := room_for(id)
	if room != null:
		room.ready_player(id)
		broadcast_lobby(room)

func confirm_loaded() -> void:
	request_loaded.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_loaded() -> void:
	var id := multiplayer.get_remote_sender_id()
	if not dedicated:
		return
	var room := room_for(id)
	if room != null:
		room.loaded(id)
		broadcast_lobby(room)

func send_input(move: Vector2, aim: Vector2, guard: bool) -> void:
	if training:
		rooms[current_code].set_input(1, move, aim, guard)
	elif not current_code.is_empty() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		request_input.rpc_id(1, move, aim, guard)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func request_input(move: Vector2, aim: Vector2, guard: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.008, "input"):
		return
	var room := room_for(id)
	if room != null:
		room.set_input(id, move, aim, guard)

func send_action(key: String, target: Vector2 = Vector2.ZERO) -> void:
	if training:
		rooms[current_code].action(1, key, target)
	elif not current_code.is_empty():
		request_action.rpc_id(1, key, target)

@rpc("any_peer", "call_remote", "reliable", 2)
func request_action(key: String, target: Vector2 = Vector2.ZERO) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.035, "action"):
		return
	var room := room_for(id)
	if room != null:
		room.action(id, key, target)

func ask_rematch() -> void:
	if training:
		var room: ArenaRoom = rooms[current_code]
		room.rematch(1)
		broadcast_lobby(room)
	else:
		request_rematch.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_rematch() -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.1, "rematch"):
		return
	var room := room_for(id)
	if room != null:
		room.rematch(id)
		broadcast_lobby(room)

func back_to_lobby() -> void:
	request_lobby.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 0)
func request_lobby() -> void:
	var id := multiplayer.get_remote_sender_id()
	if not valid_request(id, 0.1, "back"):
		return
	var room := room_for(id)
	if room != null and room.phase == "result":
		room.phase = "lobby"
		room.message = "Escolham os personagens para a próxima partida."
		for member in room.members.values():
			member.ready = false
		room.revision += 1
		broadcast_lobby(room)

func broadcast_lobby(room: ArenaRoom) -> void:
	if training:
		lobby_changed.emit(room.lobby_data())
	else:
		for id in room.members:
			if peer_alive(id):
				receive_lobby.rpc_id(id, room.lobby_data())

@rpc("authority", "call_remote", "reliable", 0)
func receive_lobby(data: Dictionary) -> void:
	current_code = data.code
	latest_revision = int(data.revision)
	lobby_changed.emit(data)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func receive_state(packet: PackedByteArray) -> void:
	if packet.size() > 65536:
		return
	var raw := packet.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() < 4:
		return
	var decoded: Variant = bytes_to_var(raw)
	if not decoded is Dictionary:
		return
	var data: Dictionary = decoded
	if data.get("code", "") == current_code and int(data.get("revision", 0)) >= latest_revision:
		state_received.emit(data)

@rpc("authority", "call_remote", "reliable", 0)
func receive_error(text: String) -> void:
	problem.emit(text)

func _peer_left(id: int) -> void:
	if not dedicated:
		return
	var room := room_for(id)
	membership.erase(id)
	rates.erase(id)
	if room == null:
		return
	room.remove_player(id)
	if room.members.is_empty():
		rooms.erase(room.code)
	else:
		broadcast_lobby(room)
