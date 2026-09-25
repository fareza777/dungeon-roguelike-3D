extends Node3D
# Batu nisan Revenant: muncul saat Revenant mati. Hancurkan dalam 3 detik
# atau tuan nisannya bangkit kembali pada 60% HP. Dihancurkan seperti guci.

signal release(tomb)

var tile := 4.0
var t := 3.0
var arch := "brute"
var room_i := 0
var done := false
var base_y := 0.0
var tick_l: Label3D = null


func setup(p_tile: float, p_arch: String, p_room: int) -> void:
	tile = p_tile
	arch = p_arch
	room_i = p_room
	add_to_group("urns")
	add_to_group("glints")
	var slab := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(0.16 * tile, 0.45 * tile, 0.06 * tile)
	slab.mesh = bx
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.34, 0.3)
	m.roughness = 0.9
	slab.material_override = m
	slab.position.y = 0.22 * tile
	add_child(slab)
	base_y = slab.position.y
	# rune ungu di muka nisan
	var rune := MeshInstance3D.new()
	var rq := QuadMesh.new()
	rq.size = Vector2(0.1 * tile, 0.1 * tile)
	rune.mesh = rq
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.7, 0.35, 1.0)
	rm.emission_enabled = true
	rm.emission = Color(0.6, 0.25, 1.0)
	rm.emission_energy_multiplier = 2.5
	rune.material_override = rm
	rune.position = Vector3(0, 0.3 * tile, 0.035 * tile)
	add_child(rune)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.6, 0.3, 1.0)
	gl.light_energy = 1.2
	gl.omni_range = 1.2 * tile
	gl.position.y = 0.4 * tile
	add_child(gl)
	tick_l = Label3D.new()
	tick_l.font_size = 60
	tick_l.pixel_size = 0.011
	tick_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tick_l.modulate = Color(0.75, 0.4, 1.0)
	tick_l.outline_size = 12
	tick_l.outline_modulate = Color(0.08, 0.03, 0.12, 0.95)
	tick_l.text = "3"
	tick_l.position.y = 0.75 * tile
	add_child(tick_l)


func _physics_process(delta: float) -> void:
	if done:
		return
	t -= delta
	scale = Vector3.ONE * (0.75 + 0.25 * maxf(0.0, t / 3.0))
	if tick_l != null:
		var rem := int(ceil(t))
		tick_l.text = str(maxi(rem, 1))
		tick_l.modulate = Color(1.0, 0.3, 0.35) if t < 1.0 else Color(0.75, 0.4, 1.0)
	if t <= 0.0:
		done = true
		release.emit(self)
		queue_free()


func smash(from_pos: Vector3) -> void:
	if done:
		return
	done = true
	var m := get_tree().current_scene
	if m != null:
		if m.has_method("_burst"):
			m._burst(global_position + Vector3(0, 0.3 * tile, 0), Color(0.7, 0.4, 1.0))
		if m.has_method("_damage_number"):
			m._damage_number(global_position + Vector3(0, 0.5 * tile, 0), "DENIED!", Color(0.75, 0.5, 1.0), true)
		if m.has_method("_quest_event"):
			m._quest_event("tomb")
	Sfx.play("hit")
	queue_free()
