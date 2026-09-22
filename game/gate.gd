extends Node3D
# Gerbang portcullis prosedural. Terbuka = tenggelam ke lantai,
# tertutup = naik menghalangi pintu (kunci arena per ruangan).

var bars: Node3D
var body: StaticBody3D
var cs: CollisionShape3D
var height := 3.0
var open := true
var tw: Tween = null


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
	set_open(true, true)


func set_open(o: bool, instant := false) -> void:
	if o == open and not instant:
		return
	open = o
	cs.set_deferred("disabled", o)
	if tw != null and tw.is_valid():
		tw.kill()
	var target_y: float = -height - 0.2 if o else 0.0
	if instant:
		bars.position.y = target_y
		return
	tw = create_tween()
	if o:
		tw.tween_property(bars, "position:y", target_y, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(bars, "position:y", target_y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
