extends Node3D
# Orchestrator roguelike v4: lantai multi-ruangan + gerbang portcullis (kunci
# arena), skill aktif bercooldown, permata XP magnet, draft relic, biome,
# tutorial, layar hero dengan preview 3D + inventaris senjata, autotest v4.

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
	Stats.pending_restore = false
	Stats.runs += 1
	Stats.save_game()
	Stats.xp_changed.connect(_update_xp)
	Stats.leveled_up.connect(_on_leveled_up)
	Stats.relics_changed.connect(_rebuild_chips)
	_new_run(seed_val)
	Sfx.play_music()
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
	var elite_chance: float = minf(0.08 + 0.02 * Stats.floor_num, 0.3)
	var table: Array = biome["enemies"]
	for sp in info.enemy_spawns:
		_spawn_enemy(sp, table[rng.randi_range(0, table.size() - 1)], rng.randf() < elite_chance)
	ui.floor_label.text = "Lantai %d • %s" % [Stats.floor_num, biome["name"]]
	_update_hp(Stats.current_hp)
	_update_xp(Stats.xp, Stats.xp_need(), Stats.level)
	_rebuild_chips()
	_hide_banner()
	_cam_snap()
	tut_active = not Stats.tutorial_done and Stats.floor_num == 1 and not autotest
	tut_step = 0
	moved_accum = 0.0
	if tut_active:
		_tut_show("Geser jempolmu di sisi kiri layar untuk bergerak")
		tut_last_pos = player.global_position
	else:
		_tut_hide()
	if Stats.floor_num > 1:
		Sfx.play("door")
	print("ROOM seed=%d floor=%d biome=%s rooms=%d enemies=%d gates=%d" % [seed_val, Stats.floor_num, biome["name"], info.get("room_count", 1), info.enemy_spawns.size(), gates.size()])


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
	if _room_alive(ri) > 0:
		_set_room_gates(ri, false)
		if ri > 0:
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


func _on_player_hp(hp: float) -> void:
	Stats.current_hp = hp
	_update_hp(hp)


func _on_player_attacked() -> void:
	if tut_active and tut_step == 1:
		tut_step = 2
		_tut_show("Habisi semua skeleton di lantai ini!")


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
	e.died.connect(_on_enemy_died)


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
	Sfx.play("death")
	Stats.count_kill()
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
	# permata XP terakhir, supaya logika gerbang di atas tidak keganggu bila gem gagal
	_spawn_gems(e.global_position, e.xp_val)


func _on_player_died() -> void:
	print("PLAYER DIED floor=%d" % Stats.floor_num)
	run_state = "dead"
	Stats.note_floor()
	Stats.clear_run()
	Stats.runs += 1
	Stats.save_game()
	_tut_hide()
	_show_banner("YOU DIED", "Lantai %d • %s\nketuk untuk mengulang — Terbaik: Lantai %d" % [Stats.floor_num, biome["name"], Stats.best_floor])


func _on_banner_tap() -> void:
	if run_state == "cleared":
		Stats.floor_num += 1
		Stats.note_floor()
		_new_run(rng.randi())
	elif run_state == "dead":
		Stats.reset_run()
		_new_run(rng.randi())


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
	var first_btn: Button = null
	for i in range(draft_choices.size()):
		var it: Dictionary = ITEMS.DB[draft_choices[i]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(148, 190)
		b.text = "%s\n\n%s\n\n%s" % [it["chip"], it["name"], it["desc"]]
		b.add_theme_font_size_override("font_size", 20)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.13, 0.2, 1.0)
		sb.border_color = ITEMS.RARITY_COLORS[int(it["rarity"])]
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		b.add_theme_stylebox_override("normal", sb)
		var idx := i
		b.pressed.connect(func() -> void: Sfx.play("click"); _pick_relic(idx))
		ui.draft_cards.add_child(b)
		if first_btn == null:
			first_btn = b
	ui.draft.visible = true
	ui.dim.visible = true
	get_tree().paused = true
	if first_btn != null:
		first_btn.grab_focus()
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
	_damage_number(pos, str(int(round(dmg))), Color(1.0, 0.5, 0.15) if crit else Color(1.0, 0.85, 0.3), crit)
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.09 if crit else 0.05, true, false, true).timeout
	Engine.time_scale = 1.0


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

	var chips := HBoxContainer.new()
	chips.anchor_top = 1.0
	chips.anchor_bottom = 1.0
	chips.offset_left = 16
	chips.offset_top = -60
	chips.offset_bottom = -16
	chips.add_theme_constant_override("separation", 6)
	layer.add_child(chips)
	ui["chips"] = chips

	# kartu tutorial
	var tut := PanelContainer.new()
	tut.anchor_left = 0.5
	tut.anchor_right = 0.5
	tut.offset_left = -240
	tut.offset_right = 240
	tut.offset_top = 110
	tut.offset_bottom = 160
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
	lb.visible = false
	layer.add_child(lb)
	ui["lvl_banner"] = lb

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.visible = false
	layer.add_child(dim)
	ui["dim"] = dim

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
	vb.add_child(t)
	vb.add_child(sub)
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
	var full := int(ceil(hp))
	for i in range(cells.size()):
		cells[i].color = Color(0.85, 0.15, 0.2) if i < full else Color(0.25, 0.1, 0.12)


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
		if Input.is_key_pressed(KEY_SPACE):
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

		# peti harta
		if not chest_opened and info.get("chest") != null and is_instance_valid(info.chest):
			if player.global_position.distance_to(info.chest.global_position) < 0.6 * info.tile:
				chest_opened = true
				player.hp = Stats.get_stat("max_hp")
				player.hp_changed.emit(player.hp)
				Stats.add_xp(3)
				Sfx.play("chest")
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
	print("FPS=", Engine.get_frames_per_second())
	print("SAVE=", FileAccess.get_file_as_string("user://save.json"))
	print("AUTOTEST V4 DONE")
	get_tree().quit()
