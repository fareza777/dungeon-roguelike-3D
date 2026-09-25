extends Control
# Splash: ikon game + bar loading kecil -> rute:
# belum onboarded -> onboarding, sudah -> menu.

func _ready() -> void:
	var fast := false
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			fast = true
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	cc.add_child(vb)
	# ikon app
	if ResourceLoader.exists("res://assets/ui/icon.png"):
		var ic := TextureRect.new()
		ic.texture = load("res://assets/ui/icon.png")
		ic.custom_minimum_size = Vector2(190, 190)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		ic.pivot_offset = Vector2(95, 95)
		vb.add_child(ic)
		ic.scale = Vector2(0.5, 0.5)
		var itw := ic.create_tween()
		itw.tween_property(ic, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		itw.tween_property(ic, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)
		var igt := ic.create_tween()
		igt.set_loops()
		igt.tween_property(ic, "modulate", Color(1.0, 0.92, 0.62), 0.9).set_trans(Tween.TRANS_SINE)
		igt.tween_property(ic, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
	var t1 := Label.new()
	t1.text = "DUNGEON"
	t1.add_theme_font_size_override("font_size", 84)
	t1.modulate = Color(1.0, 0.85, 0.4)
	t1.add_theme_color_override("font_outline_color", Color(0.22, 0.1, 0.0, 1.0))
	t1.add_theme_constant_override("outline_size", 8)
	t1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	t1.add_theme_constant_override("shadow_offset_x", 4)
	t1.add_theme_constant_override("shadow_offset_y", 4)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)
	var t2 := Label.new()
	t2.text = "SLICE"
	t2.add_theme_font_size_override("font_size", 48)
	t2.modulate = Color(1.0, 0.95, 0.8)
	t2.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05, 0.9))
	t2.add_theme_constant_override("outline_size", 5)
	t2.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	t2.add_theme_constant_override("shadow_offset_x", 3)
	t2.add_theme_constant_override("shadow_offset_y", 3)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	var t3 := Label.new()
	t3.text = "a bone-breaking roguelike"
	t3.add_theme_font_size_override("font_size", 16)
	t3.modulate = Color(1, 1, 1, 0.4)
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t3)
	# bar loading tipis
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(320, 8)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = 0.0
	var bf := StyleBoxFlat.new()
	bf.bg_color = Color(1.0, 0.8, 0.3)
	bf.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", bf)
	var bpt := bar.create_tween()
	bpt.set_loops()
	bpt.tween_property(bar, "modulate", Color(1.0, 0.9, 0.6), 0.55).set_trans(Tween.TRANS_SINE)
	bpt.tween_property(bar, "modulate", Color.WHITE, 0.55).set_trans(Tween.TRANS_SINE)
	var bb := StyleBoxFlat.new()
	bb.bg_color = Color(0.12, 0.1, 0.16)
	bb.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bb)
	vb.add_child(bar)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.1 if fast else 0.5)
	tw.set_parallel(true)
	tw.tween_property(bar, "value", 1.0, 0.1 if fast else 1.1)
	tw.set_parallel(false)
	tw.tween_interval(0.05 if fast else 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.1 if fast else 0.4)
	tw.tween_callback(func() -> void:
		Stats.load_game()
		get_tree().change_scene_to_file("res://app/onboarding.tscn" if not Stats.onboarded else "res://app/menu.tscn")
	)
