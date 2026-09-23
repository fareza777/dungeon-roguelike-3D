extends Node3D
# Jebakan duri: plat gelap + 9 duri tulang naik-turun berirama.
# Nyalanya memberi getar 0.22s sebagai telegraph; kena = 1 dmg + knockback.

var spikes: Node3D
var tile := 4.0
var t := 0.0
var phase := 0.0 # offset irama
var up := false
var armed := true
var warn_tw: Tween = null


func setup(p_tile: float, offset: float) -> void:
	tile = p_tile
	phase = offset
	# plat dasar
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5 * tile, 0.03 * tile, 0.5 * tile)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.09, 0.09, 0.12)
	bmat.metallic = 0.3
	bm.material = bmat
	base.mesh = bm
	base.position.y = 0.015 * tile
	add_child(base)
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
	smat.albedo_color = Color(0.85, 0.82, 0.7)
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
				if d.length() < 0.28 * tile:
					p.take_hit(global_position, 1)


func disarm() -> void:
	armed = false
	spikes.position.y = -0.29 * tile
