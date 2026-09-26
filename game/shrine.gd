extends Node3D
# Altar arwah: patung (Meshy kalau ada, fallback pilar) + cahaya emas.
# Player mendekat -> kuis berkat via dialog (2 pilihan). Sekali pakai.

signal invoked(shrine)
signal choice_picked(blessing)

var tile := 4.0
var used := false
var kind := 0 # 0 = altar berkat emas, 1 = wujud Mahzan, 2 = obelisk terkutuk
var glow: OmniLight3D
var statue_ref: Node3D = null
var _statue_y := 0.0
var t := 0.0
const STATUE := "res://assets/dungeon/bone_king_statue.glb"


func setup(p_tile: float, p_kind := 0) -> void:
	add_to_group("glints")
	tile = p_tile
	kind = p_kind
	var statue: Node3D
	if ResourceLoader.exists(STATUE):
		statue = load(STATUE).instantiate()
		# skala patung meshy ke ±1.6 tile
		var a := _aabb(statue)
		var sz: float = maxf(a.size.x, a.size.y)
		if sz > 0.01:
			statue.scale = Vector3.ONE * (1.6 * tile / sz)
		statue.position.y = -a.position.y * statue.scale.y
	else:
		var pillar: Node3D = load("res://assets/dungeon/pillar_decorated.gltf.glb").instantiate()
		statue = pillar
		statue.scale = Vector3.ONE * 1.4
	var mat := StandardMaterial3D.new()
	if kind == 1:
		mat.albedo_color = Color(0.5, 0.62, 0.95)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission = Color(0.2, 0.35, 0.8)
		mat.emission_energy_multiplier = 1.2
	elif kind == 2:
		mat.albedo_color = Color(0.42, 0.06, 0.09)
		mat.emission = Color(0.7, 0.05, 0.1)
		mat.emission_energy_multiplier = 1.6
	elif kind == 3:
		mat.albedo_color = Color(0.2, 0.14, 0.1)
		mat.emission = Color(1.0, 0.4, 0.1)
		mat.emission_energy_multiplier = 0.9
	elif kind == 4:
		mat.albedo_color = Color(0.55, 0.6, 0.75)
		mat.emission = Color(0.4, 0.55, 0.95)
		mat.emission_energy_multiplier = 1.1
	elif kind == 5:
		mat.albedo_color = Color(0.45, 0.25, 0.1)
		mat.emission = Color(0.9, 0.4, 0.1)
		mat.emission_energy_multiplier = 0.8
	elif kind == 6:
		mat.albedo_color = Color(0.5, 0.4, 0.15)
		mat.emission = Color(0.85, 0.7, 0.2)
		mat.emission_energy_multiplier = 1.3
	elif kind == 7:
		mat.albedo_color = Color(0.16, 0.2, 0.4)
		mat.emission = Color(0.25, 0.45, 0.95)
		mat.emission_energy_multiplier = 1.2
	elif kind == 13:
		mat.albedo_color = Color(0.25, 0.12, 0.35)
		mat.emission = Color(0.6, 0.2, 0.9)
		mat.emission_energy_multiplier = 1.8
	elif kind == 14:
		mat.albedo_color = Color(0.3, 0.4, 0.65)
		mat.emission = Color(0.75, 0.85, 1.15)
		mat.emission_energy_multiplier = 1.9
	elif kind == 15:
		mat.albedo_color = Color(0.45, 0.38, 0.2)
		mat.emission = Color(0.6, 0.85, 0.45)
		mat.emission_energy_multiplier = 1.3
	elif kind == 16:
		mat.albedo_color = Color(0.5, 0.3, 0.55)
		mat.emission = Color(0.85, 0.45, 0.9)
		mat.emission_energy_multiplier = 1.5
	elif kind == 8:
		mat.albedo_color = Color(0.35, 0.45, 0.15)
		mat.emission = Color(0.75, 0.95, 0.2)
		mat.emission_energy_multiplier = 1.4
	elif kind == 9:
		mat.albedo_color = Color(0.45, 0.32, 0.18)
		mat.emission = Color(0.8, 0.55, 0.25)
		mat.emission_energy_multiplier = 1.0
	elif kind == 10:
		mat.albedo_color = Color(0.15, 0.45, 0.4)
		mat.emission = Color(0.3, 0.95, 0.8)
		mat.emission_energy_multiplier = 1.5
	elif kind == 11:
		mat.albedo_color = Color(0.1, 0.3, 0.35)
		mat.emission = Color(0.4, 0.85, 1.0)
		mat.emission_energy_multiplier = 1.6
	elif kind == 12:
		mat.albedo_color = Color(0.12, 0.18, 0.4)
		mat.emission = Color(0.4, 0.6, 1.1)
		mat.emission_energy_multiplier = 1.7
	else:
		mat.albedo_color = Color(0.9, 0.8, 0.55)
		mat.emission = Color(0.5, 0.38, 0.12)
		mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.4
	mat.roughness = 0.55
	mat.emission_enabled = true
	_paint(statue, mat)
	add_child(statue)
	statue_ref = statue
	_statue_y = statue.position.y
	# lingkar cahaya dasar
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.5 * tile
	tor.outer_radius = 0.58 * tile
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring_col: Color = Color(0.45, 0.65, 1.0, 0.7) if kind == 1 else (Color(1.0, 0.15, 0.1, 0.75) if kind == 2 else (Color(1.0, 0.5, 0.1, 0.8) if kind == 3 else (Color(0.5, 0.7, 1.0, 0.75) if kind == 4 else (Color(1.0, 0.55, 0.15, 0.75) if kind == 5 else (Color(0.95, 0.85, 0.3, 0.8) if kind == 6 else (Color(0.35, 0.5, 1.0, 0.75) if kind == 7 else (Color(0.7, 0.95, 0.25, 0.8) if kind == 8 else (Color(0.85, 0.6, 0.3, 0.75) if kind == 9 else (Color(0.3, 0.95, 0.8, 0.8) if kind == 10 else (Color(0.4, 0.85, 1.0, 0.8) if kind == 11 else (Color(0.4, 0.6, 1.05, 0.8) if kind == 12 else (Color(0.65, 0.25, 0.95, 0.8) if kind == 13 else (Color(0.75, 0.85, 1.05, 0.8) if kind == 14 else Color(1.0, 0.8, 0.3, 0.7))))))))))))))
	rm.albedo_color = ring_col
	rm.emission_enabled = true
	rm.emission = Color(0.35, 0.55, 1.0) if kind == 1 else (Color(0.9, 0.05, 0.08) if kind == 2 else (Color(1.0, 0.45, 0.1) if kind == 3 else (Color(0.45, 0.6, 1.0) if kind == 4 else (Color(0.95, 0.5, 0.15) if kind == 5 else (Color(0.95, 0.85, 0.3) if kind == 6 else (Color(0.35, 0.5, 1.0) if kind == 7 else (Color(0.7, 0.95, 0.25) if kind == 8 else (Color(0.85, 0.6, 0.3) if kind == 9 else (Color(0.3, 0.95, 0.8) if kind == 10 else (Color(0.4, 0.85, 1.0) if kind == 11 else (Color(0.4, 0.6, 1.05) if kind == 12 else (Color(0.65, 0.25, 0.95) if kind == 13 else (Color(0.8, 0.9, 1.15) if kind == 14 else Color(1.0, 0.75, 0.25))))))))))))))
	rm.emission_energy_multiplier = 2.0
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tor.material = rm
	ring.mesh = tor
	ring.position.y = 0.06 * tile
	add_child(ring)
	glow = OmniLight3D.new()
	glow.light_color = Color(0.45, 0.6, 1.0) if kind == 1 else (Color(1.0, 0.15, 0.1) if kind == 2 else (Color(1.0, 0.45, 0.12) if kind == 3 else (Color(0.45, 0.65, 1.0) if kind == 4 else (Color(1.0, 0.55, 0.2) if kind == 5 else (Color(0.95, 0.85, 0.35) if kind == 6 else (Color(0.35, 0.5, 1.0) if kind == 7 else (Color(0.7, 0.95, 0.25) if kind == 8 else (Color(0.85, 0.6, 0.3) if kind == 9 else (Color(0.35, 0.95, 0.8) if kind == 10 else (Color(0.4, 0.85, 1.0) if kind == 11 else (Color(0.4, 0.6, 1.05) if kind == 12 else (Color(0.65, 0.25, 0.95) if kind == 13 else (Color(0.8, 0.9, 1.15) if kind == 14 else Color(1.0, 0.75, 0.3))))))))))))))
	glow.light_energy = 1.6
	glow.omni_range = 2.2 * tile
	glow.position.y = 1.0 * tile
	add_child(glow)
	# label nama melayang di atas patung — pemain tahu altar mana dari kejauhan
	var nl := Label3D.new()
	var names := {
		0: ["✦ BLESSING ALTAR", Color(1.0, 0.8, 0.3)],
		1: ["☗ MAHZAN'S STALL", Color(0.45, 0.6, 1.0)],
		2: ["☠ CURSED OBELISK", Color(1.0, 0.15, 0.1)],
		3: ["▲ SOUL FORGE", Color(1.0, 0.45, 0.12)],
		4: ["◇ MIRROR OF FATHOMS", Color(0.45, 0.65, 1.0)],
		5: ["☠ BOUNTY STONE", Color(1.0, 0.55, 0.15)],
		6: ["◈ SUNKEN VAULT", Color(0.95, 0.85, 0.3)],
		7: ["≋ FERRYMAN'S POST", Color(0.35, 0.5, 1.0)],
		8: ["◈ GAMBLER'S WELL", Color(0.7, 0.95, 0.25)],
		9: ["◈ SCAVENGER'S CACHE", Color(0.85, 0.6, 0.3)],
		10: ["◈ SOUL FOUNTAIN", Color(0.3, 0.95, 0.8)],
		11: ["≋ DROWNED ALTAR", Color(0.4, 0.85, 1.0)],
		12: ["▲ KEELSTONE", Color(0.4, 0.6, 1.05)],
		13: ["☠ THRONE'S OFFERING", Color(0.65, 0.25, 0.95)],
		14: ["☽ MOONPOOL", Color(0.8, 0.9, 1.15)],
		15: ["✚ QUARTERMASTER", Color(0.6, 0.9, 0.5)],
		16: ["♪ SIREN'S CONCH", Color(0.85, 0.5, 0.95)],
	}
	var nv: Array = names.get(kind, names[0])
	nl.text = String(nv[0])
	nl.font_size = 56
	nl.pixel_size = 0.010
	nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nl.modulate = nv[1]
	nl.outline_size = 10
	nl.outline_modulate = Color(0.06, 0.05, 0.1, 0.95)
	nl.position.y = 2.1 * tile
	add_child(nl)


func _aabb(node: Node) -> AABB:
	var a := AABB()
	var first := true
	for c in _all_mi(node):
		var ta: AABB = _rel_transform(c, node) * c.get_aabb()
		if first:
			a = ta
			first = false
		else:
			a = a.merge(ta)
	return a


func _rel_transform(n: Node, root: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		t = cur.transform * t
		cur = cur.get_parent()
	return t


func _all_mi(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_mi(c))
	return out


func _paint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for c in node.get_children():
		_paint(c, mat)


func _physics_process(delta: float) -> void:
	t += delta
	if glow != null:
		glow.light_energy = 1.4 + sin(t * 2.4) * 0.4
	# wujud Mahzan melayang pelan
	if kind == 1 and statue_ref != null and is_instance_valid(statue_ref):
		statue_ref.position.y = _statue_y + sin(t * 1.8) * 0.05 * tile
		statue_ref.rotation.y = sin(t * 0.9) * 0.12
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
	if glow != null:
		var tw := create_tween()
		tw.tween_property(glow, "light_energy", 0.2, 0.8)
