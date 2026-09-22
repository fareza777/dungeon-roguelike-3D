extends Control
# Menu utama v2: key art backdrop, tombol styled, bara api melayang,
# pengaturan (volume + kualitas + uji suara).

var autotest := false
var settings_panel: CenterContainer = null
var vol_slider: HSlider = null
var qual_opt: OptionButton = null

const GOLD := Color(0.95, 0.78, 0.35)
const INK := Color(0.07, 0.06, 0.12, 0.88)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
	Stats.load_game()
	Sfx.set_volume(Stats.volume)
	Sfx.play_music()
	_build()
	if autotest:
		_shell_autotest()


func _make_btn(txt: String, big := true) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(380, 84 if big else 64)
	b.add_theme_font_size_override("font_size", 28 if big else 20)
	b.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = INK
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.16, 0.13, 0.2, 0.95)
	sbh.border_color = Color(1.0, 0.9, 0.55)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.35, 0.27, 0.12, 1.0)
	b.add_theme_stylebox_override("pressed", sbp)
	b.pivot_offset = b.custom_minimum_size * 0.5
	b.pressed.connect(_btn_punch.bind(b))
	return b


func _btn_punch(b: Button) -> void:
	Sfx.play("click")
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.06)
	tw.tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)


func _build() -> void:
	# key art backdrop
	if ResourceLoader.exists("res://assets/ui/menu_bg.png"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/ui/menu_bg.png")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.03, 0.08)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	# overlay gelap bawah supaya teks kebaca
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# bara api melayang
	var embers := CPUParticles2D.new()
	embers.amount = 22
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(280, 30)
	embers.position = Vector2(270, 1150)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -14)
	embers.initial_velocity_min = 12.0
	embers.initial_velocity_max = 30.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.5
	embers.color = Color(1.0, 0.6, 0.25, 0.75)
	add_child(embers)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)

	var title := Label.new()
	title.text = "DUNGEON\nSLICE"
	title.add_theme_font_size_override("font_size", 80)
	title.modulate = GOLD
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vb.add_child(title)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(title, "modulate", Color(1.0, 0.88, 0.5), 1.6)
	tw.tween_property(title, "modulate", GOLD, 1.6)

	var sub := Label.new()
	sub.text = "roguelike tulang-belulang"
	sub.add_theme_font_size_override("font_size", 18)
	sub.modulate = Color(1, 1, 1, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(sub)

	var best := Label.new()
	best.text = "Terbaik: Lantai %d • Total kill: %d" % [Stats.best_floor, Stats.total_kills]
	best.add_theme_font_size_override("font_size", 17)
	best.modulate = Color(1.0, 0.9, 0.6, 0.85)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	best.add_theme_constant_override("shadow_offset_x", 2)
	best.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(best)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 26)
	vb.add_child(sp)

	if Stats.has_run():
		var bc := _make_btn("LANJUTKAN — Lantai %d" % int(Stats.saved_run.get("floor", 1)))
		bc.pressed.connect(_on_continue)
		vb.add_child(bc)

	var bn := _make_btn("GAME BARU")
	bn.pressed.connect(_on_new)
	vb.add_child(bn)

	var bs := _make_btn("PENGATURAN", false)
	bs.pressed.connect(func() -> void: settings_panel.visible = true)
	vb.add_child(bs)

	var bq := _make_btn("KELUAR", false)
	bq.pressed.connect(func() -> void: get_tree().quit())
	vb.add_child(bq)

	var ver := Label.new()
	ver.text = "v0.4.0"
	ver.anchor_left = 0.5
	ver.anchor_right = 0.5
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -100
	ver.offset_right = 100
	ver.offset_top = -44
	ver.offset_bottom = -16
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.modulate = Color(1, 1, 1, 0.35)
	add_child(ver)

	_build_settings()


func _build_settings() -> void:
	settings_panel = CenterContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.visible = false
	add_child(settings_panel)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.08, 0.07, 0.12, 0.98)
	psb.border_color = GOLD
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(16)
	psb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", psb)
	settings_panel.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.custom_minimum_size = Vector2(430, 0)
	panel.add_child(vb)

	var t := Label.new()
	t.text = "PENGATURAN"
	t.add_theme_font_size_override("font_size", 30)
	t.modulate = GOLD
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var vl := Label.new()
	vl.text = "Volume"
	vl.add_theme_font_size_override("font_size", 20)
	vb.add_child(vl)
	vol_slider = HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = Stats.volume
	vol_slider.value_changed.connect(func(v: float) -> void:
		Sfx.set_volume(v)
		Stats.volume = v
		Stats.save_game()
	)
	vb.add_child(vol_slider)

	var ts := _make_btn("Uji Suara", false)
	ts.pressed.connect(func() -> void:
		Sfx.play("swing")
		await get_tree().create_timer(0.35).timeout
		Sfx.play("levelup")
	)
	vb.add_child(ts)

	var ql := Label.new()
	ql.text = "Kualitas grafis"
	ql.add_theme_font_size_override("font_size", 20)
	vb.add_child(ql)
	qual_opt = OptionButton.new()
	qual_opt.add_item("Otomatis", 0)
	qual_opt.add_item("Hemat (HP kentang)", 1)
	qual_opt.add_item("Indah", 2)
	qual_opt.selected = clampi(Stats.quality + 1, 0, 2)
	qual_opt.item_selected.connect(func(ix: int) -> void:
		Stats.quality = ix - 1
		Stats.save_game()
	)
	vb.add_child(qual_opt)

	var back := _make_btn("Tutup", false)
	back.pressed.connect(func() -> void: settings_panel.visible = false)
	vb.add_child(back)


func _on_continue() -> void:
	Stats.pending_restore = true
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_new() -> void:
	Stats.pending_restore = false
	if Stats.seen_cinematic:
		get_tree().change_scene_to_file("res://Main.tscn")
	else:
		get_tree().change_scene_to_file("res://app/cinematic.tscn")


func _shell_autotest() -> void:
	for i in range(20):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://out_shell_2_menu.png")
	print("SAVED MENU")
	_on_new()
