extends Node3D
# Peluru sihir musuh: lurus, umur terbatas. Tabrakan diukur pakai jarak
# (karakter kita tidak punya collision shape).

var vel := Vector3.ZERO
var dmg := 1
var hit_r := 0.5
var life := 3.0


func _ready() -> void:
	add_to_group("enemy_proj")
	var mi := MeshInstance3D.new()
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
	mi.mesh = sm
	add_child(mi)


func launch(from: Vector3, target: Vector3, speed: float, p_dmg: float, p_hit_r: float) -> void:
	global_position = from
	var d: Vector3 = target - from
	d.y = 0
	vel = d.normalized() * speed
	dmg = int(round(p_dmg))
	hit_r = p_hit_r


func _physics_process(delta: float) -> void:
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
		queue_free()
