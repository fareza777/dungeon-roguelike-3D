extends CharacterBody3D
class_name Enemy
const M = preload("res://materials.gd")
const EDB = preload("res://enemies_db.gd")
const PROJ = preload("res://projectile.gd")
# Musuh berbasis arketipe (enemies_db.gd): chaser, rogue (dash), mage (ranged),
# brute (tanky). Varian elite = stat multiplier + tint merah.
# AI: idle -> chase (mage jaga jarak) -> windup (telegraph) -> strike -> recover.

signal died(enemy)

var arch_id := "chaser"
var elite := false
var hp := 3.0
var xp_val := 1
var state := "idle"
var aggro_range := 9.0
var attack_range := 2.2
var prefer_range := 0.0
var ranged := false
var dash := false
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
var room_idx := 0
var activated := true
var stun_t := 0.0


func stun(t: float) -> void:
	if state == "dead":
		return
	stun_t = maxf(stun_t, t)
	state = "recover"
	state_t = maxf(state_t, t)
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
	hp = a["hp"] * hp_growth
	speed = a["spd"] * tile
	aggro_range = a["aggro"] * tile
	attack_range = a["reach"] * tile
	prefer_range = a.get("prefer", 0.0) * tile
	windup_t = a["windup"]
	dmg = a["dmg"]
	xp_val = a["xp"]
	ranged = a.get("ranged", false)
	dash = a.get("dash", false)
	proj_speed = a.get("proj_speed", 0.0) * tile
	kb_resist = a.get("kb_resist", 0.0)
	var sc: float = a["scale"]
	if elite:
		hp *= EDB.ELITE["hp_mult"]
		dmg += EDB.ELITE["dmg_add"]
		xp_val *= EDB.ELITE["xp_mult"]
		sc *= EDB.ELITE["scale_mult"]
		speed *= EDB.ELITE["spd_mult"]
	scale = Vector3.ONE * sc
	if elite:
		print("SPAWN ELITE ", arch_id)


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
	M.play_fuzzy(ap, ["idle"])


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
	if stun_t > 0.0:
		stun_t -= delta
		velocity = kb
		kb = kb.move_toward(Vector3.ZERO, delta * room_tile * 8.0)
		move_and_slide()
		global_position.y = 0.0
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

	if p.get("dead") == true and state != "idle":
		state = "idle"
		if anim_lock <= 0.0:
			M.play_fuzzy(ap, ["idle"])

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
				if mat != null:
					mat.set_shader_parameter("flash", 0.4)
				if anim_lock <= 0.0:
					M.play_fuzzy(ap, ["idle_combat", "idle"])
			else:
				var dir := to.normalized()
				# mage mundur kalau player terlalu dekat
				if ranged and dist < prefer_range * 0.55:
					dir = -dir
				velocity = dir * speed + _separation() + kb
				if anim_lock <= 0.0:
					M.play_fuzzy(ap, ["run", "walk"])
		"windup":
			velocity = Vector3.ZERO
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 6.0)
			if state_t <= 0.0:
				state = "strike"
				if mat != null:
					var tw := create_tween()
					tw.tween_property(mat, "shader_parameter/flash", 0.0, 0.1)
				if ranged:
					anim_lock = M.play_action(ap, ["spellcast_shoot", "spellcast"], 1.2) * 0.7
					await get_tree().create_timer(0.22).timeout
					if state == "strike":
						var q2 := _player()
						if q2 != null and q2.get("dead") != true:
							var pr = PROJ.new()
							get_parent().add_child(pr)
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
						state = "recover"
						state_t = 0.7
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


func take_hit(from_pos: Vector3, dmg_taken: float) -> void:
	if state == "dead":
		return
	hp -= dmg_taken
	Sfx.play("hit")
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
		anim_lock = M.play_action(ap, ["death"], 1.0)
		died.emit(self)
	else:
		anim_lock = max(anim_lock, M.play_action(ap, ["hit_"], 1.4) * 0.6)
