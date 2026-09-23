extends Control
# Onboarding 3 slide untuk run pertama: gerak, kunci arena, boss & altar.
# Geser/ketuk = lanjut. Selesai -> tandai onboarded -> cinematic/menu.

const SLIDES := [
	{
		"img": "res://assets/ui/icon.png",
		"title": "Geser & Tebas",
		"text": "Jempol kiri untuk bergerak. Tombol ATK merah untuk menebas. Skill terbuka seiring levelmu naik.",
		"tint": Color(0.4, 0.75, 1.0),
	},
	{
		"icon": "⚑",
		"title": "Ikuti Rantai Quest",
		"text": "Kotak di pojok kiri atas menunjukkan langkahmu berikutnya — bersihkan ruangan, capai ujung lantai, buka peti.",
		"tint": Color(1.0, 0.8, 0.3),
	},
	{
		"icon": "☠",
		"title": "Boss Tiap 5 Lantai",
		"text": "Raja Tulang menunggu di singgasananya. Perhatikan lingkar merah di lantai — itu telegraph slam-nya. Altar arwah memberimu berkat.",
		"tint": Color(1.0, 0.45, 0.4),
	},
]

var idx := 0
var slide_box: VBoxContainer
var dots: HBoxContainer
var btn_next: Button
var autotest := false
const GOLD := Color(0.95, 0.78, 0.35)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# bara
	var embers := CPUParticles2D.new()
	embers.amount = 18
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(280, 30)
	embers.position = Vector2(270, 1160)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -14)
	embers.initial_velocity_min = 12.0
	embers.initial_velocity_max = 26.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	embers.color = Color(1.0, 0.6, 0.25, 0.7)
	add_child(embers)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	slide_box = VBoxContainer.new()
	slide_box.alignment = BoxContainer.ALIGNMENT_CENTER
	slide_box.add_theme_constant_override("separation", 22)
	cc.add_child(slide_box)

	dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 14)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.anchor_left = 0.5
	dots.anchor_right = 0.5
	dots.anchor_top = 1.0
	dots.anchor_bottom = 1.0
	dots.offset_left = -80
	dots.offset_right = 80
	dots.offset_top = -210
	dots.offset_bottom = -170
	add_child(dots)
	for i in range(SLIDES.size()):
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(12, 12)
		d.color = Color(1, 1, 1, 0.2)
		d.name = "dot%d" % i
		dots.add_child(d)

	btn_next = Button.new()
	btn_next.custom_minimum_size = Vector2(340, 74)
	btn_next.add_theme_font_size_override("font_size", 26)
	btn_next.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.12, 0.9)
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	btn_next.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.18, 0.15, 0.24, 0.95)
	btn_next.add_theme_stylebox_override("hover", sbh)
	btn_next.anchor_left = 0.5
	btn_next.anchor_right = 0.5
	btn_next.anchor_top = 1.0
	btn_next.anchor_bottom = 1.0
	btn_next.offset_left = -170
	btn_next.offset_right = 170
	btn_next.offset_top = -150
	btn_next.offset_bottom = -76
	btn_next.pressed.connect(_next)
	add_child(btn_next)

	var skip := Button.new()
	skip.text = "Lewati >"
	skip.add_theme_font_size_override("font_size", 18)
	skip.modulate = Color(1, 1, 1, 0.5)
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -150
	skip.offset_top = 16
	skip.offset_right = -16
	skip.offset_bottom = 56
	skip.pressed.connect(_finish)
	add_child(skip)

	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_next()
		elif e is InputEventScreenTouch and e.pressed:
			_next()
	)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_show(0)
	if autotest:
		for i in range(12):
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://out_shell_0_onboarding.png")
		print("SAVED ONBOARDING")
		_finish()


func _show(i: int) -> void:
	idx = i
	for c in slide_box.get_children():
		c.queue_free()
	var s: Dictionary = SLIDES[i]
	if s.has("img") and ResourceLoader.exists(String(s["img"])):
		var icn := TextureRect.new()
		icn.texture = load(String(s["img"]))
		icn.custom_minimum_size = Vector2(150, 150)
		icn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		icn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slide_box.add_child(icn)
	else:
		var ic := Label.new()
		ic.text = String(s.get("icon", ""))
		ic.add_theme_font_size_override("font_size", 110)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.modulate = s["tint"]
		slide_box.add_child(ic)
	var t := Label.new()
	t.text = s["title"]
	t.add_theme_font_size_override("font_size", 42)
	t.modulate = GOLD
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slide_box.add_child(t)
	var tx := Label.new()
	tx.text = s["text"]
	tx.custom_minimum_size = Vector2(420, 0)
	tx.add_theme_font_size_override("font_size", 21)
	tx.modulate = Color(1, 1, 1, 0.82)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slide_box.add_child(tx)
	for c in slide_box.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slide_box.modulate.a = 0.0
	slide_box.scale = Vector2(0.92, 0.92)
	slide_box.pivot_offset = slide_box.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(slide_box, "modulate:a", 1.0, 0.3)
	tw.tween_property(slide_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	for d in dots.get_children():
		d.color = GOLD if d.name == "dot%d" % i else Color(1, 1, 1, 0.2)
	btn_next.text = "MULAI" if i == SLIDES.size() - 1 else "LANJUT"
	Sfx.play("page")


func _next() -> void:
	Sfx.play("click")
	if idx < SLIDES.size() - 1:
		_show(idx + 1)
	else:
		_finish()


func _finish() -> void:
	Stats.onboarded = true
	Stats.save_game()
	get_tree().change_scene_to_file("res://app/cinematic.tscn" if not Stats.seen_cinematic else "res://app/menu.tscn")
