extends Control
# Joystick melayang ala Archero: muncul di mana jari menyentuh (zona kiri 62% layar).
# Mouse drag dipakai untuk testing di desktop. `fake` dipakai autotest.

var value := Vector2.ZERO
var active := false
var origin := Vector2.ZERO
var radius := 130.0
var fake := Vector2.ZERO
var appear_t := 0.0
var fade_tw: Tween = null


func _ready() -> void:
	anchor_right = 0.62
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_PASS


func get_value() -> Vector2:
	if fake != Vector2.ZERO:
		return fake
	return value


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.position)
		else:
			_end()
	elif event is InputEventScreenDrag and active:
		_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(event.position)
		else:
			_end()
	elif event is InputEventMouseMotion and active:
		_drag(event.position)


func _begin(pos: Vector2) -> void:
	active = true
	origin = pos
	value = Vector2.ZERO
	if fade_tw != null and fade_tw.is_valid():
		fade_tw.kill()
	fade_tw = create_tween()
	fade_tw.tween_property(self, "appear_t", 1.0, 0.1)
	queue_redraw()


func _drag(pos: Vector2) -> void:
	var d: Vector2 = pos - origin
	if d.length() > radius:
		d = d.normalized() * radius
	value = d / radius
	queue_redraw()


func _end() -> void:
	value = Vector2.ZERO
	if fade_tw != null and fade_tw.is_valid():
		fade_tw.kill()
	fade_tw = create_tween()
	fade_tw.tween_property(self, "appear_t", 0.0, 0.16)
	fade_tw.tween_callback(func() -> void:
		active = false
		queue_redraw())


func _process(_delta: float) -> void:
	if active or appear_t > 0.0:
		queue_redraw()


func _draw() -> void:
	if not active:
		return
	var a: float = clampf(appear_t, 0.0, 1.0)
	if a <= 0.01:
		return
	var inten: float = clampf(value.length(), 0.0, 1.0)
	var np: Vector2 = origin + value * radius
	draw_circle(origin, radius, Color(1, 1, 1, 0.07 * a))
	draw_arc(origin, radius, 0, TAU, 48, Color(1, 1, 1, 0.25 * a), 3.0)
	draw_arc(origin, 30.0, 0, TAU, 32, Color(1, 1, 1, 0.1 * a), 2.0)
	draw_circle(np, 52.0, Color(1, 1, 1, (0.3 + 0.15 * inten) * a))
	draw_arc(np, 52.0, 0, TAU, 40, Color(0.55, 0.85, 1.0, (0.2 + 0.5 * inten) * a), 2.5)
	if inten > 0.95:
		draw_circle(np, 60.0, Color(0.55, 0.85, 1.0, 0.1 * a))
