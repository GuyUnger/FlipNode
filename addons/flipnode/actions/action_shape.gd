@tool
class_name ActionShape extends ActionDraw


func _init(brush: Brush2D, draw_mode := Flip.DRAW_MODE_FRONT, color: Color = Color.BLACK):
	self.brush = brush
	self.draw_mode = draw_mode
	self.color = Color.WHITE if is_erasing() else color


func start(position: Vector2):
	position_previous = position
	stroke = Stroke.new([], [], color)
	brush.add_stroke(stroke)


func _draw_brush():
	brush.draw_stroke_outline(stroke, 1.0, color, 0.5)


func move_to(position: Vector2):
	stroke.polygon.push_back(position)
	stroke.draw()


func _complete():
	if is_erasing():
		brush.subtract_stroke(stroke)
		_undo_redo_strokes_complete("Shape Brush Erase")
	else:
		brush.merge_stroke(stroke)
		_undo_redo_strokes_complete("Shape Brush Draw")
