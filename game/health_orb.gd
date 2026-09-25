extends Node3D
# Bola jiwa merah: memantul dari musuh, magnet ke player, diserap -> heal.
# Turunan pola xp_gem (bounce pendek -> magnet -> absorb).

var heal := 1.0
var t := 0.0
var vel := Vector3.ZERO
var tile := 4.0
var absorbed := false


func setup(p_heal: float, p_tile: float) -> void:
	heal = p_heal
	tile = p_tile
	var mi := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radial_segments = 6
	om.rings = 4
	om.radius = 0.09 * tile
	om.height = 0.22 * tile
	mi.mesh = om
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.3, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.25, 0.3)
	mat.emission_energy_multiplier = 2.4
	mi.material_override = mat
	add_child(mi)
	vel = Vector3(randf_range(-1.0, 1.0), randf_range(2.2, 3.6), randf_range(-1.0, 1.0)) * 0.12 * tile


func _physics_process(delta: float) -> void:
	if absorbed:
		return
	t += delta
	rotation.y += delta * 5.0
	# denyut pelan biar kelihatan hidup
	scale = Vector3.ONE * (1.0 + 0.12 * sin(t * 6.0))
	if position.y > 0.14 or vel.y > 0.0:
		vel.y -= 22.0 * delta
		position += vel * delta
		if position.y < 0.14:
			position.y = 0.14
			vel.y = absf(vel.y) * 0.35
			vel.x *= 0.6
			vel.z *= 0.6
			if vel.y < 0.4:
				vel = Vector3.ZERO
	if t > 0.45:
		var ps := get_tree().get_nodes_in_group("player")
		if not ps.is_empty():
			var p: Node3D = ps[0]
			if p.get("dead") != true:
				var d: Vector3 = p.global_position + Vector3(0.0, 0.8, 0.0) - global_position
				var dist := d.length()
				var range := 1.4 * tile * (1.0 + Stats.magnet)
				if dist < range:
					var zip := 1.0 + clampf(1.0 - dist / range, 0.0, 1.0) * 2.6
					global_position += d.normalized() * (6.0 + t * 6.0) * zip * delta
					if dist < 0.6:
						absorbed = true
						var maxh := Stats.get_stat("max_hp")
						if p.hp < maxh - 0.01:
							p.hp = minf(maxh, p.hp + heal)
							p.hp_changed.emit(p.hp)
							Sfx.play("pickup", 0.95 + randf() * 0.12)
							var msn_ := get_tree().current_scene
							if msn_ != null and msn_.has_method("_damage_number"):
								msn_._damage_number(p.global_position + Vector3(0, 0.8, 0), "+%d" % int(ceil(heal)), Color(0.4, 1.0, 0.55), false)
						else:
							Sfx.play("xp")
						queue_free()
