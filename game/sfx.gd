extends Node
# Autoload "Sfx": bank SFX + musik. Kalau file audio belum ada, diam saja (aman).

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
}
const MUSIC := "res://assets/audio/music/dungeon.mp3"

var pool: Array = []
var music_player: AudioStreamPlayer
var volume := 0.8
var last_played := ""


func _ready() -> void:
	for i in range(10):
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
			p.volume_db = linear_to_db(maxf(volume, 0.001))
			p.play()
			last_played = n
			return


func any_playing() -> bool:
	for p in pool:
		if p.playing:
			return true
	return false


func play_music() -> void:
	if not ResourceLoader.exists(MUSIC):
		return
	if music_player.playing:
		return
	music_player.stream = load(MUSIC)
	if music_player.stream != null and music_player.stream is AudioStreamMP3:
		music_player.stream.loop = true
	music_player.volume_db = linear_to_db(maxf(volume * 0.75, 0.001))
	music_player.play()


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	if music_player.playing:
		music_player.volume_db = linear_to_db(maxf(volume * 0.75, 0.001))
