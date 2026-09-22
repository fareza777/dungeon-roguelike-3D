class_name Mats
# Helper statis: material toon, paint rekursif, resolver animasi fuzzy.

static var toon_shader: Shader = preload("res://toon.gdshader")
static var outline_shader: Shader = preload("res://outline.gdshader")


static func toon(tex: Texture2D, tint: Color, rim := 0.25, outlined := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = toon_shader
	m.set_shader_parameter("albedo_texture", tex)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("rim_strength", rim)
	if outlined:
		var o := ShaderMaterial.new()
		o.shader = outline_shader
		m.next_pass = o
	return m


static func paint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for c in node.get_children():
		paint(c, mat)


static func anim_player(node: Node) -> AnimationPlayer:
	return node.find_child("AnimationPlayer", true, false) as AnimationPlayer


# Mainkan animasi pertama yang namanya mengandung salah satu keyword.
# Tidak me-restart animasi yang sudah berjalan.
static func play_fuzzy(ap: AnimationPlayer, keywords: Array) -> String:
	if ap == null:
		return ""
	var list := ap.get_animation_list()
	for kw in keywords:
		for n in list:
			if String(n).to_lower().contains(kw):
				if ap.current_animation != n:
					ap.play(n)
				return n
	return ""


static var _act_rng := RandomNumberGenerator.new()

# Animasi aksi (attack/hit/death): dipercepat, dipilih acak dari semua yang cocok,
# dan SELALU direstart. Mengembalikan durasi kunci — selama itu pemanggil
# wajib melewati animasi locomotion supaya aksi tidak ter-stomp 1 frame.
static func play_action(ap: AnimationPlayer, keywords: Array, speed := 1.4) -> float:
	if ap == null:
		return 0.0
	var matches: Array = []
	for kw in keywords:
		for n in ap.get_animation_list():
			if String(n).to_lower().contains(kw):
				matches.append(n)
		if not matches.is_empty():
			break
	if matches.is_empty():
		return 0.0
	var pick: String = matches[_act_rng.randi_range(0, matches.size() - 1)]
	var dur: float = ap.get_animation(pick).length / max(speed, 0.01)
	ap.play(pick, -1, speed)
	return dur
