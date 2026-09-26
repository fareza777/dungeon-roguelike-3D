extends Node3D
# Peluru sihir musuh: lurus, umur terbatas. Tabrakan diukur pakai jarak
# (karakter kita tidak punya collision shape).

var vel := Vector3.ZERO
var dmg := 1
var hit_r := 0.5
var life := 3.0
var t := 0.0
var orb: MeshInstance3D = null
var effect := ""
var hook_src := Vector3.ZERO


func _ready() -> void:
	add_to_group("enemy_proj")
	orb = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.7, 0.4, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.65, 0.3, 1.0)
	m.emission_energy_multiplier = 3.0
	sm.material = m
	orb.mesh = sm
	add_child(orb)
	# jejak ekor di belakang arah gerak
	var tail := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.06, 0.55)
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_color = Color(0.6, 0.35, 1.0, 0.5)
	tm.emission_enabled = true
	tm.emission = Color(0.55, 0.3, 1.0)
	tm.emission_energy_multiplier = 1.6
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.material = tm
	tail.mesh = bm
	tail.position.z = 0.35
	add_child(tail)


func launch(from: Vector3, target: Vector3, speed: float, p_dmg: float, p_hit_r: float) -> void:
	global_position = from
	var d: Vector3 = target - from
	d.y = 0
	vel = d.normalized() * speed
	dmg = int(round(p_dmg))
	hit_r = p_hit_r
	look_at(global_position + vel, Vector3.UP)


func _physics_process(delta: float) -> void:
	t += delta
	if orb != null:
		var s: float = 1.0 + sin(t * 18.0) * 0.18
		orb.scale = Vector3(s, s, s)
	position += vel * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if Stats.draft_open:
		return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p: Node3D = ps[0]
	if p.get("dead"):
		return
	var d: Vector3 = global_position - (p.global_position + Vector3(0, 0.9, 0))
	if d.length() < hit_r:
		p.take_hit(global_position, dmg)
		if effect == "silence" and not p.get("dead"):
			p.set("silence_t", 4.0)
			var m8 := get_tree().current_scene
			if m8 != null and m8.has_method("_damage_number"):
				m8._damage_number(p.global_position + Vector3(0, 1.2, 0), "SILENCED", Color(1.0, 0.3, 0.45), true)
		if effect == "chill" and not p.get("dead"):
			p.set("chill_t", 3.0)
			var mh_c := get_tree().current_scene
			if mh_c != null and mh_c.has_method("_damage_number"):
				mh_c._damage_number(p.global_position + Vector3(0, 1.2, 0), "CHILLED", Color(0.5, 0.85, 1.0), false)
		if effect == "gale" and not p.get("dead"):
			var gd_: Vector3 = p.global_position - global_position
			gd_.y = 0
			if gd_.length() > 0.2:
				p.set("kb", p.get("kb") + gd_.normalized() * 12.0)
			var mgg := get_tree().current_scene
			if mgg != null and mgg.has_method("_damage_number"):
				mgg._damage_number(p.global_position + Vector3(0, 1.2, 0), "GUST!", Color(0.6, 0.9, 1.0), true)
		if effect == "hook" and not p.get("dead"):
			var hd_: Vector3 = hook_src - p.global_position
			hd_.y = 0
			if hd_.length() > 1.0:
				p.set("kb", p.get("kb") + hd_.normalized() * 9.0)
			var mhh := get_tree().current_scene
			if mhh != null and mhh.has_method("_damage_number"):
				mhh._damage_number(p.global_position + Vector3(0, 1.2, 0), "HOOKED!", Color(0.5, 0.85, 0.9), true)
		if effect == "weak" and not p.get("dead"):
			p.set("weak_t", 3.0)
			var m9 := get_tree().current_scene
			if m9 != null and m9.has_method("_damage_number"):
				m9._damage_number(p.global_position + Vector3(0, 1.2, 0), "WEAKENED", Color(0.9, 0.6, 0.3), true)
		if effect == "venom" and not p.get("dead"):
			p.set("venom_t", 4.0)
			var mv := get_tree().current_scene
			if mv != null and mv.has_method("_damage_number"):
				mv._damage_number(p.global_position + Vector3(0, 1.2, 0), "VENOMED", Color(0.5, 0.9, 0.3), true)
		var mi := get_tree().current_scene
		if mi != null and mi.has_method("_burst"):
			mi._burst(global_position, Color(0.7, 0.4, 1.0))
		queue_free()
