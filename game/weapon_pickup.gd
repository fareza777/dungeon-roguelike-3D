extends Node3D
# Senjata mengambang di lantai: berputar + naik-turun. Diambil dengan menyentuh.

const M = preload("res://materials.gd")
const WDB = preload("res://weapons_db.gd")

var weapon_id := ""
var tile := 4.0
var t := 0.0
var mesh_holder: Node3D
var beam: MeshInstance3D = null
var ring_node: MeshInstance3D = null
var name_lbl: Label3D = null


func setup(id: String, tex: Texture2D, p_tile: float) -> void:
	add_to_group("glints")
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
	ring_node = ring
	# pilar cahaya loot — kelihatan dari seberang ruangan
	beam = MeshInstance3D.new()
	var bcm := CylinderMesh.new()
	bcm.top_radius = 0.09 * tile
	bcm.bottom_radius = 0.24 * tile
	bcm.height = 3.2
	var bmm := StandardMaterial3D.new()
	bmm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmm.albedo_color = Color(1.0, 0.8, 0.35, 0.14)
	bmm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bcm.material = bmm
	beam.mesh = bcm
	beam.position.y = 1.6
	add_child(beam)
	var nl := Label3D.new()
	nl.text = String(w["name"]).to_upper()
	nl.font_size = 38
	nl.modulate = Color(1.0, 0.85, 0.4, 0.95)
	nl.outline_size = 10
	nl.outline_modulate = Color(0.05, 0.02, 0.0, 0.9)
	nl.position = Vector3(0, 1.25, 0)
	nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(nl)
	name_lbl = nl
	var dl := Label3D.new()
	dl.text = String(w["desc"])
	dl.font_size = 22
	dl.modulate = Color(0.95, 0.9, 0.7, 0.8)
	dl.outline_size = 8
	dl.outline_modulate = Color(0.05, 0.02, 0.0, 0.9)
	dl.position = Vector3(0, 1.02, 0)
	dl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(dl)


func _physics_process(delta: float) -> void:
	t += delta
	mesh_holder.rotation.y += delta * 1.6
	mesh_holder.position.y = 0.7 + sin(t * 3.0) * 0.08
	if beam != null:
		beam.rotation.y -= delta * 0.8
		var bm2: StandardMaterial3D = beam.mesh.material
		bm2.albedo_color.a = 0.1 + 0.07 * sin(t * 4.0)
	if ring_node != null:
		var rs := 1.0 + 0.12 * sin(t * 5.0)
		ring_node.scale = Vector3(rs, 1.0, rs)
		var rm2: StandardMaterial3D = ring_node.mesh.material
		rm2.albedo_color.a = 0.6 + 0.2 * sin(t * 5.0)
	if name_lbl != null:
		name_lbl.position.y = 1.25 + sin(t * 3.0 + 0.6) * 0.04
	if Stats.draft_open:
		return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p: Node3D = ps[0]
	if p.get("dead"):
		return
	if global_position.distance_to(p.global_position) < 0.45 * tile:
		var w: Dictionary = WDB.get_w(weapon_id)
		var m := get_tree().current_scene
		if weapon_id == Stats.weapon_id:
			var lv: int = int(Stats.weapon_lv.get(weapon_id, 1)) + 1
			Stats.weapon_lv[weapon_id] = lv
			p.refresh_stats()
			Sfx.play("levelup")
			if m != null and m.has_method("toast"):
				m.toast("FORGED! %s +1 ATK (Lv %d)" % [w["name"], lv])
			if lv >= 3 and m != null and m.has_method("_ach"):
				m._ach("forge3")
		else:
			p.equip_weapon(weapon_id)
			Sfx.play("pickup")
			if m != null and m.has_method("toast"):
				m.toast("%s — %s" % [w["name"], w["desc"]])
			# senjata baru terasa hidup: +15% ATK selama 60 detik untuk "memanaskan"
			if m != null:
				m.trial_atk_t = 60.0
				Stats.buff_atk_pct += 0.15
				p.refresh_stats()
				if m.has_method("_damage_number"):
					m._damage_number(p.global_position + Vector3(0, 1.0 * tile, 0), "TRIAL BLADE — +15% ATK 60s", Color(0.6, 0.9, 1.0), false)
		queue_free()
