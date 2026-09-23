extends CharacterBody3D
class_name Player
const M = preload("res://materials.gd")
const WDB = preload("res://weapons_db.gd")
# Stats-driven, tabrakan kapsul asli, gerakan berakselerasi,
# senjata terpasang ke handslot.r dan ikut animasi rig.

signal died
signal hp_changed(hp)
signal hit_landed(pos, dmg, crit)
signal attacked
signal stepped(pos)
signal revived

var speed := 6.0
var chill_t := 0.0
var weak_t := 0.0
var salvage_n := 0
var ambushed_ids := {}
var root_t := 0.0 # Gaoler: terjerat, tak bisa bergerak (dash masih bisa kabur)
var silence_t := 0.0
var venom_t := 0.0
var hp := 5.0
var max_hp := 5.0
var attack_cooldown := 0.45
var cd := 0.0
var invuln := 0.0
var dead := false
var hit_n := 0
var move_input := Vector2.ZERO
var bounds := {}
var room_tile := 4.0
var mat: ShaderMaterial
var ap: AnimationPlayer
var kb := Vector3.ZERO
var base_v := Vector3.ZERO
var anim_lock := 0.0
var slot_r: Node3D = null
var body_cs: CollisionShape3D = null
var dash_t := 0.0
var dash_atk_t := 0.0
var dash_dir := Vector3.ZERO
var step_t := 0.0
var last_killer := ""
var kings_n := 0 # counter King's Edge: tiap hit ke-5 meledak


func dash_burst(dir: Vector3) -> void:
	if dead:
		return
	dash_t = 0.22
	dash_atk_t = 1.5
	dash_dir = Vector3(dir.x, 0, dir.z).normalized()
	invuln = maxf(invuln, 0.4)
	anim_lock = maxf(anim_lock, 0.22)
	rotation.y = atan2(dash_dir.x, dash_dir.z)


func setup(p_mat: ShaderMaterial, tile: float, b: Dictionary) -> void:
	mat = p_mat
	room_tile = tile
	bounds = b
	refresh_stats()
	hp = Stats.current_hp


func refresh_stats() -> void:
	max_hp = Stats.get_stat("max_hp")
	speed = 1.45 * room_tile * Stats.get_stat("speed")
	attack_cooldown = 0.45 / Stats.get_stat("atk_speed")


func _ready() -> void:
	add_to_group("player")
	ap = M.anim_player(self)
	if mat != null:
		M.paint(self, mat)
	# kapsul tabrakan: layer 2 (player), menabrak world(1) + musuh(4)
	body_cs = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.15 * room_tile
	cap.height = 0.5 * room_tile
	body_cs.shape = cap
	body_cs.position.y = 0.28 * room_tile
	add_child(body_cs)
	collision_layer = 2
	collision_mask = 1 | 4
	slot_r = _find_hand_slot(self)
	equip_weapon(Stats.weapon_id)
	M.play_fuzzy(ap, ["idle"])


func _find_hand_slot(node: Node) -> Node3D:
	var nm: String = node.name.to_lower().replace(".", "").replace("_", "")
	if nm == "handslotr":
		return node as Node3D
	for c in node.get_children():
		var r := _find_hand_slot(c)
		if r != null:
			return r
	return null


func equip_weapon(id: String) -> void:
	Stats.equip_weapon(id)
	refresh_stats()
	if slot_r == null:
		return
	for c in slot_r.get_children():
		c.queue_free()
	var w: Dictionary = WDB.get_w(id)
	var wm: Node3D = load(WDB.DIR + w["gltf"]).instantiate()
	var tex: Texture2D = mat.get_shader_parameter("albedo_texture")
	M.paint(wm, M.toon(tex, w["tint"], 0.35))
	slot_r.add_child(wm)


func _physics_process(delta: float) -> void:
	if dead:
		return
	cd = max(0.0, cd - delta)
	invuln = max(0.0, invuln - delta)
	anim_lock = max(0.0, anim_lock - delta)
	var tick := delta * (2.0 if Stats.relics.has("pressure_suit") else 1.0) * (1.3 if Stats.relics.has("brine_rat") else 1.0)
	chill_t = max(0.0, chill_t - tick)
	weak_t = max(0.0, weak_t - tick)
	root_t = max(0.0, root_t - tick)
	silence_t = max(0.0, silence_t - tick)
	if venom_t > 0.0:
		venom_t = max(0.0, venom_t - tick)
		hp -= delta * (0.3 if Stats.relics.has("float_suit") else 0.6)
		hp_changed.emit(hp)
		if hp <= 0.0:
			dead = true
			if body_cs != null:
				body_cs.set_deferred("disabled", true)
			anim_lock = M.play_action(ap, ["death"], 1.0)
			died.emit()
	var spd_eff: float = speed * (0.55 if chill_t > 0.0 else 1.0) * (0.0 if root_t > 0.0 else 1.0)
	if dash_t > 0.0:
		dash_t -= delta
	if dash_atk_t > 0.0:
		dash_atk_t -= delta
		velocity = dash_dir * spd_eff * 4.2
		move_and_slide()
		global_position.x = clamp(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
		global_position.z = clamp(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
		global_position.y = 0.0
		return
	var dir := Vector3(move_input.x, 0, move_input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	# akselerasi halus: kecepatan mengejar target, bukan langsung penuh
	base_v = base_v.lerp(dir * spd_eff, 1.0 - pow(0.0005, delta))
	velocity = base_v + kb
	kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
	move_and_slide()
	global_position.x = clamp(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
	global_position.z = clamp(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
	global_position.y = 0.0
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 14.0)
		step_t -= delta
		if step_t <= 0.0:
			step_t = 0.24
			stepped.emit(global_position)
	if anim_lock <= 0.0:
		if dir.length() > 0.1:
			M.play_fuzzy(ap, ["running", "walk"])
		else:
			var near := false
			for f in get_tree().get_nodes_in_group("enemies"):
				if global_position.distance_squared_to(f.global_position) < room_tile * room_tile * 4.0:
					near = true
					break
			M.play_fuzzy(ap, ["idle_combat"] if near else ["idle"])


func attack() -> void:
	if dead or cd > 0.0 or Stats.draft_open:
		return
	cd = attack_cooldown
	attacked.emit()
	Sfx.play("swing")
	var foes := get_tree().get_nodes_in_group("enemies")
	var best: Node3D = null
	var bd := 99999.0
	for f in foes:
		var d: float = global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	if best != null and bd < room_tile * 2.5:
		var to: Vector3 = best.global_position - global_position
		rotation.y = atan2(to.x, to.z)
	anim_lock = M.play_action(ap, ["1h_melee_attack"], 1.5) * 0.7
	kb += Vector3(sin(rotation.y), 0, cos(rotation.y)) * room_tile * 0.9
	await get_tree().create_timer(0.13).timeout
	_strike()


func _strike() -> void:
	if dead:
		return
	var reach := room_tile * 0.8
	var facing := Vector3(sin(rotation.y), 0, cos(rotation.y))
	for f in get_tree().get_nodes_in_group("enemies"):
		var to: Vector3 = f.global_position - global_position
		to.y = 0
		if to.length() < reach and facing.dot(to.normalized()) > 0.3:
			var dmg: float = Stats.get_stat("atk") * (1.0 + Stats.buff_atk_pct)
			if weak_t > 0.0:
				dmg *= 0.75
			var crit := randf() < Stats.get_stat("crit")
			if not crit and Stats.relics.has("grave_rose") and not bool(f.get("fs_hit")):
				crit = true
				f.set("fs_hit", true)
			if crit:
				dmg *= 2.0
			if Stats.weapon_id == "war_blade" and f.hp < f.hp_max * 0.35:
				dmg *= 1.5
			f.take_hit(global_position, dmg)
			hit_n += 1
			if Stats.relics.has("echo_strike") and hit_n % 4 == 0:
				f.take_hit(global_position, dmg)
				hit_landed.emit(f.global_position, dmg, true)
			_weapon_proc(f, dmg, crit)
			var heal: float = dmg * Stats.get_stat("lifesteal")
			if heal > 0.0:
				hp = minf(max_hp, hp + heal)
				hp_changed.emit(hp)
			hit_landed.emit(f.global_position, dmg, crit)
	# guci tulang di busur yang sama: dihancurkan jadi permata
	for u in get_tree().get_nodes_in_group("urns"):
		var to2: Vector3 = u.global_position - global_position
		to2.y = 0
		if to2.length() < reach and facing.dot(to2.normalized()) > 0.3:
			u.smash(global_position)
	# dread obelisk di busur yang sama: hancurkan sebelum ia minum darahmu
	for ob in get_tree().get_nodes_in_group("obelisks"):
		var to3: Vector3 = ob.global_position - global_position
		to3.y = 0
		if to3.length() < reach and facing.dot(to3.normalized()) > 0.3:
			ob.smash(global_position)


# efek unik tiap senjata, terpicu setiap tebasan yang kena
func _weapon_proc(f: Node3D, dmg: float, crit: bool) -> void:
	match Stats.weapon_id:
		"bone_axe": # CLEAVE — percikan ke musuh sekitar sasaran
			for f2 in get_tree().get_nodes_in_group("enemies"):
				if f2 != f and f2.global_position.distance_to(f.global_position) < room_tile * 0.7:
					f2.take_hit(global_position, dmg * 0.5)
		"war_blade": # EXECUTIONER — +50% dmg ke musuh sekarat (<35% HP)
			if float(f.get("hp")) < float(f.get("hp_max")) * 0.35:
				f.take_hit(global_position, dmg * 0.5)
				var m5 := get_tree().current_scene
				if m5 != null and m5.has_method("_damage_number"):
					m5._damage_number(f.global_position + Vector3(0, 0.5 * room_tile, 0), "EXECUTED", Color(1.0, 0.3, 0.25), true)
		"twin_fang": # FLURRY — 25% tebasan ganda
			if randf() < 0.25:
				f.take_hit(global_position, dmg)
				hit_landed.emit(f.global_position, dmg, crit)
		"hex_staff": # HEX — tandai: musuh menerima +25% damage 4s
			f.set("hex_t", 4.0)
		"harpoon": # REACH — tiap tebasan ke-3 seret target ke jarak lengan
			var mh := get_tree().current_scene
			if mh != null:
				mh.set("harpoon_n", int(mh.get("harpoon_n")) + 1)
				var reach_at: int = 2 if Stats.relics.has("barbed_line") else 3
				if int(mh.get("harpoon_n")) >= reach_at:
					mh.set("harpoon_n", 0)
					var hdist: float = f.global_position.distance_to(global_position)
					if hdist > 1.2 * room_tile:
						var hdir: Vector3 = global_position - f.global_position
						hdir.y = 0
						f.global_position += hdir.normalized() * (hdist - 0.9 * room_tile)
						if mh.has_method("_damage_number"):
							mh._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "REACHED", Color(0.5, 0.8, 1.0), false)
		"whelk_maul": # BREACH — tiap tebasan ke-5 menembus: +60% damage
			var mw := get_tree().current_scene
			if mw != null:
				mw.set("net_n", int(mw.get("net_n")) + 1)
				if int(mw.get("net_n")) >= 5:
					mw.set("net_n", 0)
					f.take_hit(global_position, dmg * 0.6)
					if mw.has_method("_damage_number"):
						mw._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "BREACH", Color(0.6, 0.5, 1.0), true)
		"guthook": # BLEED — tiap tebasan ke-5 merobek: pulihkan 5% Max HP
			var mg := get_tree().current_scene
			if mg != null:
				mg.set("net_n", int(mg.get("net_n")) + 1)
				if int(mg.get("net_n")) >= 5:
					mg.set("net_n", 0)
					var mh: float = Stats.get_stat("max_hp")
					if hp < mh:
						hp = minf(mh, hp + mh * 0.05)
						if mg.has_method("_damage_number"):
							mg._damage_number(global_position + Vector3(0, 0.6 * room_tile, 0), "REND +HP", Color(1.0, 0.4, 0.4), false)
		"tide_shear": # SHEAR — tiap tebasan ke-5 menggunting tajam musuh: dmg −20% permanen
			var ms := get_tree().current_scene
			if ms != null:
				ms.set("net_n", int(ms.get("net_n")) + 1)
				if int(ms.get("net_n")) >= 5:
					ms.set("net_n", 0)
					if not bool(f.get("sheared")):
						f.set("sheared", true)
						f.dmg = maxi(1, int(ceil(f.dmg * 0.8)))
						if ms.has_method("_damage_number"):
							ms._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "SHEARED", Color(0.5, 0.95, 0.9), false)
		"chain_anchor": # MOORING — tiap tebasan ke-6 menambat target: stun 1.5s
			var mc := get_tree().current_scene
			if mc != null:
				mc.set("net_n", int(mc.get("net_n")) + 1)
				if int(mc.get("net_n")) >= 6:
					mc.set("net_n", 0)
					f.stun_t = 1.5
					if mc.has_method("_damage_number"):
						mc._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "MOORED", Color(0.4, 0.6, 1.0), false)
		"scourge": # LASH — tiap tebasan ke-4 menyeret musuh terdekat mendekat
			var ml := get_tree().current_scene
			if ml != null:
				ml.set("net_n", int(ml.get("net_n")) + 1)
				if int(ml.get("net_n")) >= 4:
					ml.set("net_n", 0)
					var tug: Vector3 = (global_position - f.global_position)
					tug.y = 0.0
					f.global_position += tug * 0.35
					var nearest: Node3D = null
					var nd := room_tile * 2.4
					for f2 in get_tree().get_nodes_in_group("enemies"):
						if f2 == f:
							continue
						var d2: float = f2.global_position.distance_to(f.global_position)
						if d2 < nd:
							nd = d2
							nearest = f2
					if nearest != null:
						var tug2: Vector3 = (global_position - nearest.global_position)
						tug2.y = 0.0
						nearest.global_position += tug2 * 0.35
					if ml.has_method("_damage_number"):
						ml._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "LASHED", Color(0.8, 0.5, 1.0), false)
		"driftnet": # NETS — tiap tebasan ke-4 melilit target: −40% speed 2s
			var mn := get_tree().current_scene
			if mn != null:
				mn.set("net_n", int(mn.get("net_n")) + 1)
				var net_at: int = 3 if Stats.relics.has("wicker_net") else 4
				if int(mn.get("net_n")) >= net_at:
					mn.set("net_n", 0)
					f.slow_t = 2.0
					if mn.has_method("_damage_number"):
						mn._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "NETTED", Color(0.4, 0.9, 0.6), false)
		"storm_axe": # STORM — 20% petir berantai ke musuh terdekat
			if randf() < 0.2:
				var best2: Node3D = null
				var bd2 := room_tile * 1.3
				for f2 in get_tree().get_nodes_in_group("enemies"):
					if f2 == f:
						continue
					var d: float = f.global_position.distance_to(f2.global_position)
					if d < bd2:
						bd2 = d
						best2 = f2
				if best2 != null:
					Sfx.play("thunder")
					best2.take_hit(best2.global_position, dmg * 0.8)
		"frost_fang": # FROST — beku 50% speed selama 3s
			f.set("slow_t", 3.0)
		"ember_mace": # BURN — membakar: DoT ~2.4s
			f.set("burn_t", 2.4)
		"grave_scythe": # REAPER — target yang mati mengembalikan 1 HP
			if float(f.get("hp")) <= 0.0:
				hp = minf(max_hp, hp + 1.0)
				hp_changed.emit(hp)
		"kings_edge": # KING'S WRATH — tiap hit ke-5 meledak + knockback besar
			kings_n += 1
			if kings_n >= 5:
				kings_n = 0
				f.take_hit(global_position, dmg)
				var m := get_tree().current_scene
				if m != null and m.has_method("_shock_ring"):
					m._shock_ring(f.global_position)
		"moon_katana": # RIPOSTE — setelah perfect dodge, tebasan berikutnya 2×
			if riposte_armed:
				riposte_armed = false
				f.take_hit(global_position, dmg)
				var m6 := get_tree().current_scene
				if m6 != null and m6.has_method("_damage_number"):
					m6._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "RIPOSTE", Color(0.7, 0.85, 1.3), true)
		"soul_reaver": # SIPHON — 15% tiap hit mencuri 1 jiwa
			if randf() < 0.15:
				Stats.earn_souls(1)
				var m7 := get_tree().current_scene
				if m7 != null:
					if m7.has_method("_souls_l"):
						m7._souls_l()
					if m7.has_method("_damage_number"):
						m7._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "SIPHON", Color(0.5, 1.0, 0.75), false)
		"hollow_crown": # USURPER — elite yang mati membayar 2 jiwa
			if bool(f.get("elite")) and float(f.get("hp")) <= 0.0:
				Stats.earn_souls(2)
				var m10 := get_tree().current_scene
				if m10 != null:
					if m10.has_method("_souls_l"):
						m10._souls_l()
					if m10.has_method("_damage_number"):
						m10._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "USURPER +2", Color(0.9, 0.7, 1.1), false)
		"thronebreaker": # CROWNSPLITTER — +40% damage ke bos
			if bool(f.get("is_boss")):
				f.take_hit(global_position, dmg * 0.4)
				var m9 := get_tree().current_scene
				if m9 != null and m9.has_method("_damage_number"):
					m9._damage_number(f.global_position + Vector3(0, 0.8 * room_tile, 0), "CROWNSPLITTER", Color(1.1, 0.85, 0.3), true)
		"mimic_fang": # JAW — 20% korban menggigit jiwa terlepas
			if float(f.get("hp")) <= 0.0 and randf() < 0.2:
				Stats.earn_souls(1)
				var m11 := get_tree().current_scene
				if m11 != null:
					if m11.has_method("_souls_l"):
						m11._souls_l()
					if m11.has_method("_damage_number"):
						m11._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "JAW +1", Color(1.1, 0.45, 0.3), false)
		"searbrand": # IGNITE — tiap tebasan membakar target (burn_t 4s)
			f.set("burn_t", 4.0)
			var m15 := get_tree().current_scene
			if m15 != null and randf() < 0.2 and m15.has_method("_burst"):
				m15._burst(f.global_position + Vector3(0, 0.4 * room_tile, 0), Color(1.0, 0.5, 0.15))
		"sunderfang": # REND — 25% pukulan merobek pertahanan (sunder_t)
			if randf() < 0.25:
				f.set("sunder_t", 4.0)
				var m14 := get_tree().current_scene
				if m14 != null and m14.has_method("_damage_number"):
					m14._damage_number(f.global_position + Vector3(0, 0.65 * room_tile, 0), "RENDED", Color(1.0, 0.6, 0.3), true)
		"titan_maul": # SHATTER — crit melempar musuh ke belakang & stun
			if crit and f.has_method("stun"):
				f.stun(0.9)
				var m13 := get_tree().current_scene
				if m13 != null and m13.has_method("_damage_number"):
					m13._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "SHATTERED", Color(0.75, 0.65, 1.0), true)
		"duskblade": # DUSKSTRIDE — pukulan sesaat setelah dash bergema
			if dash_atk_t > 0.0:
				f.take_hit(global_position, dmg * 0.6)
				var m16 := get_tree().current_scene
				if m16 != null and m16.has_method("_damage_number"):
					m16._damage_number(f.global_position + Vector3(0, 0.75 * room_tile, 0), "DUSKSTRIDE", Color(0.65, 0.55, 1.2), false)
		"oathbrand": # BOND — +20% dmg selama sekutu bersumpah berjalan di sisimu
			var m18 := get_tree().current_scene
			if m18 != null:
				var al: Variant = m18.get("squire_ref")
				var kn: Variant = m18.get("knight_ref")
				if (al != null and is_instance_valid(al)) or (kn != null and is_instance_valid(kn)):
					f.take_hit(global_position, dmg * 0.2)
		"snapdragon": # AMBUSH — gigitan pertama pada setiap musuh
			if not ambushed_ids.has(f.get_instance_id()):
				ambushed_ids[f.get_instance_id()] = true
				f.take_hit(global_position, dmg * 0.5)
				var m24 := get_tree().current_scene
				if m24 != null and m24.has_method("_damage_number"):
					m24._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "AMBUSHED", Color(0.5, 1.0, 0.7), false)
		"pearlrazor": # SALVAGE — tiap tebasan ke-4 membayar jiwa
			salvage_n += 1
			if salvage_n >= 4:
				salvage_n = 0
				Stats.earn_souls(1)
				var m22 := get_tree().current_scene
				if m22 != null and m22.get("salvage_ct") != null:
					m22.set("salvage_ct", int(m22.get("salvage_ct")) + 1)
					if int(m22.get("salvage_ct")) == 15 and m22.has_method("_ach"):
						m22._ach("salvager")
				var m23 := get_tree().current_scene
				if m23 != null:
					if m23.has_method("_souls_l"):
						m23._souls_l()
					if m23.has_method("_damage_number"):
						m23._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "SALVAGED", Color(0.9, 0.95, 1.0), false)
		"keelspike": # DROWN — musuh sekarat tenggelam lebih cepat
			if float(f.get("hp")) > 0.0 and float(f.get("hp")) <= 0.3 * float(f.get("hp_max")):
				f.take_hit(global_position, dmg * 0.4)
				var m21 := get_tree().current_scene
				if m21 != null and randf() < 0.25 and m21.has_method("_damage_number"):
					m21._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "DROWNED", Color(0.3, 0.7, 1.0), false)
		"undertow": # HAUL — tebasan menyeret musuh ke jangkauanmu
			var hp2: Vector3 = (global_position - f.global_position)
			hp2.y = 0
			if hp2.length() > 0.4 * room_tile:
				f.global_position += hp2.normalized() * 0.5 * room_tile
			var m20 := get_tree().current_scene
			if m20 != null and randf() < 0.15 and m20.has_method("_damage_number"):
				m20._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "HAULED", Color(0.35, 0.9, 1.0), false)
		"marsh_claw": # LEECHROOT — tiap tebasan melilit kaki musuh (speed -10%, menumpuk)
			var slw := float(f.get("speed"))
			f.set("speed", maxf(slw * 0.9, 0.3 * room_tile))
			var m19 := get_tree().current_scene
			if m19 != null and randf() < 0.2 and m19.has_method("_damage_number"):
				m19._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "ENTANGLED", Color(0.6, 0.9, 0.4), false)
		"gravebell": # TOLL — 25% korban membunyikan genta: 1x ATK ke tetangga
			if float(f.get("hp")) <= 0.0 and randf() < 0.25:
				var toll := 0
				for f3 in get_tree().get_nodes_in_group("enemies"):
					if f3 == f or String(f3.get("state")) == "dead":
						continue
					if f.global_position.distance_to(f3.global_position) < 1.1 * room_tile:
						f3.take_hit(f.global_position, dmg)
						toll += 1
				if toll > 0:
					var m12 := get_tree().current_scene
					if m12 != null:
						if m12.has_method("_shock_ring"):
							m12._shock_ring(f.global_position)
						if m12.has_method("_damage_number"):
							m12._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "TOLL ×%d" % toll, Color(0.85, 0.8, 1.2), true)
		"wisp_lantern": # WISP — korban melepas wisp yang menggigit musuh lain
			if float(f.get("hp")) <= 0.0:
				var best3: Node3D = null
				var bd3 := room_tile * 1.5
				for f2 in get_tree().get_nodes_in_group("enemies"):
					if f2 == f or String(f2.get("state")) == "dead":
						continue
					var d3: float = f.global_position.distance_to(f2.global_position)
					if d3 < bd3:
						bd3 = d3
						best3 = f2
				if best3 != null:
					best3.take_hit(best3.global_position, dmg * 0.6)
					var m11 := get_tree().current_scene
					if m11 != null and m11.has_method("_damage_number"):
						m11._damage_number(best3.global_position + Vector3(0, 0.6 * room_tile, 0), "WISP", Color(0.55, 1.2, 0.9), false)
		"gaoler_brand": # WARDEN — 12% peluang menjaring musuh di tempat
			if randf() < 0.12 and not bool(f.get("is_boss")):
				f.stun(1.2)
				var m4 := get_tree().current_scene
				if m4 != null and m4.has_method("_damage_number"):
					m4._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "CAGED", Color(0.6, 0.45, 1.0), true)
	# Ember Brand: senjata apapun punya 12% peluang membakar sasaran
	if Stats.relic_burn > 0.0 and Stats.weapon_id != "ember_mace" and randf() < 0.12:
		f.set("burn_t", maxf(float(f.get("burn_t")), 1.8))


# dash melalui serangan tepat waktu: musuh ter- stun + kena counter
var riposte_armed := false


func _perfect_dodge(from_pos: Vector3) -> void:
	riposte_armed = Stats.weapon_id == "moon_katana"
	var best: Node3D = null
	var bd := room_tile * 0.9
	for f in get_tree().get_nodes_in_group("enemies"):
		var d: float = f.global_position.distance_to(from_pos)
		if d < bd:
			bd = d
			best = f
	var m := get_tree().current_scene
	if best != null:
		best.stun(1.4)
		best.take_hit(global_position, Stats.get_stat("atk") * 1.5)
		Sfx.play("thunder")
	if m != null:
		if m.has_method("_quest_event"):
			m._quest_event("pdodge")
		if m.has_method("_damage_number"):
			m._damage_number(global_position, "PERFECT!", Color(0.6, 1.0, 0.95), true)
		m.set("trauma", 0.45)
		if m.has_method("_pdodged"):
			m._pdodged()
	Engine.time_scale = 0.3
	get_tree().create_timer(0.14, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	Sfx.play("dash")


func take_hit(from_pos: Vector3, dmg_taken: int) -> void:
	if dead or Stats.draft_open:
		return
	if invuln > 0.0:
		if dash_t > 0.0:
			_perfect_dodge(from_pos)
		return
	var mv9 := get_tree().current_scene
	if mv9 != null and Stats.relics.has("shellback") and float(mv9.get("still_t")) >= 1.0:
		dmg_taken = int(ceil(dmg_taken * 0.7))
	# berkat Bone Veil: pukulan pertama tiap lantai ditolak
	var mv := get_tree().current_scene
	if mv != null and bool(mv.get("bone_veil")) and not bool(mv.get("veil_used")):
		mv.set("veil_used", true)
		Sfx.play("shrine")
		if mv.has_method("_damage_number"):
			mv._damage_number(global_position, "VEILED", Color(0.85, 0.8, 0.5), true)
		return
	# relic Fase Hantu: peluang menghindar penuh
	if Stats.dodge > 0.0 and randf() < Stats.dodge:
		invuln = 0.5
		Sfx.play("dash")
		var m2 := get_tree().current_scene
		if m2 != null and m2.has_method("_damage_number"):
			m2._damage_number(global_position, "DODGED", Color(0.55, 0.9, 1.0), false)
		if mat != null:
			mat.set_shader_parameter("flash", 0.5)
			var dtw := create_tween()
			dtw.tween_property(mat, "shader_parameter/flash", 0.0, 0.25)
		return
	last_killer = ""
	var bd2: float = 0.7 * room_tile
	for f in get_tree().get_nodes_in_group("enemies"):
		var dd: float = f.global_position.distance_to(from_pos)
		if dd < bd2:
			bd2 = dd
			last_killer = "bone_king" if f.is_boss else String(f.arch_id)
	if last_killer == "":
		last_killer = "trap"
	var eff := maxi(1, dmg_taken + int(roundf(dmg_taken * Stats.curse_dmg)) + (int(roundf(dmg_taken * 0.3)) if Stats.deathwish else 0) - int(Stats.get_stat("armor")))
	hp -= eff
	invuln = 0.9
	Sfx.play("hurt")
	hp_changed.emit(hp)
	# relic Duri Pantulan: sebagian damage dibalik ke penyerang sekitar
	if Stats.thorns > 0.0:
		var reach2 := room_tile * 1.1
		for f in get_tree().get_nodes_in_group("enemies"):
			var d2: float = f.global_position.distance_to(global_position)
			if d2 < reach2:
				f.take_hit(global_position, dmg_taken * Stats.thorns)
	var away: Vector3 = global_position - from_pos
	away.y = 0
	kb = away.normalized() * room_tile * 1.6
	if mat != null:
		mat.set_shader_parameter("flash", 1.0)
		var tw := create_tween()
		tw.tween_property(mat, "shader_parameter/flash", 0.0, 0.18)
	if hp <= 0:
		# relic Jiwa Bangkit: sekali per run, hidup lagi dengan setengah HP
		if Stats.revive_left > 0:
			Stats.revive_left -= 1
			hp = int(maxi(1.0, max_hp * 0.5))
			invuln = 2.2
			hp_changed.emit(hp)
			revived.emit()
			Sfx.play("victory")
			if mat != null:
				mat.set_shader_parameter("flash", 1.0)
				var tw2 := create_tween()
				tw2.tween_property(mat, "shader_parameter/flash", 0.0, 0.6)
			anim_lock = max(anim_lock, M.play_action(ap, ["hit_"], 1.4))
			return
		dead = true
		if body_cs != null:
			body_cs.set_deferred("disabled", true)
		anim_lock = M.play_action(ap, ["death"], 1.0)
		died.emit()
	else:
		anim_lock = max(anim_lock, M.play_action(ap, ["hit_"], 1.4) * 0.6)


func heal_to_full() -> void:
	hp = max_hp
	hp_changed.emit(hp)
