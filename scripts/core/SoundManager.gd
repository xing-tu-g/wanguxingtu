extends Node
## Signal-driven audio manager. Listens to EventBus and plays
## procedural placeholder sounds. Replace _play_tone() with real
## audio samples when assets are available.
##
## Registered as Autoload — available in all scenes.
## Zero _process() polling; entirely event-driven.

const SAMPLE_RATE: int = 44100
const BASE_VOLUME: float = 0.22
const POOL_SIZE: int = 8

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
	_build_pool()
	_connect_signals()


func _build_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SoundPlayer%d" % i
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func _connect_signals() -> void:
	var eb := get_node("/root/EventBus")
	if eb == null:
		return
	eb.unit_attacked.connect(_on_unit_attacked)
	eb.unit_died.connect(_on_unit_died)
	eb.unit_deployed.connect(_on_unit_deployed)
	eb.master_damaged.connect(_on_master_damaged)
	eb.battle_started.connect(_on_battle_started)
	eb.battle_ended.connect(_on_battle_ended)
	eb.side_turn_started.connect(_on_side_turn_started)
	eb.star_power_changed.connect(_on_star_power_changed)

func _on_unit_attacked(_attacker: Dictionary, _target: Dictionary, _damage: int) -> void:
	_play_tone(440.0, 0.12, "square", 0.28)


func _on_unit_died(_unit: Dictionary) -> void:
	_play_tone(220.0, 0.35, "sawtooth", 0.32)
	call_deferred("_play_tone", 174.0, 0.20, "sawtooth", 0.22)


func _on_unit_deployed(_unit: Dictionary, _side: String, _cost: int) -> void:
	_play_tone(523.0, 0.10, "sine", 0.18)
	call_deferred("_play_tone", 659.0, 0.08, "sine", 0.14)


func _on_master_damaged(_side: String, _damage: int, _remaining_hp: int) -> void:
	_play_tone(110.0, 0.40, "sawtooth", 0.35)


func _on_battle_started(_config: Dictionary) -> void:
	_play_tone(262.0, 0.15, "sine", 0.20)
	call_deferred("_play_tone", 330.0, 0.12, "sine", 0.18)
	call_deferred("_play_tone", 392.0, 0.15, "sine", 0.20)


func _on_battle_ended(_victory_side: String, _stats: Dictionary) -> void:
	_play_tone(392.0, 0.18, "sine", 0.24)
	call_deferred("_play_tone", 523.0, 0.14, "sine", 0.20)
	call_deferred("_play_tone", 659.0, 0.22, "sine", 0.26)


func _on_side_turn_started(_side: String, _turn_info: Dictionary) -> void:
	_play_tone(587.0, 0.08, "triangle", 0.14)


func _on_star_power_changed(_side: String, _amount: int) -> void:
	_play_tone(784.0, 0.04, "sine", 0.10)


# ── Procedural tone generation ───────────────────────────────────────

func _play_tone(freq: float, duration: float, waveform: String, volume: float) -> void:
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.02
	player.stream = stream
	player.volume_db = linear_to_db(volume * BASE_VOLUME)

	# Must call play() BEFORE get_stream_playback()
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var samples_to_fill: int = int(duration * SAMPLE_RATE)
	for i in range(samples_to_fill):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = _waveform_sample(freq, t, waveform)
		# Fade out in last 15%
		var fade: float = 1.0
		if t > duration * 0.85 and duration > 0.0:
			fade = 1.0 - (t - duration * 0.85) / (duration * 0.15)
			fade = clampf(fade, 0.0, 1.0)
		playback.push_frame(Vector2(sample * fade, sample * fade))


func _waveform_sample(freq: float, time: float, waveform: String) -> float:
	var raw: float = sin(2.0 * PI * freq * time)
	match waveform:
		"square":
			raw = 1.0 if raw >= 0.0 else -1.0
		"sawtooth":
			raw = 2.0 * fmod(freq * time, 1.0) - 1.0
		"triangle":
			raw = 2.0 * abs(2.0 * fmod(freq * time, 1.0) - 1.0) - 1.0
	return raw
