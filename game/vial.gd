extends Node3D
# Botol jiwa: drop langka dari musuh / guci — disimpan di satchel (maks 2),
# diminum lewat tombol VIAL untuk heal 30% HP. Pola seperti health_orb.

var t := 0.0
var vel := Vector3.ZERO
var tile := 4.0
var absorbed := false


func setup(p_tile: float) -> void:
	add_to_group("glints")
	tile = p_tile
	# badan botol: bola memanjang
	var mi := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radial_segments = 8
	om.rings = 6
	om.radius = 0.075 * tile
	om.height = 0.24 * tile
	mi.mesh = om
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.3, 0.95, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 0.7)
	mat.emission_energy_multiplier = 2.6
	mi.material_override = mat
	add_child(mi)
	# leher botol
	var nk := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.02 * tile
	nm.bottom_radius = 0.03 * tile
	nm.height = 0.1 * tile
	nk.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.7, 0.6, 0.4)
	nmat.metallic = 0.6
	nk.material_override = nmat
	nk.position.y = 0.14 * tile
	add_child(nk)
	vel = Vector3(randf_range(-1.0, 1.0), randf_range(2.4, 3.8), randf_range(-1.0, 1.0)) * 0.1 * tile


func _physics_process(delta: float) -> void:
	if absorbed:
		return
	t += delta
	rotation.y += delta * 4.0
	scale = Vector3.ONE * (1.0 + 0.1 * sin(t * 5.0))
	if position.y > 0.16 or vel.y > 0.0:
		vel.y -= 22.0 * delta
		position += vel * delta
		if position.y < 0.16:
			position.y = 0.16
			vel.y = absf(vel.y) * 0.35
			vel.x *= 0.6
			vel.z *= 0.6
			if vel.y < 0.4:
				vel = Vector3.ZERO
	if t > 0.5:
		var ps := get_tree().get_nodes_in_group("player")
		if not ps.is_empty():
			var p: Node3D = ps[0]
			if p.get("dead") != true:
				var d: Vector3 = p.global_position + Vector3(0.0, 0.8, 0.0) - global_position
				var dist := d.length()
				if dist < 1.5 * tile * (1.0 + Stats.magnet):
					global_position += d.normalized() * (5.0 + t * 5.0) * delta
					if dist < 0.6:
						absorbed = true
						var m := get_tree().current_scene
						if m != null and m.has_method("_add_vial"):
							m._add_vial()
						Sfx.play("pickup")
						queue_free()
