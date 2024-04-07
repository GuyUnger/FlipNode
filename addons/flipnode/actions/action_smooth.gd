class_name ActionSmooth extends Action

var selections: Array


func _init(brush: Brush2D, selections: Array):
	self.brush = brush
	self.selections = selections
	


func start(position: Vector2, strength):
	undo_redo_strokes_start()
	for i in 8:
		smooth(strength)
	
	_undo_redo_strokes_complete("Smooth")



func smooth(strength):
	for selection: EdgeSelection in selections:
		var stroke = selection.stroke
		for i in selection.vertex_indices:
			if selection.hole_id == -1:
				stroke.polygon[i] = _smooth_polygon_point(stroke.polygon, i, strength, 1)
			else:
				stroke.holes[selection.hole_id][i] = _smooth_polygon_point(stroke.holes[selection.hole_id], i, strength, 1)
		stroke.draw()


func _smooth_polygon_point(polygon: PackedVector2Array, i: int, delta: float, points_offset := 1):
	var current = polygon[i]
	var before = polygon[(i - points_offset) % polygon.size()]
	var after = polygon[(i + points_offset) % polygon.size()]
	
	var angle_before = current.angle_to_point(before)
	var angle_after = current.angle_to_point(after)
	var angle = angle_difference(angle_before, angle_after)
	
	return lerp(current, lerp(before, after, 0.5), delta)
	if angle < PI * 0.7:
		return current
	else:
		return lerp(current, lerp(before, after, 0.5), delta)
