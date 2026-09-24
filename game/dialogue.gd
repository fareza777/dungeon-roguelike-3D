extends Control
class_name DialogueUI
# Kotak dialog ala RPG: potret + nama + teks ketik-per-huruf, ketuk=lanjut,
# opsi pilihan (max 3). Dibuat programatik; dipakai oleh main.gd & layar lain.
# Pause game selama dialog (konsisten dengan draft).

signal finished
signal choice_made(index)

const PORTRAITS := "res://assets/ui/"
const CHARACTERS := {
	"kael": {"name": "KAEL", "portrait": "portrait_kael.png", "color": Color(1.0, 0.85, 0.45)},
	"oracle": {"name": "THE ORACLE", "portrait": "portrait_oracle.png", "color": Color(0.55, 1.0, 0.75)},
	"raja": {"name": "BONE KING", "portrait": "portrait_raja.png", "color": Color(1.0, 0.45, 0.4)},
	"mahzan": {"name": "MAHZAN, SPIRIT MERCHANT", "portrait": "portrait_vendor.png", "color": Color(0.75, 0.85, 1.0)},
	"knight": {"name": "SIR VANE, THE UNMADE", "portrait": "portrait_vane.png", "color": Color(0.55, 0.8, 1.0)},
	"narator": {"name": "", "portrait": "", "color": Color(1, 1, 1, 0.6)},
}

var _lines: Array = []
var _idx := 0
var _typing := false
var _skip_typing := false
var _choices: Array = []
var _panel: PanelContainer
var _portrait: TextureRect
var _name_l: Label
var _last_who := ""
var _text_l: RichTextLabel
var _hint: Label
var _choice_box: VBoxContainer
var _choice_scroll: ScrollContainer
var _type_tw: Tween = null
var active := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.04
	_panel.anchor_right = 0.96
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -360
	_panel.offset_bottom = -24
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.05, 0.05, 0.1, 0.97)
	psb.border_color = Color(0.95, 0.78, 0.35)
	psb.set_border_width_all(3)
	psb.set_corner_radius_all(18)
	psb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", psb)
	# panel tidak menelan ketukan — biar root yang menerima tap "ketuk untuk lanjut"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hb)

	var pf := PanelContainer.new()
	pf.custom_minimum_size = Vector2(132, 132)
	var pf_sb := StyleBoxFlat.new()
	pf_sb.bg_color = Color(0.1, 0.09, 0.16)
	pf_sb.border_color = Color(0.95, 0.78, 0.35, 0.7)
	pf_sb.set_border_width_all(2)
	pf_sb.set_corner_radius_all(12)
	pf.add_theme_stylebox_override("panel", pf_sb)
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(pf)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.add_child(_portrait)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vb)
	_name_l = Label.new()
	_name_l.add_theme_font_size_override("font_size", 22)
	_name_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_name_l.add_theme_constant_override("outline_size", 4)
	_name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_name_l)
	_text_l = RichTextLabel.new()
	_text_l.bbcode_enabled = false
	_text_l.fit_content = true
	_text_l.scroll_active = false
	_text_l.custom_minimum_size = Vector2(0, 130)
	_text_l.add_theme_font_size_override("normal_font_size", 21)
	_text_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_text_l)
	_hint = Label.new()
	_hint.text = "tap to continue ▶"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.modulate = Color(1, 1, 1, 0.4)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_hint)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 8)
	_choice_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_box.visible = false
	var chscroll := ScrollContainer.new()
	_choice_scroll = chscroll
	chscroll.custom_minimum_size = Vector2(0, 0)
	chscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chscroll.add_child(_choice_box)
	vb.add_child(chscroll)


func play(lines: Array) -> void:
	_lines = lines
	_idx = 0
	_choices = []
	active = true
	visible = true
	_panel.pivot_offset = Vector2(_panel.size.x * 0.5, _panel.size.y)
	_panel.position.y += 30
	_panel.modulate.a = 0.0
	var ptw: Tween = _panel.create_tween()
	ptw.set_parallel(true)
	ptw.tween_property(_panel, "position:y", _panel.position.y - 30, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ptw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	_show(0)


func play_choices(lines: Array, choices: Array) -> void:
	_choices = choices
	play(lines)


func _show(i: int) -> void:
	_idx = i
	_choice_box.visible = false
	for c in _choice_box.get_children():
		c.queue_free()
	var l: Dictionary = _lines[i]
	var who: String = l.get("who", "narator")
	var ch: Dictionary = CHARACTERS.get(who, CHARACTERS["narator"])
	_name_l.text = String(ch["name"])
	_name_l.modulate = ch["color"]
	if _last_who != who:
		_last_who = who
		_name_l.pivot_offset = Vector2(0, _name_l.size.y)
		var ntw: Tween = _name_l.create_tween()
		_name_l.modulate.a = 0.0
		_name_l.scale = Vector2(1.0, 0.6)
		ntw.set_parallel(true)
		ntw.tween_property(_name_l, "modulate:a", 1.0, 0.15)
		ntw.tween_property(_name_l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var pp := _portrait.get_parent()
		pp.pivot_offset = pp.size * 0.5
		var ptw2: Tween = pp.create_tween()
		pp.scale = Vector2(0.85, 0.85)
		ptw2.tween_property(pp, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var p: String = ch["portrait"]
	if p != "" and ResourceLoader.exists(PORTRAITS + p):
		_portrait.texture = load(PORTRAITS + p)
		_portrait.get_parent().visible = true
	else:
		_portrait.get_parent().visible = false
	_text_l.text = ""
	_hint.visible = false
	Sfx.play("page")
	_typing = true
	_skip_typing = false
	var full: String = l.get("text", "")
	if _type_tw != null and _type_tw.is_valid():
		_type_tw.kill()
	_type_tw = create_tween()
	var chars := full.length()
	var dur: float = clampf(chars / 45.0, 0.4, 4.0)
	_type_tw.tween_method(func(n: int) -> void: _text_l.text = full.substr(0, n), 0, chars, dur)
	_type_tw.tween_callback(func() -> void:
		_typing = false
		_after_typed()
	)


func _after_typed() -> void:
	if _idx == _lines.size() - 1 and not _choices.is_empty():
		_show_choices()
	else:
		_hint.visible = true
		var htw: Tween = create_tween()
		htw.set_loops(40)
		htw.tween_property(_hint, "modulate:a", 0.85, 0.5).set_trans(Tween.TRANS_SINE)
		htw.tween_property(_hint, "modulate:a", 0.4, 0.5).set_trans(Tween.TRANS_SINE)


func _show_choices() -> void:
	_choice_box.visible = true
	if _choice_scroll != null:
		_choice_scroll.custom_minimum_size = Vector2(0, minf(_choices.size() * 64.0 + 10.0, 420.0))
	_choice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(_choices.size()):
		var ch: Dictionary = _choices[i]
		var b := Button.new()
		b.text = String(ch.get("text", "..."))
		b.add_theme_font_size_override("font_size", 19)
		b.custom_minimum_size = Vector2(0, 56)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.12, 0.2)
		sb.border_color = Color(0.95, 0.78, 0.35, 0.8)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate() as StyleBoxFlat
		sbh.bg_color = Color(0.2, 0.18, 0.28)
		b.add_theme_stylebox_override("hover", sbh)
		var sbp := sb.duplicate() as StyleBoxFlat
		sbp.bg_color = Color(0.32, 0.26, 0.14)
		b.add_theme_stylebox_override("pressed", sbp)
		var ix := i
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			b.pivot_offset = b.size * 0.5
			b.scale = Vector2(0.94, 0.94)
			_choice_box.visible = false
			choice_made.emit(ix)
			_close()
		)
		_choice_box.add_child(b)


func _close() -> void:
	active = false
	visible = false
	finished.emit()


# pilih opsi ke-i secara programatik (autotest / pintasan)
func choose(i: int) -> void:
	Sfx.play("click")
	_choice_box.visible = false
	choice_made.emit(i)
	_close()


func _advance() -> void:
	if _typing:
		if _type_tw != null and _type_tw.is_valid():
			_type_tw.custom_step(999.0)
		return
	if _idx < _lines.size() - 1:
		Sfx.play("click")
		_show(_idx + 1)
	elif _choices.is_empty():
		_close()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()
