@tool
class_name ActionRect extends ActionDraw

#TODO: add rounding
var position: Vector2

func _init(brush: Brush2D, draw_mode := Flip.DRAW_MODE_FRONT, color: Color = Color.BLACK):
	self.brush = brush
	self.draw_mode = draw_mode
	self.color = Color.WHITE if is_erasing() else color


func start(position: Vector2):
	position_previous = position


func move_to(position: Vector2):
	self.position = position


func _draw_brush():
	var polygon = get_rect_tool_shape(
			position_previous,
			brush.get_local_mouse_position(),
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_key_pressed(KEY_ALT),
	)
	
	brush.draw_polygon(polygon, [color])


func _complete():
	var polygon = get_rect_tool_shape(
			position_previous,
			position,
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_key_pressed(KEY_ALT)
	)
	var stroke := Stroke.new(polygon, [], color)
	
	match draw_mode:
		Flip.DRAW_MODE_ERASE:
			brush.subtract_stroke(stroke)
			_undo_redo_strokes_complete("Rect Brush Erase")
		Flip.DRAW_MODE_FRONT:
			brush.merge_stroke(stroke)
			_undo_redo_strokes_complete("Rect Brush Draw")


func get_rect_tool_shape(from: Vector2, to: Vector2, centered: bool, equal: bool):
	var center: Vector2
	var extent: Vector2 = (to - from) * 0.5
	if Input.is_key_pressed(KEY_ALT):
		center = from
		if Input.is_key_pressed(KEY_SHIFT):
			extent = Vector2.ONE * max(abs(extent.x), abs(extent.y))
		extent *= 2.0
	elif Input.is_key_pressed(KEY_SHIFT):
		var max_size = max(abs(extent.x), abs(extent.y))
		extent = max_size * sign(extent)
		center = from + extent
	else:
		center = (from + to) * 0.5
	return create_rect_polygon(center, extent)


func create_rect_polygon(center: Vector2, extent: Vector2) -> PackedVector2Array:
	var tl = center + extent * Vector2( -1, -1)
	var tr = center + extent * Vector2(1, -1)
	var br = center + extent * Vector2(1, 1)
	var bl = center + extent * Vector2( -1, 1)
	var polygon := [tl, tr, br, bl]
	return PackedVector2Array(polygon)
