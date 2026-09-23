extends Control
const BIO = preload("res://biomes_db.gd")
# Menu utama v5: key art, Lanjutkan/Game Baru, Pengaturan (musik+SFX terpisah,
# kualitas, reset), Tentang, Bagikan, Nilai Play Store, Keluar, label versi.

var autotest := false
var settings_panel: CenterContainer = null
var about_panel: CenterContainer = null
var souls_panel: CenterContainer = null
var souls_rows: VBoxContainer = null
var souls_lbl: Label = null
var ach_panel: CenterContainer = null
var ach_rows: VBoxContainer = null
var ach_title: Label = null
var toast_l: Label = null

const GOLD := Color(0.95, 0.78, 0.35)
const INK := Color(0.07, 0.06, 0.12, 0.88)
const STORE_URL := "https://play.google.com/store/apps/details?id="


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
	Stats.load_game()
	Sfx.set_volume(Stats.volume)
	Sfx.play_music("menu")
	_build()
	_build_souls()
	_build_ach()
	Transit.fade_in(self)
	if autotest:
		_shell_autotest()


func _make_btn(txt: String, big := true) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(380, 78 if big else 60)
	b.add_theme_font_size_override("font_size", 26 if big else 19)
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


func _toast(txt: String) -> void:
	toast_l.text = txt
	toast_l.visible = true
	toast_l.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(toast_l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: toast_l.visible = false)


func _style_slider(s: HSlider) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.16, 0.9)
	sb.set_corner_radius_all(4)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", sb)
	var hi := StyleBoxFlat.new()
	hi.bg_color = Color(0.9, 0.75, 0.3)
	hi.set_corner_radius_all(4)
	hi.content_margin_top = 4
	hi.content_margin_bottom = 4
	s.add_theme_stylebox_override("grabber_area", hi)
	s.add_theme_stylebox_override("grabber_area_highlight", hi)
	s.add_theme_icon_override("grabber", _make_grabber())
	s.add_theme_icon_override("grabber_highlight", _make_grabber())


func _make_grabber() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d <= 7.5:
				img.set_pixel(x, y, Color(1.0, 0.9, 0.6) if d <= 6.0 else Color(0.6, 0.45, 0.2))
	return ImageTexture.create_from_image(img)


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
		# ken burns: key art melayang pelan — rasa hidup di layar judul
		bg.pivot_offset = bg.size * 0.5
		var ktw := bg.create_tween()
		ktw.set_loops()
		ktw.tween_property(bg, "scale", Vector2(1.07, 1.07), 16.0).set_trans(Tween.TRANS_SINE)
		ktw.tween_property(bg, "scale", Vector2.ONE, 16.0).set_trans(Tween.TRANS_SINE)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.03, 0.08)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
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
	vb.add_theme_constant_override("separation", 12)
	cc.add_child(vb)

	var title := Label.new()
	title.text = "DUNGEON\nSLICE"
	title.add_theme_font_size_override("font_size", 80)
	title.modulate = GOLD
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0.22, 0.1, 0.0, 1.0))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vb.add_child(title)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(title, "modulate", Color(1.0, 0.88, 0.5), 1.6)
	tw.tween_property(title, "modulate", GOLD, 1.6)

	var sub := Label.new()
	sub.text = "a bone-breaking roguelike"
	sub.add_theme_font_size_override("font_size", 18)
	sub.modulate = Color(1, 1, 1, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(sub)

	var best := Label.new()
	var boss_txt := " • Bosses slain: %d" % Stats.boss_kills if Stats.boss_kills > 0 else ""
	var ach_txt := " • ◆ %d/%d" % [Stats.ach.size(), Stats.ACH_DEF.size()] if Stats.ach.size() > 0 else ""
	var ng_txt := " • ♛ NG+%d" % Stats.ng_plus if Stats.ng_plus > 0 else ""
	var lore_txt := " • Lore %d/92" % Stats.lore_seen.size() if Stats.lore_seen.size() > 0 else ""
	var oath_txt := " • ☗ %d/59" % Stats.oaths_seen.size() if Stats.oaths_seen.size() > 0 else ""
	var best_txt := " • ⚔ %d kinds slain" % Stats.arch_kills.size() if Stats.arch_kills.size() > 0 else ""
	var souls_txt := " • ◈ %d" % Stats.souls if Stats.souls > 0 else ""
	var nem_txt := "\n☠ Nemesis: %s hunts you" % Stats.nemesis_name if Stats.nemesis_name != "" else ""
	var bname := String(BIO.for_floor(maxi(Stats.best_floor, 1)).get("name", "")) if Stats.best_floor > 0 else ""
	var rank := ""
	if Stats.best_floor >= 25:
		rank = "CROWNTAKER"
	elif Stats.best_floor >= 20:
		rank = "KING'S BANE"
	elif Stats.best_floor >= 13:
		rank = "DEEP DELVER"
	elif Stats.best_floor >= 7:
		rank = "CRYPT RUNNER"
	elif Stats.best_floor >= 3:
		rank = "GRAVE DIGGER"
	best.text = "Best: Floor %d%s • Total kills: %d%s%s%s%s%s%s%s%s%s" % [Stats.best_floor, (" (" + bname + ")") if bname != "" else "", Stats.total_kills, boss_txt, ach_txt, ng_txt, lore_txt, oath_txt, souls_txt, nem_txt, best_txt, ("
✦ Rank: " + rank) if rank != "" else ""]
	best.add_theme_font_size_override("font_size", 17)
	best.modulate = Color(1.0, 0.9, 0.6, 0.85)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	best.add_theme_constant_override("shadow_offset_x", 2)
	best.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(best)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	vb.add_child(sp)

	if Stats.has_run():
		var bc := _make_btn("CONTINUE — Floor %d" % int(Stats.saved_run.get("floor", 1)))
		bc.pressed.connect(_on_continue)
		vb.add_child(bc)

	var bn := _make_btn("NEW GAME")
	bn.pressed.connect(_on_new)
	vb.add_child(bn)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	var bs := _make_btn("SETTINGS", false)
	bs.custom_minimum_size = Vector2(184, 60)
	bs.pressed.connect(func() -> void: settings_panel.visible = true)
	row.add_child(bs)
	var ba := _make_btn("ABOUT", false)
	ba.custom_minimum_size = Vector2(184, 60)
	ba.pressed.connect(func() -> void: about_panel.visible = true)
	row.add_child(ba)

	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 10)
	vb.add_child(row2)
	var bsh := _make_btn("SHARE", false)
	bsh.custom_minimum_size = Vector2(184, 60)
	bsh.pressed.connect(_on_share)
	row2.add_child(bsh)
	var br := _make_btn("RATE ★", false)
	br.custom_minimum_size = Vector2(184, 60)
	br.pressed.connect(_on_rate)
	row2.add_child(br)

	var bq := _make_btn("QUIT", false)
	bq.custom_minimum_size = Vector2(184, 60)
	bq.pressed.connect(func() -> void: get_tree().quit())
	vb.add_child(bq)

	var bso := _make_btn("HALL OF SOULS — ◈ %d" % Stats.souls, false)
	bso.custom_minimum_size = Vector2(380, 60)
	bso.pressed.connect(func() -> void:
		_refresh_souls()
		souls_panel.visible = true
	)
	vb.add_child(bso)

	var bac := _make_btn("ACHIEVEMENTS — ◆ %d/%d" % [Stats.ach.size(), Stats.ACH_DEF.size()], false)
	bac.custom_minimum_size = Vector2(380, 60)
	bac.pressed.connect(func() -> void:
		_refresh_ach()
		ach_panel.visible = true
	)
	vb.add_child(bac)

	# masuk berjenjang: panel + tombol memudar satu-satu
	var kids: Array[Control] = []
	for c in vb.get_children():
		if c is Button or c is HBoxContainer:
			kids.append(c)
	for i2 in range(kids.size()):
		var k: Control = kids[i2]
		k.modulate.a = 0.0
		var stw := create_tween()
		stw.tween_interval(0.12 + 0.06 * i2)
		stw.tween_property(k, "modulate:a", 1.0, 0.3)

	var ver := Label.new()
	ver.text = "v" + Stats.VERSION
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

	toast_l = Label.new()
	toast_l.anchor_left = 0.5
	toast_l.anchor_right = 0.5
	toast_l.anchor_top = 1.0
	toast_l.anchor_bottom = 1.0
	toast_l.offset_left = -220
	toast_l.offset_right = 220
	toast_l.offset_top = -140
	toast_l.offset_bottom = -100
	toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_l.add_theme_font_size_override("font_size", 20)
	toast_l.modulate = Color(1.0, 0.9, 0.5)
	toast_l.visible = false
	add_child(toast_l)

	_build_settings()
	_build_about()


# ---------------- pengaturan ----------------

func _vol_row(vb: VBoxContainer, label: String, cur: float, on_change: Callable) -> void:
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 18)
	l.modulate = Color(1, 1, 1, 0.7)
	vb.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = cur
	s.custom_minimum_size = Vector2(0, 32)
	_style_slider(s)
	s.value_changed.connect(on_change)
	vb.add_child(s)


func _build_settings() -> void:
	settings_panel = CenterContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.visible = false
	add_child(settings_panel)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	settings_panel.add_child(dim)
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
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(430, 0)
	panel.add_child(vb)

	var t := Label.new()
	t.text = "SETTINGS"
	t.add_theme_font_size_override("font_size", 30)
	t.modulate = GOLD
	t.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0, 0.9))
	t.add_theme_constant_override("outline_size", 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	_vol_row(vb, "Music", Stats.mus_vol(), func(v: float) -> void:
		Stats.music_volume = v
		Sfx.set_music_volume(v)
		Stats.save_game()
	)
	_vol_row(vb, "Sound FX", Stats.sfx_vol(), func(v: float) -> void:
		Stats.sfx_volume = v
		Sfx.set_volume(v)
		Stats.save_game()
	)

	var ts := _make_btn("Test Sound", false)
	ts.pressed.connect(func() -> void:
		Sfx.play("swing")
		await get_tree().create_timer(0.35).timeout
		Sfx.play("levelup")
	)
	vb.add_child(ts)

	var ql := Label.new()
	ql.text = "Graphics quality"
	ql.add_theme_font_size_override("font_size", 18)
	ql.modulate = Color(1, 1, 1, 0.7)
	vb.add_child(ql)
	var qual_opt := OptionButton.new()
	qual_opt.add_item("Auto", 0)
	qual_opt.add_item("Low", 1)
	qual_opt.add_item("High", 2)
	qual_opt.selected = clampi(Stats.quality + 1, 0, 2)
	qual_opt.add_theme_font_size_override("font_size", 17)
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(0.1, 0.09, 0.16, 0.95)
	qsb.border_color = Color(0.9, 0.75, 0.3, 0.5)
	qsb.set_border_width_all(2)
	qsb.set_corner_radius_all(10)
	qual_opt.add_theme_stylebox_override("normal", qsb)
	qual_opt.item_selected.connect(func(ix: int) -> void:
		Stats.quality = ix - 1
		Stats.save_game()
	)
	vb.add_child(qual_opt)

	var wr := _make_btn("Reset All Progress", false)
	wr.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
	wr.pressed.connect(func() -> void:
		Stats.wipe_progress()
		_toast("All progress wiped")
		Sfx.play("hurt")
	)
	vb.add_child(wr)

	var back := _make_btn("Close", false)
	back.pressed.connect(func() -> void: settings_panel.visible = false)
	vb.add_child(back)


# ---------------- tentang ----------------

func _build_about() -> void:
	about_panel = CenterContainer.new()
	about_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	about_panel.visible = false
	add_child(about_panel)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	about_panel.add_child(dim)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.08, 0.07, 0.12, 0.98)
	psb.border_color = GOLD
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(16)
	psb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", psb)
	about_panel.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(440, 0)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "ABOUT"
	t.add_theme_font_size_override("font_size", 30)
	t.modulate = GOLD
	t.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0, 0.9))
	t.add_theme_constant_override("outline_size", 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var body := Label.new()
	body.text = "DUNGEONSLICE v%s\n\nAn action roguelike from the depths below. Every 5 floors the Bone King waits on his throne — slay him or become part of it.\n\n— Small Team, Big Nerve —\nModels: KayKit Skeleton Pack\nAltar statue: Meshy AI\nMusic & SFX: ElevenLabs\nEngine: Godot 4.7" % Stats.VERSION
	body.add_theme_font_size_override("font_size", 17)
	body.modulate = Color(1, 1, 1, 0.85)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(body)
	var back := _make_btn("Close", false)
	back.pressed.connect(func() -> void: about_panel.visible = false)
	vb.add_child(back)


# ---------------- aksi ----------------

func _build_souls() -> void:
	souls_panel = CenterContainer.new()
	souls_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	souls_panel.visible = false
	add_child(souls_panel)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	souls_panel.add_child(dim)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.07, 0.05, 0.13, 0.98)
	psb.border_color = Color(0.62, 0.45, 0.95)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(16)
	psb.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", psb)
	souls_panel.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(440, 0)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "HALL OF SOULS"
	t.add_theme_font_size_override("font_size", 28)
	t.modulate = Color(0.75, 0.6, 1.0)
	t.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.3, 0.9))
	t.add_theme_constant_override("outline_size", 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	souls_lbl = Label.new()
	souls_lbl.add_theme_font_size_override("font_size", 18)
	souls_lbl.modulate = Color(0.9, 0.85, 1.0, 0.9)
	souls_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(souls_lbl)
	var hint := Label.new()
	hint.text = "Spent souls are gone forever — but the power stays."
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(1, 1, 1, 0.45)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)
	souls_rows = VBoxContainer.new()
	souls_rows.add_theme_constant_override("separation", 8)
	vb.add_child(souls_rows)
	var back := _make_btn("BACK", false)
	back.pressed.connect(func() -> void: souls_panel.visible = false)
	vb.add_child(back)


func _refresh_souls() -> void:
	souls_lbl.text = "◈ %d souls — bound forever to Kael" % Stats.souls
	for c in souls_rows.get_children():
		c.queue_free()
	for id in Stats.META_DEF.keys():
		var d: Dictionary = Stats.META_DEF[id]
		var lv: int = int(Stats.meta.get(id, 0))
		var mx: int = int(d["max"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = "%s  %s" % [String(d["name"]), "◆".repeat(lv) + "◇".repeat(mx - lv)]
		nm.add_theme_font_size_override("font_size", 18)
		nm.modulate = Color(1.0, 0.95, 0.85)
		info.add_child(nm)
		var ds := Label.new()
		ds.text = String(d["desc"])
		ds.add_theme_font_size_override("font_size", 13)
		ds.modulate = Color(1, 1, 1, 0.55)
		info.add_child(ds)
		row.add_child(info)
		var bb := _make_btn("MAX" if lv >= mx else "◈ %d" % Stats.meta_cost(id), false)
		bb.custom_minimum_size = Vector2(110, 52)
		bb.disabled = lv >= mx
		var bb_id: String = id
		var bb_d: Dictionary = d
		bb.pressed.connect(func() -> void:
			if Stats.buy_meta(bb_id):
				Sfx.play("levelup")
				_toast("Bound: %s Lv %d" % [String(bb_d["name"]), int(Stats.meta[bb_id])])
			else:
				Sfx.play("deny")
				_toast("Not enough souls")
			_refresh_souls()
		)
		row.add_child(bb)
		souls_rows.add_child(row)


func _build_ach() -> void:
	ach_panel = CenterContainer.new()
	ach_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ach_panel.visible = false
	add_child(ach_panel)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	ach_panel.add_child(dim)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.1, 0.07, 0.05, 0.98)
	psb.border_color = GOLD
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(16)
	psb.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", psb)
	ach_panel.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(460, 0)
	panel.add_child(vb)
	ach_title = Label.new()
	ach_title.add_theme_font_size_override("font_size", 26)
	ach_title.modulate = GOLD
	ach_title.add_theme_color_override("font_outline_color", Color(0.25, 0.15, 0.02, 0.9))
	ach_title.add_theme_constant_override("outline_size", 6)
	ach_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ach_title)
	var hint := Label.new()
	hint.text = "Deeds the deeps remember — earned forever."
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(1, 1, 1, 0.45)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(440, 560)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)
	ach_rows = VBoxContainer.new()
	ach_rows.add_theme_constant_override("separation", 6)
	ach_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(ach_rows)
	var back := _make_btn("BACK", false)
	back.pressed.connect(func() -> void: ach_panel.visible = false)
	vb.add_child(back)


func _refresh_ach() -> void:
	ach_title.text = "ACHIEVEMENTS — %d/%d" % [Stats.ach.size(), Stats.ACH_DEF.size()]
	for c in ach_rows.get_children():
		c.queue_free()
	for id in Stats.ACH_DEF.keys():
		var got: bool = Stats.ach.get(id, false)
		var row := PanelContainer.new()
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(0.18, 0.13, 0.06, 0.9) if got else Color(0.06, 0.05, 0.08, 0.9)
		rsb.border_color = GOLD if got else Color(0.35, 0.3, 0.3)
		rsb.set_border_width_all(1)
		rsb.set_corner_radius_all(8)
		rsb.set_content_margin_all(8)
		row.add_theme_stylebox_override("panel", rsb)
		var l := Label.new()
		l.text = ("◆ " if got else "◇ ") + String(Stats.ACH_DEF[id])
		l.add_theme_font_size_override("font_size", 16)
		l.modulate = Color(1.0, 0.9, 0.55) if got else Color(1, 1, 1, 0.35)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(l)
		ach_rows.add_child(row)


func _on_share() -> void:
	var url := STORE_URL + Stats.STORE_ID
	DisplayServer.clipboard_set("Play DungeonSlice — a bone-breaking roguelike! " + url)
	_toast("Game link copied — share it with a friend!")
	Sfx.play("click")


func _on_rate() -> void:
	Stats.rated = true
	Stats.save_game()
	var ok := OS.shell_open("market://details?id=" + Stats.STORE_ID)
	if ok != OK:
		ok = OS.shell_open(STORE_URL + Stats.STORE_ID)
	if ok != OK:
		_toast("Opening Play Store: " + Stats.STORE_ID)
	else:
		_toast("Thanks for your rating!")


func _unhandled_input(event: InputEvent) -> void:
	# tombol back: tutup panel kalau ada, kalau tidak -> keluar aplikasi
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			settings_panel.visible = false
		elif souls_panel != null and souls_panel.visible:
			souls_panel.visible = false
		elif about_panel.visible:
			about_panel.visible = false
		else:
			get_tree().quit()


func _on_continue() -> void:
	Stats.pending_restore = true
	await Transit.fade_out(self)
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_new() -> void:
	Stats.pending_restore = false
	await Transit.fade_out(self)
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
	# bukti panel pengaturan render
	settings_panel.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	img = get_viewport().get_texture().get_image()
	img.save_png("res://out_shell_3_settings.png")
	settings_panel.visible = false
	_on_new()
