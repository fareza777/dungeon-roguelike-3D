extends Node
# Autoload "Sfx": bank SFX + bank musik, volume terpisah.
# File yang belum ada di-skip dengan aman.

const BANK := {
	"swing": "res://assets/audio/sfx/swing.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"levelup": "res://assets/audio/sfx/levelup.wav",
	"click": "res://assets/audio/sfx/click.wav",
	"door": "res://assets/audio/sfx/door.wav",
	"hurt": "res://assets/audio/sfx/hurt.wav",
	"pickup": "res://assets/audio/sfx/pickup.wav",
	"dash": "res://assets/audio/sfx/dash.wav",
	"whirl": "res://assets/audio/sfx/whirl.wav",
	"thunder": "res://assets/audio/sfx/thunder.wav",
	"xp": "res://assets/audio/sfx/xp.wav",
	"chest": "res://assets/audio/sfx/chest.wav",
	"gate": "res://assets/audio/sfx/gate.wav",
	"deny": "res://assets/audio/sfx/deny.wav",
	"quest": "res://assets/audio/sfx/quest.mp3",
	"page": "res://assets/audio/sfx/page.mp3",
	"shrine": "res://assets/audio/sfx/shrine.mp3",
	"trap": "res://assets/audio/sfx/trap.mp3",
	"roar": "res://assets/audio/sfx/roar.mp3",
	"victory": "res://assets/audio/sfx/victory.mp3",
	"combo": "res://assets/audio/sfx/combo.mp3",
	"mimic": "res://assets/audio/sfx/mimic.mp3",
	"level": "res://assets/audio/sfx/levelup.wav",
	"soul": "res://assets/audio/sfx/xp.wav",
	"souls": "res://assets/audio/sfx/xp.wav",
	"relic": "res://assets/audio/sfx/shrine.mp3",
	"reliquary": "res://assets/audio/sfx/shrine.mp3",
	"slam": "res://assets/audio/sfx/thunder.wav",
	"bigslash": "res://assets/audio/sfx/swing.wav",
	"heal": "res://assets/audio/sfx/shrine.mp3",
	"whisper": "res://assets/audio/sfx/page.mp3",
	"hook": "res://assets/audio/sfx/hit.wav",
	"swoosh": "res://assets/audio/sfx/swing.wav",
	"armor": "res://assets/audio/sfx/hit.wav",
	"crit": "res://assets/audio/sfx/hit.wav",
	"fire": "res://assets/audio/sfx/thunder.wav",
	"bell": "res://assets/audio/sfx/quest.mp3",
	"hit2": "res://assets/audio/sfx/hit.wav",
}
const MUSIC_BANK := {
	"menu": "res://assets/audio/music/menu.mp3",
	"dungeon": "res://assets/audio/music/dungeon.mp3",
	"boss": "res://assets/audio/music/boss.mp3",
	"ember": "res://assets/audio/music/ember.mp3",
	"frozen": "res://assets/audio/music/frozen.mp3",
	"verdant": "res://assets/audio/music/verdant.mp3",
	"reliquary": "res://assets/audio/music/reliquary.mp3",
	"marsh": "res://assets/audio/music/marsh.mp3",
}
const MUSIC := MUSIC_BANK["dungeon"] # kompat lama

var pool: Array = []
var music_player: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var music_active: AudioStreamPlayer
var volume := 0.8 # legacy getter lama — jangan dipakai lagi
var last_played := ""
var current_track := ""
var _mus_tw: Tween = null


func _ready() -> void:
	for i in range(12):
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player_b = AudioStreamPlayer.new()
	add_child(music_player_b)
	music_active = music_player


func play(n: String, pitch := 1.0) -> void:
	if not BANK.has(n):
		return
	var path: String = BANK[n]
	if not ResourceLoader.exists(path):
		return
	for p in pool:
		if not p.playing:
			p.stream = load(path)
			p.volume_db = linear_to_db(maxf(Stats.sfx_vol(), 0.001))
			p.pitch_scale = pitch
			p.play()
			last_played = n
			return


func any_playing() -> bool:
	for p in pool:
		if p.playing:
			return true
	return false


func play_music(track := "dungeon") -> void:
	var path: String = MUSIC_BANK.get(track, MUSIC)
	if not ResourceLoader.exists(path):
		return
	if music_active != null and music_active.playing and current_track == track:
		return
	current_track = track
	var nxt: AudioStreamPlayer = music_player_b if music_active == music_player else music_player
	var old: AudioStreamPlayer = music_active
	nxt.stream = load(path)
	if nxt.stream != null and nxt.stream is AudioStreamMP3:
		nxt.stream.loop = true
	nxt.volume_db = -60.0
	nxt.play()
	var vt: float = linear_to_db(maxf(Stats.mus_vol() * 0.75, 0.001))
	_mus_tw = nxt.create_tween()
	_mus_tw.tween_property(nxt, "volume_db", vt, 1.2)
	if old != null and old.playing:
		var otw: Tween = old.create_tween()
		otw.tween_property(old, "volume_db", -60.0, 1.0)
		otw.tween_callback(old.stop)
	music_active = nxt


func stop_music() -> void:
	if music_active != null and music_active.playing:
		var stw: Tween = music_active.create_tween()
		stw.tween_property(music_active, "volume_db", -60.0, 0.6)
		stw.tween_callback(music_active.stop)
	current_track = ""
	music_active = music_player


func set_volume(v: float) -> void:
	# kompat: atur dua-duanya bila dipanggil lewat kode lama
	Stats.music_volume = clampf(v, 0.0, 1.0)
	Stats.sfx_volume = clampf(v, 0.0, 1.0)
	set_music_volume(Stats.music_volume)


func set_music_volume(v: float) -> void:
	if music_active != null and music_active.playing:
		music_active.volume_db = linear_to_db(maxf(v * 0.75, 0.001))
