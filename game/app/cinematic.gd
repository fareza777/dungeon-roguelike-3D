extends Control
# Cinematic pembuka: panel seni (cine_1..4) dengan Ken Burns + caption +
# voice over ElevenLabs (bila file ada). Ketuk = lanjut, Lewati = skip.

const LINES := [
	{"text": "In the forgotten depths of the earth, a kingdom of bone has awakened from its slumber.", "img": "cine_1.png"},
	{"text": "You are the last warrior who dares descend these stairs.", "img": "cine_2.png"},
	{"text": "Every floor grows darker. Every step more dangerous. And at the end, the Bone King waits.", "img": "cine_3.png"},
	{"text": "Descend. Survive. And never trust the dark.", "img": "cine_4.png"},
]

var idx := 0
var autotest := false
var vo: AudioStreamPlayer
var label: Label
var panel_img: TextureRect
var fade: Tween = null
var bar_t: ColorRect = null
var bar_b: ColorRect = null
var dots: HBoxContainer = null


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
	vo = AudioStreamPlayer.new()
	add_child(vo)

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# panel seni layar penuh (Ken Burns pelan)
	panel_img = TextureRect.new()
	panel_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_img)

	# letterbox bars — sinematik turun dari atas/bawah
	bar_t = ColorRect.new()
	bar_t.color = Color(0.0, 0.0, 0.02)
	bar_t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_t.custom_minimum_size = Vector2(0, 0)
	bar_t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar_t)
	bar_b = ColorRect.new()
	bar_b.color = Color(0.0, 0.0, 0.02)
	bar_b.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_b.custom_minimum_size = Vector2(0, 0)
	bar_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar_b)
	var btw := create_tween().set_parallel(true)
	btw.tween_property(bar_t, "custom_minimum_size:y", 60.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	btw.tween_property(bar_b, "custom_minimum_size:y", 60.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# page dots — progress cerita
	dots = HBoxContainer.new()
	dots.anchor_left = 0.5
	dots.anchor_right = 0.5
	dots.anchor_top = 1.0
	dots.anchor_bottom = 1.0
	dots.offset_left = -60
	dots.offset_right = 60
	dots.offset_top = -52
	dots.offset_bottom = -40
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for di in range(LINES.size()):
		var d := Label.new()
		d.text = "●"
		d.add_theme_font_size_override("font_size", 13)
		d.modulate = Color(1, 1, 1, 0.25) if di != 0 else Color(0.95, 0.78, 0.35, 0.95)
		dots.add_child(d)
	add_child(dots)

	# gradasi gelap bawah supaya caption kebaca
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.02, 0.55)
	shade.anchor_left = 0.0
	shade.anchor_right = 1.0
	shade.anchor_top = 1.0
	shade.anchor_bottom = 1.0
	shade.offset_top = -380
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	label = Label.new()
	label.custom_minimum_size = Vector2(460, 300)
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.offset_top = 220
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(label)

	var hint := Label.new()
	hint.text = "tap to continue"
	hint.add_theme_font_size_override("font_size", 15)
	hint.modulate = Color(1, 1, 1, 0.35)
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -120
	hint.offset_right = 120
	hint.offset_top = -60
	hint.offset_bottom = -30
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	var htw := hint.create_tween()
	htw.set_loops()
	htw.tween_property(hint, "modulate:a", 0.75, 0.9).set_trans(Tween.TRANS_SINE)
	htw.tween_property(hint, "modulate:a", 0.3, 0.9).set_trans(Tween.TRANS_SINE)

	var skip := Button.new()
	skip.text = "SKIP ›"
	skip.add_theme_font_size_override("font_size", 19)
	skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	skip.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1.0))
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.04, 0.04, 0.08, 0.55)
	ssb.border_color = Color(1, 1, 1, 0.28)
	ssb.set_border_width_all(1)
	ssb.set_corner_radius_all(14)
	ssb.content_margin_left = 18.0
	ssb.content_margin_right = 18.0
	skip.add_theme_stylebox_override("normal", ssb)
	var ssbh := ssb.duplicate()
	ssbh.bg_color = Color(0.1, 0.09, 0.16, 0.7)
	ssbh.border_color = Color(0.95, 0.78, 0.35, 0.7)
	skip.add_theme_stylebox_override("hover", ssbh)
	skip.add_theme_stylebox_override("pressed", ssbh)
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
	Transit.fade_in(self)
	if autotest:
		for i in range(15):
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://out_shell_1_cinematic.png")
		print("SAVED CINEMATIC")
		# bukti panel kedua juga render
		_show(2)
		for i in range(8):
			await get_tree().process_frame
		img = get_viewport().get_texture().get_image()
		img.save_png("res://out_shell_1b_cinematic.png")
		print("SAVED CINEMATIC P3")
		_finish()


func _show(i: int) -> void:
	idx = i
	var ln: Dictionary = LINES[i]
	label.text = ln["text"]
	label.modulate.a = 0.0
	if dots != null:
		for di in range(dots.get_child_count()):
			var dd: Label = dots.get_child(di)
			dd.modulate = Color(0.95, 0.78, 0.35, 0.95) if di == i else Color(1, 1, 1, 0.25)
	var img_path := "res://assets/ui/" + String(ln["img"])
	if ResourceLoader.exists(img_path):
		panel_img.texture = load(img_path)
		panel_img.modulate.a = 0.0
		panel_img.scale = Vector2(1.0, 1.0)
		panel_img.pivot_offset = Vector2(270, 600)
	if fade != null and fade.is_valid():
		fade.kill()
	fade = create_tween()
	fade.set_parallel(true)
	fade.tween_property(label, "modulate:a", 1.0, 0.6)
	fade.tween_property(panel_img, "modulate:a", 1.0, 0.5)
	fade.tween_property(panel_img, "scale", Vector2(1.07, 1.07), 5.0)
	var path := "res://assets/audio/vo/line%d.mp3" % (i + 1)
	if ResourceLoader.exists(path):
		vo.stop()
		vo.stream = load(path)
		vo.volume_db = linear_to_db(Stats.mus_vol() if Stats.music_volume >= 0.0 else Stats.volume)
		vo.play()


func _next() -> void:
	Sfx.play("click")
	if idx < LINES.size() - 1:
		_show(idx + 1)
	else:
		_finish()


func _finish() -> void:
	vo.stop()
	Stats.seen_cinematic = true
	Stats.save_game()
	await Transit.fade_out(self)
	get_tree().change_scene_to_file("res://Main.tscn")
