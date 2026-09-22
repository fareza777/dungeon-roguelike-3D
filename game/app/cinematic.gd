extends Control
# Cinematic pembuka: 4 baris cerita + voice over ElevenLabs (bila file ada).
# Ketuk layar untuk baris berikutnya, tombol Lewati untuk skip.

const LINES := [
	"Di kedalaman bumi yang terlupakan, sebuah kerajaan tulang terbangun dari tidurnya.",
	"Kaulah prajurit terakhir yang berani menuruni tangga ini.",
	"Setiap lantai semakin gelap. Setiap langkah semakin berbahaya.",
	"Turunlah. Bertahanlah. Dan jangan pernah percaya kegelapan.",
]

var idx := 0
var autotest := false
var vo: AudioStreamPlayer
var label: Label
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

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	label = Label.new()
	label.custom_minimum_size = Vector2(460, 300)
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		_finish()


func _show(i: int) -> void:
	idx = i
	label.text = LINES[i]
	label.modulate.a = 0.0
	if fade != null and fade.is_valid():
		fade.kill()
	fade = create_tween()
	fade.tween_property(label, "modulate:a", 1.0, 0.6)
	var path := "res://assets/audio/vo/line%d.mp3" % (i + 1)
	if ResourceLoader.exists(path):
		vo.stop()
		vo.stream = load(path)
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
