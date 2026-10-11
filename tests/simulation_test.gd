extends SceneTree
var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func new_match() -> ArenaRoom:
	var r := ArenaRoom.new()
	r.code = "TEST01"
	r.add_player(10, "Edward")
	r.add_player(20, "Alphonse")
	r.select(20, "Alphonse")
	r.ready_player(10)
	r.ready_player(20)
	r.loaded(10)
	r.loaded(20)
	r.tick(3.01)
	return r

func _initialize() -> void:
	var r := new_match()
	check(r.phase == "fight" and r.members.size() == 2, "Dois Ready e dois Loaded iniciam combate")
	r.fighters[10].pos = Vector2(950, 768)
	r.fighters[20].pos = Vector2(999, 768)
	r.set_input(10, Vector2.ZERO, Vector2.RIGHT, false)
	r.set_input(20, Vector2.ZERO, Vector2.LEFT, false)
	r.action(10, "attack")
	check(r.fighters[20].hp == 89, "Ataque de Edward causa dano")
	r.action(10, "attack")
	check(r.fighters[20].hp == 89, "Recarga impede repetição imediata")
	r = new_match()
	r.fighters[10].pos = Vector2(950, 768)
	r.fighters[20].pos = Vector2(995, 768)
	r.set_input(20, Vector2.ZERO, Vector2.LEFT, true)
	r.action(10, "attack")
	check(r.fighters[20].hp > 89 and r.fighters[20].stamina < 100, "Defesa frontal reduz dano e gasta resistência")
	r.fighters[10].state_time = 0
	r.fighters[20].pos = Vector2(995, 768)
	r.action(10, "grab")
	check(r.fighters[20].state == "hurt", "Agarrão supera defesa")
	r = new_match()
	r.set_input(10, Vector2.RIGHT, Vector2.RIGHT, false)
	r.action(10, "dash")
	var hp: float = r.fighters[10].hp
	r.damage(10, 10, Vector2(850, 768), 0)
	check(r.fighters[10].hp == hp and r.fighters[10].stamina == 75, "Esquiva consome resistência e evita golpe na janela")
	r = new_match()
	r.fighters[10].pos = Vector2(950, 768)
	r.action(10, "q")
	check(r.walls.size() == 1, "Edward cria parede")
	var wall: Rect2 = r.walls[0].rect
	r.fighters[10].pos = wall.get_center() - Vector2(35, 0)
	r.move_fighter(r.fighters[10], Vector2(150, 0))
	check(r.fighters[10].pos.x < wall.position.x, "Movimento não atravessa parede mesmo com deslocamento grande")
	r.walls[0].hp = 0
	r.tick(0.02)
	check(r.walls.is_empty(), "Parede destruída sai da colisão")
	r = new_match()
	var box: Dictionary = r.boxes[0]
	r.fighters[10].pos = box.pos - Vector2(40, 0)
	r.action(10, "interact")
	check(r.fighters[10].carrying == box.id and box.owner == 10, "Caixa tem um único portador")
	r.tick(0.31)
	r.action(10, "interact")
	check(r.fighters[10].carrying == -1 and box.vel.length() > 0, "Arremesso libera caixa e inicia trajetória")
	r.fighters[20].pos = box.pos + Vector2(45, 0)
	r.tick(0.1)
	check(r.fighters[20].hp == 80 and not r.boxes.has(box), "Caixa arremessada atinge jogador e quebra")
	r = new_match()
	r.fighters[10].pos = Vector2(950, 768)
	r.fighters[20].pos = Vector2(1100, 768)
	r.action(10, "e")
	check(r.fighters[20].hp == 100 and r.effects[0].pending, "Espinhos avisam antes do dano")
	r.tick(0.4)
	check(r.fighters[20].hp == 78, "Espinhos causam dano depois da preparação")
	r = new_match()
	r.fighters[10].pos = Vector2(950, 768)
	r.fighters[20].pos = Vector2(1000, 768)
	r.fighters[20].aim = Vector2.LEFT
	r.action(20, "e")
	r.tick(0.4)
	check(r.fighters[10].hp == 78, "Impacto de Alphonse funciona")
	r = new_match()
	r.fighters[10].pos = Vector2(950, 768)
	r.fighters[20].pos = Vector2(1100, 768)
	r.set_input(20, Vector2.ZERO, Vector2.LEFT, false)
	r.action(20, "q")
	check(r.fighters[10].hp == 100, "Investida não causa dano antes do contato")
	for i in 20:
		r.tick(1.0 / 60)
	check(r.fighters[10].hp == 83 and r.fighters[20].get("charge_hit", false), "Investida acerta durante o movimento uma única vez")
	r = new_match()
	r.fighters[20].hp = 0
	r.tick(0.02)
	check(r.scores[10] == 1 and r.phase == "intermission", "Primeiro KO soma round")
	r.tick(3.1)
	check(r.fighters[20].hp == 100 and r.boxes.size() == 6 and r.walls.is_empty(), "Novo round reinicia vida e cenário")
	r.tick(3.1)
	r.fighters[20].hp = 0
	r.tick(0.02)
	check(r.phase == "result" and r.scores[10] == 2, "Partida termina em 2–0")
	r.rematch(10)
	r.rematch(20)
	check(r.phase == "countdown" and r.scores[10] == 0, "Revanche exige os dois e reinicia placar")
	r = new_match()
	r.timer = 0.01
	r.tick(0.02)
	check(r.phase == "intermission" and r.scores[10] == 0 and r.scores[20] == 0, "Empate no tempo não concede ponto")
	r = new_match()
	r.set_input(10, Vector2(999, 999), Vector2.RIGHT, false)
	check(r.inputs[10].move.length() <= 1.001, "Servidor limita magnitude do movimento")
	r.set_input(10, Vector2(INF, 0), Vector2.RIGHT, false)
	check(r.inputs[10].move.is_finite(), "Servidor rejeita coordenadas inválidas")
	r = new_match()
	r.remove_player(20)
	check(r.phase == "lobby" and not r.members[10].ready, "Desconexão volta ao lobby e cancela Ready")
	r = new_match()
	r.set_input(10, Vector2.RIGHT, Vector2.RIGHT, false)
	r.tick(0.5)
	check(r.inputs[10].move == Vector2.ZERO, "Comando expirado não move jogador indefinidamente")
	r = new_match()
	r.fighters[20].hp = 0
	r.tick(0.02)
	r.tick(3.1)
	r.tick(3.1)
	r.fighters[10].hp = 0
	r.tick(0.02)
	r.tick(3.1)
	r.tick(3.1)
	r.fighters[20].hp = 0
	r.tick(0.02)
	check(r.phase == "result" and r.scores[10] == 2 and r.scores[20] == 1, "Partida termina em 2–1 após três rounds")
	r = new_match()
	r.fighters[20].hp = 70
	r.timer = 0.01
	r.tick(0.02)
	check(r.scores[10] == 1, "Maior vida vence quando acaba o tempo")
	r = new_match()
	r.fighters[10].pos = Vector2(780, 700)
	r.fighters[10].aim = Vector2.UP
	var stamina_before: float = r.fighters[10].stamina
	r.action(10, "q")
	check(r.walls.is_empty() and r.fighters[10].stamina == stamina_before, "Parede em obstáculo é rejeitada e devolve custo")
	r = new_match()
	r.fighters[10].pos = Vector2(950, 768)
	r.action(10, "q")
	r.tick(7.1)
	check(r.walls.is_empty(), "Parede temporária desaparece ao terminar duração")
	r = new_match()
	r.members[20].character = "Edward"
	r.reset_round()
	check(r.fighters[20].character == "Edward" and r.fighters[10].character == "Edward", "Duelo com dois Edwards é permitido")
	var raw := var_to_bytes(r.snapshot())
	var packet := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var decoded: Variant = bytes_to_var(packet.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE))
	check(decoded is Dictionary and decoded.fighters.size() == 2 and packet.size() < 1200, "Snapshot comprimido preserva estado e cabe no pacote alvo")
	print("SIMULATION_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
