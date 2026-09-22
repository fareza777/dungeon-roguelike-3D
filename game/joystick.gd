extends Control
# Joystick melayang ala Archero: muncul di mana jari menyentuh (zona kiri 62% layar).
# Mouse drag dipakai untuk testing di desktop. `fake` dipakai autotest.

var value := Vector2.ZERO
var active := false
var origin := Vector2.ZERO
var radius := 130.0
var fake := Vector2.ZERO


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
	queue_redraw()


func _drag(pos: Vector2) -> void:
	var d: Vector2 = pos - origin
	if d.length() > radius:
		d = d.normalized() * radius
	value = d / radius
	queue_redraw()


func _end() -> void:
	active = false
	value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	draw_circle(origin, radius, Color(1, 1, 1, 0.07))
	draw_arc(origin, radius, 0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
	draw_circle(origin + value * radius, 52.0, Color(1, 1, 1, 0.3))
