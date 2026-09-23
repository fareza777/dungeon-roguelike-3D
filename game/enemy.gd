extends CharacterBody3D
class_name Enemy
const M = preload("res://materials.gd")
const EDB = preload("res://enemies_db.gd")
const PROJ = preload("res://projectile.gd")
# Musuh berbasis arketipe (enemies_db.gd): chaser, rogue (dash), mage (ranged),
# brute (tanky). Varian elite = stat multiplier + tint merah.
# AI: idle -> chase (mage jaga jarak) -> windup (telegraph) -> strike -> recover.

signal died(enemy)
const FPOOL = preload("res://fire_pool.gd")
signal summon_requested(boss)

var arch_id := "chaser"
var elite := false
var hp := 3.0
var hp_max := 3.0
var xp_val := 1
var state := "idle"
var aggro_range := 9.0
var attack_range := 2.2
var prefer_range := 0.0
var ranged := false
var dash := false
var is_boss := false
var tier_idx := 0
var is_bomber := false
var is_summoner := false
var proj_speed := 0.0
var kb_resist := 0.0
var speed := 4.0
var dmg := 1
var windup_t := 0.45
var bounds := {}
var room_tile := 4.0
var mat: ShaderMaterial
var ap: AnimationPlayer
var kb := Vector3.ZERO
var state_t := 0.0
var anim_lock := 0.0

# bilah hp mini di atas kepala (khusus elite, muncul setelah kena hit)
var hpbar_bg: Sprite3D = null
var hpbar_fg: Sprite3D = null
var hpbar_tag: Label3D = null
var mark_tag: Label3D = null
static var _bar_tex: Texture2D = null
const BAR_W := 0.6


static func _get_bar_tex() -> Texture2D:
	if _bar_tex == null:
		var img := Image.create(64, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_bar_tex = ImageTexture.create_from_image(img)
	return _bar_tex
var room_idx := 0
var activated := true
var stun_t := 0.0
var enraged := false
var golden := false
var nemesis := false
var is_lurker := false # arketipe penyergap: sembunyi sampai pemain mendekat
var is_slammer := false # golem: pukulannya mengguncang tanah di radius lebar
var lurk_revealed := false
var lurk_warned := false
var model_ref: Node3D = null
var affix := ""
var jailer := false
var is_weeper := false
var is_warper := false
var is_hexer := false
var is_spiky := false
var warp_t := 4.0
var champion := false # elite sarang sang juara — drop senjata terjamin
var sunder_t := 0.0 # debuff SUNDERING BLOW: terima +30% damage
var chant_t := 2.5
var _base_scale := Vector3.ONE
var slam_t := 4.0
var summon_t := 11.0
var banter_75 := false
var banter_25 := false
var hex_t := 0.0   # Hex Staff: musuh bertanda menerima +25% damage
var slow_t := 0.0  # Frost Fang: beku — 50% speed
var burn_t := 0.0  # Ember Mace: terbakar — damage berkala
var _burn_acc := 0.0


func stun(t: float) -> void:
	if state == "dead":
		return
	stun_t = maxf(stun_t, t)
	state = "recover"
	state_t = maxf(state_t, t)
	scale = _base_scale
	if mat != null:
		mat.set_shader_parameter("flash", 0.6)


func setup(p_mat: ShaderMaterial, tile: float, b: Dictionary, p_arch: String, p_elite: bool, floor_num: int) -> void:
	mat = p_mat
	room_tile = tile
	bounds = b
	arch_id = p_arch
	elite = p_elite
	var a: Dictionary = EDB.get_arch(arch_id)
	var hp_growth := 1.0 + 0.15 * float(floor_num - 1)
	# New Game+: tiap kemenangan menambah kedalaman — musuh lebih keras + cepat
	var ng: float = float(Stats.ng_plus)
	hp_growth += 0.35 * ng
	hp = a["hp"] * hp_growth
	speed = a["spd"] * tile * (1.0 + 0.08 * ng)
	aggro_range = a["aggro"] * tile
	attack_range = a["reach"] * tile
	prefer_range = a.get("prefer", 0.0) * tile
	windup_t = a["windup"]
	dmg = a["dmg"] + int(ng)
	xp_val = a["xp"] + int(ng)
	ranged = a.get("ranged", false)
	dash = a.get("dash", false)
	proj_speed = a.get("proj_speed", 0.0) * tile
	kb_resist = a.get("kb_resist", 0.0)
	is_boss = a.get("boss", false)
	is_bomber = a.get("bomber", false)
	is_summoner = a.get("summoner", false)
	jailer = bool(a.get("jailer", false))
	is_weeper = bool(a.get("chanter", false))
	is_warper = bool(a.get("warper", false))
	is_hexer = bool(a.get("hexer", false))
	is_spiky = bool(a.get("spiky", false))
	is_lurker = bool(a.get("lurks", false))
	is_slammer = bool(a.get("slams", false))
	if is_summoner:
		summon_t = 9.0
	var sc: float = a["scale"]
	if elite:
		hp *= EDB.ELITE["hp_mult"]
		dmg += EDB.ELITE["dmg_add"]
		xp_val *= EDB.ELITE["xp_mult"]
		sc *= EDB.ELITE["scale_mult"]
		speed *= EDB.ELITE["spd_mult"]
		affix = ["swift", "bulwark", "vengeful", "siphon", "volatile", "mother", "frostbite", "warden", "thorned", "nightmare", "hoarded"][randi() % 11]
		match affix:
			"swift":
				speed *= 1.45
			"bulwark":
				hp *= 1.5
				xp_val = int(xp_val * 1.25)
			"siphon":
				# pukulan elite ini menyedot kombo pemain sampai nol
				xp_val = int(xp_val * 1.25)
			"frostbite":
				# pukulan elite ini mendinginkan pemain 55% speed 3s
				xp_val = int(xp_val * 1.25)
			"warden":
				# pukulan elite ini MENJERAT pemain di tempat 1s
				xp_val = int(xp_val * 1.25)
			"volatile":
				# meledak saat mati — bonus XP sebagai imbalan bahayanya
				xp_val = int(xp_val * 1.5)
			"thorned":
				# pukulan jarak dekat melukai penyerang — bonus XP
				xp_val = int(xp_val * 1.25)
			"nightmare":
				# elite ini bangkit sekali lagi pada 40% HP — bonus XP
				xp_val = int(xp_val * 1.6)
			"hoarded":
				# elite ini menelan senjata — dijatuhkan saat mati
				xp_val = int(xp_val * 1.3)
	scale = Vector3.ONE * sc
	_base_scale = scale
	hp_max = hp
	if elite:
		print("SPAWN ELITE ", arch_id)
	if is_boss:
		print("SPAWN BOSS hp=%.0f" % hp)


func _ready() -> void:
	add_to_group("enemies")
	ap = M.anim_player(self)
	if mat != null:
		M.paint(self, mat)
	# kapsul tabrakan: layer 4 (musuh), menabrak world(1) + player(2) + musuh(4)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.15 * room_tile
	cap.height = 0.5 * room_tile
	cs.shape = cap
	cs.position.y = 0.28 * room_tile
	add_child(cs)
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	if (elite or nemesis) and not is_boss:
		_mk_hpbar()
		_mk_aura()
	if is_lurker:
		model_ref = get_child(0)
		if model_ref != null:
			model_ref.visible = false
	M.play_fuzzy(ap, ["idle"])


func _mk_hpbar() -> void:
	var t := _get_bar_tex()
	var bw := BAR_W * room_tile
	hpbar_bg = Sprite3D.new()
	hpbar_bg.texture = t
	hpbar_bg.pixel_size = bw / 64.0
	hpbar_bg.modulate = Color(0.1, 0.08, 0.1, 0.85)
	hpbar_bg.position = Vector3(0, 1.12 * room_tile, 0)
	hpbar_bg.visible = false
	add_child(hpbar_bg)
	hpbar_fg = Sprite3D.new()
	hpbar_fg.texture = t
	hpbar_fg.pixel_size = bw / 64.0
	hpbar_fg.modulate = Color(1.0, 0.3, 0.22, 0.95)
	hpbar_fg.position = Vector3(0, 1.12 * room_tile, 0.02)
	hpbar_fg.visible = false
	add_child(hpbar_fg)
	if affix != "" or nemesis:
		hpbar_tag = Label3D.new()
		hpbar_tag.text = ("NEMESIS " + affix.to_upper()).strip_edges() if nemesis else affix.to_upper()
		hpbar_tag.font_size = 42
		hpbar_tag.modulate = Color(1.0, 0.75, 0.3)
		hpbar_tag.outline_size = 14
		hpbar_tag.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
		hpbar_tag.position = Vector3(0, 1.26 * room_tile, 0)
		hpbar_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		hpbar_tag.visible = false
		add_child(hpbar_tag)


func _mk_aura() -> void:
	# cincin merah berdenyut di bawah elite — penanda bahaya instan
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.30
	torus.outer_radius = 0.40
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.25, 0.18, 0.7)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.2, 0.12)
	rm.emission_energy_multiplier = 1.8
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = rm
	ring.mesh = torus
	ring.position.y = 0.06
	add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "scale", Vector3(1.15, 1.15, 1.15), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ring, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _upd_hpbar() -> void:
	if hpbar_bg == null:
		return
	var frac := clampf(hp / hp_max, 0.0, 1.0)
	var show := frac < 1.0 and frac > 0.0
	hpbar_bg.visible = show
	hpbar_fg.visible = show
	if hpbar_tag != null:
		hpbar_tag.visible = show
	hpbar_fg.scale.x = frac
	hpbar_fg.position.x = -0.5 * BAR_W * room_tile * (1.0 - frac)


func _player() -> Node3D:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return null
	return ps[0]


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self:
			continue
		var d: Vector3 = global_position - o.global_position
		d.y = 0
		var dd := d.length()
		if dd < 0.9 and dd > 0.001:
			push += d.normalized() * (0.9 - dd) * room_tile * 1.5
	return push


func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	anim_lock = max(0.0, anim_lock - delta)
	hex_t = maxf(0.0, hex_t - delta)
	slow_t = maxf(0.0, slow_t - delta)
	sunder_t = maxf(0.0, sunder_t - delta)
	# tanda debuff melayang: BURNING / HEXED / SUNDERED
	var mtxt := ""
	var mcol := Color(1.0, 0.55, 0.4)
	if burn_t > 0.0:
		mtxt = "BURNING"
	elif hex_t > 0.0:
		mtxt = "HEXED"
		mcol = Color(0.9, 0.5, 1.0)
	elif sunder_t > 0.0:
		mtxt = "SUNDERED"
		mcol = Color(1.0, 0.8, 0.35)
	if mtxt != "":
		if mark_tag == null:
			mark_tag = Label3D.new()
			mark_tag.font_size = 38
			mark_tag.outline_size = 10
			mark_tag.outline_modulate = Color(0.08, 0.02, 0.08, 0.9)
			mark_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			mark_tag.position = Vector3(0, 1.0 * room_tile, 0)
			add_child(mark_tag)
		mark_tag.text = mtxt
		mark_tag.modulate = mcol
		mark_tag.visible = true
	elif mark_tag != null:
		mark_tag.visible = false
	if burn_t > 0.0:
		burn_t -= delta
		_burn_acc += delta
		if _burn_acc >= 0.7:
			_burn_acc = 0.0
			take_hit(global_position, maxf(1.0, hp_max * 0.06))
			return
	if is_warper:
		warp_t -= delta
		if warp_t <= 0.0:
			var pw := _player()
			if pw != null and global_position.distance_to(pw.global_position) < aggro_range * 1.3:
				warp_t = randf_range(3.5, 5.0)
				var off := Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				if off.length() < 0.3:
					off = Vector3(0.6, 0, 0)
				global_position = pw.global_position + off.normalized() * prefer_range
				global_position.x = clampf(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
				global_position.z = clampf(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
				Sfx.play("dash")
				var mw := get_tree().current_scene
				if mw != null and mw.has_method("_burst"):
					mw._burst(global_position, Color(0.6, 0.4, 1.0))
			else:
				warp_t = 0.5
	if stun_t > 0.0:
		stun_t -= delta
		velocity = kb
		kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
		move_and_slide()
		global_position.y = 0.0
		return
	if is_lurker and not lurk_revealed:
		var lp := _player()
		var lrange := 1.3
		if Stats.relics.has("mata_perenungan"):
			lrange = 2.6
		if activated and lp != null and lp.get("dead") != true:
			var ld := global_position.distance_to(lp.global_position)
			if ld < lrange * room_tile:
				_lurk_reveal()
				return
			if ld < 2.4 * room_tile and not lurk_warned:
				lurk_warned = true
				Sfx.play("page")
				var m2 := get_tree().current_scene
				if m2 != null and m2.has_method("_damage_number"):
					m2._damage_number(global_position + Vector3(0, 0.5 * room_tile, 0), "...", Color(0.45, 0.45, 0.65), false)
			return
		return
	if not activated:
		velocity = kb
		kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
		move_and_slide()
		global_position.y = 0.0
		if anim_lock <= 0.0:
			M.play_fuzzy(ap, ["idle"])
		return
	var p := _player()
	if p == null:
		return
	var to: Vector3 = p.global_position - global_position
	to.y = 0
	var dist := to.length()
	state_t -= delta
	if is_weeper:
		chant_t -= delta
		if chant_t <= 0.0:
			chant_t = 3.0
			_chant()

	if p.get("dead") == true and state != "idle":
		state = "idle"
		if anim_lock <= 0.0:
			M.play_fuzzy(ap, ["idle"])

	# boss: fase 2 enrage + timer slam + panggil anak buah
	if is_boss and activated and state != "dead":
		if not enraged and hp <= hp_max * 0.5:
			enraged = true
			speed *= 1.4
			windup_t *= 0.7
			Sfx.play("roar")
			if mat != null:
				mat.set_shader_parameter("tint", Color(1.35, 0.35, 0.3))
			var m := get_tree().current_scene
			if m != null and m.has_method("_boss_enraged"):
				m._boss_enraged()
			print("BOSS ENRAGE")
		slam_t -= delta
		summon_t -= delta
		if state == "chase" and slam_t <= 0.0 and dist < 1.5 * room_tile:
			slam_t = 7.5 if not enraged else 5.5
			state = "slamming"
			state_t = 0.95
			_slam_telegraph()
		if summon_t <= 0.0:
			summon_t = 15.0 if not enraged else 9.0
			summon_requested.emit(self)
	# necromancer: membangkitkan antek tulang berkala
	if is_summoner and activated and state != "dead":
		summon_t -= delta
		if summon_t <= 0.0:
			summon_t = 13.0
			summon_requested.emit(self)

	match state:
		"idle":
			velocity = Vector3.ZERO
			if dist < aggro_range:
				state = "chase"
		"chase":
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 10.0)
			var engage := attack_range
			if ranged:
				engage = prefer_range
			if dist < engage:
				state = "windup"
				state_t = windup_t
				velocity = Vector3.ZERO
				scale = _base_scale * 1.06
				if mat != null:
					mat.set_shader_parameter("flash", 0.4)
				if anim_lock <= 0.0:
					M.play_fuzzy(ap, ["idle_combat", "idle"])
			else:
				var dir := to.normalized()
				# mage mundur kalau player terlalu dekat
				if ranged and dist < prefer_range * 0.55:
					dir = -dir
				velocity = dir * speed * (0.5 if slow_t > 0.0 else 1.0) + _separation() + kb
				if anim_lock <= 0.0:
					M.play_fuzzy(ap, ["run", "walk"])
		"windup":
			velocity = Vector3.ZERO
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 6.0)
			if is_bomber and mat != null:
				mat.set_shader_parameter("flash", 0.4 + 0.5 * absf(sin(state_t * 22.0)))
			# squash antisipasi: balik ke ukuran normal begitu strike tiba
			var wp := clampf(state_t / maxf(windup_t, 0.001), 0.0, 1.0)
			scale = _base_scale * (1.0 + 0.06 * wp)
			if state_t <= 0.0:
				state = "strike"
				scale = _base_scale
				if mat != null:
					var tw := create_tween()
					tw.tween_property(mat, "shader_parameter/flash", 0.0, 0.1)
				if is_bomber:
					_explode()
				elif ranged:
					anim_lock = M.play_action(ap, ["spellcast_shoot", "spellcast"], 1.2) * 0.7
					await get_tree().create_timer(0.22).timeout
					if state == "strike":
						var q2 := _player()
						if q2 != null and q2.get("dead") != true:
							var pr = PROJ.new()
							get_parent().add_child(pr)
							if is_hexer:
								pr.effect = "silence"
								if pr.orb != null:
									var hm: StandardMaterial3D = pr.orb.mesh.material
									hm.albedo_color = Color(1.0, 0.25, 0.4)
									hm.emission = Color(0.9, 0.2, 0.35)
							pr.launch(global_position + Vector3(0, 1.0 * scale.x, 0), q2.global_position + Vector3(0, 0.9, 0), proj_speed, dmg, 0.35 * room_tile)
						state = "recover"
						state_t = 1.1
				else:
					anim_lock = M.play_action(ap, ["melee_attack"], 1.3) * 0.7
					if dash:
						kb += Vector3(sin(rotation.y), 0, cos(rotation.y)) * room_tile * 2.8
					await get_tree().create_timer(0.13).timeout
					if state == "strike":
						var q := _player()
						if q != null and q.get("dead") != true:
							var dto: Vector3 = q.global_position - global_position
							dto.y = 0
							if dto.length() < attack_range * 1.3:
								q.take_hit(global_position, dmg)
								if is_slammer:
									_shock()
								if jailer and q.get("dead") != true:
									q.set("root_t", 1.2)
									var mm3 := get_tree().current_scene
									if mm3 != null and mm3.has_method("_damage_number"):
										mm3._damage_number(q.global_position, "CAGED!", Color(0.65, 0.45, 1.0), true)
									Sfx.play("gate")
								if affix == "frostbite":
									q.set("chill_t", 3.0)
									var mm4 := get_tree().current_scene
									if mm4 != null and mm4.has_method("_damage_number"):
										mm4._damage_number(q.global_position, "CHILLED", Color(0.5, 0.75, 1.0), true)
								if affix == "warden" and q.get("dead") != true:
									q.set("root_t", 1.0)
									var mm5 := get_tree().current_scene
									if mm5 != null and mm5.has_method("_damage_number"):
										mm5._damage_number(q.global_position, "BOUND", Color(0.8, 0.5, 1.1), true)
									Sfx.play("gate")
								if affix == "siphon":
									var mm := get_tree().current_scene
									if mm != null and mm.get("combo") != null and int(mm.combo) > 0 and mm.has_method("_combo_set"):
										mm._combo_set(0)
										if mm.has_method("_damage_number"):
											mm._damage_number(q.global_position, "COMBO SIPHONED", Color(0.5, 0.65, 1.0), true)
										Sfx.play("deny")
						state = "recover"
						state_t = 0.7
		"slamming":
			velocity = Vector3.ZERO
			if state_t <= 0.0:
				var dto2: Vector3 = p.global_position - global_position
				dto2.y = 0
				if dto2.length() < 1.35 * room_tile and p.get("dead") != true:
					p.take_hit(global_position, dmg + 1)
				_shock()
				_tier_slam()
				state = "recover"
				state_t = 0.8
		"strike":
			velocity = Vector3.ZERO
		"recover":
			velocity = Vector3.ZERO
			if state_t <= 0.0:
				state = "chase"

	kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
	move_and_slide()
	global_position.x = clamp(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
	global_position.z = clamp(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
	global_position.y = 0.0


# lingkar telegraph merah sebelum slam boss
func _slam_telegraph() -> void:
	var mi := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.42
	tor.outer_radius = 0.5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.2, 0.15, 0.85)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.15, 0.1)
	m.emission_energy_multiplier = 3.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = m
	mi.mesh = tor
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.2, 0)
	mi.scale = Vector3.ONE * 0.4 * room_tile
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.35 * room_tile, 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mi.queue_free)


func _shock() -> void:
	var mi := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.44
	tor.outer_radius = 0.5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.5, 0.2, 0.9)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.4, 0.1)
	m.emission_energy_multiplier = 4.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = m
	mi.mesh = tor
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.25, 0)
	mi.scale = Vector3.ONE * 0.3 * room_tile
	Sfx.play("thunder")
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.6 * room_tile, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.2)
	tw.tween_callback(mi.queue_free)


# gimmick per-tipe raja setelah slam
func _tier_slam() -> void:
	match tier_idx:
		1:  # EMBER — meneteskan 3 kolam api bertahan 4s
			for _i in range(3):
				var fp := FPOOL.new()
				get_parent().add_child(fp)
				fp.global_position = global_position + Vector3(randf_range(-1.1, 1.1), 0, randf_range(-1.1, 1.1)) * room_tile
				fp.setup(room_tile)
		2:  # FROST — membekukan: pemain 55% speed selama 3s
			var p2 := _player()
			if p2 != null and p2.get("dead") != true:
				p2.set("chill_t", 3.0)
		3:  # FERAL — makin cepat setiap slam
			speed = minf(speed * 1.12, 4.5 * room_tile)
		_:  # UNDYING (lantai 25) — mewarisi semua kekuatan
			for _i in range(2):
				var fp2 := FPOOL.new()
				get_parent().add_child(fp2)
				fp2.global_position = global_position + Vector3(randf_range(-1.1, 1.1), 0, randf_range(-1.1, 1.1)) * room_tile
				fp2.setup(room_tile)
			var p3 := _player()
			if p3 != null and p3.get("dead") != true:
				p3.set("chill_t", 2.5)
			speed = minf(speed * 1.08, 4.5 * room_tile)


# bomber: meledak — luka player DAN musuh lain di radius
func _explode() -> void:
	var p := _player()
	var r := 1.0 * room_tile
	if p != null and p.get("dead") != true:
		var dto: Vector3 = p.global_position - global_position
		dto.y = 0
		if dto.length() < r:
			p.take_hit(global_position, dmg)
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self:
			continue
		var d2: Vector3 = o.global_position - global_position
		d2.y = 0
		if d2.length() < r:
			o.take_hit(global_position, dmg * 0.5)
	_shock()
	hp = 0.0
	state = "dead"
	remove_from_group("enemies")
	if mat != null:
		mat.set_shader_parameter("flash", 1.0)
	anim_lock = M.play_action(ap, ["death"], 1.2)
	died.emit(self)


func _lurk_reveal() -> void:
	lurk_revealed = true
	if model_ref != null:
		model_ref.visible = true
	speed *= 1.3
	Sfx.play("roar")
	var ml3 := get_tree().current_scene
	if ml3 != null:
		if ml3.has_method("_burst"):
			ml3._burst(global_position, Color(0.9, 0.85, 1.15))
		if ml3.has_method("_damage_number"):
			ml3._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "LURKER!", Color(0.9, 0.85, 1.2), false)


func take_hit(from_pos: Vector3, dmg_taken: float) -> void:
	if state == "dead":
		return
	if is_lurker and not lurk_revealed:
		_lurk_reveal()
	if hex_t > 0.0:
		dmg_taken *= 1.25
	if sunder_t > 0.0:
		dmg_taken *= 1.3
	hp -= dmg_taken
	Sfx.play("hit")
	if (is_spiky or affix == "thorned") and state != "dead":
		var p3 := _player()
		if p3 != null and p3.get("dead") != true and p3.global_position.distance_to(from_pos) < 0.5 * room_tile:
			p3.take_hit(global_position, 0.5)
			var msp := get_tree().current_scene
			if msp != null and msp.has_method("_damage_number"):
				msp._damage_number(p3.global_position + Vector3(0, 0.5 * room_tile, 0), "SPIKED", Color(1.0, 0.6, 0.2), false)
	if is_boss and hp > 0.0:
		var frac: float = hp / hp_max
		var mb := get_tree().current_scene
		if not banter_75 and frac <= 0.75:
			banter_75 = true
			if mb != null and mb.has_method("_boss_banter"):
				mb._boss_banter(0)
		elif not banter_25 and frac <= 0.25:
			banter_25 = true
			if mb != null and mb.has_method("_boss_banter"):
				mb._boss_banter(1)
	var away: Vector3 = global_position - from_pos
	away.y = 0
	kb = away.normalized() * room_tile * 1.4 * (1.0 - kb_resist)
	if mat != null:
		mat.set_shader_parameter("flash", 1.0)
		var tw := create_tween()
		tw.tween_property(mat, "shader_parameter/flash", 0.0, 0.2)
	if hp <= 0:
		state = "dead"
		remove_from_group("enemies")
		if affix == "vengeful":
			var p := _player()
			if p != null and p.get("dead") != true:
				var dv: Vector3 = p.global_position - global_position
				dv.y = 0
				if dv.length() < 1.0 * room_tile:
					p.take_hit(global_position, dmg * 0.6)
		if affix == "volatile":
			var p2 := _player()
			if p2 != null and p2.get("dead") != true:
				var dv2: Vector3 = p2.global_position - global_position
				dv2.y = 0
				if dv2.length() < 1.6 * room_tile:
					p2.take_hit(global_position, dmg * 0.8)
			var mm2 := get_tree().current_scene
			if mm2 != null:
				if mm2.has_method("_shock_ring"):
					mm2._shock_ring(global_position)
				if mm2.has_method("_burst"):
					mm2._burst(global_position, Color(1.0, 0.4, 1.0))
		anim_lock = M.play_action(ap, ["death"], 1.0)
		died.emit(self)
	else:
		anim_lock = max(anim_lock, M.play_action(ap, ["hit_"], 1.4) * 0.6)
	_upd_hpbar()


func _chant() -> void:
	var m := get_tree().current_scene
	var healed := 0
	for f in get_tree().get_nodes_in_group("enemies"):
		if f == self or f.get("state") == "dead":
			continue
		if f.global_position.distance_to(global_position) < 2.0 * room_tile and float(f.hp) < float(f.hp_max):
			f.hp = minf(f.hp_max, f.hp + 1.0)
			healed += 1
			if m != null and m.has_method("_damage_number"):
				m._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "+1", Color(0.4, 1.0, 0.55), false)
	if healed > 0:
		Sfx.play("shrine")
		if m != null and m.has_method("_shock_ring"):
			m._shock_ring(global_position)
		if m != null and m.has_method("_damage_number"):
			m._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "WAILS...", Color(0.5, 1.0, 0.6), true)
