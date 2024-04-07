class_name ActionWarp extends Action

var selections: Array


func _init(brush: Brush2D, selections: Array):
	self.brush = brush
	self.selections = selections


func start(position: Vector2):
	position_previous = position


func move_to(position: Vector2):
	var move_delta = position - position_previous
	
	for selection: EdgeSelection in selections:
		for i in selection.get_vertex_count():
			var index = selection.vertex_indices[i]
			var weight = selection.vertex_weights[i]
			if selection.hole_id == -1:
				selection.stroke.polygon[index] += move_delta * weight
			else:
				selection.stroke.holes[selection.hole_id][index] += move_delta * weight
			selection.stroke.draw()
	position_previous = position


func _complete():
	for selection: EdgeSelection in selections:
		brush.merge_stroke(selection.stroke)
	#TODO: decide what to do with this
	for selection: EdgeSelection in selections:
		selection.stroke.optimize()
	for selection: EdgeSelection in selections:
		if Geometry2D.is_polygon_clockwise(selection.stroke.polygon):
			selection.stroke.polygon.reverse()
		var invert_fix_results = Geometry2D.offset_polygon(selection.stroke.polygon, 0.001, Geometry2D.JOIN_ROUND)
		
		var holes = selection.stroke.holes
		
		var i := 0
		var l := invert_fix_results.size()
		while i < l:
			var polygon = invert_fix_results[i]
			if Geometry2D.is_polygon_clockwise(polygon):
				holes.push_back(invert_fix_results[i])
				invert_fix_results.remove_at(i)
				l -= 1
			else:
				i += 1
		brush.remove_stroke(selection.stroke)
		for polygon in invert_fix_results:
			var stroke = Stroke.new(polygon, [], selection.stroke.color)
			for hole in holes:
				if stroke.is_polygon_overlapping(hole):
					stroke.holes.push_back(hole)
			brush.add_stroke(stroke)
	
	_undo_redo_strokes_complete("Warp Stroke")
	brush.edited.emit()

