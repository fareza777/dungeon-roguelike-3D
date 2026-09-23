extends Node3D
# Dread Obelisk: struktur bermusuhan — denyut ungu melukai pemain dalam radius
# sampai dihancurkan oleh tebasan (bayaran: +2 souls). Pola seperti urn.

var tile := 4.0
var smashed := false
var t := 0.0
var tick := 0.0
var glow: OmniLight3D = null


func setup(p_tile: float) -> void:
	tile = p_tile
	add_to_group("obelisks")
	# pilar gelap
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22 * tile, 0.9 * tile, 0.22 * tile)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.12, 0.08, 0.16)
	bmat.metallic = 0.4
	bm.material = bmat
	body.mesh = bm
	body.position.y = 0.45 * tile
	add_child(body)
	# puncak menyerupai tanduk
	var tip := MeshInstance3D.new()
	var tm := PrismMesh.new()
	tm.size = Vector3(0.3 * tile, 0.35 * tile, 0.3 * tile)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.35, 0.12, 0.5)
	tmat.emission_enabled = true
	tmat.emission = Color(0.5, 0.15, 0.8)
	tmat.emission_energy_multiplier = 1.6
	tm.material = tmat
	tip.mesh = tm
	tip.position.y = 1.05 * tile
	add_child(tip)
	glow = OmniLight3D.new()
	glow.light_color = Color(0.55, 0.2, 0.85)
	glow.light_energy = 0.6
	glow.omni_range = 1.4 * tile
	glow.position.y = 0.7 * tile
	add_child(glow)


func _physics_process(delta: float) -> void:
	if smashed:
		return
	t += delta
	# denyut: makin dekat pemain, makin cepat denyutnya
	if glow != null:
		glow.light_energy = 0.5 + 0.3 * sin(t * 4.0)
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty() or ps[0].get("dead") == true:
		return
	var d: float = global_position.distance_to(ps[0].global_position)
	if d > 1.15 * tile:
		return
	tick += delta
	if glow != null:
		glow.light_energy = 1.2 + 0.4 * sin(t * 9.0)
	if tick >= 1.15:
		tick = 0.0
		ps[0].take_hit(global_position, 1)
		Sfx.play("hurt")
		var m := get_tree().current_scene
		if m != null and m.has_method("_damage_number"):
			m._damage_number(ps[0].global_position + Vector3(0, 0.7 * tile, 0), "DREAD", Color(0.7, 0.25, 0.95), false)


func smash(from_pos: Vector3) -> void:
	if smashed:
		return
	smashed = true
	remove_from_group("obelisks")
	Sfx.play("hit")
	Stats.souls += 2
	Stats.save_game()
	var m := get_tree().current_scene
	if m != null:
		if m.has_method("_souls_l"):
			m._souls_l()
		if m.has_method("_quest_event"):
			m._quest_event("obelisk")
		if m.has_method("_burst"):
			m._burst(global_position + Vector3(0, 0.4 * tile, 0), Color(0.6, 0.2, 0.9))
		if m.has_method("_damage_number"):
			m._damage_number(global_position + Vector3(0, 0.6 * tile, 0), "+2 ◈", Color(0.6, 0.4, 1.0), false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.5, 0.1, 1.5), 0.2)
	tw.tween_property(self, "rotation:y", 4.0, 0.2)
	tw.chain().tween_callback(queue_free)
