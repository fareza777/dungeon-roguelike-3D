P = '/home/ubuntu/repos/dungeon-roguelike-3D/game/app/menu.gd'
m = open(P).read()

helper = '''
func _settings_section(vb: VBoxContainer, txt: String) -> void:
	var cap := Label.new()
	cap.text = txt
	cap.add_theme_font_size_override("font_size", 14)
	cap.modulate = Color(1.0, 0.82, 0.45, 0.75)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(cap)
	var sep := HSeparator.new()
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(1.0, 0.82, 0.45, 0.22)
	sep.custom_minimum_size = Vector2(0, 1)
	sep.add_theme_stylebox_override("separator", ssb)
	vb.add_child(sep)


func _build_settings() -> void:'''
OLD = 'func _build_settings() -> void:'
assert m.count(OLD) == 1, m.count(OLD)
m = m.replace(OLD, helper, 1)

ins = [
 ('\t_vol_row(vb, "Music", Stats.mus_vol(), func(v: float) -> void:',
  '\t_settings_section(vb, "— AUDIO —")\n\t_vol_row(vb, "Music", Stats.mus_vol(), func(v: float) -> void:'),
 ('\tvar ql := Label.new()\n\tql.text = "Graphics quality"',
  '\t_settings_section(vb, "— DISPLAY —")\n\tvar ql := Label.new()\n\tql.text = "Graphics quality"'),
 ('\tvar hl := Label.new()\n\thl.text = "Haptics (vibration)"',
  '\t_settings_section(vb, "— CONTROLS —")\n\tvar hl := Label.new()\n\thl.text = "Haptics (vibration)"'),
 ('\tvar wr := _make_btn("⟲ RESET ALL PROGRESS", false)',
  '\t_settings_section(vb, "— DANGER ZONE —")\n\tvar wr := _make_btn("⟲ RESET ALL PROGRESS", false)'),
]
for o, n in ins:
    assert m.count(o) == 1, o[:60] + " -> " + str(m.count(o))
    m = m.replace(o, n, 1)

open(P, 'w').write(m)
print("ok")
