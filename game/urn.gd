extends Node3D
# Guci tulang: dihancurkan oleh tebasan pemain — menjatuhkan permata jiwa.
# ~15% guci terkutuk: menggigit balik 1 dmg saat pecah.

var tile := 4.0
var smashed := false
var bell := false
var void_urn := false


func setup(p_tile: float, p_bell := false, p_void := false) -> void:
	bell = p_bell
	void_urn = p_void
	tile = p_tile
	add_to_group("urns")
	add_to_group("glints")
	# badan guci: silinder gemuk
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16 * tile
	cm.bottom_radius = 0.2 * tile
	cm.height = 0.45 * tile
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.85, 0.7, 0.3) if bell else (Color(0.2, 0.1, 0.35) if void_urn else Color(0.5, 0.48, 0.4))
	bm.metallic = 0.5 if bell else 0.1
	cm.material = bm
	body.mesh = cm
	body.position.y = 0.22 * tile
	if bell:
		body.scale = Vector3(1.3, 1.2, 1.3)
	add_child(body)
	# tutup setengah bola
	var lid := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.14 * tile
	lm.height = 0.22 * tile
	lid.mesh = lm
	lid.position.y = 0.45 * tile
	lid.scale.y = 0.55
	add_child(lid)
	# cahaya lembut biar terbaca di gelap
	var om := OmniLight3D.new()
	om.light_color = Color(1.0, 0.85, 0.4) if bell else (Color(0.55, 0.3, 0.9) if void_urn else Color(0.55, 0.75, 1.0))
	om.light_energy = 0.6 if bell else 0.3
	om.omni_range = 1.1 * tile
	om.position.y = 0.5 * tile
	add_child(om)


func smash(from_pos: Vector3) -> void:
	if smashed:
		return
	smashed = true
	remove_from_group("urns")
	Sfx.play("hit")
	var m := get_tree().current_scene
	if m != null:
		if m.has_method("_spawn_gems"):
			m._spawn_gems(global_position, 2 + randi() % 3)
		if randf() < 0.12 and m.has_method("_spawn_vial"):
			m._spawn_vial(global_position)
		if m.has_method("_quest_event"):
			m._quest_event("urn")
			m.set("urns_run", int(m.get("urns_run")) + 1)
			m.set("urns_floor", int(m.get("urns_floor")) + 1)
			if int(m.get("urns_floor")) == 8:
				m._quest_event("urn_floor")
			if int(m.get("urns_run")) >= 10 and m.has_method("_ach"):
				m._ach("potbellied")
			if int(m.get("urns_run")) >= 25 and m.has_method("_ach"):
				m._ach("kilnbreaker")
			if m.has_method("_quest_event"):
				m._quest_event("urnsmash")
		if m.get("urn_count") != null:
			m.set("urn_count", int(m.get("urn_count")) + 1)
			if int(m.get("urn_count")) == 8 and m.has_method("_ach"):
				m._ach("cove")
		if m.has_method("_burst"):
			m._burst(global_position + Vector3(0, 0.2 * tile, 0), Color(0.9, 0.85, 0.6))
		var ub: Dictionary = m.get("biome") if m.get("biome") is Dictionary else {}
		var reliq := String(ub.get("name", "")) == "Sunken Reliquary"
		var dry := bool(m.get("abyssal_patience")) or bool(m.get("salted_purse"))
		if bell:
			Stats.earn_souls((10 if bool(m.get("vessel")) else 5) if not dry else 0)
			if m.has_method("_quest_event"):
				m._quest_event("bellurn")
			if m.has_method("_spawn_wisp_at"):
				m._spawn_wisp_at(global_position)
			if m.has_method("toast"):
				m.toast("BELL URN — +5 souls and a wisp!")
		elif void_urn:
			Stats.souls -= mini(Stats.souls, 2)
			if m.has_method("_quest_event"):
				m._quest_event("voidurn")
			Stats.add_xp(8)
			if m.has_method("_souls_l"):
				m._souls_l()
			if m.has_method("toast"):
				m.toast("VOID LANTERN — the dark drank 2 souls and paid 8 XP")
		elif reliq and not dry:
			Stats.earn_souls((2 if bool(m.get("low_tide")) else 1) * (2 if bool(m.get("vessel")) else 1))
		if bool(m.get("salvage_rights")) and not dry:
			Stats.earn_souls(2)
		if bool(m.get("deeproot")) and not reliq and not dry:
			Stats.earn_souls(1)
		if bool(m.get("pearl_fever")) and not dry:
			Stats.earn_souls(1)
		if bool(m.get("salt_purse")) and not dry:
			Stats.earn_souls(1)
		if bool(m.get("murk_purse")) and not dry:
			Stats.earn_souls(1)
		if bool(m.get("salt_tithe")) and not dry:
			Stats.earn_souls(1)
		if bool(m.get("dead_lantern")) and not dry:
			Stats.earn_souls(1)
		if bool(m.get("urnsworn")) and not dry:
			Stats.earn_souls(1)
		if bool(m.get("hungry_urns")):
			if not dry:
				Stats.earn_souls(1)
			var pp: Node3D = m.get("player")
			if pp != null and is_instance_valid(pp) and pp.has_method("take_hit"):
				pp.take_hit(global_position, 1)
				if m.has_method("toast"):
					m.toast("THE POT BITES — −1 HP")
		if m.has_method("_souls_l"):
			m._souls_l()
		if randf() < 0.15:
			var ps := get_tree().get_nodes_in_group("player")
			if not ps.is_empty() and ps[0].get("dead") != true:
				ps[0].take_hit(from_pos, 1)
				if m.has_method("_damage_number"):
					m._damage_number(global_position + Vector3(0, 0.4 * tile, 0), "CURSED URN!", Color(0.8, 0.2, 0.6), true)
		elif randf() < 0.10 and m.has_method("_spawn_enemy"):
			# guci tidur — sesuatu masih bernapas di dalamnya
			var ri: int = int(m.get("current_room")) if m.get("current_room") != null else 0
			var ue = m._spawn_enemy({"pos": global_position + Vector3(0, 0, 0.3 * tile), "room": ri}, "crawler", false)
			if ue != null:
				ue.activated = true
			if m.has_method("_damage_number"):
				m._damage_number(global_position + Vector3(0, 0.4 * tile, 0), "SOMETHING STIRS!", Color(0.8, 0.6, 0.3), true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.4, 0.1, 1.4), 0.18)
	tw.tween_property(self, "rotation:y", 3.0, 0.18)
	tw.chain().tween_callback(queue_free)
