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
var slip_t := 0.0
var weak_t := 0.0
var salvage_n := 0
var ambushed_ids := {}
var root_t := 0.0 # Gaoler: terjerat, tak bisa bergerak (dash masih bisa kabur)
var silence_t := 0.0
var venom_t := 0.0
var rust_t := 0.0
var hp := 5.0
var max_hp := 5.0
var attack_cooldown := 0.45
var atk_buf := 0.0
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
var kb_in := 1.0 # line_splice: musuh melempar lebih pendek
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
	dash_t = 0.22 * (1.3 if Stats.relics.has("splintered_oar") else 1.0)
	dash_atk_t = 1.5
	var streak := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.28, 0.5, 2.6)
	streak.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(0.5, 0.85, 1.0, 0.45)
	streak.material_override = smat
	streak.position = global_position + Vector3(0, 0.4, 0)
	streak.rotation.y = atan2(dash_dir.x, dash_dir.z)
	get_tree().current_scene.add_child(streak)
	var stw: Tween = streak.create_tween()
	stw.set_parallel(true)
	stw.tween_property(smat, "albedo_color:a", 0.0, 0.3)
	stw.tween_property(streak, "scale:z", 2.2, 0.3)
	stw.chain().tween_callback(streak.queue_free)
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
	atk_buf = max(0.0, atk_buf - delta)
	if atk_buf > 0.0 and cd <= 0.0 and not dead and not Stats.draft_open:
		atk_buf = 0.0
		attack()
	invuln = max(0.0, invuln - delta)
	visible = fmod(invuln * 14.0, 2.0) < 1.4 if invuln > 0.0 else true
	anim_lock = max(0.0, anim_lock - delta)
	var tick := delta * (2.0 if Stats.relics.has("pressure_suit") else 1.0) * (1.3 if Stats.relics.has("brine_rat") else 1.0)
	var rosary_mult_: float = 2.0 if get_tree().current_scene.get("salt_rosary") == true else 1.0
	if chill_t > 0.0:
		chill_t = max(0.0, chill_t - tick * (1.8 if Stats.relics.has("warm_blood") else 1.0) * rosary_mult_)
		if chill_t == 0.0 and Stats.relics.has("warm_blood"):
			var mcs := get_tree().current_scene
			if mcs != null and mcs.has_method("_quest_event"):
				mcs._quest_event("chillshake", 1)
	slip_t = max(0.0, slip_t - tick)
	weak_t = max(0.0, weak_t - tick * rosary_mult_)
	if Stats.relics.has("tarred_rope"):
		root_t = 0.0
	root_t = max(0.0, root_t - tick * (1.5 if Stats.relics.has("silk_greaves") else 1.0) * rosary_mult_)
	if get_tree().current_scene.get("moonwater") == true and not dead:
		hp = minf(Stats.get_stat("max_hp"), hp + delta * 0.3)
		hp_changed.emit(hp)
	silence_t = max(0.0, silence_t - tick * rosary_mult_)
	if Stats.relics.has("wormwood"):
		venom_t = 0.0
	if venom_t > 0.0:
		venom_t = max(0.0, venom_t - tick * rosary_mult_)
	if rust_t > 0.0:
		rust_t = max(0.0, rust_t - tick * rosary_mult_)
		hp -= delta * (0.3 if Stats.relics.has("float_suit") else 0.6)
		hp_changed.emit(hp)
		if hp <= 0.0:
			dead = true
			if body_cs != null:
				body_cs.set_deferred("disabled", true)
			anim_lock = M.play_action(ap, ["death"], 1.0)
			died.emit()
	var mspd := get_tree().current_scene
	var spd_eff: float = speed * (0.55 if chill_t > 0.0 else 1.0) * (0.0 if root_t > 0.0 else 1.0) * (1.15 if slip_t > 0.0 else 1.0) * (0.88 if mspd != null and bool(mspd.get("mire_hollow")) else 1.0)
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
	velocity = base_v + kb * kb_in
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
	if dead or Stats.draft_open:
		return
	if cd > 0.0:
		atk_buf = 0.15
		return
	cd = attack_cooldown
	attacked.emit()
	Sfx.play("swing", 0.94 + randf() * 0.12)
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
	var reach := room_tile * 0.8 + float(Stats.get_stat("reach")) * room_tile
	var facing := Vector3(sin(rotation.y), 0, cos(rotation.y))
	for f in get_tree().get_nodes_in_group("enemies"):
		var to: Vector3 = f.global_position - global_position
		to.y = 0
		if to.length() < reach and facing.dot(to.normalized()) > 0.3:
			var dmg: float = Stats.get_stat("atk") * (1.0 + Stats.buff_atk_pct)
			if weak_t > 0.0:
				dmg *= 0.75
			if rust_t > 0.0:
				dmg *= 0.8
			var msh := get_tree().current_scene
			if msh != null and bool(msh.get("salt_shear")) and float(f.get("slow_t")) > 0.0:
				dmg *= 1.25
			var crit := randf() < Stats.get_stat("crit")
			if not crit and Stats.relics.has("grave_rose") and not bool(f.get("fs_hit")):
				crit = true
				f.set("fs_hit", true)
			if Stats.weapon_id == "brine_gavel":
				var bgn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bgn)
				if bgn % 6 == 0:
					for bgf in get_tree().get_nodes_in_group("enemies"):
						if bgf != f and bgf.global_position.distance_to(f.global_position) < 2.2:
							var bgd: Vector3 = bgf.global_position - global_position
							bgd.y = 0.0
							if bgd.length() > 0.01:
								bgf.velocity += bgd.normalized() * 9.0
			if Stats.weapon_id == "broadside":
				var bsn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bsn)
				if bsn % 10 == 0:
					for bsf in get_tree().get_nodes_in_group("enemies"):
						if bsf != f and bsf.global_position.distance_to(f.global_position) < 2.0:
							bsf.take_hit(global_position, float(Stats.get_stat("atk")))
			if Stats.weapon_id == "mooring_pin":
				var mpn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", mpn)
				if mpn % 7 == 0:
					f.set("slow_t", 2.5)
			if Stats.weapon_id == "rigging_hook":
				var rgn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", rgn)
				if rgn % 7 == 0:
					var rgdir: Vector3 = (global_position - f.global_position)
					rgdir.y = 0
					if rgdir.length() > 0.1:
						f.velocity += rgdir.normalized() * 10.0
						f.stun(0.35)
			if Stats.weapon_id == "fog_cutter":
				var fcn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", fcn)
				if fcn % 6 == 0:
					for f2 in get_tree().get_nodes_in_group("enemies"):
						if f2.get("dead") == true:
							continue
						f2.set("slow_t", 1.5)
					Sfx.play("soul")
			if Stats.weapon_id == "thunderhead":
				var thn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", thn)
				if thn % 5 == 0:
					var tf = null
					var tbest := 1e9
					for f3 in get_tree().get_nodes_in_group("enemies"):
						if f3.get("dead") == true:
							continue
						var f3d: float = global_position.distance_to(f3.global_position)
						if f3d < tbest:
							tbest = f3d
							tf = f3
					if tf != null:
						tf.stun(0.8)
						Sfx.play("crit")
			if Stats.weapon_id == "bilge_wick":
				var bwn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bwn)
				if bwn % 7 == 0:
					f.set("burn_t", float(f.get("burn_t")) + 3.0)
					Sfx.play("hit2")
			if Stats.weapon_id == "ropes_end":
				var ren: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ren)
				if ren % 9 == 0:
					for rf in get_tree().get_nodes_in_group("enemies"):
						if rf.get("dead") == true:
							continue
						var rfd: Vector3 = global_position - rf.global_position
						rfd.y = 0
						if rfd.length() > 0.2:
							rf.velocity += rfd.normalized() * 7.0
					Sfx.play("hook")
			if Stats.weapon_id == "gafflant":
				var gfn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", gfn)
				if gfn % 8 == 0:
					var gsorted := get_tree().get_nodes_in_group("enemies").filter(func(g): return g.get("dead") != true)
					gsorted.sort_custom(func(a2, b2): return global_position.distance_to(a2.global_position) < global_position.distance_to(b2.global_position))
					var gmarked := 0
					for gf in gsorted:
						if gmarked >= 2:
							break
						gf.set("vuln_t", 3.0)
						gmarked += 1
					if gmarked > 0:
						Sfx.play("soul")
			if Stats.weapon_id == "saltthorn":
				var stn2: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", stn2)
				if stn2 % 5 == 0:
					var sns := get_tree().get_nodes_in_group("enemies").filter(func(s): return s.get("dead") != true)
					if sns.size() > 0:
						sns.sort_custom(func(a2, b2): return global_position.distance_to(a2.global_position) < global_position.distance_to(b2.global_position))
						sns[0].set("slow_t", 2.5)
						sns[0].set("velocity", Vector3.ZERO)
						var mst := get_tree().current_scene
						if mst != null and mst.has_method("_damage_number"):
							mst._damage_number(sns[0].global_position + Vector3(0, 0.8, 0), "ROOTED", Color(0.4, 0.8, 0.5), false)
						Sfx.play("hook")
			if Stats.weapon_id == "grim_reel":
				var grn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", grn)
				if grn % 7 == 0:
					Stats.earn_souls(1)
					var mgr := get_tree().current_scene
					if mgr != null:
						if mgr.has_method("_souls_l"):
							mgr._souls_l()
						if mgr.has_method("_damage_number"):
							mgr._damage_number(global_position + Vector3(0, 0.9, 0), "+1 ◈", Color(0.5, 0.95, 1.0), false)
						Sfx.play("soul")
			if Stats.weapon_id == "curse_cutter":
				var ccn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ccn)
				if ccn % 5 == 0:
					var had_curse := false
					for deb in ["chill_t", "weak_t", "root_t", "venom_t", "silence_t", "rust_t"]:
						if float(get(deb)) > 0.0:
							had_curse = true
						set(deb, 0.0)
					if had_curse:
						var mcc := get_tree().current_scene
						if mcc != null and mcc.has_method("_damage_number"):
							mcc._damage_number(global_position + Vector3(0, 0.9, 0), "CLEANSED", Color(0.7, 0.9, 1.0), true)
						Sfx.play("shrine")
			if Stats.weapon_id == "belay_hook":
				var bhn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bhn)
				if bhn % 5 == 0 and f != null and f.get("state") != "dead":
					var bdir: Vector3 = global_position - f.global_position
					bdir.y = 0
					if bdir.length() > 0.8 * room_tile:
						f.global_position = global_position - bdir.normalized() * 0.8 * room_tile
						f.set("slow_t", 1.5)
						Sfx.play("hook")
						var mbh := get_tree().current_scene
						if mbh != null and mbh.has_method("_damage_number"):
							mbh._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "YOINKED", Color(0.8, 0.6, 0.3), false)
			if Stats.weapon_id == "candle_snuff":
				var csn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", csn)
				if csn % 5 == 0 and f != null and f.get("state") != "dead":
					var slow_now: float = float(f.get("slow_t") or 0.0)
					var chill_now: float = float(f.get("chill_t") or 0.0)
					if slow_now > 0.0 or chill_now > 0.0:
						f.take_hit(global_position, Stats.get_stat("atk") * 0.6)
						var mcs := get_tree().current_scene
						if mcs != null and mcs.has_method("_damage_number"):
							mcs._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "EXTINGUISHED", Color(0.9, 0.85, 0.5), false)
						Sfx.play("hit")
			if Stats.weapon_id == "wisp_lure":
				var wln: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", wln)
				if wln % 6 == 0:
					var mwl := get_tree().current_scene
					if mwl != null and mwl.has_method("_spawn_wisp_at"):
						mwl._spawn_wisp_at(f.global_position + Vector3(0.5 * room_tile, 0, 0))
						Sfx.play("pickup")
			if Stats.weapon_id == "anchor_maul":
				var amn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", amn)
				if amn % 3 == 0:
					f.velocity += (f.global_position - global_position).normalized() * 9.0
					Sfx.play("hit", 0.6)
			if Stats.weapon_id == "gilt_edge":
				var gbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", gbn)
				if gbn % 7 == 0:
					Stats.earn_souls(2)
					var mgb := get_tree().current_scene
					Sfx.play("soul", 0.7)
					if mgb != null and mgb.has_method("_souls_l"):
						mgb._souls_l()
					if mgb != null and mgb.has_method("_damage_number"):
						mgb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "GILT +2", Color(1.0, 0.85, 0.3), true)
			if Stats.weapon_id == "ledger_edge":
				var lbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", lbn)
				if lbn % 8 == 0:
					Stats.earn_souls(1)
					Stats.add_xp(3)
					var mlb := get_tree().current_scene
					Sfx.play("soul", 0.6)
					if mlb != null and mlb.has_method("_souls_l"):
						mlb._souls_l()
					if mlb != null and mlb.has_method("_damage_number"):
						mlb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "LEDGER", Color(0.85, 0.95, 0.5), true)
			if Stats.weapon_id == "keelscore":
				var ksn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ksn)
				if ksn % 5 == 0:
					f.set("slow_t", 0.9)
					f.take_hit(global_position, Stats.get_stat("atk") * 0.5)
					Sfx.play("hit", 0.75)
					var mks := get_tree().current_scene
					if mks != null and mks.has_method("_damage_number"):
						mks._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SCORE", Color(0.7, 0.9, 1.0), false)
			if Stats.weapon_id == "knell_hook":
				var khn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", khn)
				if khn % 6 == 0:
					f.set("slow_t", 0.7)
					Stats.add_xp(4)
					Sfx.play("whisper", 0.75)
					var mkh := get_tree().current_scene
					if mkh != null:
						if mkh.has_method("_damage_number"):
							mkh._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "KNELL", Color(0.65, 0.6, 1.0), false)
						if mkh.has_method("_atk_pulse"):
							mkh._atk_pulse()
			if Stats.weapon_id == "bilge_maul":
				var bmn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bmn)
				if bmn % 7 == 0:
					Stats.earn_souls(1)
					Sfx.play("soul", 0.8)
					var mbm := get_tree().current_scene
					if mbm != null:
						if mbm.has_method("_damage_number"):
							mbm._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "GROG +1◈", Color(0.6, 0.9, 0.6), false)
						if mbm.has_method("_atk_pulse"):
							mbm._atk_pulse()
			if Stats.weapon_id == "stay_hook":
				var stn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", stn)
				if stn % 5 == 0:
					Sfx.play("hook", 0.8)
					var stpull: Vector3 = global_position - f.global_position
					stpull.y = 0.0
					if stpull.length() > 0.01:
						f.kb += stpull.normalized() * 6.0
					var mst := get_tree().current_scene
					if mst != null and mst.has_method("_damage_number"):
						mst._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "STAY", Color(0.9, 0.8, 0.4), false)
			if Stats.weapon_id == "saltfang":
				var sfn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", sfn)
				if sfn % 7 == 0:
					Sfx.play("swoosh", 0.7)
					f.set("slow_t", 2.0)
					var msf := get_tree().current_scene
					if msf != null and msf.has_method("_damage_number"):
						msf._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "FANG", Color(0.6, 0.9, 0.95), false)
			if Stats.weapon_id == "wake_bind":
				var wbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", wbn)
				if wbn % 6 == 0:
					Sfx.play("hook", 0.7)
					var wbp: Vector3 = global_position - f.global_position
					wbp.y = 0.0
					if wbp.length() > 0.01:
						f.kb += wbp.normalized() * 4.0
					f.set("slow_t", 2.0)
					var mwb := get_tree().current_scene
					if mwb != null and mwb.has_method("_damage_number"):
						mwb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "BIND", Color(0.55, 0.75, 0.95), false)
			if Stats.weapon_id == "keel_lantern":
				var kln: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", kln)
				if kln % 6 == 0:
					Sfx.play("soul", 0.7)
					if f.has_method("stun"):
						f.stun(0.9)
					var mkl := get_tree().current_scene
					if mkl != null and mkl.has_method("_damage_number"):
						mkl._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "LANTERN", Color(0.95, 0.8, 0.4), false)
					if randf() < 0.35:
						Stats.earn_souls(1)
			if Stats.weapon_id == "keel_judge":
				var kjn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", kjn)
				if kjn % 9 == 0 and float(f.hp) / float(f.hp_max) < 0.15:
					Sfx.play("thunder", 0.7)
					f.take_hit(global_position, 9999.0)
					var mkj := get_tree().current_scene
					if mkj != null and mkj.has_method("_damage_number"):
						mkj._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "JUDGED", Color(0.95, 0.75, 0.35), true)
			if Stats.weapon_id == "ghost_oar":
				var gon: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", gon)
				if gon % 6 == 0:
					Sfx.play("swoosh", 0.8)
					for gf in get_tree().get_nodes_in_group("enemies"):
						var gpush: Vector3 = gf.global_position - global_position
						gpush.y = 0.0
						if gpush.length() < 2.2 * room_tile and gpush.length() > 0.01:
							gf.kb += gpush.normalized() * 5.0
					var mgo := get_tree().current_scene
					if mgo != null and mgo.has_method("_damage_number"):
						mgo._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SWEEP", Color(0.6, 0.8, 0.85), false)
			if Stats.weapon_id == "toll_hook":
				var thn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", thn)
				if thn % 7 == 0:
					Sfx.play("soul", 0.7)
					Stats.earn_souls(1)
					var mth := get_tree().current_scene
					if mth != null and mth.has_method("_damage_number"):
						mth._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "TOLL +1 ◈", Color(0.9, 0.8, 0.4), false)
			if Stats.weapon_id == "deep_lamp":
				var dln: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", dln)
				if dln % 8 == 0:
					Sfx.play("soul", 0.5)
					f.set("burn_t", maxf(float(f.get("burn_t")), 2.0))
					var mdl := get_tree().current_scene
					if mdl != null and mdl.has_method("_damage_number"):
						mdl._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "BEACON", Color(1.0, 0.8, 0.4), false)
			if Stats.weapon_id == "rip_current":
				var rcn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", rcn)
				if rcn % 8 == 0:
					Sfx.play("swoosh", 0.7)
					var rfoes: Array = get_tree().get_nodes_in_group("enemies")
					for rf in rfoes:
						if rf.global_position.distance_to(f.global_position) < 2.5 * room_tile:
							rf.set("slow_t", maxf(float(rf.get("slow_t")), 2.0))
					var mrc := get_tree().current_scene
					if mrc != null and mrc.has_method("_damage_number"):
						mrc._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "RIP", Color(0.5, 0.85, 0.9), false)
			if Stats.weapon_id == "mast_stinger":
				var msn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", msn)
				if msn % 6 == 0:
					Sfx.play("hit", 0.5)
					f.take_hit(f.global_position, Stats.get_stat("atk") * 0.5)
					var mms := get_tree().current_scene
					if mms != null and mms.has_method("_damage_number"):
						mms._damage_number(f.global_position + Vector3(0.3, 0.7 * room_tile, 0), "STING", Color(1.0, 0.7, 0.4), false)
			if Stats.weapon_id == "knell_edge":
				var ken: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ken)
				if ken % 9 == 0:
					Sfx.play("soul", 0.6)
					Stats.earn_souls(1)
					var mke := get_tree().current_scene
					if mke != null and mke.has_method("_damage_number"):
						mke._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "KNELL +1◈", Color(0.9, 0.8, 0.5), false)
			if Stats.weapon_id == "vergers_rod":
				var vrn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", vrn)
				if vrn % 11 == 0:
					Sfx.play("thunder", 0.5)
					for vf in get_tree().get_nodes_in_group("enemies"):
						if vf.get("state") != "dead" and vf.global_position.distance_to(global_position) < 3.0 * room_tile:
							var vrd: Vector3 = (vf.global_position - global_position).normalized()
							vf.kb += vrd * 9.0
							vf.set("slow_t", maxf(float(vf.get("slow_t") or 0.0), 1.5))
					var mvr := get_tree().current_scene
					if mvr != null and mvr.has_method("_damage_number"):
						mvr._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "VERGE", Color(0.6, 0.85, 0.7), false)
			if Stats.weapon_id == "brine_jack":
				var bjn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bjn)
				if bjn % 9 == 0:
					Sfx.play("swoosh", 0.8)
					var bjd: Vector3 = (f.global_position - global_position).normalized()
					f.kb += bjd * 14.0
					var mbj := get_tree().current_scene
					if mbj != null and mbj.has_method("_damage_number"):
						mbj._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "JACK", Color(0.5, 0.9, 0.7), false)
			if Stats.weapon_id == "mourning_edge":
				var mdn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", mdn)
				if mdn % 10 == 0:
					Sfx.play("hit", 0.6)
					f.set("burn_t", maxf(float(f.get("burn_t") or 0.0), 2.0))
					var mmd := get_tree().current_scene
					if mmd != null and mmd.has_method("_damage_number"):
						mmd._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "DIRGE", Color(0.55, 0.6, 0.85), false)
			if Stats.weapon_id == "grey_oar":
				var gon: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", gon)
				if gon % 10 == 0:
					Sfx.play("swoosh", 0.6)
					var god2: Vector3 = (f.global_position - global_position).normalized()
					f.kb -= god2 * 11.0
					var mgo := get_tree().current_scene
					if mgo != null and mgo.has_method("_damage_number"):
						mgo._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "STROKE", Color(0.6, 0.75, 0.55), false)
			if Stats.weapon_id == "pale_trident":
				var ptn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ptn)
				if ptn % 3 == 0:
					f.set("slow_t", 1.5)
					var ptm := get_tree().current_scene
					if ptm != null and ptm.has_method("_damage_number"):
						ptm._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "TRINE", Color(0.7, 0.9, 0.8), false)
			if Stats.weapon_id == "grey_harpoon":
				var ghn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ghn)
				if ghn % 6 == 0:
					Sfx.play("swoosh", 0.55)
					var ghd: Vector3 = (f.global_position - global_position).normalized()
					f.kb -= ghd * 9.0
					var ghm := get_tree().current_scene
					if ghm != null and ghm.has_method("_damage_number"):
						ghm._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "GAFF", Color(0.55, 0.7, 0.6), false)
			if Stats.weapon_id == "keelbell":
				var kb8: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", kb8)
				if kb8 % 8 == 0:
					var ktl := 0
					for ktf in get_tree().get_nodes_in_group("enemies"):
						if ktf != f and ktf.get("state") != "dead" and ktf.global_position.distance_to(f.global_position) < 2.0 * room_tile:
							ktf.take_hit(f.global_position, Stats.get_stat("atk") * 0.5)
							ktl += 1
					if ktl > 0:
						Sfx.play("bell", 0.5)
						get_tree().current_scene._damage_number(f.global_position, "TOLL", Color(0.8, 0.85, 0.9), true)
			if Stats.weapon_id == "salt_psalter":
				var spn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", spn)
				if spn % 9 == 0:
					Stats.earn_souls(1)
					var mps := get_tree().current_scene
					if mps != null and mps.has_method("_damage_number"):
						mps._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "VERSE +1 ◈", Color(0.85, 0.8, 0.5), false)
			if Stats.weapon_id == "grey_salter":
				var gsn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", gsn)
				if gsn % 7 == 0:
					f.set("slow_t", 2.0)
					var mgs := get_tree().current_scene
					if mgs != null and mgs.has_method("_damage_number"):
						mgs._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "BRINE", Color(0.6, 0.75, 0.6), false)
			if Stats.weapon_id == "fog_gaff":
				var fgn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", fgn)
				if fgn % 5 == 0:
					var fgd: Vector3 = (f.global_position - global_position)
					fgd.y = 0
					if fgd.length() > 0.1:
						f.kb += fgd.normalized() * 10.0
						var mfg := get_tree().current_scene
						if mfg != null and mfg.has_method("_damage_number"):
							mfg._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "PEAL", Color(0.75, 0.8, 0.85), false)
			if Stats.weapon_id == "wake_anchor":
				var wan: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", wan)
				if wan % 6 == 0:
					f.set("slow_t", 2.0)
					var mwa := get_tree().current_scene
					if mwa != null and mwa.has_method("_damage_number"):
						mwa._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "GROUND", Color(0.5, 0.6, 0.68), false)
			if Stats.weapon_id == "toll_blade":
				var tbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", tbn)
				if tbn % 8 == 0:
					Stats.earn_souls(1)
					var mtb := get_tree().current_scene
					if mtb != null and mtb.has_method("_damage_number"):
						mtb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "LEVY", Color(0.78, 0.7, 0.5), false)
			if Stats.weapon_id == "crest_blade":
				var cbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", cbn)
				if cbn % 7 == 0:
					var cbd: Vector3 = (f.global_position - global_position)
					cbd.y = 0
					if cbd.length() > 0.1:
						f.kb += cbd.normalized() * 8.0
						var mcb := get_tree().current_scene
						if mcb != null and mcb.has_method("_damage_number"):
							mcb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "BREAKER", Color(0.8, 0.85, 0.9), false)
			if Stats.weapon_id == "bottom_brand":
				var bbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bbn)
				if bbn % 6 == 0:
					f.stun(0.7)
					var mbb := get_tree().current_scene
					if mbb != null and mbb.has_method("_damage_number"):
						mbb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "PRESS", Color(0.45, 0.5, 0.62), false)
			if Stats.weapon_id == "writ_edge":
				var wen: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", wen)
				if wen % 9 == 0:
					Stats.earn_souls(1)
					var mwe := get_tree().current_scene
					if mwe != null and mwe.has_method("_damage_number"):
						mwe._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "WRIT", Color(0.7, 0.75, 0.68), false)
			if Stats.weapon_id == "pale_gaff":
				var pgn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", pgn)
				if pgn % 7 == 0:
					var pgd: Vector3 = (global_position - f.global_position)
					pgd.y = 0
					if pgd.length() > 0.1:
						f.kb += pgd.normalized() * 2.5
						var mpg := get_tree().current_scene
						if mpg != null and mpg.has_method("_damage_number"):
							mpg._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "HOOK", Color(0.65, 0.68, 0.7), false)
			if Stats.weapon_id == "audit_edge":
				var aen: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", aen)
				if aen % 8 == 0:
					Stats.earn_souls(1)
					var mae := get_tree().current_scene
					if mae != null and mae.has_method("_damage_number"):
						mae._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "AUDIT", Color(0.85, 0.85, 0.7), false)
			if Stats.weapon_id == "bailiff_maul":
				var bmn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", bmn)
				if bmn % 6 == 0:
					f.stun(0.8)
					var mbm := get_tree().current_scene
					if mbm != null and mbm.has_method("_damage_number"):
						mbm._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SERVE", Color(0.85, 0.8, 0.6), false)
			if Stats.weapon_id == "docket_blade":
				var dkn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", dkn)
				if dkn % 9 == 0:
					f.stun(1.0)
					var mdk := get_tree().current_scene
					if mdk != null and mdk.has_method("_damage_number"):
						mdk._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "HEARING", Color(0.7, 0.7, 0.66), false)
			if Stats.weapon_id == "census_edge":
				var CEe: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", CEe)
				if CEe % 8 == 0:
					Stats.earn_souls(1)
					var mce := get_tree().current_scene
					if mce != null and mce.has_method("_damage_number"):
						mce._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "ENUMERATE", Color(0.8, 0.85, 1.0), false)
			if Stats.weapon_id == "roll_blade":
				var RBe: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", RBe)
				if RBe % 7 == 0:
					Stats.earn_souls(1)
					var mrb := get_tree().current_scene
					if mrb != null and mrb.has_method("_damage_number"):
						mrb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "TALLY", Color(0.72, 0.76, 0.82), false)
			if Stats.weapon_id == "due_edge":
				var DEe: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", DEe)
				if DEe % 9 == 0:
					f.stun(0.8)
					Stats.earn_souls(1)
					var mde := get_tree().current_scene
					if mde != null and mde.has_method("_damage_number"):
						mde._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "COLLECT", Color(0.75, 0.78, 0.7), false)
			if Stats.weapon_id == "auditor_edge":
				var AEe: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", AEe)
				if AEe % 8 == 0:
					Stats.earn_souls(1)
					f.set("slow_t", 1.2)
					var mae := get_tree().current_scene
					if mae != null and mae.has_method("_damage_number"):
						mae._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "RECEIPT", Color(0.8, 0.8, 0.88), false)
			if Stats.weapon_id == "ledger_reaper":
				var LRe: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", LRe)
				if LRe % 10 == 0:
					Stats.earn_souls(2)
					f.set("slow_t", 1.5)
					var mlr := get_tree().current_scene
					if mlr != null and mlr.has_method("_damage_number"):
						mlr._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "POST", Color(0.7, 0.72, 0.65), false)
			if Stats.weapon_id == "folio_edge":
				var FEn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", FEn)
				if FEn % 8 == 0:
					Stats.earn_souls(1)
					f.stun(0.9)
					var mfe := get_tree().current_scene
					if mfe != null and mfe.has_method("_damage_number"):
						mfe._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "FOLIO", Color(0.72, 0.68, 0.62), false)
			if Stats.weapon_id == "verdict_edge":
				var VEn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", VEn)
				if VEn % 9 == 0:
					Stats.earn_souls(1)
					f.stun(0.7)
					var mve := get_tree().current_scene
					if mve != null and mve.has_method("_damage_number"):
						mve._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "VERDICT", Color(0.62, 0.6, 0.66), false)
			if Stats.weapon_id == "session_edge":
				var SEn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", SEn)
				if SEn % 7 == 0:
					Stats.earn_souls(1)
					f.set("slow_t", 1.5)
					var mse := get_tree().current_scene
					if mse != null and mse.has_method("_damage_number"):
						mse._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SESSION", Color(0.66, 0.64, 0.7), false)
			if Stats.weapon_id == "scribe_edge":
				var SCn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", SCn)
				if SCn % 8 == 0:
					Stats.earn_souls(1)
					f.set("slow_t", 1.2)
					var mscr := get_tree().current_scene
					if mscr != null and mscr.has_method("_damage_number"):
						mscr._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SCRIBE", Color(0.6, 0.55, 0.72), false)
			if Stats.weapon_id == "ink_edge":
				var INn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", INn)
				if INn % 9 == 0:
					Stats.earn_souls(1)
					f.stun(0.8)
					var minke := get_tree().current_scene
					if minke != null and minke.has_method("_damage_number"):
						minke._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "INK", Color(0.32, 0.3, 0.5), false)
			if Stats.weapon_id == "verdict_blade":
				var VBn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", VBn)
				if VBn % 10 == 0:
					Stats.earn_souls(2)
					f.stun(1.0)
					var mvb := get_tree().current_scene
					if mvb != null and mvb.has_method("_damage_number"):
						mvb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "VERDICT", Color(0.5, 0.48, 0.4), false)
			if Stats.weapon_id == "neap_edge":
				var NPn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", NPn)
				if NPn % 9 == 0:
					for npf in get_tree().get_nodes_in_group("enemies"):
						if npf.get("state") != "dead" and npf.global_position.distance_to(global_position) < 3.0 * room_tile:
							npf.set("slow_t", 2.0)
					var mnp := get_tree().current_scene
					if mnp != null and mnp.has_method("_damage_number"):
						mnp._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "NEAP", Color(0.42, 0.55, 0.62), false)
			if Stats.weapon_id == "spring_edge":
				var SPn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", SPn)
				if SPn % 8 == 0:
					Sfx.play("swoosh", 0.7)
					var sprs: Array = []
					for sf in get_tree().get_nodes_in_group("enemies"):
						if sf.get("state") != "dead" and sf.global_position.distance_to(global_position) < 5.0 * room_tile:
							sprs.append(sf)
					sprs.sort_custom(func(sa: Object, sb: Object) -> bool: return sa.global_position.distance_squared_to(global_position) < sb.global_position.distance_squared_to(global_position))
					for sf2 in sprs.slice(0, 2):
						sf2.kb += (global_position - sf2.global_position).normalized() * 16.0
					var msp := get_tree().current_scene
					if msp != null and msp.has_method("_damage_number"):
						msp._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SPRING", Color(0.38, 0.72, 0.8), false)
			if Stats.weapon_id == "canticle_edge":
				var cen: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", cen)
				if cen % 9 == 0 and hp < max_hp:
					Sfx.play("heal", 0.7)
					hp = minf(max_hp, hp + max_hp * 0.03)
					var mce := get_tree().current_scene
					if mce != null and mce.has_method("_damage_number"):
						mce._damage_number(global_position + Vector3(0, 1.1 * room_tile, 0), "CANTICLE", Color(0.7, 0.9, 0.6), false)
			if Stats.weapon_id == "pilot_lantern":
				var pln: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", pln)
				if pln % 8 == 0:
					Sfx.play("whisper", 0.6)
					var plb: Node3D = null
					var pld := 1e9
					for pf in get_tree().get_nodes_in_group("enemies"):
						if pf.get("state") != "dead":
							var pdd: float = pf.global_position.distance_to(global_position)
							if pdd < pld and pdd < 4.0 * room_tile:
								pld = pdd
								plb = pf
					if plb != null:
						plb.stun(1.2)
					var mpl := get_tree().current_scene
					if mpl != null and mpl.has_method("_damage_number"):
						mpl._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "PILOT", Color(0.85, 0.9, 0.5), false)
			if Stats.weapon_id == "wake_splitter":
				var wsn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", wsn)
				if wsn % 10 == 0:
					Sfx.play("swoosh", 0.7)
					for wf in get_tree().get_nodes_in_group("enemies"):
						if wf != f and wf.get("state") != "dead" and wf.global_position.distance_to(f.global_position) < 2.5 * room_tile:
							var wsd: Vector3 = (wf.global_position - f.global_position).normalized()
							wf.kb += wsd * 11.0
					var mws := get_tree().current_scene
					if mws != null and mws.has_method("_damage_number"):
						mws._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "WAKE", Color(0.5, 0.85, 1.0), false)
			if Stats.weapon_id == "keel_hammer":
				var khn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", khn)
				if khn % 8 == 0:
					Sfx.play("thunder", 0.6)
					var mkh := get_tree().current_scene
					for nf in get_tree().get_nodes_in_group("enemies"):
						if nf.get("state") != "dead" and nf.global_position.distance_to(f.global_position) < 2.5 * room_tile:
							var kdir: Vector3 = nf.global_position - f.global_position
							kdir.y = 0.0
							nf.kb += kdir.normalized() * 7.0
					if mkh != null and mkh.has_method("_damage_number"):
						mkh._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SPLINTERED", Color(0.9, 0.6, 0.4), true)
			if Stats.weapon_id == "deck_reaver":
				var drn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", drn)
				if drn % 9 == 0:
					Sfx.play("crit", 0.8)
					f.take_hit(global_position, Stats.get_stat("atk") * 2.5)
					var mdr := get_tree().current_scene
					if mdr != null and mdr.has_method("_damage_number"):
						mdr._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "CARVED", Color(1.0, 0.5, 0.3), true)
			if Stats.weapon_id == "grim_fathom":
				var gfn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", gfn)
				if gfn % 8 == 0:
					Sfx.play("hook", 0.7)
					var gfd: Vector3 = global_position - f.global_position
					gfd.y = 0.0
					if gfd.length() > 0.5:
						f.kb += gfd.normalized() * 6.0
					var mgf := get_tree().current_scene
					if mgf != null and mgf.has_method("_damage_number"):
						mgf._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "HOISTED", Color(0.5, 0.6, 0.8), false)
			if Stats.weapon_id == "saltwire":
				var swn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", swn)
				if swn % 7 == 0:
					Sfx.play("hook", 0.65)
					f.stun(1.5)
					var msw := get_tree().current_scene
					if msw != null and msw.has_method("_damage_number"):
						msw._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SNARED", Color(0.9, 0.85, 0.6), false)
			if Stats.weapon_id == "hull_mender":
				var hmn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", hmn)
				if hmn % 8 == 0:
					Sfx.play("shrine", 0.6)
					if hp < Stats.get_stat("max_hp"):
						hp = minf(hp + 1.0, Stats.get_stat("max_hp"))
						hp_changed.emit(hp)
					var mhm := get_tree().current_scene
					if mhm != null and mhm.has_method("_damage_number"):
						mhm._damage_number(global_position + Vector3(0, 0.9 * room_tile, 0), "MEND +1", Color(0.55, 0.9, 0.6), false)
			if Stats.weapon_id == "saltverdict":
				var svn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", svn)
				if svn % 6 == 0:
					Sfx.play("thunder", 0.7)
					var msv := get_tree().current_scene
					if f.has_method("stun"):
						f.stun(0.6)
					if msv != null:
						if msv.has_method("_damage_number"):
							msv._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "VERDICT", Color(0.95, 0.95, 0.8), false)
						if msv.has_method("_atk_pulse"):
							msv._atk_pulse()
			if Stats.weapon_id == "mastfall":
				var mfn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", mfn)
				if mfn % 8 == 0:
					Stats.earn_souls(2)
					Sfx.play("slam", 0.8)
					var mmf := get_tree().current_scene
					if mmf != null:
						if mmf.has_method("_damage_number"):
							mmf._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "MASTFALL +2◈", Color(0.9, 0.7, 0.35), false)
						if mmf.has_method("_shock_ring"):
							mmf._shock_ring(f.global_position)
						if mmf.has_method("_atk_pulse"):
							mmf._atk_pulse()
			if Stats.weapon_id == "wraithbell":
				var wbn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", wbn)
				if wbn % 6 == 0:
					Sfx.play("reliquary", 0.6)
					var mwb := get_tree().current_scene
					for fb in mwb.get_tree().get_nodes_in_group("enemies"):
						if fb != null and fb.global_position.distance_to(f.global_position) < 6.0:
							fb.set("slow_t", 2.0)
					if mwb.has_method("_damage_number"):
						mwb._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "TOLL", Color(0.7, 0.6, 1.0), false)
			if Stats.weapon_id == "barnacle_edge":
				var ben: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", ben)
				if ben % 3 == 0:
					f.set("slow_t", 2.5)
					Sfx.play("hit", 0.7)
					var mbe := get_tree().current_scene
					if mbe != null and mbe.has_method("_damage_number"):
						mbe._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "FOULED", Color(0.6, 0.7, 0.4), false)
			if Stats.weapon_id == "dirge_edge":
				var dgn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", dgn)
				if dgn % 6 == 0:
					hp = minf(max_hp, hp + 1.0)
					hp_changed.emit(hp)
					var mdg := get_tree().current_scene
					if mdg != null:
						var dcd: Dictionary = mdg.get("skill_cd")
						for dsk in dcd.keys():
							dcd[dsk] = maxf(0.0, float(dcd[dsk]) - 0.5)
					if mdg != null and mdg.has_method("_burst"):
						mdg._burst(global_position + Vector3(0, 0.6 * room_tile, 0), Color(0.5, 0.85, 0.6))
					Sfx.play("pickup")
			if Stats.weapon_id == "hull_render":
				var hrn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", hrn)
				if hrn % 4 == 0:
					f.set("vuln_t", maxf(float(f.get("vuln_t") or 0.0), 2.5))
					var mhr := get_tree().current_scene
					if mhr != null and mhr.has_method("_damage_number"):
						mhr._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "SUNDERED", Color(0.95, 0.6, 0.35), false)
					Sfx.play("hit", 0.8)
			if Stats.weapon_id == "lantern_maul":
				var lmn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", lmn)
				if lmn % 6 == 0:
					var mlm := get_tree().current_scene
					for lf in get_tree().get_nodes_in_group("enemies"):
						if lf.get("state") != "dead" and lf.global_position.distance_to(global_position) < 2.2 * room_tile:
							var ldir: Vector3 = lf.global_position - global_position
							ldir.y = 0
							lf.velocity += ldir.normalized() * room_tile * 3.5
					if mlm != null:
						if mlm.has_method("_shock_ring"):
							mlm._shock_ring(global_position)
						if mlm.has_method("_burst"):
							mlm._burst(global_position + Vector3(0, 0.6, 0), Color(1.0, 0.9, 0.5))
					Sfx.play("shrine")
			if Stats.weapon_id == "salt_lantern":
				var sln: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", sln)
				if sln % 9 == 0:
					var msl := get_tree().current_scene
					if msl != null and msl.has_method("_spawn_wisp_at"):
						msl._spawn_wisp_at(global_position + Vector3(0, 0.5, 0))
			if Stats.weapon_id == "undertow_pike":
				var upn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", upn)
				if upn % 8 == 0:
					var upf: Node = null
					var upd := 0.0
					for upe in get_tree().get_nodes_in_group("enemies"):
						if upe != f and upe.get("state") != "dead":
							var upd2: float = upe.global_position.distance_to(global_position)
							if upd2 > upd:
								upd = upd2
								upf = upe
					if upf != null and upd > 1.6:
						upf.global_position = global_position + (upf.global_position - global_position).normalized() * 1.4
						upf.stun(0.5)
			if Stats.weapon_id == "salt_whip":
				var swn: int = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", swn)
				if swn % 5 == 0:
					for swf in get_tree().get_nodes_in_group("enemies"):
						if swf != f and swf.global_position.distance_to(f.global_position) < 1.8:
							swf.take_hit(global_position, float(Stats.get_stat("atk")) * 0.5)
			if Stats.weapon_id == "kraken_bell":
				var kbn = int(get_tree().current_scene.get("net_n") or 0) + 1
				get_tree().current_scene.set("net_n", kbn)
				if kbn % 9 == 0:
					for kb in get_tree().get_nodes_in_group("enemies"):
						if kb != f and kb.global_position.distance_to(f.global_position) < 2.5:
							kb.stun(0.6)
			if Stats.weapon_id == "bilge_hammer":
				var bhn: Node = get_tree().current_scene
				var bhn2: int = int(bhn.get("net_n")) + 1
				bhn.set("net_n", bhn2)
				if bhn2 >= 12:
					bhn.set("net_n", 0)
					for bh_ in get_tree().get_nodes_in_group("enemies"):
						if bh_.get("state") != "dead" and bh_ != f and bh_.global_position.distance_to(f.global_position) < 2.5:
							bh_.take_hit(global_position, float(Stats.get_stat("atk")) * 0.6)
					if bhn.has_method("_shock_ring"):
						bhn._shock_ring(f.global_position)
			if Stats.weapon_id == "tide_press":
				var tpn: Node = get_tree().current_scene
				var tpn2: int = int(tpn.get("net_n")) + 1
				tpn.set("net_n", tpn2)
				if tpn2 >= 10:
					tpn.set("net_n", 0)
					f.take_hit(global_position, float(Stats.get_stat("atk")) * 0.8)
					if tpn.has_method("_shock_ring"):
						tpn._shock_ring(f.global_position)
			if Stats.weapon_id == "salt_scythe":
				var scn2: Node = get_tree().current_scene
				var sn2: int = int(scn2.get("net_n")) + 1
				scn2.set("net_n", sn2)
				if sn2 >= 8:
					scn2.set("net_n", 0)
					if scn2.has_method("_spawn_wisp_at"):
						scn2._spawn_wisp_at(global_position + Vector3(0, 0.5, 0))
			if Stats.weapon_id == "foghorn":
				var fh_ = get_tree().current_scene
				fh_.set("net_n", int(fh_.get("net_n")) + 1)
				if int(fh_.get("net_n")) >= 9:
					fh_.set("net_n", 0)
					for fh2_ in get_tree().get_nodes_in_group("enemies"):
						if fh2_.get("state") != "dead" and fh2_.global_position.distance_to(global_position) < 3.5:
							fh2_.stun(0.8)
					if fh_.has_method("_shock_ring"):
						fh_._shock_ring(global_position)
					Sfx.play("roar")
			if Stats.weapon_id == "barnacle_mace":
				var bm_ = get_tree().current_scene
				bm_.set("net_n", int(bm_.get("net_n")) + 1)
				if int(bm_.get("net_n")) >= 6:
					bm_.set("net_n", 0)
					f.stun(1.2)
			if Stats.weapon_id == "coral_bite":
				var cb_ = get_tree().current_scene
				cb_.set("net_n", int(cb_.get("net_n")) + 1)
				if int(cb_.get("net_n")) >= 7:
					cb_.set("net_n", 0)
					f.take_hit(global_position, float(Stats.get_stat("atk")) * 0.8)
			if Stats.weapon_id == "tar_rope":
				var tr_ = get_tree().current_scene
				tr_.set("net_n", int(tr_.get("net_n")) + 1)
				if int(tr_.get("net_n")) >= 5:
					tr_.set("net_n", 0)
					f.stun(0.8)
			if Stats.weapon_id == "harpoon_reel":
				var hr_ = get_tree().current_scene
				hr_.set("net_n", int(hr_.get("net_n")) + 1)
				if int(hr_.get("net_n")) >= 6:
					hr_.set("net_n", 0)
					f.velocity += (global_position - f.global_position).normalized() * 14.0
					f.stun(0.6)
			if Stats.weapon_id == "powder_horn":
				var ph_ = get_tree().current_scene
				ph_.set("net_n", int(ph_.get("net_n")) + 1)
				if int(ph_.get("net_n")) >= 8:
					ph_.set("net_n", 0)
					var shot_dir: Vector3 = (f.global_position - global_position).normalized()
					for sf in get_tree().get_nodes_in_group("enemies"):
						if sf == f or sf.get("state") == "dead":
							continue
						var to_sf: Vector3 = sf.global_position - global_position
						if to_sf.length() < 6.0 and to_sf.normalized().dot(shot_dir) > 0.85:
							sf.take_hit(global_position, float(Stats.get_stat("atk")) * 0.7)
			if Stats.weapon_id == "oathblade":
				var ob_ = get_tree().current_scene
				ob_.set("net_n", int(ob_.get("net_n")) + 1)
				if int(ob_.get("net_n")) >= 10:
					ob_.set("net_n", 0)
					f.take_hit(global_position, float(Stats.get_stat("atk")) * 0.5)
					f.velocity += (f.global_position - global_position).normalized() * 12.0
			if Stats.weapon_id == "saltbrand":
				var sb_ = get_tree().current_scene
				sb_.set("net_n", int(sb_.get("net_n")) + 1)
				if int(sb_.get("net_n")) >= 5:
					sb_.set("net_n", 0)
					f.set("slow_t", 3.0)
			if Stats.weapon_id == "deckcleaver":
				var dc_ = get_tree().current_scene
				dc_.set("net_n", int(dc_.get("net_n")) + 1)
				if int(dc_.get("net_n")) >= 6:
					dc_.set("net_n", 0)
					for dcf in get_tree().get_nodes_in_group("enemies"):
						if dcf.get("state") != "dead" and dcf != f and dcf.global_position.distance_to(global_position) < 1.6:
							dcf.take_hit(global_position, float(Stats.get_stat("atk")) * 0.5)
			if Stats.weapon_id == "oarlock":
				var ol_ = get_tree().current_scene
				ol_.set("net_n", int(ol_.get("net_n")) + 1)
				if int(ol_.get("net_n")) >= 6:
					ol_.set("net_n", 0)
					if f.has_method("stun"):
						f.stun(0.8)
			if Stats.weapon_id == "chumblade":
				var cb_ = get_tree().current_scene
				cb_.set("net_n", int(cb_.get("net_n")) + 1)
				if int(cb_.get("net_n")) >= 4:
					cb_.set("net_n", 0)
					var cbfoes: Array = []
					for cbf in get_tree().get_nodes_in_group("enemies"):
						if cbf.get("state") != "dead" and cbf.global_position.distance_to(global_position) < 3.0:
							cbfoes.append(cbf)
					if cbfoes.size() > 0:
						cbfoes[randi() % cbfoes.size()].take_hit(global_position, float(Stats.get_stat("atk")) * 0.6)
			if Stats.weapon_id == "kedge":
				var kg_ = get_tree().current_scene
				kg_.set("net_n", int(kg_.get("net_n")) + 1)
				if int(kg_.get("net_n")) >= 5:
					kg_.set("net_n", 0)
					velocity += (f.global_position - global_position).normalized() * 8.0
			if Stats.weapon_id == "garroter":
				var gr_ = get_tree().current_scene
				gr_.set("net_n", int(gr_.get("net_n")) + 1)
				if int(gr_.get("net_n")) >= 7:
					gr_.set("net_n", 0)
					f.stun(1.2)
					f.take_hit(global_position, float(Stats.get_stat("atk")) * 0.8)
			if Stats.weapon_id == "wakefang":
				var wf_ = get_tree().current_scene
				wf_.set("net_n", int(wf_.get("net_n")) + 1)
				if int(wf_.get("net_n")) >= 6:
					wf_.set("net_n", 0)
					var wffar: Node3D = null
					var wfd := 0.0
					for other3 in get_tree().get_nodes_in_group("enemies"):
						if other3.get("state") != "dead" and other3 != f:
							var d3: float = global_position.distance_to(other3.global_position)
							if d3 > wfd:
								wfd = d3
								wffar = other3
					if wffar != null:
						wffar.take_hit(global_position, float(Stats.get_stat("atk")) * 0.7)
			if Stats.weapon_id == "thresh_hook":
				var th_ = get_tree().current_scene
				th_.set("net_n", int(th_.get("net_n")) + 1)
				if int(th_.get("net_n")) >= 8:
					th_.set("net_n", 0)
					var thlist: Array = []
					for other2 in get_tree().get_nodes_in_group("enemies"):
						if other2.get("state") != "dead" and other2 != f:
							thlist.append(other2)
					thlist.sort_custom(func(a2: Object, b2: Object) -> bool: return a2.global_position.distance_squared_to(global_position) < b2.global_position.distance_squared_to(global_position))
					var thd: float = float(Stats.get_stat("atk")) * 0.5
					for ti in range(mini(3, thlist.size())):
						thlist[ti].take_hit(global_position, thd)
			if Stats.weapon_id == "stanchion":
				var st2_ = get_tree().current_scene
				st2_.set("net_n", int(st2_.get("net_n")) + 1)
				if int(st2_.get("net_n")) >= 5:
					st2_.set("net_n", 0)
					f.set("slow_t", 3.0)
			if Stats.weapon_id == "mirenet":
				var mn_ = get_tree().current_scene
				mn_.set("net_n", int(mn_.get("net_n")) + 1)
				if int(mn_.get("net_n")) >= 6:
					mn_.set("net_n", 0)
					f.stun(1.5)
			if Stats.weapon_id == "bilge_lantern":
				var bl_ = get_tree().current_scene
				bl_.set("net_n", int(bl_.get("net_n")) + 1)
				if int(bl_.get("net_n")) >= 7:
					bl_.set("net_n", 0)
					var blnears: Array = []
					for bf in get_tree().get_nodes_in_group("enemies"):
						if bf.get("state") != "dead" and bf != f and bf.global_position.distance_to(global_position) < 3.5:
							blnears.append(bf)
					blnears.sort_custom(func(a3: Object, b3: Object) -> bool: return a3.global_position.distance_squared_to(global_position) < b3.global_position.distance_squared_to(global_position))
					for bi in range(mini(3, blnears.size())):
						blnears[bi].take_hit(global_position, float(Stats.get_stat("atk")) * 0.6)
			if Stats.weapon_id == "saltline":
				var sl_ = get_tree().current_scene
				sl_.set("net_n", int(sl_.get("net_n")) + 1)
				if int(sl_.get("net_n")) >= 6:
					sl_.set("net_n", 0)
					var slf_: Object = null
					var sld_: float = 0.0
					for sf2 in get_tree().get_nodes_in_group("enemies"):
						if sf2.get("state") != "dead" and sf2 != f:
							var sd2: float = sf2.global_position.distance_to(global_position)
							if sd2 > sld_ and sd2 < 6.0:
								sld_ = sd2
								slf_ = sf2
					if slf_ != null:
						slf_.velocity += (global_position - slf_.global_position).normalized() * 12.0
			if Stats.weapon_id == "oarsplitter":
				var os_ = get_tree().current_scene
				os_.set("net_n", int(os_.get("net_n")) + 1)
				if int(os_.get("net_n")) >= 5:
					os_.set("net_n", 0)
					var onears: Array = []
					for of_ in get_tree().get_nodes_in_group("enemies"):
						if of_.get("state") != "dead" and of_ != f and of_.global_position.distance_to(global_position) < 4.0:
							onears.append(of_)
					onears.sort_custom(func(a1: Object, b1: Object) -> bool: return a1.global_position.distance_squared_to(global_position) < b1.global_position.distance_squared_to(global_position))
					for oi_ in range(mini(2, onears.size())):
						onears[oi_].take_hit(global_position, float(Stats.get_stat("atk")) * 0.8)
					if onears.size() > 0 and os_.has_method("_shock_ring"):
						os_._shock_ring(global_position)
			if Stats.weapon_id == "rustwake":
				var rw_ = get_tree().current_scene
				rw_.set("net_n", int(rw_.get("net_n")) + 1)
				if int(rw_.get("net_n")) >= 4:
					rw_.set("net_n", 0)
					slip_t = 2.0
			if Stats.weapon_id == "grog_blade":
				var gb_ = get_tree().current_scene
				gb_.set("net_n", int(gb_.get("net_n")) + 1)
				if int(gb_.get("net_n")) >= 7:
					gb_.set("net_n", 0)
					var gm_ := Stats.get_stat("max_hp")
					hp = minf(gm_, hp + gm_ * 0.03)
					hp_changed.emit(hp)
					Stats.current_hp = hp
			if Stats.weapon_id == "belaying_pin":
				var bp_ = get_tree().current_scene
				bp_.set("net_n", int(bp_.get("net_n")) + 1)
				if int(bp_.get("net_n")) >= 4:
					bp_.set("net_n", 0)
					if f.has_method("stun"):
						f.stun(1.0)
			if Stats.weapon_id == "saltcaller":
				var sc_ = get_tree().current_scene
				sc_.set("net_n", int(sc_.get("net_n")) + 1)
				if int(sc_.get("net_n")) >= 6:
					sc_.set("net_n", 0)
					for wf in get_tree().get_nodes_in_group("enemies"):
						if wf.get("state") != "dead" and wf.global_position.distance_to(global_position) < 2.0:
							wf.take_hit(global_position, 1.0)
					if sc_.has_method("_shock_ring"):
						sc_._shock_ring(global_position)
			if Stats.weapon_id == "sisters_hook":
				var sh_ = get_tree().current_scene
				sh_.set("net_n", int(sh_.get("net_n")) + 1)
				if int(sh_.get("net_n")) >= 8:
					sh_.set("net_n", 0)
					Stats.earn_souls(1)
					if sh_.has_method("_souls_l"):
						sh_._souls_l()
					if sh_.has_method("_damage_number"):
						sh_._damage_number(f.global_position + Vector3(0, 0.9, 0), "TRAWL +1", Color(0.5, 0.9, 0.8), false)
			if Stats.weapon_id == "palehook":
				var ph_ = get_tree().current_scene
				ph_.set("net_n", int(ph_.get("net_n")) + 1)
				if int(ph_.get("net_n")) >= 3:
					ph_.set("net_n", 0)
					var phf_: Object = null
					var phd_: float = 0.0
					for pf in get_tree().get_nodes_in_group("enemies"):
						if pf.get("state") != "dead" and pf != f:
							var pd_: float = pf.global_position.distance_to(global_position)
							if pd_ > phd_ and pd_ < 6.0:
								phd_ = pd_
								phf_ = pf
					if phf_ != null:
						phf_.velocity += (global_position - phf_.global_position).normalized() * 10.0
			if Stats.weapon_id == "deckhands_edge":
				var de_ = get_tree().current_scene
				de_.set("net_n", int(de_.get("net_n")) + 1)
				if int(de_.get("net_n")) >= 2:
					de_.set("net_n", 0)
					var dd_: Vector3 = (f.global_position - global_position).normalized()
					f.velocity += dd_ * 5.5
			if Stats.weapon_id == "galebrand":
				var gb_ = get_tree().current_scene
				gb_.set("net_n", int(gb_.get("net_n")) + 1)
				if int(gb_.get("net_n")) >= 3:
					gb_.set("net_n", 0)
					for gf in get_tree().get_nodes_in_group("enemies"):
						if gf.get("state") != "dead" and gf.global_position.distance_to(f.global_position) < 1.6:
							var gd_: Vector3 = (gf.global_position - global_position).normalized()
							gf.velocity += gd_ * 7.0
			if Stats.weapon_id == "keelbreak":
				var kb_ = get_tree().current_scene
				kb_.set("net_n", int(kb_.get("net_n")) + 1)
				if int(kb_.get("net_n")) >= 5:
					kb_.set("net_n", 0)
					var dir_: Vector3 = (f.global_position - global_position).normalized()
					f.velocity += dir_ * 9.0
					if f.has_method("stun"):
						f.stun(0.8)
			if Stats.weapon_id == "widows_fang":
				f.set("slow_t", 1.5)
			if Stats.weapon_id == "undertow_blade":
				var ub_ = get_tree().current_scene
				ub_.set("net_n", int(ub_.get("net_n")) + 1)
				if int(ub_.get("net_n")) >= 4:
					ub_.set("net_n", 0)
					if f.has_method("stun"):
						f.stun(1.0)
			if Stats.weapon_id == "fathom_score":
				f.set("mark_t", 2.0)
			if Stats.weapon_id == "oathbreak" and (bool(f.get("elite")) or bool(f.get("is_boss"))):
				dmg *= 1.5
			if Stats.weapon_id == "mistrune":
				var mr_ = get_tree().current_scene
				mr_.set("net_n", int(mr_.get("net_n")) + 1)
				if int(mr_.get("net_n")) >= 3:
					mr_.set("net_n", 0)
					f.set("slow_t", 1.5)
			if Stats.weapon_id == "sextant_edge":
				var sx_ = get_tree().current_scene
				sx_.set("net_n", int(sx_.get("net_n")) + 1)
				if int(sx_.get("net_n")) >= 5:
					sx_.set("net_n", 0)
					crit = true
			if crit:
				dmg *= 2.0
				Sfx.play("crit", 1.3 + randf() * 0.15)
			if Stats.weapon_id == "war_blade" and f.hp < f.hp_max * 0.35:
				dmg *= 1.5
			if Stats.weapon_id == "keelhook":
				var kh_: Vector3 = (global_position - f.global_position)
				kh_.y = 0
				f.kb -= kh_.normalized() * 0.5 * room_tile
			if Stats.weapon_id == "nightfang" and not bool(f.get("activated")):
				dmg *= 1.3
			if Stats.weapon_id == "hullbreaker" and f.hp >= f.hp_max * 0.95:
				dmg *= 1.25
			if Stats.weapon_id == "king_gavel":
				var kg_ := get_tree().current_scene
				if kg_ != null:
					kg_.set("net_n", int(kg_.get("net_n")) + 1)
					if int(kg_.get("net_n")) >= 7:
						kg_.set("net_n", 0)
						dmg *= 1.5
			f.take_hit(global_position, dmg)
			if get_tree().current_scene.get("tar_knots") == true:
				var tk_: Vector3 = f.global_position - global_position
				tk_.y = 0
				f.kb += tk_.normalized() * room_tile * 0.9
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
		"whale_saw": # SAW — tiap tebasan ke-4 menggergaji: +40% dmg pada musuh di bawah setengah HP
			var mw := get_tree().current_scene
			if mw != null:
				mw.set("net_n", int(mw.get("net_n")) + 1)
				if int(mw.get("net_n")) >= 4 and f.hp < f.hp_max * 0.5:
					mw.set("net_n", 0)
					if f.has_method("take_hit"):
						f.take_hit(global_position, dmg * 0.4)
					if mw.has_method("_damage_number"):
						mw._damage_number(f.global_position + Vector3(0, 0.6 * room_tile, 0), "SAWED", Color(1.0, 0.7, 0.3), false)
		"chimecleaver": # PEAL — tiap tebasan ke-6 membunyikan genta setrum
			var cc_ := get_tree().current_scene
			if cc_ != null:
				cc_.set("net_n", int(cc_.get("net_n")) + 1)
				if int(cc_.get("net_n")) >= 6:
					cc_.set("net_n", 0)
					for cf_ in cc_.get_tree().get_nodes_in_group("enemies"):
						if cf_.get("state") != "dead" and cf_.global_position.distance_to(f.global_position) < 1.6 * room_tile:
							cf_.stun(1.2)
					if cc_.has_method("_damage_number"):
						cc_._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "PEAL!", Color(0.95, 0.85, 0.4), true)
		"scurvy_blade": # SCURVY — tiap tebasan menambah pembusukan
			f.set("burn_t", float(f.get("burn_t")) + 0.8)
		"bilge_saw": # SAWED — tiap tebasan ke-5 membakar luka
			var bs_ := get_tree().current_scene
			if bs_ != null:
				bs_.set("net_n", int(bs_.get("net_n")) + 1)
				if int(bs_.get("net_n")) >= 5:
					bs_.set("net_n", 0)
					f.set("burn_t", 3.0)
					if bs_.has_method("_damage_number"):
						bs_._damage_number(f.global_position + Vector3(0, 0.8 * room_tile, 0), "SAWED", Color(1.0, 0.55, 0.3), false)
		"salt_pike": # GAFF — tiap tebasan ke-4 pada elite mencongkel +1 jiwa
			if bool(f.get("elite")):
				var gp_ := get_tree().current_scene
				if gp_ != null:
					gp_.set("net_n", int(gp_.get("net_n")) + 1)
					if int(gp_.get("net_n")) >= 4:
						gp_.set("net_n", 0)
						Stats.earn_souls(1)
						if gp_.has_method("_souls_l"):
							gp_._souls_l()
						if gp_.has_method("_damage_number"):
							gp_._damage_number(f.global_position + Vector3(0, 0.9 * room_tile, 0), "GAFF +1", Color(0.6, 0.9, 0.8), false)
		"coral_bludgeon": # REEFING — tiap tebasan ke-5 +8% speed 4s
			var cb_ := get_tree().current_scene
			if cb_ != null:
				cb_.set("net_n", int(cb_.get("net_n")) + 1)
				if int(cb_.get("net_n")) >= 5:
					cb_.set("net_n", 0)
					Stats.buff_speed_pct += 0.08
					refresh_stats()
					await get_tree().create_timer(4.0).timeout
					Stats.buff_speed_pct -= 0.08
					refresh_stats()
					if cb_.has_method("_damage_number"):
						cb_._damage_number(global_position + Vector3(0, 0.8 * room_tile, 0), "REEFING", Color(1.0, 0.65, 0.5), false)
		"quarterstaff": # SWEEP — tiap tebasan ke-8 mendorong semua musuh dekat
			var qst := get_tree().current_scene
			if qst != null:
				qst.set("net_n", int(qst.get("net_n")) + 1)
				if int(qst.get("net_n")) >= 8:
					qst.set("net_n", 0)
					var sw_n := 0
					for fo2 in get_tree().get_nodes_in_group("enemies"):
						if fo2.get("state") == "dead" or not is_instance_valid(fo2):
							continue
						if global_position.distance_to(fo2.global_position) > 1.8 * room_tile:
							continue
						var sdir: Vector3 = fo2.global_position - global_position
						sdir.y = 0
						fo2.kb += sdir.normalized() * room_tile * 8.0
						sw_n += 1
					if sw_n > 0:
						Sfx.play("whirl")
						if qst.has_method("_damage_number"):
							qst._damage_number(global_position + Vector3(0, 0.8 * room_tile, 0), "SWEEP ×%d" % sw_n, Color(0.85, 0.75, 0.5), false)
		"reef_chorus": # CHORUS — tiap tebasan ke-7 mempercepat skill terlama
			var rck := get_tree().current_scene
			if rck != null:
				rck.set("net_n", int(rck.get("net_n")) + 1)
				if int(rck.get("net_n")) >= 7:
					rck.set("net_n", 0)
					var longest := ""
					var longv := 0.0
					for sid2 in rck.get("skill_cd"):
						var cv := float(rck.get("skill_cd")[sid2])
						if cv > longv:
							longv = cv
							longest = String(sid2)
					if longest != "":
						rck.get("skill_cd")[longest] = maxf(0.0, longv - 3.0)
						if rck.has_method("_damage_number"):
							rck._damage_number(global_position + Vector3(0, 0.8 * room_tile, 0), "CHORUS", Color(0.5, 0.95, 0.8), false)
		"harpooner": # SKEWER — tiap tebasan ke-5: +50% dmg dan sundur baju musuh
			var hpk := get_tree().current_scene
			if hpk != null:
				hpk.set("net_n", int(hpk.get("net_n")) + 1)
				if int(hpk.get("net_n")) >= 5:
					hpk.set("net_n", 0)
					f.take_hit(global_position, dmg * 0.5)
					f.set("sunder_t", 4.0)
					if hpk.has_method("_damage_number"):
						hpk._damage_number(f.global_position + Vector3(0, 0.65 * room_tile, 0), "SKEWERED", Color(0.6, 0.8, 1.0), false)
		"gaff_hook": # GAFF — tiap tebasan ke-7 merobek musuh lain terdekat
			var gfk := get_tree().current_scene
			if gfk != null:
				gfk.set("net_n", int(gfk.get("net_n")) + 1)
				if int(gfk.get("net_n")) >= 7:
					gfk.set("net_n", 0)
					var best_gf = null
					var bd_gf := 999.0
					for fo in get_tree().get_nodes_in_group("enemies"):
						if fo == f or fo.get("state") == "dead" or not is_instance_valid(fo):
							continue
						var fd := global_position.distance_to(fo.global_position)
						if fd < bd_gf and fd < 3.0 * room_tile:
							bd_gf = fd
							best_gf = fo
					if best_gf != null:
						best_gf.take_hit(global_position, dmg * 0.4)
						if gfk.has_method("_damage_number"):
							gfk._damage_number(best_gf.global_position + Vector3(0, 0.65 * room_tile, 0), "GAFFED", Color(0.9, 0.6, 0.4), false)
		"riptide_fang": # RIP — tiap tebasan ke-6: lambatkan musuh + percepat langkahmu
			var rfk := get_tree().current_scene
			if rfk != null:
				rfk.set("net_n", int(rfk.get("net_n")) + 1)
				if int(rfk.get("net_n")) >= 6:
					rfk.set("net_n", 0)
					f.set("slow_t", 1.5)
					slip_t = 1.5
					if rfk.has_method("_damage_number"):
						rfk._damage_number(f.global_position + Vector3(0, 0.65 * room_tile, 0), "RIPTIDE", Color(0.4, 0.8, 0.9), false)
		"captains_hook": # HOOKED — tiap tebasan ke-5 menyeret musuh ke jangkauan
			var chk := get_tree().current_scene
			if chk != null:
				chk.set("net_n", int(chk.get("net_n")) + 1)
				if int(chk.get("net_n")) >= 5:
					chk.set("net_n", 0)
					if f.get("state") != "dead" and not bool(f.get("is_boss")):
						var pull_dir: Vector3 = (global_position - f.global_position)
						pull_dir.y = 0.0
						f.kb = pull_dir.normalized() * minf(pull_dir.length() * 4.0, 9.0) * (1.0 - float(f.get("kb_resist")))
						if chk.has_method("_damage_number"):
							chk._damage_number(f.global_position + Vector3(0, 0.65 * room_tile, 0), "HOOKED", Color(0.75, 0.55, 0.3), false)
		"murkmaker": # SLIP — tiap tebasan ke-5 memercepat langkah 3s
			var mmk := get_tree().current_scene
			if mmk != null:
				mmk.set("net_n", int(mmk.get("net_n")) + 1)
				if int(mmk.get("net_n")) >= 5:
					mmk.set("net_n", 0)
					slip_t = 3.0
					if mmk.has_method("_damage_number"):
						mmk._damage_number(global_position + Vector3(0, 0.7 * room_tile, 0), "SLIPSTREAM", Color(0.45, 0.7, 0.9), false)
		"saltpeter": # SPARK — tiap tebasan ke-4 melontarkan tembakan bubuk ke musuh terdekat kedua
			var msp := get_tree().current_scene
			if msp != null:
				msp.set("net_n", int(msp.get("net_n")) + 1)
				if int(msp.get("net_n")) >= 4:
					msp.set("net_n", 0)
					var best_sp = null
					var bd_sp := 999.0
					for f2 in get_tree().get_nodes_in_group("enemies"):
						if f2 == f or f2.get("state") == "dead" or not bool(f2.get("activated")):
							continue
						var dd2: float = f2.global_position.distance_to(global_position)
						if dd2 < bd_sp and dd2 < 2.5 * room_tile:
							bd_sp = dd2
							best_sp = f2
					if best_sp != null and best_sp.has_method("take_hit"):
						best_sp.take_hit(global_position, dmg * 0.8)
						if msp.has_method("_damage_number"):
							msp._damage_number(best_sp.global_position + Vector3(0, 0.7 * room_tile, 0), "POWDER!", Color(0.9, 0.7, 0.4), false)
		"silkfang": # SNARE — tiap tebasan ke-4 mengikat target: slow 1.5s
			var msf := get_tree().current_scene
			if msf != null:
				msf.set("net_n", int(msf.get("net_n")) + 1)
				if int(msf.get("net_n")) >= 4:
					msf.set("net_n", 0)
					f.slow_t = 1.5
					if msf.has_method("_damage_number"):
						msf._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "SNARED", Color(0.62, 0.55, 0.78), false)
		"brine_cutlass": # BRINE — tiap tebasan ke-6 encharca o alvo: slow 2s
			var mbc := get_tree().current_scene
			if mbc != null:
				mbc.set("net_n", int(mbc.get("net_n")) + 1)
				if int(mbc.get("net_n")) >= 6:
					mbc.set("net_n", 0)
					f.slow_t = 2.0
					if mbc.has_method("_damage_number"):
						mbc._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "BRINED", Color(0.5, 0.8, 0.75), false)
		"bilge_hook": # GUT — tiap tebasan ke-5 mengait jiwa: +1 soul
			var mbh := get_tree().current_scene
			if mbh != null:
				mbh.set("net_n", int(mbh.get("net_n")) + 1)
				if int(mbh.get("net_n")) >= 5:
					mbh.set("net_n", 0)
					Stats.earn_souls(1)
					if mbh.has_method("_souls_l"):
						mbh._souls_l()
					if mbh.has_method("_damage_number"):
						mbh._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "GUTTED +1", Color(0.6, 0.9, 0.95), false)
		"oarblade": # SLAP — tiap tebasan ke-3 memukul rata: lawan terpental sejauh 1 tile
			var mo := get_tree().current_scene
			if mo != null:
				mo.set("net_n", int(mo.get("net_n")) + 1)
				if int(mo.get("net_n")) >= 3:
					mo.set("net_n", 0)
					if float(f.get("kb_resist")) < 1.0:
						var bk2: Vector3 = f.global_position - global_position
						bk2.y = 0
						f.kb += bk2.normalized() * room_tile * 3.0
					if mo.has_method("_damage_number"):
						mo._damage_number(f.global_position + Vector3(0, 0.7 * room_tile, 0), "SLAPPED", Color(0.8, 0.7, 0.45), false)
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
	if Stats.dodge + 0.01 * float(Stats.meta.get("lampluck", 0)) > 0.0 and randf() < Stats.dodge + 0.01 * float(Stats.meta.get("lampluck", 0)):
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
	if mv != null and mv.has_method("_hurt_dir"):
		mv._hurt_dir(from_pos)
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
