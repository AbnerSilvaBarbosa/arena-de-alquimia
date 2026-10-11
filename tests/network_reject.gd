extends SceneTree
var net: ArenaNet
var expected := "full"
var code_path := ""
var port := 17007
var elapsed := 0.0
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expect="): expected = arg.trim_prefix("--expect=")
		if arg.begins_with("--code-file="): code_path = arg.trim_prefix("--code-file=")
		if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	net = ArenaNet.new()
	net.name = "Net"
	main.add_child(net)
	call_deferred("connect_peer")
func connect_peer() -> void:
	net.multiplayer.connected_to_server.disconnect(net._connected)
	net.multiplayer.connected_to_server.connect(on_connected)
	net.problem.connect(on_problem)
	net.connect_game("127.0.0.1", port, "join", "", "Teste rejeição")
func on_connected() -> void:
	net.connection_clock = 0
	if expected == "version":
		net.request_create.rpc_id(1, "Versão errada", 999)
	elif expected == "missing":
		net.request_join.rpc_id(1, "!!!!!!", "Código errado", ArenaNet.PROTOCOL)
	else:
		net.request_join.rpc_id(1, FileAccess.get_file_as_string(code_path), "Terceiro jogador", ArenaNet.PROTOCOL)
func on_problem(message: String) -> void:
	var matched: bool = (expected == "full" and "dois jogadores" in message) or (expected == "missing" and "não encontrada" in message) or (expected == "version" and "incompatível" in message)
	if matched:
		print("REJECTION_PASS " + expected)
		quit()
	else:
		push_error("Unexpected rejection: " + message)
		quit(1)
func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 8:
		push_error("Rejection timeout: " + expected)
		quit(1)
	return false
