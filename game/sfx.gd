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
}
const MUSIC_BANK := {
	"menu": "res://assets/audio/music/menu.mp3",
	"dungeon": "res://assets/audio/music/dungeon.mp3",
	"boss": "res://assets/audio/music/boss.mp3",
	"ember": "res://assets/audio/music/ember.mp3",
	"frozen": "res://assets/audio/music/frozen.mp3",
	"verdant": "res://assets/audio/music/verdant.mp3",
}
const MUSIC := MUSIC_BANK["dungeon"] # kompat lama

var pool: Array = []
var music_player: AudioStreamPlayer
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


func play(n: String) -> void:
	if not BANK.has(n):
		return
	var path: String = BANK[n]
	if not ResourceLoader.exists(path):
		return
	for p in pool:
		if not p.playing:
			p.stream = load(path)
			p.volume_db = linear_to_db(maxf(Stats.sfx_vol(), 0.001))
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
	if music_player.playing and current_track == track:
		return
	current_track = track
	music_player.stream = load(path)
	if music_player.stream != null and music_player.stream is AudioStreamMP3:
		music_player.stream.loop = true
	music_player.volume_db = linear_to_db(maxf(Stats.mus_vol() * 0.75, 0.001))
	music_player.play()


func stop_music() -> void:
	music_player.stop()
	current_track = ""


func set_volume(v: float) -> void:
	# kompat: atur dua-duanya bila dipanggil lewat kode lama
	Stats.music_volume = clampf(v, 0.0, 1.0)
	Stats.sfx_volume = clampf(v, 0.0, 1.0)
	set_music_volume(Stats.music_volume)


func set_music_volume(v: float) -> void:
	if music_player.playing:
		music_player.volume_db = linear_to_db(maxf(v * 0.75, 0.001))
