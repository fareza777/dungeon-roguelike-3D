extends Control
# Cinematic pembuka: panel seni (cine_1..4) dengan Ken Burns + caption +
# voice over ElevenLabs (bila file ada). Ketuk = lanjut, Lewati = skip.

const LINES := [
	{"text": "Di kedalaman bumi yang terlupakan, sebuah kerajaan tulang terbangun dari tidurnya.", "img": "cine_1.png"},
	{"text": "Kaulah prajurit terakhir yang berani menuruni tangga ini.", "img": "cine_2.png"},
	{"text": "Setiap lantai semakin gelap. Setiap langkah semakin berbahaya. Dan di ujung, Raja Tulang menunggu.", "img": "cine_3.png"},
	{"text": "Turunlah. Bertahanlah. Dan jangan pernah percaya kegelapan.", "img": "cine_4.png"},
]

var idx := 0
var autotest := false
var vo: AudioStreamPlayer
var label: Label
var panel_img: TextureRect
var fade: Tween = null


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
	vo = AudioStreamPlayer.new()
	add_child(vo)

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# panel seni layar penuh (Ken Burns pelan)
	panel_img = TextureRect.new()
	panel_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_img)

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
	cc.add_child(label)

	var hint := Label.new()
	hint.text = "ketuk untuk lanjut"
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
	add_child(hint)

	var skip := Button.new()
	skip.text = "Lewati >"
	skip.add_theme_font_size_override("font_size", 20)
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
	get_tree().change_scene_to_file("res://Main.tscn")
