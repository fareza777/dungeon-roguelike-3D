class_name Transit
# Helper transisi scene: overlay hitam di CanvasLayer paling atas.
# Tween di-bind ke rect (PROCESS_MODE_ALWAYS) jadi jalan juga saat tree paused.

static func _mk(owner: Node, alpha: float) -> ColorRect:
	var cv := CanvasLayer.new()
	cv.layer = 200
	owner.add_child(cv)
	var r := ColorRect.new()
	r.color = Color(0, 0, 0)
	r.modulate.a = alpha
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.process_mode = Node.PROCESS_MODE_ALWAYS
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	cv.add_child(r)
	var mark := Label.new()
	mark.text = "☠"
	mark.add_theme_font_size_override("font_size", 44)
	mark.modulate = Color(1.0, 0.85, 0.4, 0.0)
	mark.set_anchors_preset(Control.PRESET_CENTER)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.process_mode = Node.PROCESS_MODE_ALWAYS
	cv.add_child(mark)
	var mtw := mark.create_tween()
	mtw.tween_property(mark, "modulate:a", 0.45, 0.35)
	mtw.tween_interval(0.4)
	mtw.tween_property(mark, "modulate:a", 0.0, 0.3)
	return r


static func fade_in(owner: Node, dur := 0.35) -> void:
	var r := _mk(owner, 1.0)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, dur)
	await tw.finished
	r.get_parent().queue_free()


static func fade_out(owner: Node, dur := 0.28) -> void:
	var r := _mk(owner, 0.0)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 1.0, dur)
	await tw.finished
