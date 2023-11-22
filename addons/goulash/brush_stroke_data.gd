@tool
class_name BrushStrokeData
extends Resource

@export var color: Color
@export var polygon: PackedVector2Array
@export var polygon_curve: Curve2D
@export var holes:  Array[PackedVector2Array]
@export var hole_curves: Array[Curve2D]

func _init(polygon := PackedVector2Array(), holes: Array[PackedVector2Array] = [], color: Color = Color.WHITE):
	self.polygon = polygon
	self.holes = holes
	self.color = color


func union_stroke(stroke: BrushStrokeData):
	var polygon_a = polygon.duplicate()
	var polygon_b = stroke.polygon.duplicate()
	var holes_a = holes
	var holes_b = stroke.holes
	
	var merged_polygon: PackedVector2Array
	var merged_holes: Array[PackedVector2Array]
	
	var merged_polygon_results = Geometry2D.merge_polygons(polygon_a, polygon_b)
	for p in merged_polygon_results:
		if Geometry2D.is_polygon_clockwise(p):
			merged_holes.push_back(p)
		else:
			merged_polygon = p
	
	for hole_a in holes_a:
		if Geometry2D.intersect_polygons(hole_a, polygon_b).size() == 0:
			merged_holes.push_back(hole_a)
		else:
			var polygons_clipped = Geometry2D.clip_polygons(hole_a, polygon_b)
			for p in polygons_clipped:
				merged_holes.push_front(p)
	
	for hole_b in holes_b:
		if Geometry2D.intersect_polygons(hole_b, polygon_a).size() == 0:
			merged_holes.push_back(hole_b)
		else:
			var polygons_clipped = Geometry2D.clip_polygons(hole_b, polygon_a)
			for p in polygons_clipped:
				merged_holes.push_front(p)
	
	for hole_a in holes_a:
		for hole_b in holes_b:
			var interected_holes = Geometry2D.intersect_polygons(hole_a, hole_b)
			for intersected_hole in interected_holes:
				merged_holes.push_back(intersected_hole)
	
	polygon = merged_polygon
	holes = merged_holes


func union_polygon(with_polygon: PackedVector2Array):
	#💡 merge stroke
	var merged_polygons = Geometry2D.merge_polygons(polygon, with_polygon)
	var new_polygon
	for merged_polygon in merged_polygons:
		if Geometry2D.is_polygon_clockwise(merged_polygon):
			holes.push_back(merged_polygon)
		else:
			new_polygon = merged_polygon
	polygon = new_polygon
	
	##💡 subtract holes
	var i := 0
	while i < holes.size():
		var hole = holes[i]
		if Geometry2D.intersect_polygons(hole, with_polygon).size() > 0:
			holes.remove_at(i)
			var polygons_clipped = Geometry2D.clip_polygons(hole, with_polygon)
			for p in polygons_clipped:
				holes.push_front(p)
				i += 1
		else:
			i += 1


func subtract_stroke(stroke: BrushStrokeData) -> Array:
	if not is_stroke_overlapping(stroke):
		return [self]
	
	## Goes over all holes and "collects" overlapping ones into one stroke, adds the hole back at the end
	var subtract_polygon = stroke.polygon
	
	var subtracted_holes: Array[PackedVector2Array]
	var strokes := []
	
	for hole in holes:
		if Geometry2D.intersect_polygons(subtract_polygon, hole).size() > 0:
			var result_polygons = Geometry2D.merge_polygons(subtract_polygon, hole)
			for result_polygon in result_polygons:
				if Geometry2D.is_polygon_clockwise(result_polygon):
					## island inside hole, make a new stroke
					result_polygon.reverse()
					strokes.push_back(create_stroke(result_polygon))
				else:
					subtract_polygon = result_polygon
		else:
			subtracted_holes.push_back(hole)
	
	if Geometry2D.clip_polygons(subtract_polygon, polygon).size() == 0:
		## hole added
		subtracted_holes.push_back(subtract_polygon)
		holes = subtracted_holes
		strokes.push_back(self)
		return strokes
	
	var clipped_polygons = Geometry2D.clip_polygons(polygon, subtract_polygon)
	if clipped_polygons.size() == 0:
		## completely erased
		pass
	elif clipped_polygons.size() == 1:
		## polygon altered
		polygon = clipped_polygons[0]
		holes = subtracted_holes
		strokes.push_back(self)
	else:
		## split into multiple
		for p in clipped_polygons:
			var seperated_stroke = create_stroke(p)
			## assign holes to strokes they belong to
			for hole in subtracted_holes:
				if Geometry2D.intersect_polygons(p, hole).size() > 0:
					seperated_stroke.holes.push_back(hole)
			strokes.push_back(seperated_stroke)
	
	return strokes

#func subtract_polygon(with_polygon: PackedVector2Array):
	#var i := 0
	#
	###💡 Merge with holes
	#var merged_polygon = polygon
	#var hole_merged := false
	#while i < holes.size():
		#var hole = holes[i]
		#if Geometry2D.intersect_polygons(hole, merged_polygon).size() > 0:
			#holes.remove_at(i)
			#var merged = Geometry2D.merge_polygons(hole, merged_polygon)
			#for polygon in merged:
				#if Geometry2D.is_polygon_clockwise(polygon):
					#parent.add_stroke(create_stroke(polygon))
				#else:
					#hole_merged = true
					#merged_polygon = polygon
		#else:
			#i += 1
	#if hole_merged:
		#holes.push_back(merged_polygon)
	#
	###💡 Subtract brush from strokes
	#if Geometry2D.intersect_polygons(polygon, merged_polygon).size() > 0:
		#var clipped_polygons = Geometry2D.clip_polygons(polygon, merged_polygon)
		#for p in clipped_polygons:
			#parent.add_stroke(create_stroke(p))
		#parent.remove_stroke(self)


func translate(offset: Vector2):
	polygon = _translate_polygon(polygon, offset)
	for hole in holes:
		hole = _translate_polygon(hole, offset)


func _translate_polygon(polygon: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	for i in polygon.size():
		polygon[i] = polygon[i] + offset
	return polygon


func create_stroke(polygon: PackedVector2Array, holes: Array[PackedVector2Array] = []) -> BrushStrokeData:
	return BrushStrokeData.new(polygon, holes, color)


func is_stroke_overlapping(stroke: BrushStrokeData) -> bool:
	if Geometry2D.intersect_polygons(polygon, stroke.polygon).size() > 0:
		if _is_inside_hole(stroke) or stroke._is_inside_hole(self):
			return false
		else:
			return true
	return false


#func is_polygon_overlapping() -> bool:
	#if Geometry2D.intersect_polygons(polygon, polygon).size() > 0 and not _is_polygon_inside_hole(polygon):
		#return true
	#return false


func is_stroke_inside(stroke: BrushStrokeData) -> bool:
	if Geometry2D.clip_polygons(polygon, stroke.polygon).size() == 0:
		return not _is_inside_hole(stroke)
	else:
		return false


func _is_inside_hole(stroke: BrushStrokeData) -> bool:
	return _is_polygon_inside_hole(stroke.polygon)


func _is_polygon_inside_hole(checking_polygon: PackedVector2Array) -> bool:
	for hole: PackedVector2Array in holes:
		if Geometry2D.clip_polygons(checking_polygon, hole).size() == 0:
			return true
	return false


func is_point_inside(point: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(point, polygon):
		return not _is_point_inside_hole(point)
	return false


func _is_point_inside_hole(point: Vector2) -> bool:
	for hole: PackedVector2Array in holes:
		if Geometry2D.is_point_in_polygon(point, hole):
			return true
	return false


func optimize(tolerance := 1.0) -> void:
	polygon_curve = polygon_to_curve(_douglas_peucker(polygon, tolerance), tolerance)
	polygon = polygon_curve.get_baked_points()
	hole_curves = []
	for i in holes.size():
		var hole_curve = polygon_to_curve(_douglas_peucker(holes[i]), tolerance)
		hole_curves.push_back(hole_curve)
		holes[i] = hole_curve.get_baked_points()


func create_curves():
	polygon_curve = polygon_to_curve(polygon, 1.0)
	hole_curves = []
	for i in holes.size():
		var hole_curve = polygon_to_curve(_douglas_peucker(holes[i]), 1.0)
		hole_curves.push_back(hole_curve)


func polygon_to_curve(polygon: PackedVector2Array, bake_interval: float) -> Curve2D:
	var curve := Curve2D.new()
	curve.bake_interval = bake_interval * 20.0
	for p in polygon:
		curve.add_point(p)
	return curve


func _douglas_peucker(points: PackedVector2Array, tolerance := 1.0) -> PackedVector2Array:
	if points.size() < 3:
		return points
	
	## Find the point with the maximum distance from the line between the first and last point
	var dmax := 0.0
	var index := 0
	for i in range(1, points.size() - 1):
		var d := 0.0
		var point = points[i]
		var point1 = points[0]
		var point2 = points[points.size() - 1]
		## Calculate the perpendicular distance between point and line segment point1-point2 
		var dx = point2.x - point1.x
		var dy = point2.y - point1.y
		if dx == 0 and dy == 0:
			## Point1 and point2 are the same point
			d = point1.distance_to(point)
		else:
			var t = ((point.x - point1.x) * dx + (point.y - point1.y) * dy) / (dx ** 2 + dy ** 2)
			if t < 0.0:
				## Point is beyond the 'left' end of the segment
				d = point.distance_to(point1)
			elif t > 1:
				### Point is beyond the 'right' end of the segment
				d = point.distance_to(point2)
			else:
				## Point is within the segment
				var point_t = Vector2(
						point1.x + t * dx,
						point1.y + t * dy
					)
				d = point.distance_to(point_t)
		
		if d > dmax:
			index = i
			dmax = d
	
	## If the maximum distance is greater than the tolerance, recursively simplify
	if dmax > tolerance:
		var results1 = _douglas_peucker(points.slice(0, index+1), tolerance)
		var results2 = _douglas_peucker(points.slice(index), tolerance)
		return results1 + results2.slice(1)
	else:
		return PackedVector2Array([points[0], points[points.size() - 1]])
