extends Node3D
# Kunang jiwa: berkeliaran pelan di lorong, memudar setelah ~22 detik.
# Diserap saat disentuh -> +1 soul. Pola pickup seperti vial/health_orb.

var t := 0.0
var life := 22.0
var tile := 4.0
var dir := Vector3.ZERO
var retarget := 0.0
var absorbed := false


func setup(p_tile: float) -> void:
	tile = p_tile
	var mi := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radial_segments = 10
	om.rings = 8
	om.radius = 0.06 * tile
	om.height = 0.12 * tile
	mi.mesh = om
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.5, 0.95, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.95, 0.85)
	mat.emission_energy_multiplier = 3.2
	mi.material_override = mat
	add_child(mi)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.45, 0.95, 0.85)
	gl.light_energy = 0.8
	gl.omni_range = 0.8 * tile
	add_child(gl)
	dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()


func _physics_process(delta: float) -> void:
	if absorbed:
		return
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if life < 3.0:
		scale = Vector3.ONE * maxf(0.05, life / 3.0)
	else:
		scale = Vector3.ONE * (1.0 + 0.12 * sin(t * 6.0))
	retarget -= delta
	if retarget <= 0.0:
		retarget = randf_range(1.0, 2.0)
		dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	# melayang pelan — hindari nabrak terlalu jauh: pantul di radius 2.4 tile dari spawn
	# Soul Lens (lensa_jiwa): kunang terhisap ke pemain dari radius 2.6 tile
	var pl := get_tree().get_nodes_in_group("player")
	if not pl.is_empty() and Stats.relics.has("lensa_jiwa"):
		var d: Vector3 = pl[0].global_position - global_position
		d.y = 0.0
		if d.length() < 2.6 * tile and d.length() > 0.2:
			dir = d.normalized()
			global_position += dir * 1.15 * tile * delta
		else:
			global_position += dir * 0.45 * tile * delta
	else:
		global_position += dir * 0.45 * tile * delta
	global_position.y = 0.35 * tile + 0.05 * tile * sin(t * 3.0)
	var ps := get_tree().get_nodes_in_group("player")
	if not ps.is_empty():
		var p: Node3D = ps[0]
		if p.get("dead") != true:
			var d: Vector3 = p.global_position + Vector3(0.0, 0.8, 0.0) - global_position
			d.y = 0.0
			if d.length() < 0.35 * tile:
				absorbed = true
				var m0 := get_tree().current_scene
				var wp := 2 if (m0 != null and (bool(m0.get("low_tide")) or bool(m0.get("starved_deep")))) else 1
				if m0 != null and bool(m0.get("moonwrit")):
					wp += 1
				if Stats.relics.has("soul_creel"):
					wp += 1
				if m0 != null and bool(m0.get("waxpale")):
					wp *= 2
				wp += int(Stats.meta.get("shepherd", 0))
				Stats.earn_souls(wp)
				if m0 != null and m0.get("biome") is Dictionary and String(m0.biome.get("name", "")) == "Sunken Reliquary":
					m0.reliquary_wisps += wp
					if m0.reliquary_wisps >= 15 and m0.has_method("_ach"):
						m0._ach("salvager")
				if p.hp < Stats.get_stat("max_hp"):
					p.hp = minf(p.hp + Stats.get_stat("max_hp") * 0.02, Stats.get_stat("max_hp"))
					p.hp_changed.emit(p.hp)
				if Stats.relics.has("stoples_bara"):
					Stats.add_xp(3)
				Stats.save_game()
				var cb_ := 0
				var cbv_ = m0.get("combo") if m0 != null else null
				if cbv_ != null:
					cb_ = int(cbv_)
				Sfx.play("xp", 0.9 + randf() * 0.08 + minf(cb_, 12) * 0.02)
				var m := get_tree().current_scene
				if m != null:
					if m.has_method("_burst"):
						m._burst(global_position, Color(0.45, 0.95, 0.85))
					if m.has_method("_souls_l"):
						m._souls_l()
					if m.has_method("_quest_event"):
						m._quest_event("wisp")
					if m.has_method("_damage_number"):
						m._damage_number(global_position + Vector3(0, 0.4 * tile, 0), "+1 ◈", Color(0.45, 0.95, 0.85), false)
				queue_free()
