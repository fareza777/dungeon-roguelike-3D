extends Node
# Autoload "Stats": sheet stat run, XP/level, relic, senjata, snapshot run,
# pengaturan (musik/sfx/kualitas), flag onboarding, dan save user://save.json.

signal xp_changed(cur, need, level)
signal leveled_up(level)
signal relics_changed
signal weapon_changed

const ITEMS = preload("res://items_db.gd")
const WDB = preload("res://weapons_db.gd")
const SAVE_PATH := "user://save.json"
const VERSION := "1.0.0"
const STORE_ID := "com.kimi.dungeonslice"

var floor_num := 1
var level := 1
var xp := 0
var relics: Array = []
var kills := 0
var current_hp := 5.0
var weapon_id := "rusty_blade"
var owned_weapons: Array = ["rusty_blade"]
var draft_open := false

# buff sementara (hilang saat run reset / turun lantai sesuai flag)
var buff_atk_pct := 0.0 # berkat altar: run ini saja
var buff_armor := 0 # berkat altar: armor datar run ini
var revive_left := 0 # jiwa bangkit: hidup lagi sekali per run
var ach := {} # prestasi terbuka: id -> true (persist lintas run)
var thorns := 0.0 # duri pantulan: balikkan dmg
var dodge := 0.0 # fase hantu: peluang bebas damage
var magnet := 0.0 # magnet jiwa: perbesar radius serap orb
var berserk := 0.0 # amukan: bonus ATK saat HP kritis

# meta (tersimpan)
var best_floor := 0
var total_kills := 0
var runs := 0
var boss_kills := 0
var tutorial_done := false
var seen_cinematic := false
var onboarded := false
var rated := false
var quality := -1 # -1 auto, 0 hemat, 1 indah
var volume := 0.8 # legacy: dipakai kalau music/sfx belum pernah diset
var music_volume := -1.0
var sfx_volume := -1.0
var saved_run := {}

# dipakai menu -> game
var pending_restore := false

var base := {"max_hp": 5.0, "atk": 1.0, "speed": 1.0, "crit": 0.05, "lifesteal": 0.0, "atk_speed": 1.0, "armor": 0.0}


func get_stat(n: String) -> float:
	var flat: float = base.get(n, 0.0)
	var mult := 1.0
	for r in relics:
		var mods: Dictionary = ITEMS.DB[r]["mods"]
		if mods.has(n):
			flat += mods[n]
		if mods.has(n + "_pct"):
			mult += mods[n + "_pct"]
	var wmods: Dictionary = WDB.get_w(weapon_id)["mods"]
	if wmods.has(n):
		flat += wmods[n]
	if wmods.has(n + "_pct"):
		mult += wmods[n + "_pct"]
	if n == "atk":
		mult += buff_atk_pct
		# amukan: +ATK saat HP di bawah 35%
		if berserk > 0.0 and current_hp <= get_stat("max_hp") * 0.35:
			mult += berserk
	if n == "armor":
		flat += buff_armor
	return flat * mult


func mus_vol() -> float:
	return volume if music_volume < 0.0 else music_volume


func sfx_vol() -> float:
	return volume if sfx_volume < 0.0 else sfx_volume


func xp_need() -> int:
	return 3 + level * 2


func add_xp(n: int) -> void:
	xp += n
	while xp >= xp_need():
		xp -= xp_need()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_need(), level)


func add_relic(id: String) -> void:
	relics.append(id)
	var mods: Dictionary = ITEMS.DB[id]["mods"]
	if mods.has("revive"):
		revive_left += int(mods["revive"])
	if mods.has("thorns"):
		thorns += float(mods["thorns"])
	if mods.has("dodge"):
		dodge += float(mods["dodge"])
	if mods.has("magnet"):
		magnet += float(mods["magnet"])
	if mods.has("berserk"):
		berserk += float(mods["berserk"])
	relics_changed.emit()


func equip_weapon(id: String) -> void:
	weapon_id = id
	if not owned_weapons.has(id):
		owned_weapons.append(id)
	weapon_changed.emit()


func count_kill() -> void:
	kills += 1
	total_kills += 1


func reset_run() -> void:
	floor_num = 1
	level = 1
	xp = 0
	relics.clear()
	kills = 0
	weapon_id = "rusty_blade"
	owned_weapons = ["rusty_blade"]
	buff_atk_pct = 0.0
	buff_armor = 0
	revive_left = 0
	thorns = 0.0
	dodge = 0.0
	magnet = 0.0
	berserk = 0.0
	current_hp = get_stat("max_hp")
	draft_open = false
	saved_run = {}
	relics_changed.emit()
	weapon_changed.emit()
	xp_changed.emit(0, xp_need(), 1)


func register_kill(xp_val: int) -> void:
	kills += 1
	total_kills += 1
	add_xp(xp_val)


func note_floor() -> void:
	if floor_num > best_floor:
		best_floor = floor_num
	save_game()


# snapshot run supaya tombol "Lanjutkan" di menu berarti
func save_run() -> void:
	saved_run = {"floor": floor_num, "level": level, "xp": xp, "relics": relics.duplicate(), "weapon_id": weapon_id, "owned": owned_weapons.duplicate(), "hp": current_hp, "kills": kills, "revive": revive_left, "thorns": thorns, "dodge": dodge, "magnet": magnet, "berserk": berserk}
	save_game()


func has_run() -> bool:
	return not saved_run.is_empty()


func clear_run() -> void:
	saved_run = {}
	save_game()


func restore_run() -> bool:
	if saved_run.is_empty():
		return false
	floor_num = int(saved_run.get("floor", 1))
	level = int(saved_run.get("level", 1))
	xp = int(saved_run.get("xp", 0))
	relics = saved_run.get("relics", [])
	weapon_id = saved_run.get("weapon_id", "rusty_blade")
	var ow = saved_run.get("owned", [])
	owned_weapons = ow if ow is Array and not ow.is_empty() else [weapon_id]
	kills = int(saved_run.get("kills", 0))
	revive_left = int(saved_run.get("revive", 0))
	thorns = float(saved_run.get("thorns", 0.0))
	dodge = float(saved_run.get("dodge", 0.0))
	magnet = float(saved_run.get("magnet", 0.0))
	berserk = float(saved_run.get("berserk", 0.0))
	buff_atk_pct = 0.0
	current_hp = float(saved_run.get("hp", get_stat("max_hp")))
	draft_open = false
	relics_changed.emit()
	weapon_changed.emit()
	xp_changed.emit(xp, xp_need(), level)
	return true


func wipe_progress() -> void:
	best_floor = 0
	total_kills = 0
	runs = 0
	boss_kills = 0
	tutorial_done = false
	onboarded = false
	rated = false
	saved_run = {}
	reset_run()
	save_game()


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"best_floor": best_floor, "total_kills": total_kills, "runs": runs,
			"boss_kills": boss_kills,
			"tutorial_done": tutorial_done, "seen_cinematic": seen_cinematic,
			"onboarded": onboarded, "rated": rated,
			"quality": quality, "volume": volume,
			"music_volume": music_volume, "sfx_volume": sfx_volume,
			"run": saved_run,
			"ach": ach,
		}))


func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if d is Dictionary:
			best_floor = int(d.get("best_floor", 0))
			total_kills = int(d.get("total_kills", 0))
			runs = int(d.get("runs", 0))
			boss_kills = int(d.get("boss_kills", 0))
			tutorial_done = d.get("tutorial_done", false)
			seen_cinematic = d.get("seen_cinematic", false)
			onboarded = d.get("onboarded", false)
			rated = d.get("rated", false)
			quality = int(d.get("quality", -1))
			volume = float(d.get("volume", 0.8))
			music_volume = float(d.get("music_volume", -1.0))
			sfx_volume = float(d.get("sfx_volume", -1.0))
			var r = d.get("run", {})
			if r is Dictionary:
				saved_run = r
			var a2 = d.get("ach", {})
			if a2 is Dictionary:
				ach = a2
