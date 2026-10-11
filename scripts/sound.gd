class_name ArenaSound
extends Node
var enabled := true
var volume := 0.45
var players: Array[AudioStreamPlayer] = []
var tone_cache: Dictionary = {}
var clock := 0.0

func _ready() -> void:
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func play(kind: String) -> void:
	if not enabled or volume <= 0:
		return
	var frequencies := {"ui": 440.0, "ready": 660.0, "attack": 125.0, "alchemy": 880.0, "hit": 90.0, "round": 523.25}
	if not tone_cache.has(kind):
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var duration := 0.16 if kind != "round" else 0.45
		var buffer := PackedByteArray()
		buffer.resize(int(duration * 22050) * 2)
		var frequency: float = frequencies.get(kind, 440.0)
		for i in int(duration * 22050):
			var t := float(i) / 22050
			var envelope := pow(1 - t / duration, 2) * minf(1, t * 200)
			var sample := sin(TAU * frequency * t * (1 - t * 0.5)) * 0.2
			if kind in ["attack", "hit"]:
				sample += sin(i * 73.321) * 0.12
			buffer.encode_s16(i * 2, int(clampf(sample * envelope, -1, 1) * 32767))
		stream.data = buffer
		tone_cache[kind] = stream
	for player in players:
		if not player.playing:
			player.stream = tone_cache[kind]
			player.volume_db = linear_to_db(volume)
			player.play()
			return

var music_player: AudioStreamPlayer
var music_volume := 0.18
var music_scene := ""
var music_cache: Dictionary = {}

func set_scene(scene: String) -> void:
	if music_scene == scene:
		return
	music_scene = scene
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
	if not music_cache.has(scene):
		# Original small synthesized loop; no soundtrack or sample from the anime.
		var notes: Array = [50, 57, 62, 65, 64, 62, 57, 53, 50, 57, 60, 64, 62, 57, 53, 57] if scene == "menu" else [50, 50, 57, 62, 50, 53, 57, 60, 48, 48, 55, 60, 53, 57, 60, 65]
		var beat := 0.4 if scene == "menu" else 0.3
		var duration: float = beat * notes.size()
		var length := int(duration * 22050)
		var data := PackedByteArray()
		data.resize(length * 2)
		for i in length:
			var t := float(i) / 22050
			var note_index := mini(notes.size() - 1, int(t / beat))
			var nt := fmod(t, beat)
			var freq := 440.0 * pow(2, (notes[note_index] - 69) / 12.0)
			var env := sin(PI * nt / beat) * exp(-nt * 3)
			var bass := sin(TAU * freq * 0.5 * t) * 0.15
			var melody := (sin(TAU * freq * t) + sin(TAU * freq * 2 * t) * 0.2) * env * 0.14
			var drum := sin(TAU * (80 - nt * 150) * nt) * exp(-nt * 35) * (0.12 if scene == "battle" else 0.025)
			data.encode_s16(i * 2, int((bass + melody + drum) * 32767))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = data
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = length
		music_cache[scene] = stream
	music_player.stop()
	music_player.stream = music_cache[scene]
	update_music_volume()
	music_player.play()

func update_music_volume() -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(maxf(0.0001, music_volume))

func stop_all() -> void:
	for player in players:
		player.stop()
		player.stream = null
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	tone_cache.clear()
	music_cache.clear()

func _exit_tree() -> void:
	stop_all()
