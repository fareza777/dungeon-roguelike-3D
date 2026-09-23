extends Node3D
# Jebakan: kind 0 = plat duri tulang naik-turun; kind 1 = semburan api berirama
# (lingkaran membara = telegraph, cone api muncul saat aktif); kind 2 = sigil beku
# (chill); kind 3 = sigil void (menjerat kaki). Kena = 1 dmg.

var spikes: Node3D
var jet: MeshInstance3D = null
var glow: MeshInstance3D = null
var kind := 0 # 0 = duri, 1 = api, 2 = sigil beku, 3 = void, 4 = lentera penyembuh
var tile := 4.0
var t := 0.0
var phase := 0.0 # offset irama
var up := false
var armed := true
var warn_tw: Tween = null


func setup(p_tile: float, offset: float, p_kind := 0) -> void:
	tile = p_tile
	phase = offset
	kind = p_kind
	# plat dasar
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5 * tile, 0.03 * tile, 0.5 * tile)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.16, 0.07, 0.04) if kind == 1 else (Color(0.05, 0.1, 0.2) if kind == 2 else (Color(0.14, 0.05, 0.2) if kind == 3 else (Color(0.05, 0.14, 0.08) if kind == 4 else Color(0.09, 0.09, 0.12))))
	bmat.metallic = 0.3
	bm.material = bmat
	base.mesh = bm
	base.position.y = 0.015 * tile
	add_child(base)
	if kind == 1:
		# lingkaran emas membara (telegraph api)
		glow = MeshInstance3D.new()
		var gm := PlaneMesh.new()
		gm.size = Vector2(0.42 * tile, 0.42 * tile)
		var gmat := StandardMaterial3D.new()
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gmat.albedo_color = Color(1.0, 0.35, 0.08, 0.85)
		gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.material = gmat
		glow.mesh = gm
		glow.position.y = 0.035 * tile
		add_child(glow)
		# sembur api (cone)
		jet = MeshInstance3D.new()
		var jm := CylinderMesh.new()
		jm.top_radius = 0.05 * tile
		jm.bottom_radius = 0.22 * tile
		jm.height = 0.75 * tile
		var jmat := StandardMaterial3D.new()
		jmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		jmat.albedo_color = Color(1.0, 0.45, 0.1, 0.8)
		jmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		jm.material = jmat
		jet.mesh = jm
		jet.position.y = 0.375 * tile
		jet.scale = Vector3(1, 0.001, 1)
		jet.visible = false
		add_child(jet)
		return
	if kind == 2 or kind == 3 or kind == 4:
		# sigil beku / void / lentera — cincin telegraph berdenyut
		glow = MeshInstance3D.new()
		var gm3 := PlaneMesh.new()
		gm3.size = Vector2(0.44 * tile, 0.44 * tile)
		var gmat3 := StandardMaterial3D.new()
		gmat3.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gmat3.albedo_color = Color(0.4, 0.75, 1.0, 0.8) if kind == 2 else (Color(0.5, 1.0, 0.55, 0.85) if kind == 4 else Color(0.75, 0.3, 1.0, 0.8))
		gmat3.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm3.material = gmat3
		glow.mesh = gm3
		glow.position.y = 0.035 * tile
		add_child(glow)
		if kind == 4:
			return
	# lubang duri (lubang gelap biar kelihatan ada jebakan)
	var holes := MeshInstance3D.new()
	var hm := PlaneMesh.new()
	hm.size = Vector2(0.42 * tile, 0.42 * tile)
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.albedo_color = Color(0.02, 0.02, 0.03)
	hm.material = hmat
	holes.mesh = hm
	holes.position.y = 0.04 * tile
	add_child(holes)
	# duri
	spikes = Node3D.new()
	add_child(spikes)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.6, 0.85, 1.15) if kind == 2 else (Color(0.75, 0.5, 1.0) if kind == 3 else Color(0.85, 0.82, 0.7))
	for i in range(3):
		for j in range(3):
			var s := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 0.035 * tile
			cm.height = 0.28 * tile
			cm.material = smat
			s.mesh = cm
			s.position = Vector3((i - 1) * 0.14 * tile, 0.14 * tile, (j - 1) * 0.14 * tile)
			spikes.add_child(s)
	spikes.position.y = -0.29 * tile


func _physics_process(delta: float) -> void:
	t += delta
	var cyc: float = fmod(t + phase, 1.9)
	var target: float
	if cyc < 0.9:
		target = -0.29 * tile # tidur
	elif cyc < 1.1:
		target = 0.0 # keluar
	else:
		target = -0.29 * tile
	var prev_up := up
	up = cyc >= 0.9 and cyc < 1.1
	if kind == 1:
		if jet != null:
			jet.visible = up or jet.scale.y > 0.05
			var jscale: float = lerpf(jet.scale.y, 1.0 if up else 0.001, delta * (20.0 if up else 12.0))
			jet.scale = Vector3(1.0 + 0.25 * randf(), jscale, 1.0 + 0.25 * randf())
			jet.rotation.y += delta * 7.0
		if glow != null:
			var gm2: StandardMaterial3D = glow.mesh.material
			gm2.albedo_color.a = 0.5 + 0.5 * sin(t * 9.0) if not up else 1.0
	else:
		if (kind == 2 or kind == 3 or kind == 4) and glow != null:
			var gm4: StandardMaterial3D = glow.mesh.material
			gm4.albedo_color.a = 0.45 + 0.45 * sin(t * 7.0) if not up else 1.0
		if spikes != null:
			spikes.position.y = lerpf(spikes.position.y, target, delta * (22.0 if up else 10.0))
	if up and not prev_up:
		Sfx.play("trap")
	if up and armed:
		var ps := get_tree().get_nodes_in_group("player")
		if not ps.is_empty():
			var p: Node3D = ps[0]
			if p.get("dead") != true and p.get("invuln") <= 0.0:
				var d: Vector3 = p.global_position - global_position
				d.y = 0
				if d.length() < (0.3 * tile if kind == 1 else 0.28 * tile):
					if kind == 4:
						if float(p.get("hp")) < float(p.get("max_hp")):
							p.set("hp", minf(float(p.get("max_hp")), float(p.get("hp")) + 1.0))
							p.emit_signal("hp_changed", p.get("hp"))
							Sfx.play("pickup")
							var ml := get_tree().current_scene
							if ml != null and ml.has_method("_burst"):
								ml._burst(p.global_position + Vector3(0, 0.4, 0), Color(0.5, 1.0, 0.55))
							armed = false
					else:
						if kind == 2:
							p.set("chill_t", 2.0)
						elif kind == 3:
							p.set("root_t", 1.0)
						p.take_hit(global_position, 1)


func disarm() -> void:
	armed = false
	if kind == 1:
		if jet != null:
			jet.visible = false
	else:
		if spikes != null:
			spikes.position.y = -0.29 * tile
		if glow != null:
			glow.visible = false
