extends Node3D
# Gerbang portcullis prosedural. Terbuka = tenggelam ke lantai,
# tertutup = naik menghalangi pintu (kunci arena per ruangan).

var bars: Node3D
var body: StaticBody3D
var cs: CollisionShape3D
var height := 3.0
var open := true
var tw: Tween = null
var glow_mat: StandardMaterial3D = null
var chev: MeshInstance3D = null
var exit_light: OmniLight3D = null


func setup(tile: float, wall_h: float) -> void:
	height = wall_h
	bars = Node3D.new()
	add_child(bars)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.12, 0.15)
	mat.metallic = 0.8
	mat.roughness = 0.5
	var gap_w := 0.6 * tile
	var n_bars := 5
	for i in range(n_bars):
		var x := -gap_w * 0.5 + gap_w * float(i) / float(n_bars - 1)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.045 * tile, height, 0.05 * tile)
		mi.mesh = bm
		mi.material_override = mat
		mi.position = Vector3(x, height * 0.5, 0.0)
		bars.add_child(mi)
		var sp := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045 * tile
		cm.bottom_radius = 0.0
		cm.height = 0.2 * tile
		sp.mesh = cm
		sp.material_override = mat
		sp.rotation_degrees.x = 180.0
		sp.position = Vector3(x, -0.1 * tile, 0.0)
		bars.add_child(sp)
	for j in range(3):
		var hb := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(gap_w + 0.06 * tile, 0.06 * tile, 0.07 * tile)
		hb.mesh = hm
		hb.material_override = mat
		hb.position = Vector3(0.0, height * (0.22 + 0.28 * j), 0.0)
		bars.add_child(hb)
	body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	cs = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(gap_w + 0.1 * tile, height, 0.3 * tile)
	cs.shape = box
	cs.position.y = height * 0.5
	body.add_child(cs)
	add_child(body)
	# strip menyala di ambang: merah redup = terkunci, emas = terbuka
	glow_mat = StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.emission_enabled = true
	glow_mat.emission_energy_multiplier = 2.2
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var gm := PlaneMesh.new()
	gm.size = Vector2(gap_w + 0.15 * tile, 0.3 * tile)
	gm.material = glow_mat
	var glow := MeshInstance3D.new()
	glow.mesh = gm
	glow.rotation.x = -PI / 2
	glow.position.y = 0.03 * tile
	add_child(glow)
	# chevron melayang penanda jalan keluar
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.15 * tile
	cm2.bottom_radius = 0.0
	cm2.height = 0.22 * tile
	chev = MeshInstance3D.new()
	chev.mesh = cm2
	chev.material_override = glow_mat
	chev.rotation_degrees.x = 180.0
	chev.position.y = height * 0.68
	add_child(chev)
	var btw := chev.create_tween()
	btw.set_loops()
	btw.tween_property(chev, "position:y", height * 0.68 + 0.1 * tile, 0.7).set_trans(Tween.TRANS_SINE)
	btw.tween_property(chev, "position:y", height * 0.68 - 0.1 * tile, 0.7).set_trans(Tween.TRANS_SINE)
	# lampu exit: lingkaran cahaya emas di lantai pintu terbuka
	exit_light = OmniLight3D.new()
	exit_light.light_color = Color(1.0, 0.8, 0.35)
	exit_light.light_energy = 0.0
	exit_light.omni_range = 1.5 * tile
	exit_light.position = Vector3(0, 0.5 * tile, 0)
	add_child(exit_light)
	set_open(true, true)


func set_open(o: bool, instant := false) -> void:
	if o == open and not instant:
		return
	open = o
	cs.set_deferred("disabled", o)
	if glow_mat != null:
		if o:
			glow_mat.albedo_color = Color(1.0, 0.8, 0.35, 0.55)
			glow_mat.emission = Color(1.0, 0.75, 0.3)
		else:
			glow_mat.albedo_color = Color(0.55, 0.14, 0.1, 0.25)
			glow_mat.emission = Color(0.5, 0.12, 0.08)
		chev.visible = o
		if exit_light != null:
			exit_light.light_energy = 1.1 if o else 0.0
	if tw != null and tw.is_valid():
		tw.kill()
	var target_y: float = -height - 0.2 if o else 0.0
	if instant:
		bars.position.y = target_y
		return
	Sfx.play("gate", 1.1 if o else 0.85)
	tw = create_tween()
	if o:
		tw.tween_property(bars, "position:y", target_y, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(bars, "position:y", target_y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
