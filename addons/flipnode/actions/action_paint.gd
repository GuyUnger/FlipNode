@tool
class_name ActionPaint extends ActionDraw

var curve_points := []
var curve_widths := []

var catmull_rom := false


func _init(
		brush: Brush2D, draw_mode := Flip.DRAW_MODE_FRONT,
		color: Color = Color.BLACK, catmull_rom := false
):
	self.brush = brush
	self.draw_mode = draw_mode
	self.color = Color.WHITE if is_erasing() else color
	self.catmull_rom = catmull_rom


func start(position: Vector2, width: float = 16.0):
	position_previous = position
	stroke = Stroke.new([], [], color)
	brush.add_stroke(stroke)
	stroke.stroke_polygon.z_index = 4096
	if draw_mode == Flip.DRAW_MODE_INSIDE:
		stroke_inside = brush.get_stroke_at_position(position)
	move_to(position, width)


func move_to(position: Vector2, width: float = 16.0):
	if catmull_rom:
		curve_points.push_back(position)
		curve_widths.push_back(width)
	
	var brush_polygon = Flip.create_polygon_line(position_previous, position, width)
	stroke.union_polygon(brush_polygon)
	stroke.draw()
	
	position_previous = position


func _complete():
	if catmull_rom and curve_points.size() >= 4:
		# Smooth with catmull-rom.
		brush.remove_stroke(stroke)
		stroke = Stroke.new([], [], stroke.color)
		
		var curve_catmull_rom = Flip.catmull_rom(curve_points)
		for i in range(1, curve_catmull_rom.size()):
			#TODO: its not yet using the width saved in each step
			var brush_polygon = Flip.create_polygon_line(
					curve_catmull_rom[i - 1], curve_catmull_rom[i], curve_widths[0]
			)
			stroke.union_polygon(brush_polygon)
	
	stroke.optimize()
	
	if is_erasing():
		brush.subtract_stroke(stroke)
		_undo_redo_strokes_complete("Paint Erase")
	else:
		if stroke_inside:
			brush.remove_stroke(stroke)
			var masked_strokes = stroke.mask_stroke(stroke_inside)
			for stroke in masked_strokes:
				stroke.polygon = Geometry2D.offset_polygon(stroke.polygon, 0.01)[0]
				brush.merge_stroke(stroke)
		elif draw_mode == Flip.DRAW_MODE_INSIDE or draw_mode == Flip.DRAW_MODE_BEHIND:
			brush.move_stroke_to_back(stroke)
			brush.draw()
			brush.edited.emit()
		else:
			brush.merge_stroke(stroke)
		_undo_redo_strokes_complete("Paint")
	brush.edited.emit()
