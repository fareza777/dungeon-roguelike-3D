extends Node3D
# Orchestrator roguelike v5: lantai multi-ruangan + gerbang portcullis, skill
# aktif, draft relic, biome, tutorial, layar hero — plus rantai quest berurutan
# per lantai, dialog karakter berpotret, lantai BOSS tiap kelipatan 5 (Raja
# Tulang: enrage + slam + summon), jebakan duri, altar arwah, peti mimic,
# kombo kill, minimap, dan musik adaptif (dungeon/boss).

const CHARS := "res://assets/characters/"
const M = preload("res://materials.gd")
const RG = preload("res://room_gen.gd")
const EDB = preload("res://enemies_db.gd")
const BIO = preload("res://biomes_db.gd")
const ITEMS = preload("res://items_db.gd")
const WDB = preload("res://weapons_db.gd")
const WPICK = preload("res://weapon_pickup.gd")
const GATE = preload("res://gate.gd")
const GEM = preload("res://xp_gem.gd")
const SK = preload("res://skills_db.gd")
const QDB = preload("res://quests_db.gd")
const DLG = preload("res://dialogue.gd")
const TRAP = preload("res://trap.gd")
const SHRINE = preload("res://shrine.gd")
const DUNGEON := "res://assets/dungeon/"

var dungeon_tex: Texture2D
var skeleton_tex: Texture2D

var room: Node3D = null
var info := {}
var biome := {}
var player = null
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var joystick
var ui := {}
var trauma := 0.0
var run_state := "playing"
var seed_val := 7
var autotest := false
var rng := RandomNumberGenerator.new()
var pending_drafts := 0
var draft_choices: Array = []
var low_quality := false
var chest_opened := false
var toast_tween: Tween = null

# polish r2: pause, ringkasan run, transisi fade, juice vfx
var paused_ui := false
var kills_run := 0
var run_time := 0.0
var fade_rect: ColorRect = null
var pause_panel: PanelContainer = null
var vign: TextureRect = null
var vign_tween: Tween = null
var prev_hp := -1.0

# prestasi lintas run + varian bos per 5 lantai
const ACH := {
	"kill1": "Pembantaian Pertama",
	"k50": "Algojo Lorong (50 kill)",
	"k200": "Penghuni Kubur (200 kill)",
	"f5": "Penurun Nekara (Lantai 5)",
	"f10": "Tanpa Takut (Lantai 10)",
	"f20": "Jantung Kedalaman (Lantai 20)",
	"b1": "Pemecah Singgasana",
	"b3": "Pemburu Raja (3 bos)",
	"r5": "Kolektor Relik (5 relik)",
	"w5": "Gudang Senjata (5 senjata)",
}
const BOSS_TIERS := [
	{"name": "RAJA TULANG", "tint": Color(1.05, 1.05, 1.05)},
	{"name": "RAJA BARA", "tint": Color(1.4, 0.65, 0.4)},
	{"name": "RAJA BEKU", "tint": Color(0.55, 0.85, 1.45)},
	{"name": "RAJA LIAR", "tint": Color(0.65, 1.35, 0.55)},
]
var boss_name := "RAJA TULANG"
var atk_held := false
var tip_l: Label = null

const TIPS := [
	"Elite berpendar merah memberi XP ganda.",
	"Peti bermata merah itu mimic — waspada.",
	"Dash memberi kekebalan sesaat.",
	"Jeda combo memutus streak — tebas terus.",
	"Altar arwah: pilih berkat sesuai gaya mainmu.",
	"Duri lantai punya irama — pelajari sebelum lewat.",
	"Raja yang marah memanggil antek — jaga jarak.",
	"Relik Jiwa Bangkit menghidupkanmu sekali.",
]


func _boss_tier() -> Dictionary:
	return BOSS_TIERS[(Stats.floor_num / 5 - 1) % BOSS_TIERS.size()]


func _ach(id: String) -> void:
	if Stats.ach.get(id, false):
		return
	Stats.ach[id] = true
	Stats.save_game()
	_lvl_banner("◆ PENCAPAIAN — " + String(ACH[id]))
	Sfx.play("quest")

# v5: boss + quest + kombo + altar + peti mimic + dialog + minimap
var boss_ref = null
var quest_steps: Array = []
var quest_idx := 0
var combo := 0
var combo_t := 0.0
var mimic_pending := false
var shrine_used := false
var dlg: DialogueUI = null
var dlg_pending_choice := -1
var map_dots: Array = []
var map_t := 0.0

# gerbang / ruangan
var gates := {}
var current_room := -1

# skill
var skill_cd := {"dash": 0.0, "whirl": 0.0, "thunder": 0.0}
var skill_ui := {}

# tutorial
var tut_active := false
var tut_step := 0
var moved_accum := 0.0
var tut_last_pos := Vector3.ZERO
var quest_moved := 0.0
var quest_last_p := Vector3.ZERO
var shrine_ref = null


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
		elif a.begins_with("--seed="):
			seed_val = int(a.trim_prefix("--seed="))
	rng.seed = seed_val * 7919 + 13
	dungeon_tex = load(DUNGEON + "dungeon_texture.png")
	skeleton_tex = load(CHARS + "skeleton_texture.png")
	Sfx.set_volume(Stats.volume)
	_setup_world()
	_apply_quality()
	_build_ui()
	if Stats.pending_restore and Stats.restore_run():
		print("LANJUTKAN run lantai=", Stats.floor_num)
	else:
		Stats.reset_run()
		kills_run = 0
		run_time = 0.0
	Stats.pending_restore = false
	Stats.runs += 1
	Stats.save_game()
	Stats.xp_changed.connect(_update_xp)
	Stats.leveled_up.connect(_on_leveled_up)
	Stats.relics_changed.connect(_rebuild_chips)
	_new_run(seed_val)
	_fade_to(0.0, 0.6)
	if autotest:
		_run_autotest()


# ---------------- world ----------------

func _setup_world() -> void:
	sun = DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.shadow_enabled = true

	var we := WorldEnvironment.new()
	env = Environment.new()
	we.environment = env
	add_child(we)
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.1
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.07

	cam = Camera3D.new()
	add_child(cam)
	cam.fov = 42.0
	cam.current = true
	cam.position = Vector3(6, 12, 10)


func _apply_quality() -> void:
	var q := Stats.quality
	if q == -1:
		q = 0 if OS.has_feature("android") else 1
	low_quality = q == 0
	sun.shadow_enabled = not low_quality
	env.glow_enabled = not low_quality
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low_quality else Viewport.MSAA_2X
	get_viewport().scaling_3d_scale = 0.85 if low_quality else 1.0
	print("KUALITAS=", "hemat" if low_quality else "indah")


func _apply_biome() -> void:
	env.background_color = biome["bg"]
	env.fog_density = biome["fog_d"]
	env.fog_light_color = biome["fog"]
	env.ambient_light_color = biome["ambient"]
	sun.light_color = biome["sun"]
	sun.light_energy = 0.9


func _style_room() -> void:
	var floor_mat := M.toon(dungeon_tex, biome["floor"], 0.15)
	var wall_mat := M.toon(dungeon_tex, biome["wall"], 0.2)
	var prop_mat := M.toon(dungeon_tex, biome["prop"], 0.2)
	var gold_mat := M.toon(dungeon_tex, Color(1.1, 1.0, 0.75), 0.4)
	for n in info.floors:
		M.paint(n, floor_mat)
	for n in info.walls:
		M.paint(n, wall_mat)
	for n in info.props:
		M.paint(n, prop_mat)
	if info.chest != null:
		M.paint(info.chest, gold_mat)
	for t in info.torches:
		M.paint(t, prop_mat)
		var omni := OmniLight3D.new()
		room.add_child(omni)
		omni.global_position = t.global_position + Vector3(0.0, 0.4, 0.4)
		omni.light_color = biome["torch"]
		omni.light_energy = biome.get("torch_e", 1.4)
		omni.omni_range = biome.get("torch_r", 7.0)
		omni.omni_attenuation = 1.3


# ---------------- run lifecycle ----------------

func _new_run(new_seed: int) -> void:
	seed_val = new_seed
	run_state = "playing"
	chest_opened = false
	current_room = -1
	for id in skill_cd:
		skill_cd[id] = 0.0
	biome = BIO.for_floor(Stats.floor_num)
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = Node3D.new()
	room.name = "Room"
	add_child(room)
	info = RG.build_floor(room, seed_val, Stats.floor_num)
	_apply_biome()
	_style_room()
	_build_gates()
	_spawn_player(info.player_pos)
	var boss_floor: bool = QDB.is_boss_floor(Stats.floor_num)
	boss_ref = null
	shrine_ref = null
	shrine_used = false
	chest_opened = false
	mimic_pending = Stats.floor_num >= 2 and rng.randf() < 0.35
	var last_room: int = int(info.get("room_count", 1)) - 1
	var elite_chance: float = minf(0.08 + 0.02 * Stats.floor_num, 0.3)
	var table: Array = biome["enemies"]
	for sp in info.enemy_spawns:
		# di lantai boss, ruangan terakhir hanya untuk Raja Tulang
		if boss_floor and int(sp.get("room", 0)) == last_room:
			continue
		_spawn_enemy(sp, table[rng.randi_range(0, table.size() - 1)], rng.randf() < elite_chance)
	if boss_floor:
		var lr: Dictionary = info.ranges[last_room]
		_spawn_enemy({"pos": Vector3((lr["x0"] + lr["x1"]) * 0.5, 0.0, lr["z1"] + 1.6 * info.tile), "room": last_room}, "bone_king", false)
	else:
		_spawn_traps(last_room)
		_spawn_shrine(last_room)
	_start_quests(boss_floor, int(info.get("room_count", 1)))
	_build_minimap()
	Sfx.play_music("boss" if boss_floor else "dungeon")
	ui.floor_label.text = "Lantai %d • %s" % [Stats.floor_num, biome["name"]]
	_update_hp(Stats.current_hp)
	_update_xp(Stats.xp, Stats.xp_need(), Stats.level)
	_rebuild_chips()
	_hide_banner()
	_cam_snap()
	tut_active = not Stats.tutorial_done and Stats.floor_num == 1 and not autotest
	tut_step = 0
	moved_accum = 0.0
	quest_moved = 0.0
	quest_last_p = info.player_pos
	if tut_active:
		_tut_show("Geser jempolmu di sisi kiri layar untuk bergerak")
		tut_last_pos = player.global_position
	else:
		_tut_hide()
	if Stats.floor_num > 1:
		Sfx.play("door")
	_boss_bar_hide()
	_combo_set(0)
	print("ROOM seed=%d floor=%d biome=%s rooms=%d enemies=%d gates=%d boss=%s" % [seed_val, Stats.floor_num, biome["name"], info.get("room_count", 1), info.enemy_spawns.size(), gates.size(), str(QDB.is_boss_floor(Stats.floor_num))])
	_floor_intro_lines(boss_floor)
	if Stats.floor_num > 1:
		_lvl_banner("LANTAI %d — %s" % [Stats.floor_num, String(biome["name"]).to_upper()])


func _build_gates() -> void:
	gates.clear()
	for d in info.get("doors", []):
		var g = GATE.new()
		room.add_child(g)
		g.position = d["pos"]
		g.setup(info.tile, info.wall_h)
		gates[int(d["room"])] = g


func _room_at(z: float) -> int:
	# margin sisi selatan (arah pintu masuk): pemain harus benar-benar masuk
	# ruangan sebelum dianggap pindah, supaya gerbang tidak menutup di badannya
	var margin: float = 0.3 * float(info.get("tile", 4.0))
	var rs: Array = info.get("ranges", [])
	for i in range(rs.size()):
		var r: Dictionary = rs[i]
		if z <= r["z0"] - margin and z > r["z1"]:
			return i
	return -1


func _room_alive(ri: int) -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.room_idx == ri:
			n += 1
	return n


func _set_room_gates(ri: int, open: bool) -> void:
	for gi in [ri - 1, ri]:
		if gates.has(gi):
			var g = gates[gi]
			if g.open != open:
				g.set_open(open)
				if open:
					Sfx.play("door")
				else:
					Sfx.play("gate")
					_burst(g.global_position + Vector3(0, 0.2, 0), Color(0.7, 0.65, 0.6))


func _on_room_enter(ri: int) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.activated = e.room_idx == ri
	_quest_event("reach_room", ri)
	if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.activated:
		Sfx.play("roar")
		Sfx.play_music("boss")
	if _room_alive(ri) > 0:
		_set_room_gates(ri, false)
		if ri > 0:
			if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.room_idx == ri:
				toast(boss_name + " MENGHADANG — bunuh dia!")
			else:
				toast("Ruangan terkunci — habisi semua skeleton!")
		print("RUANGAN %d TERKUNCI (musuh=%d)" % [ri, _room_alive(ri)])


func _spawn_player(pos: Vector3) -> void:
	player = preload("res://player.gd").new()
	var model: Node3D = load(CHARS + "Skeleton_Warrior.glb").instantiate()
	player.add_child(model)
	player.setup(M.toon(skeleton_tex, Color(1, 1, 1), 0.4, true), info.tile, info)
	player.position = pos
	room.add_child(player)
	player.hp_changed.connect(_on_player_hp)
	player.died.connect(_on_player_died)
	player.hit_landed.connect(_on_hit_landed)
	player.attacked.connect(_on_player_attacked)
	player.stepped.connect(_step_dust)
	player.revived.connect(_on_player_revived)


func _on_player_hp(hp: float) -> void:
	Stats.current_hp = hp
	_update_hp(hp)


func _on_player_revived() -> void:
	_lvl_banner("JIWA BANGKIT!")
	_burst(player.global_position, Color(1.0, 0.9, 0.5))
	_souls(player.global_position, 16, Color(0.6, 1.0, 0.75))
	toast("Relik Jiwa Bangkit menyelamatkanmu — separuh HP kembali")


func _on_player_attacked() -> void:
	if tut_active and tut_step == 1:
		tut_step = 2
		_tut_show("Habisi semua skeleton di lantai ini!")
	_slash_vfx()


func _slash_vfx() -> void:
	if player == null or not is_instance_valid(player):
		return
	var q := PlaneMesh.new()
	q.size = Vector2(1.1 * info.tile, 0.42 * info.tile)
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color(0.75, 0.9, 1.0, 0.85)
	mt.emission_enabled = true
	mt.emission = Color(0.6, 0.85, 1.0)
	mt.emission_energy_multiplier = 2.5
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = mt
	var m := MeshInstance3D.new()
	m.mesh = q
	add_child(m)
	var dir := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	m.global_position = player.global_position + dir * 0.55 * info.tile + Vector3(0, 0.45 * info.tile, 0)
	m.rotation.y = player.rotation.y
	m.rotation.x = -1.15
	m.scale = Vector3(0.3, 1, 1)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale:x", 1.25, 0.14).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.16)
	tw.set_parallel(false)
	tw.tween_callback(m.queue_free)


func _souls(pos: Vector3, n := 7, col := Color(0.6, 0.85, 1.0)) -> void:
	var p := CPUParticles3D.new()
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12 * info.tile
	p.direction = Vector3(0, 1, 0)
	p.spread = 35.0
	p.gravity = Vector3(0, 0.9 * info.tile, 0)
	p.initial_velocity_min = 0.6 * info.tile
	p.initial_velocity_max = 1.3 * info.tile
	p.damping_min = 0.4 * info.tile
	p.damping_max = 1.0 * info.tile
	p.scale_amount_min = 0.04 * info.tile
	p.scale_amount_max = 0.08 * info.tile
	p.color = col
	add_child(p)
	p.global_position = pos + Vector3(0, 0.35 * info.tile, 0)
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(p.queue_free)


func _step_dust(pos: Vector3) -> void:
	var q := PlaneMesh.new()
	q.size = Vector2(0.22 * info.tile, 0.22 * info.tile)
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color(0.65, 0.58, 0.5, 0.3)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = mt
	var m := MeshInstance3D.new()
	m.mesh = q
	add_child(m)
	m.global_position = pos + Vector3(randf_range(-0.05, 0.05), 0.03 * info.tile, randf_range(-0.05, 0.05))
	m.rotation.x = -PI / 2
	m.scale = Vector3(0.5, 0.5, 1)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1.5, 1.5, 1), 0.45)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.45)
	tw.set_parallel(false)
	tw.tween_callback(m.queue_free)


func _spawn_enemy(sp: Dictionary, arch_id: String, elite: bool) -> void:
	var a: Dictionary = EDB.get_arch(arch_id)
	var e = preload("res://enemy.gd").new()
	var model: Node3D = load(CHARS + a["glb"]).instantiate()
	e.add_child(model)
	var tint: Color = a["tint"]
	if elite:
		tint = EDB.ELITE["tint"]
	e.setup(M.toon(skeleton_tex, tint, 0.35, true), info.tile, info, arch_id, elite, Stats.floor_num)
	e.position = sp["pos"]
	e.room_idx = int(sp.get("room", 0))
	e.activated = false
	room.add_child(e)
	# spawn-in: muncul pop supaya tidak hard-cut
	e.scale = Vector3(0.01, 0.01, 0.01)
	var stw := e.create_tween()
	stw.tween_property(e, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	e.died.connect(_on_enemy_died)
	if e.is_boss:
		boss_ref = e
		var tier := _boss_tier()
		boss_name = String(tier["name"])
		M.paint(e, M.toon(skeleton_tex, tier["tint"], 0.35, true))
		if ui.has("boss_name"):
			ui.boss_name.text = "☠ " + boss_name
		e.summon_requested.connect(_on_boss_summon)


# boss memanggil 2 antek; dibatasi supaya ruangan tidak banjir
func _on_boss_summon(boss) -> void:
	var alive := _room_alive(boss.room_idx)
	if alive >= 7:
		return
	Sfx.play("roar")
	toast(boss_name + " memanggil antek-anteknya!")
	for k in range(2):
		var off := Vector3((k - 0.5) * 0.8 * info.tile, 0, 0.5 * info.tile)
		_spawn_enemy({"pos": boss.global_position + off, "room": boss.room_idx}, "chaser", false)


# jebakan duri di ruang-ruang tengah (tidak di ruang spawn / ruang boss)
func _spawn_traps(last_room: int) -> void:
	var count: int = mini(maxi(Stats.floor_num - 1, 0), 3)
	for i in range(count):
		var ri: int = rng.randi_range(1, last_room)
		var r: Dictionary = info.ranges[ri]
		var pos := Vector3.ZERO
		var ok := false
		for t in range(14):
			pos = Vector3(rng.randf_range(r["x0"] + 0.6 * info.tile, r["x1"] - 0.6 * info.tile), 0.0, rng.randf_range(r["z1"] + 0.9 * info.tile, r["z0"] - 0.9 * info.tile))
			ok = true
			for pr in info.props:
				if pr.global_position.distance_to(pos) < 0.8 * info.tile:
					ok = false
					break
			if ok:
				break
		if not ok:
			continue
		var tr = TRAP.new()
		room.add_child(tr)
		tr.global_position = pos
		tr.setup(info.tile, rng.randf_range(0.0, 1.9))


# altar arwah di ruangan terakhir — 45% kesempatan, sekali pakai
func _spawn_shrine(last_room: int) -> void:
	if rng.randf() >= 0.45:
		return
	var r: Dictionary = info.ranges[last_room]
	var pos := Vector3((r["x0"] + r["x1"]) * 0.5, 0.0, r["z0"] - 1.1 * info.tile)
	for pr in info.props:
		if pr.global_position.distance_to(pos) < 1.0 * info.tile:
			return
	var s = SHRINE.new()
	room.add_child(s)
	s.global_position = pos
	s.setup(info.tile)
	shrine_ref = s
	s.invoked.connect(_on_shrine_invoked)


func spawn_weapon_drop(pos: Vector3, wid: String) -> Node3D:
	var pk = WPICK.new()
	room.add_child(pk)
	pk.global_position = pos
	pk.setup(wid, skeleton_tex, info.tile)
	return pk


func _spawn_gems(pos: Vector3, total: int) -> void:
	var n := mini(maxi(total, 1), 4)
	var per := int(total / n)
	for i in range(n):
		var v := per
		if i == n - 1:
			v = total - per * (n - 1)
		if v <= 0:
			continue
		var gem = GEM.new()
		room.add_child(gem)
		gem.global_position = pos + Vector3(0, 0.5, 0)
		gem.setup(v, info.tile)


func _on_enemy_died(e) -> void:
	print("ENEMY DIED arch=%s elite=%s xp=%d" % [e.arch_id, e.elite, e.xp_val])
	trauma = 0.7
	_burst(e.global_position)
	_souls(e.global_position, 22 if e.is_boss else 7, Color(1.0, 0.5, 0.3) if e.is_boss else Color(0.6, 0.85, 1.0))
	Sfx.play("death")
	kills_run += 1
	Stats.count_kill()
	if Stats.total_kills >= 1:
		_ach("kill1")
	if Stats.total_kills >= 50:
		_ach("k50")
	if Stats.total_kills >= 200:
		_ach("k200")
	_quest_event("kill")
	_combo_set(combo + 1)
	if e.is_boss:
		_on_boss_died(e)
	if e.elite and rng.randf() < 0.6:
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
	elif e.arch_id == "brute" and rng.randf() < 0.25:
		spawn_weapon_drop(e.global_position, WDB.roll_drop(rng, Stats.weapon_id))
	var tw := create_tween()
	tw.tween_property(e, "scale", Vector3(0.01, 0.01, 0.01), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(e.queue_free)
	await get_tree().process_frame
	await get_tree().process_frame
	while Stats.draft_open:
		await get_tree().process_frame
	if run_state == "playing":
		if _room_alive(e.room_idx) == 0:
			_quest_event("clear_floor")
			_set_room_gates(e.room_idx, true)
			if not get_tree().get_nodes_in_group("enemies").is_empty():
				toast("Ruangan bersih — gerbang terbuka!")
		if get_tree().get_nodes_in_group("enemies").is_empty():
			run_state = "cleared"
			Stats.note_floor()
			Stats.save_run()
			for gi in gates:
				gates[gi].set_open(true)
			if tut_active and tut_step >= 2:
				tut_active = false
				Stats.tutorial_done = true
				Stats.save_game()
				_tut_hide()
			_show_banner("LANTAI %d BERSIH" % Stats.floor_num, "ketuk untuk turun ke Lantai %d" % [Stats.floor_num + 1])
			if player != null and is_instance_valid(player):
				_burst(player.global_position, Color(1.0, 0.85, 0.3))
				_souls(player.global_position, 12, Color(1.0, 0.8, 0.35))
				Sfx.play("victory")
	# permata XP terakhir, supaya logika gerbang di atas tidak keganggu bila gem gagal
	_spawn_gems(e.global_position, e.xp_val)


func _on_boss_died(_e) -> void:
	boss_ref = null
	Stats.boss_kills += 1
	Stats.save_game()
	Sfx.play("victory")
	Sfx.play_music("dungeon")
	_quest_event("boss_kill")
	if Stats.boss_kills >= 1:
		_ach("b1")
	if Stats.boss_kills >= 3:
		_ach("b3")
	_boss_bar_hide()
	toast(boss_name + " roboh! +15 XP")
	# epilog singkat setelah bos tumbang (kecuali pemain buru-buru turun)
	var fl := Stats.floor_num
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if Stats.floor_num != fl or Stats.draft_open or (dlg != null and dlg.active):
			return
		_say([
			{"who": "raja", "text": "...tidak mungkin... singgasanaku... retak..."},
			{"who": "oracle", "text": "Dia akan bangkit lagi lima lantai lebih dalam — lebih kuat. Terus turun, Kael."},
		]))
	_damage_number(_e.global_position, "BOSS TUMBANG", Color(1.0, 0.5, 0.2), true)


func _on_player_died() -> void:
	print("PLAYER DIED floor=%d" % Stats.floor_num)
	run_state = "dead"
	Stats.note_floor()
	Stats.clear_run()
	Stats.runs += 1
	Stats.save_game()
	_tut_hide()
	Input.vibrate_handheld(280)
	if player != null and is_instance_valid(player):
		_souls(player.global_position, 18, Color(0.85, 0.9, 1.0))
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	_show_banner("KAMU MATI", "Lantai %d • %s\n%d kill • Lv %d • %d relik • %d:%02d\nTerbaik: Lantai %d — ketuk untuk mengulang" % [Stats.floor_num, biome["name"], kills_run, Stats.level, Stats.relics.size(), mins, secs, Stats.best_floor])


func _on_banner_tap() -> void:
	if run_state == "cleared":
		_quest_event("descend")
		Stats.floor_num += 1
		Stats.note_floor()
		if Stats.floor_num >= 5:
			_ach("f5")
		if Stats.floor_num >= 10:
			_ach("f10")
		if Stats.floor_num >= 20:
			_ach("f20")
		await _fade_to(1.0, 0.3)
		_new_run(rng.randi())
		_fade_to(0.0, 0.45)
	elif run_state == "dead":
		Stats.reset_run()
		kills_run = 0
		run_time = 0.0
		await _fade_to(1.0, 0.3)
		_new_run(rng.randi())
		_fade_to(0.0, 0.45)


# ---------------- tutorial ----------------

func _tut_show(txt: String) -> void:
	ui.tut_label.text = txt
	ui.tut.visible = true


func _tut_hide() -> void:
	ui.tut.visible = false


# ---------------- draft (level up) ----------------

func _on_leveled_up(lv: int) -> void:
	Sfx.play("levelup")
	if player != null and is_instance_valid(player):
		player.hp = minf(Stats.get_stat("max_hp"), player.hp + 2.0)
		player.hp_changed.emit(player.hp)
	_lvl_banner("NAIK LEVEL — Lv %d" % lv)
	for id in SK.ORDER:
		if int(SK.DB[id]["unlock"]) == lv:
			toast("Skill terbuka: %s!" % SK.DB[id]["name"])
	pending_drafts += 1
	_try_open_draft()


func _try_open_draft() -> void:
	if Stats.draft_open or pending_drafts <= 0 or run_state == "dead":
		return
	Stats.draft_open = true
	pending_drafts -= 1
	draft_choices = ITEMS.roll_choices(Stats.relics, rng)
	for c in ui.draft_cards.get_children():
		c.queue_free()
	for i in range(draft_choices.size()):
		var it: Dictionary = ITEMS.DB[draft_choices[i]]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(148, 190)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.13, 0.2, 1.0)
		sb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", sb)
		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 8)
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip := Label.new()
		chip.text = String(it["chip"])
		chip.add_theme_font_size_override("font_size", 30)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var nl := Label.new()
		nl.text = String(it["name"])
		nl.add_theme_font_size_override("font_size", 18)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var dl := Label.new()
		dl.text = String(it["desc"])
		dl.add_theme_font_size_override("font_size", 15)
		dl.modulate = Color(1, 1, 1, 0.72)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for cc in [chip, nl, dl]:
			cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cvb.add_child(cc)
		card.add_child(cvb)
		var idx := i
		card.gui_input.connect(func(e: InputEvent) -> void:
			if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
				Sfx.play("click")
				_pick_relic(idx)
		)
		ui.draft_cards.add_child(card)
	ui.draft.visible = true
	ui.dim.visible = true
	get_tree().paused = true
	print("DRAFT terbuka: %s (Lv %d)" % [str(draft_choices), Stats.level])


func _pick_relic(i: int) -> void:
	if not Stats.draft_open or i >= draft_choices.size():
		return
	var id: String = draft_choices[i]
	var before := Stats.get_stat("max_hp")
	Stats.add_relic(id)
	var after := Stats.get_stat("max_hp")
	if player != null and is_instance_valid(player):
		if after > before:
			player.hp += after - before
		player.hp = minf(player.hp, Stats.get_stat("max_hp"))
		player.refresh_stats()
		player.hp_changed.emit(player.hp)
	Stats.draft_open = false
	ui.draft.visible = false
	if run_state == "playing":
		ui.dim.visible = false
	get_tree().paused = false
	print("RELIK DIPILIH: %s | ATK=%.1f SPD=%.2f HPmax=%.0f CRIT=%.2f" % [id, Stats.get_stat("atk"), Stats.get_stat("speed"), Stats.get_stat("max_hp"), Stats.get_stat("crit")])
	_try_open_draft()


# ---------------- skill ----------------

func _cast_skill(id: String) -> void:
	if player == null or not is_instance_valid(player) or player.dead or Stats.draft_open or run_state != "playing":
		return
	if not SK.is_unlocked(id, Stats.level):
		Sfx.play("deny")
		toast("%s terbuka di Lv %d" % [SK.DB[id]["name"], int(SK.DB[id]["unlock"])])
		return
	if skill_cd[id] > 0.0:
		Sfx.play("deny")
		return
	match id:
		"dash":
			var dir := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
			if player.move_input.length() > 0.1:
				dir = Vector3(player.move_input.x, 0, player.move_input.y).normalized()
			player.dash_burst(dir)
			Sfx.play("dash")
			_burst(player.global_position + Vector3(0, 0.4, 0), Color(0.5, 0.9, 1.0))
		"whirl":
			player.anim_lock = M.play_action(player.ap, ["spin", "1h_melee_attack"], 1.6)
			Sfx.play("whirl")
			_shock_ring(player.global_position)
			var dmg := Stats.get_stat("atk") * 2.0
			var hit := 0
			for f in get_tree().get_nodes_in_group("enemies"):
				if f.global_position.distance_to(player.global_position) < 0.95 * info.tile:
					f.take_hit(player.global_position, dmg)
					hit += 1
			trauma = 0.6
			print("SKILL whirl hit=%d dmg=%.1f" % [hit, dmg])
		"thunder":
			var foes := get_tree().get_nodes_in_group("enemies")
			var pp: Vector3 = player.global_position
			foes.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(pp) < b.global_position.distance_squared_to(pp))
			var struck := 0
			for f in foes:
				if struck >= 3:
					break
				if f.global_position.distance_to(pp) > 2.5 * info.tile:
					break
				_lightning(f.global_position)
				f.take_hit(f.global_position, Stats.get_stat("atk") * 3.0)
				f.stun(1.4)
				struck += 1
			if struck == 0:
				Sfx.play("deny")
				toast("Tidak ada musuh dalam jangkauan petir")
				return
			Sfx.play("thunder")
			trauma = 0.9
			print("SKILL thunder struck=%d" % struck)
	skill_cd[id] = float(SK.DB[id]["cd"])


func _shock_ring(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	mi.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.5, 0.95, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.9, 1.0)
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	room.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.3, 0)
	mi.scale = Vector3.ONE * 0.15 * info.tile
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.1 * info.tile, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mi.queue_free)


func _lightning(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1 * info.tile, 7.0, 0.1 * info.tile)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.95, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.4)
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	room.add_child(mi)
	mi.global_position = pos + Vector3(0, 3.5, 0)
	_burst(pos, Color(1.0, 0.9, 0.4))
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3(1.8, 1.0, 1.8), 0.1)
	tw.tween_property(mi, "scale", Vector3(0.05, 1.0, 0.05), 0.22)
	tw.tween_callback(mi.queue_free)


func _build_skill_buttons(layer: CanvasLayer) -> void:
	var labels := {"dash": "DASH", "whirl": "PUTAR", "thunder": "PETIR"}
	for i in range(SK.ORDER.size()):
		var id: String = SK.ORDER[i]
		var b := Button.new()
		b.text = labels[id]
		b.add_theme_font_size_override("font_size", 14)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.16, 0.24, 0.88)
		sb.border_color = Color(0.45, 0.75, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(12)
		b.add_theme_stylebox_override("normal", sb)
		var sbp := sb.duplicate() as StyleBoxFlat
		sbp.bg_color = Color(0.25, 0.4, 0.55, 0.95)
		b.add_theme_stylebox_override("pressed", sbp)
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
		b.offset_left = -118
		b.offset_right = -40
		b.offset_top = -318 - (SK.ORDER.size() - 1 - i) * 88
		b.offset_bottom = -240 - (SK.ORDER.size() - 1 - i) * 88
		var cd := Label.new()
		cd.set_anchors_preset(Control.PRESET_TOP_WIDE)
		cd.offset_top = 2.0
		cd.offset_bottom = 42.0
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd.add_theme_font_size_override("font_size", 22)
		cd.modulate = Color(1.0, 0.95, 0.6)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cd)
		var sid := id
		b.pressed.connect(func() -> void: _cast_skill(sid))
		layer.add_child(b)
		skill_ui[id] = {"btn": b, "cd": cd, "name": labels[id]}


func _tick_skill_ui(delta: float) -> void:
	for id in SK.ORDER:
		if not skill_ui.has(id):
			continue
		skill_cd[id] = maxf(0.0, skill_cd[id] - delta)
		var rec: Dictionary = skill_ui[id]
		var b: Button = rec["btn"]
		var lab: Label = rec["cd"]
		if not SK.is_unlocked(id, Stats.level):
			b.modulate = Color(1, 1, 1, 0.3)
			b.text = "Lv%d" % int(SK.DB[id]["unlock"])
			lab.text = ""
		elif skill_cd[id] > 0.0:
			b.modulate = Color(1, 1, 1, 0.45)
			b.text = ""
			lab.text = str(int(ceil(skill_cd[id])))
		else:
			b.modulate = Color(1, 1, 1, 1)
			b.text = String(rec["name"])
			lab.text = ""


# ---------------- layar hero ----------------

func _find_slot(node: Node) -> Node3D:
	var nm: String = node.name.to_lower().replace(".", "").replace("_", "")
	if nm == "handslotr":
		return node as Node3D
	for c in node.get_children():
		var r := _find_slot(c)
		if r != null:
			return r
	return null


func _toggle_hero(open: bool) -> void:
	if open:
		_refresh_hero()
		ui.hero.visible = true
		ui.dim.visible = true
		Stats.draft_open = true
		get_tree().paused = true
		Sfx.play("click")
	else:
		ui.hero.visible = false
		Stats.draft_open = false
		get_tree().paused = false
		if run_state == "playing":
			ui.dim.visible = false
		Sfx.play("click")


func _hero_equip(wid: String) -> void:
	if player != null and is_instance_valid(player):
		player.equip_weapon(wid)
	else:
		Stats.equip_weapon(wid)
	Sfx.play("pickup")
	if Stats.owned_weapons.size() >= 5:
		_ach("w5")
	_refresh_hero()


func _refresh_hero() -> void:
	# senjata di tangan model preview
	var slot := _find_slot(ui.hero_model)
	if slot != null:
		for c in slot.get_children():
			c.queue_free()
		var w: Dictionary = WDB.get_w(Stats.weapon_id)
		var wm: Node3D = load(WDB.DIR + w["gltf"]).instantiate()
		M.paint(wm, M.toon(skeleton_tex, w["tint"], 0.35))
		slot.add_child(wm)
	# kolom kanan
	var vb: VBoxContainer = ui.hero_right
	for c in vb.get_children():
		c.queue_free()

	var t := Label.new()
	t.text = "HERO"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var rows := [
		["Level", str(Stats.level)],
		["XP", "%d / %d" % [Stats.xp, Stats.xp_need()]],
		["ATK", "%.0f" % Stats.get_stat("atk")],
		["HP Maks", "%.0f" % Stats.get_stat("max_hp")],
		["Kecepatan", "%.0f%%" % (Stats.get_stat("speed") * 100.0)],
		["Crit", "%.0f%%" % (Stats.get_stat("crit") * 100.0)],
		["Lifesteal", "%.0f%%" % (Stats.get_stat("lifesteal") * 100.0)],
		["Armor", "%d" % int(Stats.get_stat("armor"))],
		["Kecepatan Serang", "%.0f%%" % (Stats.get_stat("atk_speed") * 100.0)],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	for r in rows:
		var k := Label.new()
		k.text = r[0]
		k.modulate = Color(1, 1, 1, 0.6)
		k.add_theme_font_size_override("font_size", 17)
		grid.add_child(k)
		var v := Label.new()
		v.text = r[1]
		v.add_theme_font_size_override("font_size", 17)
		grid.add_child(v)
	vb.add_child(grid)

	var wl := Label.new()
	wl.text = "SENJATA (ketuk untuk ganti)"
	wl.add_theme_font_size_override("font_size", 15)
	wl.modulate = Color(1.0, 0.85, 0.4)
	vb.add_child(wl)
	for wid in Stats.owned_weapons:
		var wd: Dictionary = WDB.get_w(wid)
		var wb := Button.new()
		var cur: bool = wid == Stats.weapon_id
		wb.text = ("• " if cur else "") + wd["name"] + "\n" + wd["desc"]
		wb.add_theme_font_size_override("font_size", 14)
		wb.custom_minimum_size = Vector2(0, 54)
		var wsb := StyleBoxFlat.new()
		wsb.bg_color = Color(0.2, 0.17, 0.1, 0.95) if cur else Color(0.13, 0.12, 0.18, 0.95)
		wsb.border_color = Color(0.9, 0.75, 0.3) if cur else Color(0.35, 0.32, 0.4)
		wsb.set_border_width_all(2)
		wsb.set_corner_radius_all(8)
		wb.add_theme_stylebox_override("normal", wsb)
		var swid: String = wid
		wb.pressed.connect(func() -> void: _hero_equip(swid))
		vb.add_child(wb)

	var rl := Label.new()
	rl.text = "RELIC (%d)" % Stats.relics.size()
	rl.add_theme_font_size_override("font_size", 15)
	rl.modulate = Color(1.0, 0.85, 0.4)
	vb.add_child(rl)
	var rgrid := GridContainer.new()
	rgrid.columns = 6
	rgrid.add_theme_constant_override("h_separation", 6)
	rgrid.add_theme_constant_override("v_separation", 6)
	for rid in Stats.relics:
		var it: Dictionary = ITEMS.DB[rid]
		var p := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.1, 0.1, 0.16, 0.9)
		psb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(6)
		psb.set_content_margin_all(6)
		p.add_theme_stylebox_override("panel", psb)
		var l := Label.new()
		l.text = it["chip"]
		l.add_theme_font_size_override("font_size", 14)
		l.tooltip_text = it["name"] + " — " + it["desc"]
		p.add_child(l)
		rgrid.add_child(p)
	if Stats.relics.is_empty():
		var none := Label.new()
		none.text = "(belum ada relic)"
		none.modulate = Color(1, 1, 1, 0.4)
		none.add_theme_font_size_override("font_size", 14)
		rgrid.add_child(none)
	vb.add_child(rgrid)

	var sl := Label.new()
	sl.text = "SKILL"
	sl.add_theme_font_size_override("font_size", 15)
	sl.modulate = Color(1.0, 0.85, 0.4)
	vb.add_child(sl)
	for id in SK.ORDER:
		var sd: Dictionary = SK.DB[id]
		var unlocked := SK.is_unlocked(id, Stats.level)
		var sl2 := Label.new()
		sl2.text = "%s — %s%s" % [sd["name"], sd["desc"], "" if unlocked else " (terkunci: Lv %d)" % int(sd["unlock"])]
		sl2.add_theme_font_size_override("font_size", 14)
		sl2.modulate = Color(1, 1, 1, 0.85) if unlocked else Color(1, 1, 1, 0.35)
		sl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(sl2)

	var hclose := Button.new()
	hclose.text = "Tutup"
	hclose.add_theme_font_size_override("font_size", 22)
	hclose.custom_minimum_size = Vector2(0, 52)
	hclose.pressed.connect(func() -> void: _toggle_hero(false))
	vb.add_child(hclose)


# ---------------- combat juice ----------------

func _on_hit_landed(pos: Vector3, dmg: float, crit: bool) -> void:
	trauma = 0.65 if crit else 0.5
	_hit_spark(pos, crit)
	Input.vibrate_handheld(45 if crit else 25)
	_damage_number(pos, str(int(round(dmg))), Color(1.0, 0.5, 0.15) if crit else Color(1.0, 0.85, 0.3), crit)
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.09 if crit else 0.05, true, false, true).timeout
	Engine.time_scale = 1.0


func _hit_spark(pos: Vector3, crit: bool) -> void:
	var sm := SphereMesh.new()
	sm.radial_segments = 6
	sm.rings = 4
	sm.radius = 0.12 * info.tile * (1.6 if crit else 1.0)
	sm.height = sm.radius * 2.0
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color(1.0, 0.65, 0.2, 0.9) if crit else Color(1.0, 0.95, 0.7, 0.8)
	mt.emission_enabled = true
	mt.emission = mt.albedo_color
	mt.emission_energy_multiplier = 3.0
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var m := MeshInstance3D.new()
	m.mesh = sm
	m.material_override = mt
	add_child(m)
	m.global_position = pos + Vector3(0, 0.5 * info.tile, 0)
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1.7, 1.7, 1.7), 0.12)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.14)
	tw.set_parallel(false)
	tw.tween_callback(m.queue_free)


func _damage_number(pos: Vector3, txt: String, col: Color, big := false) -> void:
	var l := Label3D.new()
	room.add_child(l)
	l.text = txt
	l.font_size = 140 if big else 96
	l.pixel_size = 0.012
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = col
	l.no_depth_test = true
	l.global_position = pos + Vector3(0, 1.3, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.2, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)


func _burst(pos: Vector3, col := Color(0.95, 0.95, 1.0)) -> void:
	var p := GPUParticles3D.new()
	room.add_child(p)
	p.global_position = pos + Vector3(0, 0.8, 0)
	p.amount = 12 if low_quality else 22
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.7
	p.visibility_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	pm.color = col
	p.process_material = pm
	var dot := SphereMesh.new()
	dot.radius = 0.035
	dot.height = 0.07
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = col
	dm.emission_enabled = true
	dm.emission = col
	dm.emission_energy_multiplier = 2.0
	dot.material = dm
	p.draw_pass_1 = dot
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func toast(txt: String) -> void:
	ui.toast.text = txt
	ui.toast.visible = true
	ui.toast.modulate.a = 1.0
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(ui.toast, "modulate:a", 0.0, 0.4)
	toast_tween.tween_callback(func() -> void: ui.toast.visible = false)


func _lvl_banner(txt: String) -> void:
	var l: Label = ui.lvl_banner
	l.text = txt
	l.visible = true
	l.modulate.a = 1.0
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: l.visible = false)


# ---------------- quest berurutan ----------------

func _start_quests(boss_floor: bool, room_count: int) -> void:
	quest_steps = QDB.for_floor(Stats.floor_num, room_count)
	for st in quest_steps:
		st["done"] = 0
	quest_idx = 0
	_quest_render()


func _quest_event(kind: String, num: int = 1) -> void:
	if quest_idx >= quest_steps.size():
		return
	var st: Dictionary = quest_steps[quest_idx]
	if String(st["kind"]) != kind:
		return
	if kind == "reach_room":
		# reach_room selesai saat pemain sampai ruangan ke-"need"
		if num < int(st["need"]):
			return
		st["done"] = int(st["need"])
	else:
		st["done"] = int(st.get("done", 0)) + num
	if int(st["done"]) >= int(st["need"]):
		quest_idx += 1
		Sfx.play("quest")
	_quest_render()


func _quest_render() -> void:
	if not ui.has("quest_l"):
		return
	if quest_idx >= quest_steps.size():
		ui.quest_box.visible = false
		return
	var st: Dictionary = quest_steps[quest_idx]
	ui.quest_box.visible = true
	ui.quest_l.text = "◆ %d/%d %s" % [quest_idx + 1, quest_steps.size(), String(st["title"])]
	var desc := String(st["desc"])
	if int(st["need"]) > 1:
		desc += "  (%d/%d)" % [int(st["done"]), int(st["need"])]
	ui.quest_d.text = desc


# ---------------- kombo kill ----------------

func _combo_set(n: int) -> void:
	combo = n
	combo_t = 4.0
	if not ui.has("combo_l"):
		return
	if combo >= 3:
		ui.combo_l.visible = true
		ui.combo_l.text = "KOMBO ×%d" % combo
		ui.combo_l.pivot_offset = ui.combo_l.size * 0.5
		ui.combo_l.scale = Vector2(1.35, 1.35)
		var tw := create_tween()
		tw.tween_property(ui.combo_l, "scale", Vector2.ONE, 0.18)
		if combo >= 5:
			Sfx.play("combo")
	else:
		ui.combo_l.visible = false


# ---------------- bar HP boss ----------------

func _boss_bar_show() -> void:
	ui.boss_bar.visible = true


func _boss_bar_hide() -> void:
	if ui.has("boss_bar"):
		ui.boss_bar.visible = false


# ---------------- dialog + altar ----------------

func _say(lines: Array, choices: Array = []) -> void:
	if dlg == null or lines.is_empty() or dlg.active:
		return
	Stats.draft_open = true
	get_tree().paused = true
	ui.dim.visible = true
	if choices.is_empty():
		dlg.play(lines)
	else:
		dlg.play_choices(lines, choices)
	if autotest:
		# bukti visual: dialog benar-benar tergambar sebelum dilewati
		for _w in range(3):
			await get_tree().process_frame
		_shot("res://out_v5_dlg.png")
		# autotest: lewati semua dialog otomatis supaya alur tak pernah diam
		for _i in range(80):
			if not dlg.active or dlg._choice_box.visible:
				break
			dlg._advance()
			await get_tree().process_frame


func _on_dlg_end() -> void:
	get_tree().paused = false
	Stats.draft_open = false
	if run_state == "playing":
		ui.dim.visible = false
	_try_open_draft()


func _on_dlg_choice(idx: int) -> void:
	match idx:
		0:
			Stats.buff_atk_pct += 0.15
			toast("Berkat Perang: +15% ATK")
		1:
			Stats.buff_armor += 1
			toast("Berkat Besi: +1 Armor")
		2:
			if player != null and is_instance_valid(player):
				player.heal_to_full()
			toast("Berkat Darah: HP pulih penuh")
	if player != null and is_instance_valid(player):
		player.refresh_stats()
		_burst(player.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.4))


func _on_shrine_invoked(s) -> void:
	shrine_used = true
	s.consume()
	Sfx.play("shrine")
	_say(
		[{"who": "mahzan", "text": "Arwah-arwah tua masih menghormati tulang pemberani. Pilih satu berkat, jangan serakah."}],
		[
			{"text": "Berkat Perang — +15% ATK run ini"},
			{"text": "Berkat Besi — +1 Armor run ini"},
			{"text": "Berkat Darah — pulihkan HP penuh"},
		]
	)


func _floor_intro_lines(boss_floor: bool) -> void:
	var lines: Array = []
	if Stats.floor_num == 1:
		lines = [
			{"who": "oracle", "text": "Kael... kau sudah bangun. Kedalaman ini sekarang milik Raja Tulang."},
			{"who": "kael", "text": "Aku turun bukan untuk mati, Peramal. Tunjukkan jalannya."},
			{"who": "oracle", "text": "Setiap lima lantai dia menunggu di singgasananya. Patung arwah di lorong masih mendengar — sentuh, dan mintalah berkat."},
		]
	elif boss_floor:
		lines = [
			{"who": "oracle", "text": "Hati-hati — Raja Tulang ada di ujung lorong ini. Bila tanah bergetar merah, MINGGIR."},
			{"who": "raja", "text": "KAU LAGI, SI KECIL YANG WANGI. Aku akan menambahkan tulangmu ke singgasanaku."},
		]
	elif Stats.floor_num > 1 and rng.randf() < 0.3:
		var tips := [
			"Duri di lantai itu hidup — perhatikan iramanya sebelum melangkah.",
			"Peti tak selalu peti. Yang bergigi disebut mimic, dan ia lapar.",
			"Elite berpendar merah. Jangan biarkan mereka mengepungmu.",
			"Rantai pembunuhan tanpa jeda — kombo. Musik untuk telinga Raja Tulang.",
		]
		lines = [{"who": "oracle", "text": tips[rng.randi_range(0, tips.size() - 1)]}]
	if lines.is_empty():
		return
	_say(lines)


# ---------------- minimap ----------------

func _map_pos(wp: Vector3, sc: float) -> Vector2:
	return Vector2((wp.x - info["min_x"]) * sc - 3.0, (wp.z - info["min_z"]) * sc - 3.0)


func _build_minimap() -> void:
	if not ui.has("map_view"):
		return
	var mv: Control = ui.map_view
	for c in mv.get_children():
		c.queue_free()
	map_dots.clear()
	var xs: float = info["max_x"] - info["min_x"]
	var zs: float = info["max_z"] - info["min_z"]
	if xs < 0.1 or zs < 0.1:
		ui.map.visible = false
		return
	ui.map.visible = true
	var sc: float = minf(130.0 / xs, 178.0 / zs)
	for r in info.ranges:
		var rc := ColorRect.new()
		rc.color = Color(0.32, 0.3, 0.42, 0.9)
		rc.position = Vector2((r["x0"] - info["min_x"]) * sc, (r["z1"] - info["min_z"]) * sc)
		rc.size = Vector2(maxf((r["x1"] - r["x0"]) * sc, 4.0), maxf((r["z0"] - r["z1"]) * sc, 4.0))
		mv.add_child(rc)
	if info.get("chest") != null:
		var cd := ColorRect.new()
		cd.color = Color(1.0, 0.8, 0.2)
		cd.size = Vector2(5, 5)
		cd.position = _map_pos(info.chest.global_position, sc)
		mv.add_child(cd)
	var pd := ColorRect.new()
	pd.color = Color(1.0, 1.0, 1.0)
	pd.size = Vector2(6, 6)
	mv.add_child(pd)
	ui["map_pdot"] = pd
	ui["map_scale"] = sc
	_update_minimap()


func _update_minimap() -> void:
	if not ui.has("map_view") or not ui.map.visible or player == null or not is_instance_valid(player):
		return
	var sc: float = ui["map_scale"]
	ui.map_pdot.position = _map_pos(player.global_position, sc)
	for d in map_dots:
		if is_instance_valid(d):
			d.queue_free()
	map_dots.clear()
	for f in get_tree().get_nodes_in_group("enemies"):
		var d := ColorRect.new()
		d.color = Color(1.0, 0.3, 0.3)
		d.size = Vector2(4, 4)
		d.position = _map_pos(f.global_position, sc) + Vector2(1, 1)
		ui.map_view.add_child(d)
		map_dots.append(d)


# ---------------- UI ----------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	joystick = preload("res://joystick.gd").new()
	layer.add_child(joystick)

	var atk := Button.new()
	atk.text = "ATK"
	atk.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.5, 0.12, 0.14, 0.85)
	sb.set_corner_radius_all(14)
	atk.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = Color(0.75, 0.2, 0.2, 0.95)
	atk.add_theme_stylebox_override("pressed", sb2)
	atk.anchor_left = 1.0
	atk.anchor_top = 1.0
	atk.anchor_right = 1.0
	atk.anchor_bottom = 1.0
	atk.offset_left = -200
	atk.offset_top = -220
	atk.offset_right = -40
	atk.offset_bottom = -60
	atk.button_down.connect(func() -> void: atk_held = true)
	atk.button_up.connect(func() -> void: atk_held = false)
	atk.pressed.connect(func() -> void:
		if player != null and is_instance_valid(player):
			player.attack()
	)
	layer.add_child(atk)

	_build_skill_buttons(layer)

	var hb := HBoxContainer.new()
	hb.position = Vector2(16, 16)
	hb.add_theme_constant_override("separation", 6)
	layer.add_child(hb)
	ui["hp_box"] = hb
	ui["hp_cells"] = []

	var xpb := ProgressBar.new()
	xpb.position = Vector2(16, 50)
	xpb.custom_minimum_size = Vector2(260, 18)
	xpb.show_percentage = false
	var xpfill := StyleBoxFlat.new()
	xpfill.bg_color = Color(0.95, 0.8, 0.25)
	xpfill.set_corner_radius_all(6)
	xpb.add_theme_stylebox_override("fill", xpfill)
	var xpbg := StyleBoxFlat.new()
	xpbg.bg_color = Color(0.1, 0.1, 0.14, 0.9)
	xpbg.set_corner_radius_all(6)
	xpb.add_theme_stylebox_override("background", xpbg)
	layer.add_child(xpb)
	ui["xp_bar"] = xpb

	var lvl := Label.new()
	lvl.position = Vector2(16, 72)
	lvl.add_theme_font_size_override("font_size", 22)
	lvl.modulate = Color(1.0, 0.9, 0.5)
	layer.add_child(lvl)
	ui["lv_label"] = lvl

	var fl := Label.new()
	fl.add_theme_font_size_override("font_size", 18)
	fl.modulate = Color(1, 1, 1, 0.6)
	fl.anchor_left = 1.0
	fl.anchor_right = 1.0
	fl.offset_left = -280
	fl.offset_top = 14
	fl.offset_right = -12
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(fl)
	ui["floor_label"] = fl

	var hero_btn := Button.new()
	hero_btn.text = "HERO"
	hero_btn.add_theme_font_size_override("font_size", 20)
	hero_btn.anchor_left = 1.0
	hero_btn.anchor_right = 1.0
	hero_btn.offset_left = -132
	hero_btn.offset_top = 44
	hero_btn.offset_right = -12
	hero_btn.offset_bottom = 88
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.16, 0.15, 0.24, 0.85)
	hsb.set_corner_radius_all(10)
	hero_btn.add_theme_stylebox_override("normal", hsb)
	hero_btn.pressed.connect(func() -> void: _toggle_hero(true))
	layer.add_child(hero_btn)

	# tombol jeda di kiri HERO
	var pbtn := Button.new()
	pbtn.text = "II"
	pbtn.add_theme_font_size_override("font_size", 17)
	pbtn.anchor_left = 1.0
	pbtn.anchor_right = 1.0
	pbtn.offset_left = -184
	pbtn.offset_right = -140
	pbtn.offset_top = 44
	pbtn.offset_bottom = 88
	var psbb := StyleBoxFlat.new()
	psbb.bg_color = Color(0.07, 0.07, 0.14, 0.75)
	psbb.border_color = Color(0.9, 0.75, 0.3, 0.5)
	psbb.set_border_width_all(2)
	psbb.set_corner_radius_all(9)
	pbtn.add_theme_stylebox_override("normal", psbb)
	pbtn.pressed.connect(_toggle_pause)
	layer.add_child(pbtn)

	var chips := HBoxContainer.new()
	chips.anchor_top = 1.0
	chips.anchor_bottom = 1.0
	chips.offset_left = 16
	chips.offset_top = -60
	chips.offset_bottom = -16
	chips.add_theme_constant_override("separation", 6)
	layer.add_child(chips)
	ui["chips"] = chips

	# angka HP di samping sel
	var ht := Label.new()
	ht.add_theme_font_size_override("font_size", 18)
	ht.modulate = Color(1.0, 0.85, 0.8)
	hb.add_child(ht)
	ui["hp_text"] = ht

	# kotak quest kiri atas
	var qb := PanelContainer.new()
	qb.position = Vector2(16, 96)
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(0.06, 0.06, 0.11, 0.72)
	qsb.border_color = Color(0.9, 0.75, 0.3, 0.55)
	qsb.set_border_width_all(2)
	qsb.set_corner_radius_all(10)
	qsb.set_content_margin_all(9)
	qb.add_theme_stylebox_override("panel", qsb)
	var qvb := VBoxContainer.new()
	qvb.add_theme_constant_override("separation", 2)
	var ql := Label.new()
	ql.add_theme_font_size_override("font_size", 17)
	ql.modulate = Color(1.0, 0.85, 0.4)
	var qd := Label.new()
	qd.add_theme_font_size_override("font_size", 13)
	qd.modulate = Color(1, 1, 1, 0.72)
	qd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qvb.add_child(ql)
	qvb.add_child(qd)
	qb.add_child(qvb)
	layer.add_child(qb)
	ui["quest_box"] = qb
	ui["quest_l"] = ql
	ui["quest_d"] = qd

	# bar HP boss di atas tengah
	var bb := PanelContainer.new()
	bb.anchor_left = 0.5
	bb.anchor_right = 0.5
	bb.offset_left = -200
	bb.offset_right = 200
	bb.offset_top = 150
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.07, 0.04, 0.05, 0.85)
	bsb.border_color = Color(1.0, 0.3, 0.25)
	bsb.set_border_width_all(2)
	bsb.set_corner_radius_all(10)
	bsb.set_content_margin_all(8)
	bb.add_theme_stylebox_override("panel", bsb)
	var bvb := VBoxContainer.new()
	var bn := Label.new()
	bn.text = "☠ RAJA TULANG"
	ui["boss_name"] = bn
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bn.add_theme_font_size_override("font_size", 16)
	bn.modulate = Color(1.0, 0.55, 0.45)
	var bf := ProgressBar.new()
	bf.max_value = 100
	bf.value = 100
	bf.custom_minimum_size = Vector2(0, 14)
	bf.show_percentage = false
	var bff := StyleBoxFlat.new()
	bff.bg_color = Color(0.85, 0.2, 0.15)
	bff.set_corner_radius_all(4)
	bf.add_theme_stylebox_override("fill", bff)
	var bfb := StyleBoxFlat.new()
	bfb.bg_color = Color(0.15, 0.08, 0.08)
	bfb.set_corner_radius_all(4)
	bf.add_theme_stylebox_override("background", bfb)
	bvb.add_child(bn)
	bvb.add_child(bf)
	bb.add_child(bvb)
	bb.visible = false
	layer.add_child(bb)
	ui["boss_bar"] = bb
	ui["boss_fill"] = bf

	# label kombo
	var cl := Label.new()
	cl.anchor_left = 0.5
	cl.anchor_right = 0.5
	cl.anchor_top = 1.0
	cl.anchor_bottom = 1.0
	cl.offset_left = -160
	cl.offset_right = 160
	cl.offset_top = -370
	cl.offset_bottom = -326
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.add_theme_font_size_override("font_size", 30)
	cl.modulate = Color(1.0, 0.7, 0.25)
	cl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	cl.add_theme_constant_override("shadow_offset_x", 2)
	cl.add_theme_constant_override("shadow_offset_y", 2)
	cl.visible = false
	layer.add_child(cl)
	ui["combo_l"] = cl

	# minimap kanan atas
	var mp := PanelContainer.new()
	mp.anchor_left = 1.0
	mp.anchor_right = 1.0
	mp.offset_left = -162
	mp.offset_right = -12
	mp.offset_top = 100
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.05, 0.05, 0.09, 0.6)
	msb.border_color = Color(1, 1, 1, 0.25)
	msb.set_border_width_all(1)
	msb.set_corner_radius_all(8)
	msb.set_content_margin_all(6)
	mp.add_theme_stylebox_override("panel", msb)
	var mv := Control.new()
	mv.custom_minimum_size = Vector2(140, 190)
	mp.add_child(mv)
	layer.add_child(mp)
	ui["map"] = mp
	ui["map_view"] = mv

	# kartu tutorial
	var tut := PanelContainer.new()
	tut.anchor_left = 0.0
	tut.anchor_right = 0.0
	tut.offset_left = 16
	tut.offset_right = 330
	tut.offset_top = 190
	tut.offset_bottom = 250
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.08, 0.08, 0.14, 0.9)
	tsb.border_color = Color(0.9, 0.75, 0.3)
	tsb.set_border_width_all(2)
	tsb.set_corner_radius_all(10)
	tsb.set_content_margin_all(10)
	tut.add_theme_stylebox_override("panel", tsb)
	var tl := Label.new()
	tl.add_theme_font_size_override("font_size", 20)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut.add_child(tl)
	tut.visible = false
	layer.add_child(tut)
	ui["tut"] = tut
	ui["tut_label"] = tl

	# toast
	var tst := Label.new()
	tst.anchor_left = 0.5
	tst.anchor_right = 0.5
	tst.anchor_top = 1.0
	tst.anchor_bottom = 1.0
	tst.offset_left = -260
	tst.offset_right = 260
	tst.offset_top = -300
	tst.offset_bottom = -260
	tst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tst.add_theme_font_size_override("font_size", 22)
	tst.modulate = Color(1.0, 0.9, 0.5, 1.0)
	tst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tst.visible = false
	layer.add_child(tst)
	ui["toast"] = tst

	# banner naik level (non-blokir)
	var lb := Label.new()
	lb.anchor_left = 0.5
	lb.anchor_right = 0.5
	lb.anchor_top = 0.5
	lb.anchor_bottom = 0.5
	lb.offset_left = -260
	lb.offset_right = 260
	lb.offset_top = -260
	lb.offset_bottom = -210
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.add_theme_font_size_override("font_size", 44)
	lb.modulate = Color(1.0, 0.85, 0.3)
	lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lb.add_theme_constant_override("shadow_offset_x", 3)
	lb.add_theme_constant_override("shadow_offset_y", 3)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.visible = false
	layer.add_child(lb)
	ui["lvl_banner"] = lb

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.visible = false
	layer.add_child(dim)
	ui["dim"] = dim

	# dialog karakter: ditambahkan SETELAH dim supaya tergambar & tersentuh di atasnya
	dlg = DLG.new()
	layer.add_child(dlg)
	dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg.finished.connect(_on_dlg_end)
	dlg.choice_made.connect(_on_dlg_choice)

	var bc := CenterContainer.new()
	bc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bc.mouse_filter = Control.MOUSE_FILTER_STOP
	bc.visible = false
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := Label.new()
	t.add_theme_font_size_override("font_size", 64)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := Label.new()
	sub.add_theme_font_size_override("font_size", 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for ll in [t, sub]:
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(ll)
	bc.add_child(vb)
	bc.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_on_banner_tap()
		elif e is InputEventScreenTouch and e.pressed:
			_on_banner_tap()
	)
	layer.add_child(bc)
	ui["banner"] = bc
	ui["banner_t"] = t
	ui["banner_sub"] = sub

	var dr := CenterContainer.new()
	dr.set_anchors_preset(Control.PRESET_FULL_RECT)
	dr.visible = false
	dr.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.08, 0.07, 0.12, 0.97)
	psb.set_corner_radius_all(18)
	psb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", psb)
	var dvb := VBoxContainer.new()
	dvb.add_theme_constant_override("separation", 18)
	var dt := Label.new()
	dt.text = "LEVEL UP — pilih satu"
	dt.add_theme_font_size_override("font_size", 34)
	dt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dvb.add_child(dt)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	dvb.add_child(cards)
	panel.add_child(dvb)
	dr.add_child(panel)
	layer.add_child(dr)
	ui["draft"] = dr
	ui["draft_cards"] = cards

	# layar hero: kiri = model 3D muter, kanan = stat + senjata + relic + skill
	var hr := Control.new()
	hr.set_anchors_preset(Control.PRESET_FULL_RECT)
	hr.visible = false
	hr.process_mode = Node.PROCESS_MODE_ALWAYS
	var hbg := ColorRect.new()
	hbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbg.color = Color(0.03, 0.03, 0.06, 0.96)
	hr.add_child(hbg)
	var hcc := CenterContainer.new()
	hcc.set_anchors_preset(Control.PRESET_FULL_RECT)
	hr.add_child(hcc)
	var hhb := HBoxContainer.new()
	hhb.add_theme_constant_override("separation", 14)
	hcc.add_child(hhb)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(210, 560)
	svc.process_mode = Node.PROCESS_MODE_ALWAYS
	hhb.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.size = Vector2i(420, 1120)
	sv.process_mode = Node.PROCESS_MODE_ALWAYS
	svc.add_child(sv)
	var stage := Node3D.new()
	sv.add_child(stage)
	var sc := Camera3D.new()
	stage.add_child(sc)
	sc.fov = 38.0
	sc.look_at_from_position(Vector3(0.0, 1.55, 4.1), Vector3(0, 0.95, 0))
	sc.current = true
	var sl := DirectionalLight3D.new()
	stage.add_child(sl)
	sl.rotation_degrees = Vector3(-45, -30, 0)
	sl.light_energy = 1.4
	var senv_n := WorldEnvironment.new()
	var senv := Environment.new()
	senv.background_mode = Environment.BG_COLOR
	senv.background_color = Color(0.05, 0.05, 0.09, 0.0)
	senv.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	senv.ambient_light_color = Color(0.5, 0.52, 0.6)
	senv.ambient_light_energy = 0.7
	senv_n.environment = senv
	stage.add_child(senv_n)
	var hero_model: Node3D = load(CHARS + "Skeleton_Warrior.glb").instantiate()
	stage.add_child(hero_model)
	M.paint(hero_model, M.toon(skeleton_tex, Color(1, 1, 1), 0.4))
	var hap: AnimationPlayer = M.anim_player(hero_model)
	hap.process_mode = Node.PROCESS_MODE_ALWAYS
	M.play_fuzzy(hap, ["idle"])
	# turntable: muter pelan walau game sedang pause
	var stw := svc.create_tween()
	stw.set_loops()
	stw.tween_property(hero_model, "rotation:y", TAU, 7.0).from(0.0)
	ui["hero_stage"] = stage
	ui["hero_model"] = hero_model
	ui["hero_svc"] = svc

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.add_theme_constant_override("separation", 8)
	right.process_mode = Node.PROCESS_MODE_ALWAYS
	hhb.add_child(right)
	ui["hero_right"] = right

	layer.add_child(hr)
	ui["hero"] = hr

	# vignette HP rendah: tepi merah berdenyut
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.55, 1.0])
	vg.colors = PackedColorArray([Color(0.6, 0.02, 0.05, 0.0), Color(0.6, 0.02, 0.05, 0.55)])
	var gt := GradientTexture2D.new()
	gt.gradient = vg
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 540
	gt.height = 1200
	vign = TextureRect.new()
	vign.texture = gt
	vign.set_anchors_preset(Control.PRESET_FULL_RECT)
	vign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vign.stretch_mode = TextureRect.STRETCH_SCALE
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vign.modulate.a = 0.0
	vign.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(vign)

	# panel JEDA (resume / restart lantai / volume / keluar ke menu)
	var pp := PanelContainer.new()
	pp.anchor_left = 0.5
	pp.anchor_right = 0.5
	pp.anchor_top = 0.5
	pp.anchor_bottom = 0.5
	pp.offset_left = -200
	pp.offset_right = 200
	pp.offset_top = -280
	pp.offset_bottom = 280
	pp.process_mode = Node.PROCESS_MODE_ALWAYS
	var ppsb := StyleBoxFlat.new()
	ppsb.bg_color = Color(0.05, 0.05, 0.1, 0.96)
	ppsb.border_color = Color(0.9, 0.75, 0.3, 0.7)
	ppsb.set_border_width_all(2)
	ppsb.set_corner_radius_all(14)
	ppsb.set_content_margin_all(20)
	pp.add_theme_stylebox_override("panel", ppsb)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 12)
	pvb.process_mode = Node.PROCESS_MODE_ALWAYS
	pp.add_child(pvb)
	var pt := Label.new()
	pt.text = "JEDA"
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pt.add_theme_font_size_override("font_size", 30)
	pt.modulate = Color(1.0, 0.85, 0.4)
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pvb.add_child(pt)
	_pause_vol_row(pvb, "Musik", Stats.mus_vol(), func(v: float) -> void:
		Stats.music_volume = v
		Sfx.set_music_volume(v)
		Stats.save_game())
	_pause_vol_row(pvb, "Efek Suara", Stats.sfx_vol(), func(v: float) -> void:
		Stats.sfx_volume = v
		Stats.save_game())
	var b_qual := _pause_btn("KUALITAS: " + ("HEMAT" if low_quality else "INDAH"))
	b_qual.pressed.connect(func() -> void:
		Stats.quality = 0 if not low_quality else 1
		_apply_quality()
		b_qual.text = "KUALITAS: " + ("HEMAT" if low_quality else "INDAH")
		Stats.save_game()
		Sfx.play("click"))
	pvb.add_child(b_qual)
	var b_resume := _pause_btn("LANJUT")
	b_resume.pressed.connect(_toggle_pause)
	pvb.add_child(b_resume)
	var b_floor := _pause_btn("ULANGI LANTAI INI")
	b_floor.pressed.connect(func() -> void:
		if paused_ui:
			_toggle_pause()
		_new_run(rng.randi()))
	pvb.add_child(b_floor)
	var b_menu := _pause_btn("KELUAR KE MENU")
	b_menu.pressed.connect(_quit_to_menu)
	pvb.add_child(b_menu)
	pp.visible = false
	layer.add_child(pp)
	pause_panel = pp
	ui["pause_panel"] = pp

	# rect fade transisi (paling atas di layer UI)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0)
	fade_rect.modulate.a = 1.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	# tips loading saat layar gelap antar lantai
	tip_l = Label.new()
	tip_l.visible = false
	tip_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_l.process_mode = Node.PROCESS_MODE_ALWAYS
	tip_l.set_anchors_preset(Control.PRESET_CENTER)
	tip_l.anchor_left = 0.1
	tip_l.anchor_right = 0.9
	tip_l.offset_top = 360
	tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	tip_l.add_theme_font_size_override("font_size", 15)
	tip_l.modulate = Color(0.9, 0.82, 0.62, 0.9)
	tip_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	tip_l.add_theme_constant_override("shadow_offset_x", 1)
	tip_l.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(tip_l)


func _pause_vol_row(vb: VBoxContainer, label: String, cur: float, on_change: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(150, 0)
	l.add_theme_font_size_override("font_size", 17)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = cur
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 32)
	s.value_changed.connect(on_change)
	hb.add_child(l)
	hb.add_child(s)
	vb.add_child(hb)


func _pause_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 21)
	return b


func _toggle_pause() -> void:
	if run_state == "dead" or Stats.draft_open or (dlg != null and dlg.active):
		return
	paused_ui = not paused_ui
	get_tree().paused = paused_ui
	ui.dim.visible = paused_ui or Stats.draft_open
	pause_panel.visible = paused_ui
	Sfx.play("click")


func _quit_to_menu() -> void:
	Stats.save_run()
	get_tree().paused = false
	paused_ui = false
	Sfx.play("click")
	await _fade_to(1.0, 0.3)
	get_tree().change_scene_to_file("res://app/menu.tscn")


func _fade_to(a: float, dur: float) -> void:
	if fade_rect == null:
		return
	if a > 0.5 and tip_l != null:
		tip_l.text = "◆ " + TIPS[rng.randi() % TIPS.size()]
		tip_l.visible = true
	var tw := fade_rect.create_tween()
	tw.tween_property(fade_rect, "modulate:a", a, dur)
	await tw.finished
	if a <= 0.05 and tip_l != null:
		get_tree().create_timer(1.1).timeout.connect(func() -> void: tip_l.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ui.hero.visible:
			_toggle_hero(false)
		elif pause_panel.visible:
			_toggle_pause()
		elif run_state == "playing" and not Stats.draft_open and not (dlg != null and dlg.active):
			_toggle_pause()
		get_viewport().set_input_as_handled()


func _update_hp(hp: float) -> void:
	var maxh := int(ceil(Stats.get_stat("max_hp")))
	var cells: Array = ui.get("hp_cells", [])
	var hb: HBoxContainer = ui.get("hp_box")
	if cells.size() != maxh:
		for c in cells:
			c.queue_free()
		cells.clear()
		var cw := 26.0 if maxh <= 10 else 16.0
		for i in range(maxh):
			var r := ColorRect.new()
			r.custom_minimum_size = Vector2(cw, 26)
			hb.add_child(r)
			cells.append(r)
		hb.move_child(ui.hp_text, hb.get_child_count() - 1)
	var full := int(ceil(hp))
	for i in range(cells.size()):
		cells[i].color = Color(0.85, 0.15, 0.2) if i < full else Color(0.25, 0.1, 0.12)
	if ui.has("hp_text"):
		ui.hp_text.text = "%d/%d" % [maxi(int(ceil(hp)), 0), maxh]
	if prev_hp >= 0.0 and hp < prev_hp - 0.001:
		trauma = maxf(trauma, 0.6)
		_vign_flash()
	prev_hp = hp
	_set_low_hp(hp <= 1.0 and hp > 0.0)


func _vign_flash() -> void:
	# kilat merah sekali saat terluka; kalau denyut HP-kritis sedang jalan, biarkan
	if vign == null or (vign_tween != null and vign_tween.is_valid()):
		return
	vign.modulate.a = 0.45
	var tw := vign.create_tween()
	tw.tween_property(vign, "modulate:a", 0.0, 0.5)


func _set_low_hp(on: bool) -> void:
	if vign == null:
		return
	if on:
		if vign_tween == null or not vign_tween.is_valid():
			vign_tween = vign.create_tween()
			vign_tween.set_loops()
			vign_tween.tween_property(vign, "modulate:a", 0.75, 0.55)
			vign_tween.tween_property(vign, "modulate:a", 0.3, 0.55)
	else:
		if vign_tween != null and vign_tween.is_valid():
			vign_tween.kill()
		vign_tween = null
		if vign.modulate.a > 0.01:
			var tw := vign.create_tween()
			tw.tween_property(vign, "modulate:a", 0.0, 0.4)


func _update_xp(cur: int, need: int, lv: int) -> void:
	ui.xp_bar.max_value = need
	ui.xp_bar.value = cur
	ui.lv_label.text = "Lv %d" % lv


func _rebuild_chips() -> void:
	for c in ui.chips.get_children():
		c.queue_free()
	for id in Stats.relics:
		var it: Dictionary = ITEMS.DB[id]
		var p := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.1, 0.1, 0.16, 0.9)
		psb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		psb.set_border_width_all(2)
		psb.set_corner_radius_all(6)
		psb.set_content_margin_all(6)
		p.add_theme_stylebox_override("panel", psb)
		var l := Label.new()
		l.text = it["chip"]
		l.add_theme_font_size_override("font_size", 16)
		p.add_child(l)
		ui.chips.add_child(p)
	if Stats.relics.size() >= 5:
		_ach("r5")


func _show_banner(title: String, sub: String) -> void:
	ui.banner_t.text = title
	ui.banner_sub.text = sub
	ui.banner.visible = true
	ui.dim.visible = true


func _hide_banner() -> void:
	ui.banner.visible = false
	if not Stats.draft_open:
		ui.dim.visible = false


# ---------------- per-frame ----------------

func _process(delta: float) -> void:
	if player != null and is_instance_valid(player) and run_state == "playing":
		run_time += delta
		var k := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			k.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			k.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			k.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			k.x += 1.0
		if k != Vector2.ZERO:
			player.move_input = k.normalized()
		else:
			player.move_input = joystick.get_value()
		if Input.is_key_pressed(KEY_SPACE) or atk_held:
			player.attack()
		if Input.is_key_pressed(KEY_H):
			_toggle_hero(true)

		_tick_skill_ui(delta)

		# pelacakan ruangan -> kunci arena
		var ri := _room_at(player.global_position.z)
		if ri >= 0 and ri != current_room:
			current_room = ri
			_on_room_enter(ri)

		# preview hero ikut muter walau game pause? tidak perlu, layar hero punya sendiri
		# tutorial langkah 0: gerak
		if tut_active and tut_step == 0:
			moved_accum += player.global_position.distance_to(tut_last_pos)
			tut_last_pos = player.global_position
			if moved_accum > 1.2 * info.tile:
				tut_step = 1
				_tut_show("Ketuk tombol ATK merah untuk menebas")
				_quest_event("moved")

		# quest "moved": akumulasi gerak pemain
		if quest_idx < quest_steps.size() and String(quest_steps[quest_idx].get("kind", "")) == "moved":
			quest_moved += player.global_position.distance_to(quest_last_p)
			quest_last_p = player.global_position
			if quest_moved > 1.2 * info.tile:
				_quest_event("moved")

		# kombo kill: decay + label
		if combo_t > 0.0:
			combo_t -= delta
			if combo_t <= 0.0:
				_combo_set(0)

		# bar HP boss mengikuti sisa nyawa
		if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.activated:
			_boss_bar_show()
			var frac: float = clampf(boss_ref.hp / boss_ref.hp_max, 0.0, 1.0)
			ui.boss_fill.value = frac * 100.0
		else:
			_boss_bar_hide()

		# titik musuh di minimap
		map_t -= delta
		if map_t <= 0.0:
			map_t = 0.25
			_update_minimap()

		# peti harta — atau peti PALSU (mimic): 35% mulai lantai 2
		if not chest_opened and info.get("chest") != null and is_instance_valid(info.chest):
			if player.global_position.distance_to(info.chest.global_position) < 0.6 * info.tile:
				chest_opened = true
				_quest_event("open_chest")
				if mimic_pending:
					mimic_pending = false
					Sfx.play("mimic")
					trauma = 0.8
					_burst(info.chest.global_position, Color(1.0, 0.35, 0.2))
					toast("PETI PALSU! Itu bergerak!")
					for mk in range(2):
						var off := Vector3((mk - 0.5) * 0.9 * info.tile, 0, 0.7 * info.tile)
						_spawn_enemy({"pos": info.chest.global_position + off, "room": int(info.get("room_count", 1)) - 1}, "chaser", false)
				else:
					player.hp = Stats.get_stat("max_hp")
					player.hp_changed.emit(player.hp)
					Stats.add_xp(3)
					Sfx.play("chest")
					_burst(info.chest.global_position, Color(1.0, 0.85, 0.3))
					_souls(info.chest.global_position, 8, Color(1.0, 0.8, 0.35))
					M.paint(info.chest, M.toon(dungeon_tex, Color(0.45, 0.4, 0.32), 0.1))
					toast("Peti Harta: HP pulih penuh, +3 XP")

	if player != null and is_instance_valid(player) and cam != null:
		var s: float = info.get("tile", 4.0)
		var target: Vector3 = player.global_position + Vector3(0.0, 3.0 * s, 2.6 * s)
		cam.global_position = cam.global_position.lerp(target, 1.0 - pow(0.0001, delta))
		if trauma > 0.0:
			trauma = max(0.0, trauma - delta * 1.8)
			cam.global_position += Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)) * trauma * 0.18
		cam.look_at(player.global_position + Vector3(0, 0, -0.9 * s))


func _cam_snap() -> void:
	var s: float = info.get("tile", 4.0)
	if player != null and cam != null:
		cam.global_position = player.global_position + Vector3(0.0, 3.0 * s, 2.6 * s)
		cam.look_at(player.global_position + Vector3(0, 0, -0.9 * s))


# ---------------- autotest v4 ----------------

func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SAVED ", ProjectSettings.globalize_path(path))


func _nearest_foe() -> Node3D:
	var foes := get_tree().get_nodes_in_group("enemies")
	var best: Node3D = null
	var bd := 1e9
	for f in foes:
		var d: float = player.global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	return best


func _run_autotest() -> void:
	for i in range(20):
		await get_tree().process_frame
	_shot("res://out_v4_1_spawn.png")

	# bukti audio benar-benar berbunyi (bank .wav termuat)
	Sfx.play("click")
	await get_tree().process_frame
	print("SFX playing=%s last=%s" % [str(Sfx.any_playing()), Sfx.last_played])

	# bukti tabrakan: jalan ke barat, harus terhenti tembok
	var x0: float = player.global_position.x
	joystick.fake = Vector2(-1, 0)
	await get_tree().create_timer(1.6).timeout
	joystick.fake = Vector2.ZERO
	var dx: float = player.global_position.x - x0
	print("COLLISION dx=%.2f tile=%.2f (terhenti tembok bila |dx| < 3 tile)" % [dx, info.tile])
	await get_tree().create_timer(0.3).timeout

	# bukti serangan + senjata terpasang
	player.attack()
	await get_tree().create_timer(0.22).timeout
	print("ATK_ANIM=", player.ap.current_animation, " WEAPON=", Stats.weapon_id)
	_shot("res://out_v4_2_attack.png")
	await get_tree().create_timer(0.5).timeout

	# bukti GERBANG: ruangan 0 terkunci selama musuh hidup
	var g0 = gates.get(0)
	if g0 != null:
		print("GATE0 open=%s (harus false saat musuh hidup)" % str(g0.open))
		player.global_position = g0.global_position + Vector3(0, 0, 0.8 * info.tile)
		await get_tree().create_timer(0.2).timeout
		joystick.fake = Vector2(0, -1)
		await get_tree().create_timer(1.2).timeout
		joystick.fake = Vector2.ZERO
		var passed: bool = player.global_position.z < g0.global_position.z - 0.2 * info.tile
		print("GATE BLOCK passed=%s (harus false) pz=%.1f gate_z=%.1f" % [str(passed), player.global_position.z, g0.global_position.z])
		player.global_position = info.player_pos
		await get_tree().create_timer(0.2).timeout

	# bukti pickup senjata -> masuk inventaris
	var pk := spawn_weapon_drop(player.global_position + Vector3(0.6 * info.tile, 0, 0), "bone_axe")
	var tw := 0.0
	while is_instance_valid(pk) and tw < 3.0:
		var to: Vector3 = pk.global_position - player.global_position
		joystick.fake = Vector2(to.x, to.z).normalized()
		tw += 0.12
		await get_tree().create_timer(0.12).timeout
	joystick.fake = Vector2.ZERO
	print("PICKUP weapon=%s ATK=%.1f owned=%s" % [Stats.weapon_id, Stats.get_stat("atk"), str(Stats.owned_weapons)])
	_shot("res://out_v4_3_weapon.png")

	# bersihkan seluruh lantai (multi-ruangan + gerbang) dengan anti-mentok
	player.hp = Stats.get_stat("max_hp")
	player.hp_changed.emit(player.hp)
	var xp_mark := Stats.level * 1000 + Stats.xp
	var draft_shot := false
	var elapsed := 0.0
	var last_p: Vector3 = player.global_position
	var stuck := 0.0
	var strafe := 1.0
	while run_state == "playing" and elapsed < 150.0:
		while Stats.draft_open:
			if not draft_shot:
				await get_tree().process_frame
				await get_tree().process_frame
				_shot("res://out_v4_4_draft.png")
				draft_shot = true
			_pick_relic(0)
			await get_tree().create_timer(0.1).timeout
		var foe := _nearest_foe()
		if foe == null:
			break
		# waypoint: kalau musuh di ruangan lain, bidik pintu gerbangnya dulu
		var target: Vector3 = foe.global_position
		var ri_now := _room_at(player.global_position.z)
		if ri_now >= 0 and foe.room_idx != ri_now:
			var gi: int = ri_now if foe.room_idx > ri_now else foe.room_idx
			if gates.has(gi):
				target = gates[gi].global_position
				if player.global_position.distance_to(target) < 0.45 * info.tile:
					target = foe.global_position
		var d: float = player.global_position.distance_to(target)
		if foe.room_idx == ri_now and d <= info.tile * 0.7:
			joystick.fake = Vector2.ZERO
			player.move_input = Vector2.ZERO
			player.attack()
		elif d > info.tile * 0.25:
			var to2: Vector3 = target - player.global_position
			var mv := Vector2(to2.x, to2.z).normalized()
			if player.global_position.distance_to(last_p) < 0.04 * info.tile:
				stuck += 0.22
			else:
				stuck = 0.0
			if stuck > 0.66:
				strafe = -strafe
				stuck = 0.0
			if stuck > 0.3:
				mv = mv.rotated(1.2 * strafe)
			joystick.fake = mv
		else:
			joystick.fake = Vector2.ZERO
			player.move_input = Vector2.ZERO
			player.attack()
		if player.hp < 2.0:
			player.hp = Stats.get_stat("max_hp")
			player.hp_changed.emit(player.hp)
		last_p = player.global_position
		await get_tree().create_timer(0.22).timeout
		elapsed += 0.22
	joystick.fake = Vector2.ZERO
	player.move_input = Vector2.ZERO

	await get_tree().create_timer(1.2).timeout
	var all_open := true
	for gi in gates:
		if not gates[gi].open:
			all_open = false
	print("GATES all_open=%s (harus true setelah bersih)" % str(all_open))
	print("GEMS xp_mark=%d -> %d (naik = permata XP jalan)" % [xp_mark, Stats.level * 1000 + Stats.xp])
	_shot("res://out_v4_5_cleared.png")
	print("FASE1 state=%s kills=%d level=%d rooms=%d" % [run_state, Stats.kills, Stats.level, info.get("room_count", 1)])

	# turun lantai
	_on_banner_tap()
	for i in range(12):
		await get_tree().process_frame
	print("FLOOR2 enemies=%d biome=%s rooms=%d" % [get_tree().get_nodes_in_group("enemies").size(), biome["name"], info.get("room_count", 1)])

	# SKILL: paksa level supaya semua terbuka
	Stats.level = maxi(Stats.level, 6)
	var p0: Vector3 = player.global_position
	player.move_input = Vector2(0, -1)
	_cast_skill("dash")
	print("DBG dash_t=%.2f dir=%s speed=%.1f paused=%s state=%s" % [player.dash_t, str(player.dash_dir), player.speed, str(get_tree().paused), run_state])
	await get_tree().create_timer(0.45).timeout
	player.move_input = Vector2.ZERO
	print("SKILL dash dist=%.2f cd=%.1f (harus > 1.5)" % [player.global_position.distance_to(p0), skill_cd["dash"]])

	# dekati musuh untuk whirl + thunder
	var foe2 := _nearest_foe()
	var wt := 0.0
	while foe2 != null and wt < 10.0:
		foe2 = _nearest_foe()
		if foe2 == null:
			break
		var d2: float = player.global_position.distance_to(foe2.global_position)
		if d2 < info.tile * 0.8:
			break
		var to3: Vector3 = foe2.global_position - player.global_position
		joystick.fake = Vector2(to3.x, to3.z).normalized()
		wt += 0.2
		await get_tree().create_timer(0.2).timeout
	joystick.fake = Vector2.ZERO
	if foe2 != null:
		var hp0: float = foe2.hp
		_cast_skill("whirl")
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(foe2):
			print("SKILL whirl dmg=%.1f (harus > 0)" % (hp0 - foe2.hp))
		else:
			print("SKILL whirl membunuh musuh (dmg >= sisa hp)")
		foe2 = _nearest_foe()
		if foe2 != null:
			# teleport dekat supaya petir pasti kena (jangkauan 2.5 tile)
			player.global_position = foe2.global_position + Vector3(0.6 * info.tile, 0, 0)
			await get_tree().create_timer(0.1).timeout
			var hp1: float = foe2.hp
			_cast_skill("thunder")
			await get_tree().create_timer(0.18).timeout
			_shot("res://out_v4_6_skills.png")
			if is_instance_valid(foe2) and foe2.get("state") != "dead":
				print("SKILL thunder dmg=%.1f stun=%.2f (harus > 0)" % [hp1 - foe2.hp, foe2.stun_t])
			else:
				print("SKILL thunder membunuh musuh (dmg=%.1f tersalurkan)" % (hp1))

	# pause menu: buka -> screenshot -> resume, tidak boleh soft-lock
	_toggle_pause()
	for _i in range(6):
		await get_tree().process_frame
	_shot("res://out_v5_12_pause.png")
	print("PAUSE open=%s paused=%s (harus true)" % [pause_panel.visible, get_tree().paused])
	_toggle_pause()
	await get_tree().process_frame
	print("PAUSE resume=%s (harus true)" % (not get_tree().paused and not pause_panel.visible))

	# layar hero + ganti senjata dari inventaris
	_toggle_hero(true)
	await get_tree().process_frame
	await get_tree().process_frame
	_shot("res://out_v4_7_hero.png")
	var other: String = "rusty_blade" if Stats.weapon_id != "rusty_blade" else ("bone_axe" if Stats.owned_weapons.has("bone_axe") else String(Stats.owned_weapons[0]))
	_hero_equip(other)
	await get_tree().process_frame
	print("EQUIP weapon=%s (berubah dari layar hero)" % Stats.weapon_id)
	_toggle_hero(false)

	# mati -> retry dari lantai 1
	player.invuln = 0.0
	player.take_hit(player.global_position + Vector3(1, 0, 0), 999)
	await get_tree().create_timer(0.6).timeout
	_shot("res://out_v4_8_died.png")
	print("DEATH state=%s" % run_state)
	_on_banner_tap()
	for i in range(12):
		await get_tree().process_frame
	print("RETRY floor=%d state=%s" % [Stats.floor_num, run_state])
	# ---- v5: lantai BOSS (loncat ke 5 lewat jalur normal) ----
	Stats.floor_num = 4
	run_state = "cleared"
	_on_banner_tap()
	for i in range(16):
		await get_tree().process_frame
	var boss = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_boss:
			boss = e
	print("BOSS spawned=%s quest_idx=%d steps=%d" % [str(boss != null), quest_idx, quest_steps.size()])
	if boss != null:
		# aktifkan boss + cek bar HP
		player.global_position = boss.global_position + Vector3(0, 0, 3.0 * info.tile)
		await get_tree().create_timer(0.4).timeout
		print("BOSS activated=%s bar=%s hp=%.0f/%.0f" % [str(boss.activated), str(ui.boss_bar.visible), boss.hp, boss.hp_max])
		_shot("res://out_v5_9_boss.png")
		# enrage saat hp < 50%
		player.invuln = 9.0
		boss.hp = boss.hp_max * 0.45
		await get_tree().create_timer(0.4).timeout
		print("BOSS enraged=%s (harus true)" % str(boss.enraged))
		# slam AoE
		player.global_position = boss.global_position + Vector3(0.5 * info.tile, 0, 0.5 * info.tile)
		boss.slam_t = 0.0
		await get_tree().create_timer(1.3).timeout
		_shot("res://out_v5_10_slam.png")
		# summon antek
		var n0 := get_tree().get_nodes_in_group("enemies").size()
		boss.summon_t = 0.0
		await get_tree().create_timer(0.35).timeout
		var n1 := get_tree().get_nodes_in_group("enemies").size()
		print("BOSS summon %d -> %d (harus naik)" % [n0, n1])
		# bunuh boss -> quest boss_kill + victory
		boss.take_hit(player.global_position, 9999)
		await get_tree().create_timer(0.9).timeout
		print("BOSS dead=%s boss_kills=%d quest_idx=%d" % [str(boss_ref == null), Stats.boss_kills, quest_idx])
		_shot("res://out_v5_11_bossdown.png")

	# altar: kalau ada di lantai ini, picu + pilih berkat
	if shrine_ref != null and is_instance_valid(shrine_ref):
		_on_shrine_invoked(shrine_ref)
		for i in range(24):
			await get_tree().process_frame
			if dlg == null or not dlg.active:
				break
			if i > 4 and dlg._choices.size() > 0:
				dlg.choose(0)
		await get_tree().process_frame
		print("SHRINE buff_atk=%.2f paused=%s" % [Stats.buff_atk_pct, str(get_tree().paused)])

	print("FPS=", Engine.get_frames_per_second())
	print("SAVE=", FileAccess.get_file_as_string("user://save.json"))
	print("AUTOTEST V5 DONE")
	get_tree().quit()
