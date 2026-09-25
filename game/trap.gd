extends Node3D
# Jebakan: kind 0 = plat duri tulang naik-turun; kind 1 = semburan api berirama
# (lingkaran membara = telegraph, cone api muncul saat aktif); kind 2 = sigil beku
# (chill); kind 3 = sigil void (menjerat kaki). Kena = 1 dmg.

var spikes: Node3D
var jet: MeshInstance3D = null
var glow: MeshInstance3D = null
var kind := 0 # 0 = duri, 1 = api, 2 = sigil beku, 3 = void, 4 = lentera penyembuh, 5 = busur, 6 = kepiting, 7 = penjepit, 8 = siphon, 9 = fathom grate (blink), 10 = bilge vent, 11 = keel snare
var tile := 4.0
var t := 0.0
var phase := 0.0 # offset irama
var up := false
var armed := true
var warn_tw: Tween = null
var bolts: Array = [] # anak panah sigil busur (kind 5)


func setup(p_tile: float, offset: float, p_kind := 0) -> void:
	tile = p_tile
	phase = offset
	kind = p_kind
	# plat dasar
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5 * tile, 0.03 * tile, 0.5 * tile)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.16, 0.07, 0.04) if kind == 1 else (Color(0.05, 0.1, 0.2) if kind == 2 else (Color(0.14, 0.05, 0.2) if kind == 3 else (Color(0.05, 0.14, 0.08) if kind == 4 else (Color(0.04, 0.12, 0.11) if kind == 5 else (Color(0.06, 0.14, 0.13) if kind == 6 else (Color(0.12, 0.05, 0.2) if kind == 7 else (Color(0.05, 0.03, 0.15) if kind == 8 else (Color(0.02, 0.14, 0.1) if kind == 9 else (Color(0.1, 0.12, 0.03) if kind == 10 else (Color(0.08, 0.13, 0.06) if kind == 11 else Color(0.09, 0.09, 0.12)))))))))))
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
	if kind == 2 or kind == 3 or kind == 4 or kind == 5 or kind == 6 or kind == 7 or kind == 8 or kind == 9 or kind == 10 or kind == 11:
		# sigil beku / void / lentera — cincin telegraph berdenyut
		glow = MeshInstance3D.new()
		var gm3 := PlaneMesh.new()
		gm3.size = Vector2(0.44 * tile, 0.44 * tile)
		var gmat3 := StandardMaterial3D.new()
		gmat3.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gmat3.albedo_color = Color(0.4, 0.75, 1.0, 0.8) if kind == 2 else (Color(0.5, 1.0, 0.55, 0.85) if kind == 4 else (Color(0.35, 0.95, 0.85, 0.85) if kind == 5 else (Color(0.95, 0.95, 0.9, 0.85) if kind == 6 else (Color(0.6, 0.3, 1.0, 0.85) if kind == 7 else (Color(0.75, 0.55, 1.1, 0.85) if kind == 8 else (Color(0.45, 0.95, 0.8, 0.85) if kind == 9 else (Color(0.7, 0.9, 0.3, 0.85) if kind == 10 else (Color(0.4, 0.85, 0.5, 0.85) if kind == 11 else Color(0.75, 0.3, 1.0, 0.8)))))))))
		gmat3.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm3.material = gmat3
		glow.mesh = gm3
		glow.position.y = 0.035 * tile
		add_child(glow)
		if kind == 6:
			# cangkang kerang — kubah bertutup saat "menjepit"
			var shell := MeshInstance3D.new()
			var sh := SphereMesh.new()
			sh.radius = 0.16 * tile
			sh.height = 0.14 * tile
			sh.radial_segments = 12
			var shmat := StandardMaterial3D.new()
			shmat.albedo_color = Color(0.78, 0.72, 0.62)
			shmat.metallic = 0.5
			shmat.roughness = 0.35
			shmat.emission_enabled = true
			shmat.emission = Color(0.2, 0.32, 0.3) * 0.6
			sh.material = shmat
			shell.mesh = sh
			shell.position.y = 0.05 * tile
			shell.scale.y = 0.55
			add_child(shell)
		if kind == 4 or kind == 5 or kind == 6 or kind == 7 or kind == 8 or kind == 9 or kind == 10 or kind == 11:
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
	smat.albedo_color = Color(0.6, 0.85, 1.15) if kind == 2 else (Color(0.75, 0.5, 1.0) if kind == 3 else (Color(0.95, 0.95, 0.9) if kind == 6 else (Color(0.6, 0.35, 1.0) if kind == 7 else (Color(0.7, 0.5, 1.15) if kind == 8 else (Color(0.4, 0.9, 0.75) if kind == 9 else (Color(0.75, 0.85, 0.35) if kind == 10 else (Color(0.45, 0.8, 0.55) if kind == 11 else Color(0.85, 0.82, 0.7))))))))
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
	var msw := get_tree().current_scene
	var calmdown := msw != null and bool(msw.get("still_waters"))
	var doze := 1.26 if calmdown else 0.9 # ambang tidur->keluar
	var mroot := get_tree().current_scene
	if kind == 6 and mroot != null and bool(mroot.get("shell_game")):
		doze *= 1.5
	var cyc: float = fmod(t + phase, 1.9 * (1.4 if calmdown else 1.0))
	var target: float
	if cyc < doze:
		target = -0.29 * tile # tidur
	elif cyc < doze + 0.2:
		target = 0.0 # keluar
	else:
		target = -0.29 * tile
	var prev_up := up
	up = cyc >= doze and cyc < doze + 0.2
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
		if (kind == 2 or kind == 3 or kind == 4 or kind == 6 or kind == 7 or kind == 8 or kind == 9 or kind == 11) and glow != null:
			var gm4: StandardMaterial3D = glow.mesh.material
			gm4.albedo_color.a = 0.45 + 0.45 * sin(t * 7.0) if not up else 1.0
		if spikes != null:
			spikes.position.y = lerpf(spikes.position.y, target, delta * (22.0 if up else 10.0))
	if up and not prev_up:
		Sfx.play("trap")
		if kind == 5 and armed:
			_fire_bolts()
	if up and armed and kind != 5:
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
						elif kind == 6 and not Stats.relics.has("oyster_king"):
							p.set("root_t", 0.4 if Stats.relics.has("tidebound_anklet") else 1.3)
							var mc := get_tree().current_scene
							if mc != null and mc.has_method("_ach"):
								mc._ach("clamsnack")
						elif kind == 7:
							p.set("root_t", 0.5 if Stats.relics.has("tidebound_anklet") else 1.0)
							var pd3: Vector3 = global_position - p.global_position
							pd3.y = 0
							p.global_position += pd3 * 0.35
							var mv := get_tree().current_scene
							if mv != null and mv.has_method("_damage_number"):
								mv._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "PINCHED", Color(0.6, 0.35, 1.0), true)
						elif kind == 10:
							p.set("weak_t", maxf(float(p.get("weak_t") or 0.0), 2.5))
							var mvt := get_tree().current_scene
							if mvt != null:
								if mvt.has_method("_burst"):
									mvt._burst(p.global_position + Vector3(0, 0.4 * tile, 0), Color(0.7, 0.9, 0.3))
								if mvt.has_method("_damage_number"):
									mvt._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "BILGE-SOAKED", Color(0.7, 0.9, 0.3), true)
								if mvt.has_method("_quest_event"):
									mvt._quest_event("bilge_soak")
						elif kind == 11:
							p.set("root_t", 0.4 if Stats.relics.has("tidebound_anklet") else 2.0)
							var mks := get_tree().current_scene
							if mks != null:
								if mks.has_method("_burst"):
									mks._burst(p.global_position + Vector3(0, 0.4 * tile, 0), Color(0.4, 0.85, 0.5))
								if mks.has_method("_damage_number"):
									mks._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "SNARED", Color(0.5, 0.9, 0.55), true)
								if mks.has_method("_quest_event"):
									mks._quest_event("keel_snare")
							armed = false
						elif kind == 9:
							var hdir: Vector3 = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
							if hdir.length() > 0.01:
								var mfg := get_tree().current_scene
								p.global_position += hdir.normalized() * tile * 1.4
								if mfg != null:
									if mfg.has_method("_burst"):
										mfg._burst(p.global_position + Vector3(0, 0.5 * tile, 0), Color(0.4, 0.95, 0.8))
									if mfg.has_method("_damage_number"):
										mfg._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "SWALLOWED", Color(0.45, 0.95, 0.8), true)
									if mfg.has_method("_quest_event"):
										mfg._quest_event("grate_hop")
							armed = false
						elif kind == 8:
							p.set("root_t", 0.4 if Stats.relics.has("tidebound_anklet") else 0.8)
							var drained: int = mini(Stats.souls, 2)
							Stats.souls -= drained
							var ms := get_tree().current_scene
							if ms != null:
								if ms.has_method("_souls_l"):
									ms._souls_l()
								if ms.has_method("_damage_number"):
									ms._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "SIPHONED −%d ◈" % drained, Color(0.75, 0.5, 1.1), true)
								if ms.has_method("_quest_event"):
									ms._quest_event("siphon_hit")
						var mw := get_tree().current_scene
						if mw != null and int(mw.get("trap_wrapped") or 0) > 0:
							mw.set("trap_wrapped", int(mw.get("trap_wrapped")) - 1)
							if mw.has_method("_damage_number"):
								mw._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "WRAPPED", Color(0.7, 0.8, 1.0), true)
						elif mw != null and bool(mw.get("keel_prayer")):
							mw.set("keel_prayer", false)
							p.hp = minf(p.max_hp, p.hp + 2.0)
							p.hp_changed.emit(p.hp)
							if mw.has_method("_damage_number"):
								mw._damage_number(p.global_position + Vector3(0, 0.7 * tile, 0), "KEEL MENDS", Color(0.5, 0.95, 0.7), true)
						else:
							var td_: int = (3 if bool(get_tree().current_scene.get("salted_deck")) else 2) if bool(get_tree().current_scene.get("bilge_run")) else (2 if bool(get_tree().current_scene.get("salted_deck")) else 1)
							if bool(get_tree().current_scene.get("wet_wool")):
								td_ = maxi(0, td_ - 1)
							p.take_hit(global_position, td_)

	# sentuh jebakan saat fase tidur untuk melucutinya (kecuali lentera)
	if not up and armed and kind != 4:
		var ps2 := get_tree().get_nodes_in_group("player")
		if not ps2.is_empty():
			var p2: Node3D = ps2[0]
			if p2.get("dead") != true:
				var d2: Vector3 = p2.global_position - global_position
				d2.y = 0
				var ml2 := get_tree().current_scene
				var disarm_reach: float = 0.26 * tile
				if ml2 != null and bool(ml2.get("barnacle_sense")):
					disarm_reach *= 1.5
				if d2.length() < disarm_reach:
					disarm()
					Sfx.play("click")
					if ml2 != null:
						if ml2.has_method("_quest_event"):
							ml2._quest_event("trap_disarm")
						if ml2.has_method("_shock_ring"):
							ml2._shock_ring(global_position, Color(0.5, 0.95, 0.7))
						if ml2.has_method("_souls"):
							ml2._souls(global_position, 6, Color(0.5, 0.95, 0.7))
						if Stats.relics.has("clamheart"):
							Stats.earn_souls(1)
							if ml2.has_method("_souls_l"):
								ml2._souls_l()
						if ml2 != null and bool(ml2.get("muckraker")):
							Stats.earn_souls(1)
							if ml2.has_method("_souls_l"):
								ml2._souls_l()
						if bool(ml2.get("bilge_run")):
							Stats.earn_souls(2)
						if bool(ml2.get("salted_deck")):
							Stats.earn_souls(1)
							if ml2.has_method("_souls_l"):
								ml2._souls_l()
						if ml2.has_method("toast"):
							ml2.toast("Trap defused!")
						if kind == 6:
							var pearl_pay: int = 4 if bool(ml2.get("shell_game")) else 2
							if Stats.relics.has("oyster_king"):
								pearl_pay += 1
							var clams_run: int = int(ml2.get("clams_run")) + 1
							ml2.set("clams_run", clams_run)
							if clams_run >= 12:
								ml2._ach("pearlhunter")
							if Stats.relics.has("shellshield") and not bool(ml2.get("shellshield_used")):
								ml2.set("shellshield_used", true)
								pearl_pay += 2
							Stats.earn_souls(pearl_pay)
							if ml2.has_method("_quest_event"):
								ml2._quest_event("clam")
							if ml2.has_method("_souls_l"):
								ml2._souls_l()
							if ml2.has_method("toast"):
								ml2.toast("PEARL PRIZE — +%d souls" % pearl_pay)
						if kind == 7:
							Stats.earn_souls(2)
							if ml2.has_method("_quest_event"):
								ml2._quest_event("pinch")
							if ml2.has_method("_souls_l"):
								ml2._souls_l()
							if ml2.has_method("toast"):
								ml2.toast("VOID PRIZE — +2 souls")
						if kind == 8:
							Stats.earn_souls(3)
							if ml2.has_method("_quest_event"):
								ml2._quest_event("siphon")
							if ml2.has_method("_souls_l"):
								ml2._souls_l()
							if ml2.has_method("toast"):
								ml2.toast("SIPHON SEALED — +3 souls")
						if ml2.has_method("_burst"):
							ml2._burst(global_position + Vector3(0, 0.3, 0), Color(0.6, 0.8, 1.0))

	# anak panah sigil: bergerak lurus, 1 dmg bila kena, hilang setelah ~3 tile
	for i in range(bolts.size() - 1, -1, -1):
		var bd: Dictionary = bolts[i]
		var bn: Node3D = bd["node"]
		if not is_instance_valid(bn):
			bolts.remove_at(i)
			continue
		bd["dist"] = float(bd["dist"]) + 2.6 * tile * delta
		bn.global_position += bd["dir"] * 2.6 * tile * delta
		bn.rotation.y += delta * 6.0
		if float(bd["dist"]) > 3.2 * tile:
			bn.queue_free()
			bolts.remove_at(i)
			continue
		var ps3 := get_tree().get_nodes_in_group("player")
		if not ps3.is_empty():
			var p3: Node3D = ps3[0]
			if p3.get("dead") != true and p3.get("invuln") <= 0.0:
				var d3: Vector3 = p3.global_position - bn.global_position
				d3.y = 0
				if d3.length() < 0.2 * tile:
					var mw2 := get_tree().current_scene
					if mw2 != null and int(mw2.get("trap_wrapped") or 0) > 0:
						mw2.set("trap_wrapped", int(mw2.get("trap_wrapped")) - 1)
						if mw2.has_method("_damage_number"):
							mw2._damage_number(p3.global_position + Vector3(0, 0.7 * tile, 0), "WRAPPED", Color(0.7, 0.8, 1.0), true)
					else:
						var td2_: int = (3 if bool(get_tree().current_scene.get("salted_deck")) else 2) if bool(get_tree().current_scene.get("bilge_run")) else (2 if bool(get_tree().current_scene.get("salted_deck")) else 1)
						if bool(get_tree().current_scene.get("wet_wool")):
							td2_ = maxi(0, td2_ - 1)
						p3.take_hit(global_position, td2_)
					bn.queue_free()
					bolts.remove_at(i)


func _fire_bolts() -> void:
	var psb := get_tree().get_nodes_in_group("player")
	if psb.is_empty() or psb[0].get("dead") == true:
		return
	var tgt: Vector3 = psb[0].global_position
	if tgt.distance_to(global_position) > 2.6 * tile:
		return
	var bdir: Vector3 = (tgt - global_position)
	bdir.y = 0
	bdir = bdir.normalized()
	for bi in range(-1, 2):
		var bn := MeshInstance3D.new()
		var bm: CylinderMesh = CylinderMesh.new()
		bm.top_radius = 0.02 * tile
		bm.bottom_radius = 0.055 * tile
		bm.height = 0.16 * tile
		var bmat := StandardMaterial3D.new()
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.albedo_color = Color(0.4, 1.0, 0.9)
		bmat.emission_enabled = true
		bmat.emission = Color(0.3, 0.95, 0.85)
		bmat.emission_energy_multiplier = 2.2
		bm.material = bmat
		bn.mesh = bm
		get_parent().add_child(bn)
		bn.global_position = global_position + Vector3(0, 0.35 * tile, 0)
		var bd2: Vector3 = bdir.rotated(Vector3.UP, float(bi) * 0.22)
		bn.rotation.x = PI / 2.0
		bolts.append({"node": bn, "dir": bd2, "dist": 0.0})
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
