extends Node3D
# Permata XP: memantul keluar dari musuh, magnet ke player, diserap -> Stats.add_xp.

var value := 1
var t := 0.0
var vel := Vector3.ZERO
var tile := 4.0
var absorbed := false


func setup(val: int, p_tile: float) -> void:
	value = val
	tile = p_tile
	var mi := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radial_segments = 5
	om.rings = 3
	om.radius = 0.075 * tile * (1.0 + 0.12 * mini(val - 1, 3))
	om.height = 0.19 * tile * (1.0 + 0.12 * mini(val - 1, 3))
	mi.mesh = om
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 1.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.5)
	mat.emission_energy_multiplier = 2.2
	mi.material_override = mat
	add_child(mi)
	vel = Vector3(randf_range(-1.0, 1.0), randf_range(2.5, 4.0), randf_range(-1.0, 1.0)) * 0.12 * tile


func _physics_process(delta: float) -> void:
	if absorbed:
		return
	t += delta
	rotation.y += delta * 4.0
	var settled := false
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
	settled = vel == Vector3.ZERO
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
					scale = Vector3.ONE * clampf(0.45 + 0.55 * dist / range, 0.45, 1.0)
					if dist < 0.6:
						absorbed = true
						Stats.add_xp(value)
						Sfx.play("xp", 0.94 + randf() * 0.14)
						var m := get_tree().current_scene
						if m != null and m.has_method("_quest_event"):
							m._quest_event("gem")
						queue_free()
				elif settled:
					position.y = 0.14 + sin(t * 2.6) * 0.06
