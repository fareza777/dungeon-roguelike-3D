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
	"oracle": {"name": "SANG PERAMAL", "portrait": "portrait_oracle.png", "color": Color(0.55, 1.0, 0.75)},
	"raja": {"name": "RAJA TULANG", "portrait": "portrait_raja.png", "color": Color(1.0, 0.45, 0.4)},
	"mahzan": {"name": "MAHZAN, PEDAGANG ARWAH", "portrait": "portrait_vendor.png", "color": Color(0.75, 0.85, 1.0)},
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
var _text_l: RichTextLabel
var _hint: Label
var _choice_box: VBoxContainer
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
	add_child(_panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_panel.add_child(hb)

	var pf := PanelContainer.new()
	pf.custom_minimum_size = Vector2(132, 132)
	var pf_sb := StyleBoxFlat.new()
	pf_sb.bg_color = Color(0.1, 0.09, 0.16)
	pf_sb.set_corner_radius_all(12)
	pf.add_theme_stylebox_override("panel", pf_sb)
	hb.add_child(pf)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pf.add_child(_portrait)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	_name_l = Label.new()
	_name_l.add_theme_font_size_override("font_size", 20)
	vb.add_child(_name_l)
	_text_l = RichTextLabel.new()
	_text_l.bbcode_enabled = false
	_text_l.fit_content = true
	_text_l.scroll_active = false
	_text_l.custom_minimum_size = Vector2(0, 130)
	_text_l.add_theme_font_size_override("normal_font_size", 21)
	_text_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_text_l)
	_hint = Label.new()
	_hint.text = "ketuk untuk lanjut ▶"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.modulate = Color(1, 1, 1, 0.4)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_hint)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 8)
	_choice_box.visible = false
	vb.add_child(_choice_box)


func play(lines: Array) -> void:
	_lines = lines
	_idx = 0
	_choices = []
	active = true
	visible = true
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


func _show_choices() -> void:
	_choice_box.visible = true
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
		var ix := i
		b.pressed.connect(func() -> void:
			Sfx.play("click")
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
