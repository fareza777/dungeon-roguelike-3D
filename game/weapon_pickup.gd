extends Node3D
# Senjata mengambang di lantai: berputar + naik-turun. Diambil dengan menyentuh.

const M = preload("res://materials.gd")
const WDB = preload("res://weapons_db.gd")

var weapon_id := ""
var tile := 4.0
var t := 0.0
var mesh_holder: Node3D


func setup(id: String, tex: Texture2D, p_tile: float) -> void:
	weapon_id = id
	tile = p_tile
	mesh_holder = Node3D.new()
	add_child(mesh_holder)
	var w: Dictionary = WDB.get_w(id)
	var wm: Node3D = load(WDB.DIR + w["gltf"]).instantiate()
	M.paint(wm, M.toon(tex, w["tint"], 0.5))
	mesh_holder.add_child(wm)
	mesh_holder.position.y = 0.7
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.42
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.8, 0.3, 0.8)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.75, 0.25)
	rm.emission_energy_multiplier = 1.6
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = rm
	ring.mesh = torus
	ring.position.y = 0.12
	add_child(ring)


func _physics_process(delta: float) -> void:
	t += delta
	mesh_holder.rotation.y += delta * 1.6
	mesh_holder.position.y = 0.7 + sin(t * 3.0) * 0.08
	if Stats.draft_open:
		return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p: Node3D = ps[0]
	if p.get("dead"):
		return
	if global_position.distance_to(p.global_position) < 0.45 * tile:
		p.equip_weapon(weapon_id)
		Sfx.play("pickup")
		var w: Dictionary = WDB.get_w(weapon_id)
		var m := get_tree().current_scene
		if m != null and m.has_method("toast"):
			m.toast("%s — %s" % [w["name"], w["desc"]])
		queue_free()
