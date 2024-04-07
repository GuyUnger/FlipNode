@tool
class_name ActionOval extends ActionDraw

var position: Vector2


func _init(brush: Brush2D, draw_mode := Flip.DRAW_MODE_FRONT, color: Color = Color.BLACK):
	self.brush = brush
	self.draw_mode = draw_mode
	self.color = Color.WHITE if draw_mode == Flip.DRAW_MODE_ERASE else color


func start(position: Vector2):
	position_previous = position


func move_to(position):
	self.position = position


func _draw_brush():
	var polygon = get_oval_tool_shape(
			position_previous,
			brush.get_local_mouse_position(),
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_key_pressed(KEY_ALT)
	)
	
	brush.draw_polygon(polygon, [color])


func _complete():
	var polygon = get_oval_tool_shape(
			position_previous,
			position,
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_key_pressed(KEY_ALT)
	)
	var stroke := Stroke.new(polygon, [], color)
	
	if is_erasing():
		brush.subtract_stroke(stroke)
		_undo_redo_strokes_complete("Oval Brush Erase")
	else:
		brush.merge_stroke(stroke)
		_undo_redo_strokes_complete("Oval Brush Draw")


func get_oval_tool_shape(from: Vector2, to: Vector2, centered: bool, equal: bool):
	var center: Vector2
	var size: Vector2 = (to - from) * 0.5
	if Input.is_key_pressed(KEY_ALT):
		center = from
		if Input.is_key_pressed(KEY_SHIFT):
			size = Vector2.ONE * max(abs(size.x), abs(size.y))
		size *= 2.0
	elif Input.is_key_pressed(KEY_SHIFT):
		var max_size = max(abs(size.x), abs(size.y))
		size = max_size * sign(size)
		center = from + size
	else:
		center = (from + to) * 0.5
	return create_oval_polygon(center, size)


func create_oval_polygon(center: Vector2, size: Vector2) -> PackedVector2Array:
	var polygon := []
	for i in 36.0:
		polygon.push_back(center + Vector2.from_angle(i / 36.0 * TAU) * size)
	return PackedVector2Array(polygon)
