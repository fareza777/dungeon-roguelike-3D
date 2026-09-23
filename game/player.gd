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
var hp := 5.0
var max_hp := 5.0
var attack_cooldown := 0.45
var cd := 0.0
var invuln := 0.0
var dead := false
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
var dash_dir := Vector3.ZERO
var step_t := 0.0


func dash_burst(dir: Vector3) -> void:
	if dead:
		return
	dash_t = 0.22
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
	if dash_t > 0.0:
		dash_t -= delta
		velocity = dash_dir * speed * 4.2
		move_and_slide()
		global_position.x = clamp(global_position.x, bounds.get("min_x", -100.0), bounds.get("max_x", 100.0))
		global_position.z = clamp(global_position.z, bounds.get("min_z", -100.0), bounds.get("max_z", 100.0))
		global_position.y = 0.0
		return
	var dir := Vector3(move_input.x, 0, move_input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	# akselerasi halus: kecepatan mengejar target, bukan langsung penuh
	base_v = base_v.lerp(dir * speed, 1.0 - pow(0.0005, delta))
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
			var crit := randf() < Stats.get_stat("crit")
			if crit:
				dmg *= 2.0
			f.take_hit(global_position, dmg)
			var heal: float = dmg * Stats.get_stat("lifesteal")
			if heal > 0.0:
				hp = minf(max_hp, hp + heal)
				hp_changed.emit(hp)
			hit_landed.emit(f.global_position, dmg, crit)


func take_hit(from_pos: Vector3, dmg_taken: int) -> void:
	if dead or invuln > 0.0 or Stats.draft_open:
		return
	# relic Fase Hantu: peluang menghindar penuh
	if Stats.dodge > 0.0 and randf() < Stats.dodge:
		invuln = 0.5
		Sfx.play("dash")
		if mat != null:
			mat.set_shader_parameter("flash", 0.5)
			var dtw := create_tween()
			dtw.tween_property(mat, "shader_parameter/flash", 0.0, 0.25)
		return
	var eff := maxi(1, dmg_taken - int(Stats.get_stat("armor")))
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
