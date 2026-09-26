extends Node3D
# Batu pengetahuan: kristal rune melayang berpendar teal.
# Dekati -> satu baris lore dari Oracle via dialog. Sekali pakai, lalu menghilang.

signal invoked(stone)

var tile := 4.0
var used := false
var glow: OmniLight3D = null
var crystal: MeshInstance3D = null
var t := 0.0


func setup(p_tile: float) -> void:
	add_to_group("glints")
	tile = p_tile
	crystal = MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.3 * tile, 0.68 * tile, 0.3 * tile)
	crystal.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.55, 0.95, 1.0, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.8, 1.0)
	mat.emission_energy_multiplier = 2.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal.material_override = mat
	crystal.position.y = 0.6 * tile
	add_child(crystal)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.34 * tile
	tor.outer_radius = 0.42 * tile
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.4, 0.85, 1.0, 0.6)
	rm.emission_enabled = true
	rm.emission = Color(0.3, 0.75, 1.0)
	rm.emission_energy_multiplier = 1.8
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = rm
	ring.mesh = tor
	ring.position.y = 0.05 * tile
	add_child(ring)
	glow = OmniLight3D.new()
	glow.light_color = Color(0.45, 0.8, 1.0)
	glow.light_energy = 1.1
	glow.omni_range = 1.6 * tile
	glow.position.y = 0.8 * tile
	add_child(glow)


func _physics_process(delta: float) -> void:
	t += delta
	if crystal != null:
		crystal.position.y = 0.6 * tile + sin(t * 2.0) * 0.08 * tile
		crystal.rotation.y += delta * 1.3
	if glow != null:
		glow.light_energy = 1.0 + sin(t * 2.8) * 0.3
	if used:
		return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p: Node3D = ps[0]
	if p.get("dead"):
		return
	var d: Vector3 = p.global_position - global_position
	d.y = 0
	if d.length() < 0.55 * tile:
		used = true
		invoked.emit(self)


func consume() -> void:
	used = true
	var tw := create_tween()
	tw.set_parallel(true)
	if crystal != null:
		tw.tween_property(crystal, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK)
	if glow != null:
		tw.tween_property(glow, "light_energy", 0.0, 0.4)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)
