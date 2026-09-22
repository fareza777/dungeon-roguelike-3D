extends Control
# Splash: logo fade in -> tahan -> fade out -> menu.

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
	cc.add_child(vb)
	var t1 := Label.new()
	t1.text = "DUNGEON"
	t1.add_theme_font_size_override("font_size", 84)
	t1.modulate = Color(1.0, 0.85, 0.4)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)
	var t2 := Label.new()
	t2.text = "SLICE"
	t2.add_theme_font_size_override("font_size", 48)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	var t3 := Label.new()
	t3.text = "roguelike tulang-belulang"
	t3.add_theme_font_size_override("font_size", 16)
	t3.modulate = Color(1, 1, 1, 0.4)
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t3)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.1 if fast else 0.5)
	tw.tween_interval(0.05 if fast else 1.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.1 if fast else 0.4)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://app/menu.tscn"))
