extends Node3D

# Visual target test: satu ruangan dungeon, portrait mobile.
# Mode "before" = aset mentah + lighting default (tampilan asset-flip).
# Mode "after"  = lapis unifikasi: toon+outline, fog, bloom, grading, palet.
#
# Jalankan:
#   godot --path visual-test -- --mode before
#   godot --path visual-test -- --mode after

const DUNGEON := "res://assets/dungeon/"
const CHARS := "res://assets/characters/"

var mode := "after"

var toon_shader: Shader = preload("res://toon.gdshader")
var outline_shader: Shader = preload("res://outline.gdshader")
var dungeon_tex: Texture2D = preload("res://assets/dungeon/dungeon_texture.png")
var skeleton_tex: Texture2D = preload("res://assets/characters/skeleton_texture.png")

var g_floors: Array = []
var g_walls: Array = []
var g_props: Array = []
var g_chars: Array = []
var g_chest: Node3D = null
var g_torches: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.trim_prefix("--mode=")
	_build()
	_shoot()


func _scene(path: String) -> PackedScene:
	var ps: PackedScene = load(path)
	if ps == null:
		push_error("Gagal load: " + path)
	return ps


func _meshes(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_meshes(c))
	return out


func _world_aabb(node: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for mi in _meshes(node):
		mi.force_update_transform()
		var ta: AABB = mi.global_transform * mi.get_aabb()
		if first:
			aabb = ta
			first = false
		else:
			aabb = aabb.merge(ta)
	return aabb


# Instance, lalu geser supaya pusat XZ di target.x/z dan dasar AABB di target.y
func _place(ps: PackedScene, target: Vector3, rot_y_deg: float = 0.0) -> Node3D:
	var inst: Node3D = ps.instantiate()
	add_child(inst)
	inst.rotation_degrees.y = rot_y_deg
	var a := _world_aabb(inst)
	var c := a.get_center()
	inst.global_position += Vector3(target.x - c.x, target.y - a.position.y, target.z - c.z)
	return inst


func _toon(tex: Texture2D, tint: Color, rim: float = 0.25, outlined: bool = false) -> ShaderMaterial:
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


func _paint(node: Node, mat: Material) -> void:
	for mi in _meshes(node):
		mi.material_override = mat


func _play_idle(node: Node) -> void:
	var ap := node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	var pick := ""
	var list := ap.get_animation_list()
	for n in list:
		if String(n).to_lower().contains("idle"):
			pick = n
			break
	if pick == "" and list.size() > 0:
		pick = list[0]
	if pick != "":
		ap.play(pick)
		ap.advance(0.35)


func _build() -> void:
	# --- lantai 4x5, ukuran grid diukur dari AABB tile aslinya ---
	var floor_ps := _scene(DUNGEON + "floor_tile_large.gltf.glb")
	var first := _place(floor_ps, Vector3.ZERO)
	g_floors.append(first)
	var fa := _world_aabb(first)
	var sx: float = fa.size.x
	var sz: float = fa.size.z
	for i in range(4):
		for j in range(5):
			if i == 0 and j == 0:
				continue
			g_floors.append(_place(floor_ps, Vector3(i * sx, 0.0, -j * sz)))

	var cx := 1.5 * sx

	# --- dinding utara dengan gerbang ganda di tengah ---
	var wall_ps := _scene(DUNGEON + "wall.gltf.glb")
	var door_ps := _scene(DUNGEON + "wall_doorway.glb")
	for i in range(4):
		var ps: PackedScene = door_ps if (i == 1 or i == 2) else wall_ps
		g_walls.append(_place(ps, Vector3(i * sx, 0.0, -4.5 * sz)))
	# dinding barat & timur
	for j in range(5):
		g_walls.append(_place(wall_ps, Vector3(-1.0 * sx, 0.0, -j * sz), 90.0))
		g_walls.append(_place(wall_ps, Vector3(4.0 * sx, 0.0, -j * sz), -90.0))

	# --- props ---
	g_props.append(_place(_scene(DUNGEON + "pillar_decorated.gltf.glb"), Vector3(-0.1 * sx, 0.0, -3.7 * sz)))
	g_props.append(_place(_scene(DUNGEON + "pillar_decorated.gltf.glb"), Vector3(3.1 * sx, 0.0, -3.7 * sz)))
	g_chest = _place(_scene(DUNGEON + "chest_gold.glb"), Vector3(1.5 * sx, 0.0, -3.3 * sz), 180.0)
	g_props.append(_place(_scene(DUNGEON + "barrel_large.gltf.glb"), Vector3(0.3 * sx, 0.0, -2.2 * sz), 25.0))
	g_props.append(_place(_scene(DUNGEON + "crates_stacked.gltf.glb"), Vector3(3.0 * sx, 0.0, -2.4 * sz), -15.0))
	g_props.append(_place(_scene(DUNGEON + "rubble_half.gltf.glb"), Vector3(0.7 * sx, 0.0, -0.8 * sz), 70.0))
	g_torches.append(_place(_scene(DUNGEON + "torch_mounted.gltf.glb"), Vector3(0.6 * sx, 1.5, -4.3 * sz)))
	g_torches.append(_place(_scene(DUNGEON + "torch_mounted.gltf.glb"), Vector3(2.5 * sx, 1.5, -4.3 * sz)))
	g_props.append(_place(_scene(DUNGEON + "banner_red.gltf.glb"), Vector3(1.5 * sx, 1.8, -4.38 * sz)))

	# --- karakter ---
	var warrior := _place(_scene(CHARS + "Skeleton_Warrior.glb"), Vector3(1.2 * sx, 0.0, -1.1 * sz), -160.0)
	var minion := _place(_scene(CHARS + "Skeleton_Minion.glb"), Vector3(1.8 * sx, 0.0, -2.2 * sz), 25.0)
	g_chars.append(warrior)
	g_chars.append(minion)
	_play_idle(warrior)
	_play_idle(minion)

	# --- kamera portrait: tinggi, karakter di sepertiga bawah ---
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(cx + 0.2 * sx, 3.2 * sx, 1.9 * sx)
	cam.look_at(Vector3(cx, 0.3 * sx, -2.2 * sz))
	cam.fov = 42.0
	cam.current = true

	var sun := DirectionalLight3D.new()
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	we.environment = env
	add_child(we)

	if mode == "before":
		# tampilan "asset flip": satu lampu putih datar, ambient abu, tanpa efek
		sun.rotation_degrees = Vector3(-50, -30, 0)
		sun.shadow_enabled = false
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.55, 0.58, 0.62)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(1, 1, 1)
		env.ambient_light_energy = 0.7
	else:
		_style_after(sun, env, cx, sx, sz)


func _style_after(sun: DirectionalLight3D, env: Environment, cx: float, sx: float, sz: float) -> void:
	# palet: dungeon biru-ungu dingin + api oranye hangat (teal-orange)
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 0.9
	sun.shadow_enabled = true

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.03, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.28, 0.45)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.1
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_density = 0.024
	env.fog_light_color = Color(0.09, 0.08, 0.16)
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.adjustment_contrast = 1.07

	# toon per kategori, palet disatukan lewat tint
	var floor_mat := _toon(dungeon_tex, Color(0.78, 0.85, 1.08), 0.15)
	var wall_mat := _toon(dungeon_tex, Color(0.9, 0.92, 1.06), 0.2)
	var prop_mat := _toon(dungeon_tex, Color(1.05, 0.97, 0.9), 0.2)
	var gold_mat := _toon(dungeon_tex, Color(1.1, 1.0, 0.75), 0.35)
	var char_mat := _toon(skeleton_tex, Color(1, 1, 1), 0.4, true)

	for n in g_floors:
		_paint(n, floor_mat)
	for n in g_walls:
		_paint(n, wall_mat)
	for n in g_props:
		_paint(n, prop_mat)
	if g_chest != null:
		_paint(g_chest, gold_mat)
	for n in g_chars:
		_paint(n, char_mat)
	for t in g_torches:
		_paint(t, prop_mat)

	# lampu api di tiap torch
	for t in g_torches:
		var omni := OmniLight3D.new()
		add_child(omni)
		omni.global_position = t.global_position + Vector3(0.0, 0.4, 0.4)
		omni.light_color = Color(1.0, 0.55, 0.22)
		omni.light_energy = 1.4
		omni.omni_range = 7.0
		omni.omni_attenuation = 1.3

	# ember melayang, ditangkap bloom
	var embers := GPUParticles3D.new()
	add_child(embers)
	embers.position = Vector3(cx, 0.4, -2.2 * sz)
	embers.amount = 28
	embers.lifetime = 3.2
	embers.preprocess = 3.2
	embers.visibility_aabb = AABB(Vector3(-8, -1, -14), Vector3(16, 10, 16))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.6 * sx, 0.5, 2.2 * sz)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0, 0.12, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	pm.color = Color(1.0, 0.55, 0.2)
	embers.process_material = pm
	var dot := SphereMesh.new()
	dot.radius = 0.02
	dot.height = 0.04
	var dot_mat := StandardMaterial3D.new()
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mat.albedo_color = Color(1.0, 0.6, 0.25)
	dot_mat.emission_enabled = true
	dot_mat.emission = Color(1.0, 0.5, 0.2)
	dot_mat.emission_energy_multiplier = 2.5
	dot.material = dot_mat
	embers.draw_pass_1 = dot


func _shoot() -> void:
	for i in range(24):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := "res://out_" + mode + ".png"
	img.save_png(path)
	print("SAVED ", ProjectSettings.globalize_path(path))
	get_tree().quit()
