extends Node3D
# Kolam api sisa slam Ember King — berdiri 4s, membakar pemain yang berdiri di atasnya.

var tile := 4.0
var life := 4.0
var tick := 0.0
var t := 0.0
var disc: MeshInstance3D = null
var glow: OmniLight3D = null


func setup(p_tile: float) -> void:
	tile = p_tile
	glow = OmniLight3D.new()
	glow.light_color = Color(1.0, 0.45, 0.12)
	glow.light_energy = 1.1
	glow.omni_range = 1.3 * tile
	glow.position.y = 0.3 * tile
	add_child(glow)
	disc = MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.55 * tile
	dm.bottom_radius = 0.55 * tile
	dm.height = 0.03 * tile
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.4, 0.08, 0.55)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.3, 0.05)
	m.emission_energy_multiplier = 1.8
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.material = m
	disc.mesh = dm
	disc.position.y = 0.04 * tile
	add_child(disc)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	tick -= delta
	if disc != null:
		var f: float = 0.8 + 0.2 * sin(t * 9.0)
		disc.scale = Vector3(f, 1.0, f)
		if life < 1.0 and disc.mesh != null:
			var mm: StandardMaterial3D = disc.mesh.material
			mm.albedo_color.a = life * 0.55
	if glow != null:
		# api berkerlap tidak beraturan: dua sinus tak selaras + jitter kecil
		glow.light_energy = (0.9 + 0.25 * sin(t * 11.0) + 0.1 * sin(t * 23.7)) * clampf(life, 0.0, 1.0)
	if life <= 0.0:
		queue_free()
		return
	if tick > 0.0:
		return
	tick = 0.5
	for p in get_tree().get_nodes_in_group("player"):
		if p.get("dead") == true:
			continue
		var d: Vector3 = p.global_position - global_position
		d.y = 0
		if d.length() < 0.55 * tile:
			p.take_hit(global_position, 1.0)
