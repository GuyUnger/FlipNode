@tool
class_name ActionFill extends ActionDraw


func _init(brush: Brush2D, draw_mode := Flip.DRAW_MODE_FRONT, color: Color = Color.BLACK):
	self.brush = brush
	self.draw_mode = draw_mode
	self.color = color


func start(position):
	if draw_mode == Flip.DRAW_MODE_ERASE:
		var stroke = brush.get_stroke_at_position(position)
		if stroke:
			
			brush.remove_stroke(stroke)
			brush.edited.emit()
			_undo_redo_strokes_complete("Fill Erase")
		return
	
	var stroke_at_position = brush.get_stroke_at_position(position)
	if stroke_at_position:
		stroke_at_position.color = color
		brush.merge_stroke(stroke_at_position)
		_undo_redo_strokes_complete("Fill Color")
		return
	
	for stroke: Stroke in brush.strokes:
		for i in stroke.holes.size():
			if Geometry2D.is_point_in_polygon(position, stroke.holes[i]):
				if stroke.color.to_html() == color.to_html():
					stroke.holes.remove_at(i)
					# If there are strokes inside a hole they have to be removed from the filled space.
					for stroke_inside in brush.strokes:
						if stroke == stroke_inside:
							continue
						stroke.subtract_stroke(stroke_inside)
					stroke.draw()
					brush.edited.emit()
					_undo_redo_strokes_complete("Fill Hole")
					return
				else:
					var polygon = stroke.holes[i].duplicate()
					polygon.reverse()
					var fill_stroke = Stroke.new(polygon, [], color)
					for stroke_inside in brush.strokes:
						fill_stroke.subtract_stroke(stroke_inside)
					brush.add_stroke(fill_stroke)
					
					stroke.draw()
					brush.edited.emit()
					_undo_redo_strokes_complete("Fill Hole")
					return
