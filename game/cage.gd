extends Node3D
# Penjara spektral: jeruji + ksatria spektral berlutut.
# Player mendekat -> jeruji tenggelam, hantu bebas & bertempur di sisi player
# sampai lantai berakhir (via main.gd yang me- spawn klon Squire).
signal freed(cage)

var tile := 4.0
var used := false
var glow: OmniLight3D
var _bars: Node3D = null
var _kneel: Node3D = null
var t := 0.0
const MINION := "res://assets/characters/Skeleton_Minion.glb"


func setup(p_tile: float) -> void:
	add_to_group("glints")
	tile = p_tile
	# jeruji: 6 batang tipis melingkar
	_bars = Node3D.new()
	add_child(_bars)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.25, 0.3, 0.42)
	bmat.metallic = 0.85
	bmat.roughness = 0.35
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var bar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.025 * tile
		cm.bottom_radius = 0.025 * tile
		cm.height = 0.95 * tile
		cm.material = bmat
		bar.mesh = cm
		bar.position = Vector3(cos(ang) * 0.42 * tile, 0.475 * tile, sin(ang) * 0.42 * tile)
		_bars.add_child(bar)
	# ksatria berlutut (model skeleton, tint spektral)
	_kneel = Node3D.new()
	add_child(_kneel)
	if ResourceLoader.exists(MINION):
		var model: Node3D = load(MINION).instantiate()
		model.scale = Vector3(0.55, 0.42, 0.55)
		model.rotation.x = 0.25
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.55, 0.8, 1.0, 0.85)
		smat.emission_enabled = true
		smat.emission = Color(0.3, 0.6, 1.0)
		smat.emission_energy_multiplier = 0.9
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_paint(model, smat)
		_kneel.add_child(model)
	# cincin lantai biru pucat
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.5 * tile
	tor.outer_radius = 0.56 * tile
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.5, 0.75, 1.0, 0.6)
	rm.emission_enabled = true
	rm.emission = Color(0.4, 0.7, 1.0)
	rm.emission_energy_multiplier = 1.8
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = rm
	ring.mesh = tor
	ring.position.y = 0.05 * tile
	add_child(ring)
	glow = OmniLight3D.new()
	glow.light_color = Color(0.5, 0.75, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 1.8 * tile
	glow.position.y = 0.9 * tile
	add_child(glow)


func _paint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for c in node.get_children():
		_paint(c, mat)


func _physics_process(delta: float) -> void:
	t += delta
	if glow != null:
		glow.light_energy = 1.2 + sin(t * 2.0) * 0.35
	if _kneel != null:
		_kneel.rotation.y = sin(t * 0.6) * 0.2
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
		freed.emit(self)
		# jeruji tenggelam ke lantai + hantu perlahan lenyap (klon hidup di main)
		if _bars != null:
			var tw := create_tween()
			tw.tween_property(_bars, "position:y", -0.95 * tile, 0.6)
		if _kneel != null:
			var tw2 := create_tween()
			tw2.tween_property(_kneel, "position:y", 0.6 * tile, 0.7)
			tw2.parallel().tween_property(_kneel, "scale", Vector3(1, 0.05, 1), 0.7)
			tw2.tween_callback(_kneel.queue_free)
		if glow != null:
			var tw3 := create_tween()
			tw3.tween_property(glow, "light_energy", 0.0, 0.9)
