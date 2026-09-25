extends Node3D
# Bone Squire — antek setia dari relic "tulang_kesatria".
# Mengekor player, menebas musuh terdekat tiap ~1.1 detik (dmg = 35% ATK pemain).

var tile := 4.0
var atk_cd := 0.0
var t := 0.0
var ap: AnimationPlayer = null
var act_lock := 0.0
var dmg := 1.0
var is_vane := false # Sir Vane: kadang bicara setelah menebas
var life_t := -1.0 # >0 = THRALL ghost — memudar saat habis


func setup(p_tile: float, p_dmg: float, p_tint := Color(0.95, 0.88, 0.6), p_orb := Color(1.0, 0.85, 0.3)) -> void:
	tile = p_tile
	dmg = p_dmg
	var mh2 := get_tree().current_scene
	if mh2 != null and bool(mh2.get("crew_oath")):
		dmg *= 1.5
	var model: Node3D = load("res://assets/characters/Skeleton_Minion.glb").instantiate()
	model.scale = Vector3.ONE * 0.62
	ap = M.anim_player(model)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = p_tint
	mat.metallic = 0.2
	_paint(model, mat)
	add_child(model)
	# orb emas kecil di atasnya biar kebaca "kawan"
	var eye := MeshInstance3D.new()
	var es := SphereMesh.new()
	es.radius = 0.04 * tile
	es.height = 0.07 * tile
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = p_orb
	em.emission_enabled = true
	em.emission = p_orb
	em.emission_energy_multiplier = 2.5
	es.material = em
	eye.mesh = es
	eye.position.y = 0.62 * tile
	add_child(eye)


func _paint(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		n.material_override = mat
	for c in n.get_children():
		_paint(c, mat)


func _physics_process(delta: float) -> void:
	t += delta
	if life_t > 0.0:
		life_t -= delta
		var fade: float = clampf(life_t / 4.0, 0.0, 1.0)
		scale = Vector3.ONE * (0.6 + fade * 0.4)
		position.y += delta * 0.4 * tile * (1.0 - fade)
		if life_t <= 0.0:
			queue_free()
			return
	atk_cd -= delta
	act_lock -= delta
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p: Node3D = ps[0]
	if p.get("dead") == true:
		return
	var to_p: Vector3 = p.global_position - global_position
	to_p.y = 0
	var dp := to_p.length()
	if dp > 0.85 * tile:
		var spd: float = (3.2 if dp > 2.5 * tile else 1.5) * tile
		global_position += to_p.normalized() * spd * delta
		look_at(global_position + to_p.normalized(), Vector3.UP)
		if act_lock <= 0.0:
			M.play_fuzzy(ap, ["run", "walk"])
	elif act_lock <= 0.0:
		M.play_fuzzy(ap, ["idle"])
	if atk_cd > 0.0:
		return
	var best: Node3D = null
	var bd := 1e9
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = e.global_position - global_position
		d.y = 0
		var dl := d.length()
		if dl < bd:
			bd = dl
			best = e
	if best != null and bd < 1.15 * tile:
		atk_cd = 1.1
		look_at(Vector3(best.global_position.x, global_position.y, best.global_position.z), Vector3.UP)
		best.take_hit(global_position, dmg)
		act_lock = max(act_lock, M.play_action(ap, ["attack", "slash", "swing"], 1.5))
		Sfx.play("swing")
		var m := get_tree().current_scene
		if m != null and m.has_method("_damage_number"):
			m._damage_number(best.global_position + Vector3(0, 0.3 * tile, 0), "-%d" % int(dmg), Color(1.0, 0.9, 0.5), false)
		if is_vane and m != null and randf() < 0.16 and m.has_method("_damage_number"):
			var quips := ["That one had it coming.", "Still got it.", "For the nursery!", "Rust won't stop steel.", "Bones break the same as ever.", "Tell the King I'm coming.", "Even the drowned kneel, boy.", "Salt won't save them.", "My old crew would laugh.", "Swing like the tide, boy.", "The deep takes all debts.", "One less ghost in the water.", "They fall like rigging in a gale.", "Mind the undertow, boy.", "Back to the brine with you.", "The crows eat well tonight.", "Webs cut like rigging, boy.", "Two shots? I fought faster crews.", "The deep keeps books — pay her early."]

			m._damage_number(global_position + Vector3(0, 0.8 * tile, 0), quips[randi() % quips.size()], Color(0.65, 0.85, 1.0), true)
