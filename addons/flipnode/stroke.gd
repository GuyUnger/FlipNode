@tool
class_name Stroke
extends Resource

@export var color: Color
@export var unified_polygon: PackedVector2Array
@export var polygon: PackedVector2Array
@export var holes: Array[PackedVector2Array]

var stroke_polygon: StrokePolygon2D

# Curves.
var polygon_curve: Curve2D:
	get:
		if _curves_dirty:
			create_curves()
		return polygon_curve
var hole_curves: Array[Curve2D]:
	get:
		if _curves_dirty:
			create_curves()
		return hole_curves
var _curves_dirty := true

var _erasing := false


func _init(polygon := PackedVector2Array(), holes: Array[PackedVector2Array] = [], color: Color = Color.WHITE):
	self.polygon = polygon
	self.holes = holes
	self.color = color


func draw():
	if Engine.is_editor_hint():
		generate_unified_polygon()
	if stroke_polygon:
		stroke_polygon.polygon = unified_polygon
		stroke_polygon.color = color


func union_stroke(stroke: Stroke):
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
				p.reverse()
				merged_holes.push_front(p)
	
	for hole_b in holes_b:
		if Geometry2D.intersect_polygons(hole_b, polygon_a).size() == 0:
			if not Geometry2D.is_polygon_clockwise(hole_b):
				hole_b.reverse()
			merged_holes.push_back(hole_b)
		else:
			var polygons_clipped = Geometry2D.clip_polygons(hole_b, polygon_a)
			for p in polygons_clipped:
				p.reverse()
				merged_holes.push_front(p)
	
	for hole_a in holes_a:
		for hole_b in holes_b:
			var interected_holes = Geometry2D.intersect_polygons(hole_a, hole_b)
			for intersected_hole in interected_holes:
				intersected_hole.reverse()
				merged_holes.push_back(intersected_hole)
	
	polygon = merged_polygon
	holes = merged_holes
	_curves_dirty = true


func union_polygon(with_polygon: PackedVector2Array):
	# merge stroke
	var merged_polygons = Geometry2D.merge_polygons(polygon, with_polygon)
	var new_polygon
	for merged_polygon in merged_polygons:
		if Geometry2D.is_polygon_clockwise(merged_polygon):
			holes.push_back(merged_polygon)
		else:
			new_polygon = merged_polygon
	polygon = new_polygon
	
	# subtract holes
	var i := 0
	while i < holes.size():
		var hole = holes[i]
		if Geometry2D.intersect_polygons(hole, with_polygon).size() > 0:
			holes.remove_at(i)
			var polygons_clipped = Geometry2D.clip_polygons(hole, with_polygon)
			for p in polygons_clipped:
				if not Geometry2D.is_polygon_clockwise(p):
					p.reverse()
				holes.push_front(p)
				i += 1
		else:
			i += 1
	_curves_dirty = true


func subtract_stroke(stroke: Stroke) -> Array:
	if not is_stroke_overlapping(stroke):
		return [self]
	
	# Goes over all holes and "collects" overlapping ones into one stroke, adds the hole back at the end.
	var subtract_polygon = stroke.polygon.duplicate()
	
	var subtracted_holes: Array[PackedVector2Array]
	var subtracted_strokes := []
	
	var holes_in_holes := []
	
	for hole in holes:
		if Geometry2D.intersect_polygons(subtract_polygon, hole).size() > 0:
			var result_polygons = Geometry2D.merge_polygons(subtract_polygon, hole)
			for result_polygon in result_polygons:
				if Geometry2D.is_polygon_clockwise(result_polygon):
					## island inside hole, make a new stroke, not sure if this is needed?
					result_polygon.reverse()
					subtracted_strokes.push_back(create_stroke(result_polygon))
				else:
					subtract_polygon = result_polygon
		else:
			if not Geometry2D.is_polygon_clockwise(hole):
				hole.reverse()
			subtracted_holes.push_back(hole)
		
		for hole_a in stroke.holes:
			var results = Geometry2D.intersect_polygons(hole, hole_a)
			for result in results:
				result.reverse()
				holes_in_holes.push_back(result)
	
	for hole_b in stroke.holes:
		var results = Geometry2D.intersect_polygons(polygon, hole_b)
		if results.size() > 0:
			for result in results:
				var shape_holes: Array[PackedVector2Array]
				for hole_a in holes_in_holes:
					if Geometry2D.intersect_polygons(hole_a, result).size() > 0: ## overlapping
						if Geometry2D.clip_polygons(hole_a, result).size() == 0: ## inside
							shape_holes.push_back(hole_a)
						else:
							var clip = Geometry2D.clip_polygons(result, hole_a)
							if clip.size() > 0:
								result = clip[0]
				subtracted_strokes.push_back(create_stroke(result, shape_holes))
	
	if Geometry2D.clip_polygons(subtract_polygon, polygon).size() == 0:
		# hole added
		subtract_polygon.reverse()
		subtracted_holes.push_back(subtract_polygon)
		
		holes = subtracted_holes
		subtracted_strokes.push_back(self)
		return subtracted_strokes
	
	var clipped_polygons = Geometry2D.clip_polygons(polygon, subtract_polygon)
	if clipped_polygons.size() == 0:
		# completely erased
		pass
	elif clipped_polygons.size() == 1:
		# polygon altered
		polygon = clipped_polygons[0]
		holes = subtracted_holes
		
		if is_polygon_valid(polygon):
			subtracted_strokes.push_back(self)
	else:
		# split into multiple
		for p in clipped_polygons:
			if not is_polygon_valid(p):
				continue
			var seperated_stroke = create_stroke(p)
			# assign holes to strokes they belong to
			for hole in subtracted_holes:
				if Geometry2D.intersect_polygons(p, hole).size() > 0:
					seperated_stroke.holes.push_back(hole)
			subtracted_strokes.push_back(seperated_stroke)
	
	_curves_dirty = true
	return subtracted_strokes


func subtract_polygon(subtracting_polygon: PackedVector2Array) -> Array:
	var subtracted_strokes := []
	var hole_merged := false
	var merged_holes: Array[PackedVector2Array]
	
	for hole in holes:
		if Geometry2D.intersect_polygons(hole, subtracting_polygon).size() > 0:
			subtracting_polygon = Geometry2D.merge_polygons(hole, subtracting_polygon)[0]
		else:
			merged_holes.push_back(hole)
	
	if Geometry2D.clip_polygons(subtracting_polygon, polygon).size() == 0:
		holes = merged_holes
		holes.push_back(subtracting_polygon)
		return [self]
	else:
		var results = Geometry2D.clip_polygons(polygon, subtracting_polygon)
		if results.size() > 0:
		
			for p in results:
				for hole in merged_holes:
					var holes: Array[PackedVector2Array]
					if Geometry2D.intersect_polygons(p, subtracting_polygon).size() > 0:
						holes.push_back(hole)
						merged_holes.erase(hole)
				subtracted_strokes.push_back(create_stroke(p, holes))
	
	return subtracted_strokes


func mask_stroke(stroke: Stroke) -> Array:
	var masked_strokes := []
	
	var results = Geometry2D.intersect_polygons(polygon, stroke.polygon)
	for result_polygon in results:
		if Geometry2D.is_polygon_clockwise(result_polygon):
			continue
		var result_holes: Array[PackedVector2Array]
		for hole in holes:
			if Geometry2D.intersect_polygons(result_polygon, hole).size() > 0:
				result_holes.push_back(hole)
		for hole in stroke.holes:
			# Todo maybe this should check if the hole is inside a hole?.
			if Geometry2D.intersect_polygons(result_polygon, hole).size() > 0:
				result_holes.push_back(hole)
		masked_strokes.push_back(create_stroke(result_polygon, result_holes))
	return masked_strokes


func translate(offset: Vector2):
	polygon = _translate_polygon(polygon, offset)
	for hole in holes:
		hole = _translate_polygon(hole, offset)
	_curves_dirty = true


func _translate_polygon(polygon: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	for i in polygon.size():
		polygon[i] = polygon[i] + offset
	return polygon


func create_stroke(polygon: PackedVector2Array, holes: Array[PackedVector2Array] = []) -> Stroke:
	return Stroke.new(polygon, holes, color)


func is_stroke_overlapping(stroke: Stroke) -> bool:
	if Geometry2D.intersect_polygons(polygon, stroke.polygon).size() > 0:
		if _is_inside_hole(stroke) or stroke._is_inside_hole(self):
			return false
		else:
			return true
	return false


func is_polygon_overlapping(polygon: PackedVector2Array) -> bool:
	if Geometry2D.intersect_polygons(self.polygon, polygon).size() > 0 and not _is_polygon_inside_hole(polygon):
		return true
	return false


func is_stroke_inside(stroke: Stroke) -> bool:
	if Geometry2D.clip_polygons(polygon, stroke.polygon).size() == 0:
		return not _is_inside_hole(stroke)
	else:
		return false


func _is_inside_hole(stroke: Stroke) -> bool:
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


func optimize(tolerance := 0.1) -> void:
	_curves_dirty = false
	polygon = Flip.douglas_peucker(polygon, tolerance)
	polygon_curve = polygon_to_curve(polygon, tolerance)
	polygon = polygon_curve.get_baked_points()
	hole_curves = []
	for i in holes.size():
		var hole_polygon = Flip.douglas_peucker(holes[i], tolerance)
		var hole_curve = polygon_to_curve(hole_polygon, tolerance)
		hole_curves.push_back(hole_curve)
		var optimized_hole = hole_curve.get_baked_points()
		if not Geometry2D.is_polygon_clockwise(optimized_hole):
			optimized_hole.reverse()
		holes[i] = optimized_hole


func create_curves():
	_curves_dirty = false
	polygon_curve = polygon_to_curve(polygon, 1.0)
	hole_curves = []
	for i in holes.size():
		var hole_curve = polygon_to_curve(Flip.douglas_peucker(holes[i]), 1.0)
		hole_curves.push_back(hole_curve)


func polygon_to_curve(polygon: PackedVector2Array, bake_interval: float) -> Curve2D:
	var curve := Curve2D.new()
	curve.bake_interval = bake_interval * 16.0
	for vertex in polygon:
		curve.add_point(vertex)
	return curve


func generate_unified_polygon():
	unified_polygon = polygon
	
	var holes_ordered := []
	
	for hole_i in holes.size():
		var hole = holes[hole_i]
		var left := 999999.0
		var left_vertex_id
		for id in hole.size():
			if hole[id].x < left:
				left = hole[id].x
				left_vertex_id = id
		holes_ordered.push_back([left, hole_i, left_vertex_id])
	
	holes_ordered.sort_custom(_sort_holes)
	
	for hole_ordered in holes_ordered:
		var hole: PackedVector2Array = holes[hole_ordered[1]]
		#if not Geometry2D.is_polygon_clockwise(hole):
			#push_error("Counter-Clockwise Hole Detected.", hole_ordered)
		var left_vertex_id = hole_ordered[2]
		var left_vertex = hole[left_vertex_id]
		var closest_distance := 999999.0
		var closest_intersect_i
		var closest_intersect_position
		for i in unified_polygon.size() - 1:
			var intersect = Geometry2D.segment_intersects_segment(
					unified_polygon[i], unified_polygon[i+1],
					left_vertex, left_vertex + Vector2.LEFT * 9999999.0
				)
			
			if intersect:
				var distance = left_vertex.distance_to(intersect)
				if distance < closest_distance:
					closest_distance = distance
					closest_intersect_i = i
					closest_intersect_position = intersect
		
		var hole_before = hole
		hole = hole.slice(left_vertex_id) +  hole.slice(0, left_vertex_id + 1)
		
		var intersect = PackedVector2Array([closest_intersect_position])
		
		if closest_intersect_i != null:
			unified_polygon = (
					unified_polygon.slice(0, closest_intersect_i + 1) +
					intersect + hole + intersect +
					unified_polygon.slice(closest_intersect_i + 1)
				)


func _sort_holes(a, b):
	return a[0] < b[0]


func is_polygon_valid(polygon):
	if polygon.size() > 8:
		return true
	var bounds_min := Vector2.ONE * 999999
	var bounds_max := Vector2.ONE * -999999
	
	var area := 0.0
	var triangles = Geometry2D.triangulate_delaunay(polygon)
	
	for i in range(0, triangles.size(), 3):
		var a = polygon[triangles[i]].distance_to(polygon[triangles[i+1]])
		var b = polygon[triangles[i+1]].distance_to(polygon[triangles[i+2]])
		var c = polygon[triangles[i+2]].distance_to(polygon[triangles[i]])
		var s = (a + b + c) / 2.0
		var ar = sqrt(s * (s - a) * (s - b) * (s - c))
		if not is_nan(ar):
			area += ar
	
	return area > 4 ** 2


func is_valid() -> bool:
	return is_polygon_valid(polygon)


func get_vertex_count() -> int:
	var count = polygon.size()
	for hole in holes:
		count += hole.size()
	return count


func copy():
	_curves_dirty = true
	var holes_copy: Array[PackedVector2Array]
	for hole in holes:
		holes_copy.push_back(hole.duplicate())
	return Stroke.new(polygon.duplicate(), holes_copy, color)


func get_edge_selection() -> Array:
	var selection = EdgeSelection.new(self)
	var selections := [selection]
	
	for i in polygon.size():
		selection.add_vertex_unsafe(i, 1.0)
	
	# Holes.
	for i in holes.size():
		var hole = holes[i]
		selection = EdgeSelection.new(self)
		for j in hole.size():
			selection.add_vertex_unsafe(j, 1.0)
		selections.push_back(selection)
		selection.hole_id = i
	
	return selections


func get_edge_selection_ranged(position: Vector2, range: float,
		ease_mode, max_distance := 6.0, connected: bool = true) -> EdgeSelection:
	
	var selection: EdgeSelection
	
	selection = _get_polygon_edge_selection(polygon, polygon_curve, position, range, ease_mode,
			max_distance, connected)
	if selection:
		return selection
	
	# Holes.
	for i in holes.size():
		selection = _get_polygon_edge_selection(holes[i], hole_curves[i], position, range, ease_mode,
				max_distance, connected)
		if selection:
			selection.hole_id = i
			return selection
	return null


func _get_polygon_edge_selection(polygon: PackedVector2Array, curve: Curve2D,
		position: Vector2, range: float, ease_mode, max_distance := 6.0, connected: bool = true):
	
	if not connected:
		var selection = EdgeSelection.new(self)
		var l = polygon.size()
		for i in l:
			var distance = polygon[i].distance_to(position)
			if distance < range:
				var t = 1.0 - distance / range
				var weight = Flip.warp_ease(t, ease_mode)
				selection.add_vertex(i, weight)
		if selection.get_vertex_count() > 0:
			return selection
		return null
	
	var closest_point_on_edge = curve.get_closest_point(position)
	var distance_to_edge = closest_point_on_edge.distance_to(position)
	
	if distance_to_edge > max_distance:
		# Not in dragging range.
		return null
	
	var l = polygon.size()
	var closest_vertex_i: int = -1
	var closest_distance: float = 999.0
	for vertex_i in l:
		var dist = closest_point_on_edge.distance_to(polygon[vertex_i])
		if dist < closest_distance:
			closest_distance = dist
			closest_vertex_i = vertex_i
	
	var selection := EdgeSelection.new(self)
	
	selection.add_vertex(closest_vertex_i, 1.0)
	
	# Travel clockwise of start point 👉.
	var total_dist := 0.0
	for i in int(l * 0.5):
		var vertex_i = (closest_vertex_i + i + 1) % l
		var vertex_i_prev = (closest_vertex_i + i) % l
		
		var dist = polygon[vertex_i].distance_to(polygon[vertex_i_prev])
		
		total_dist += dist
		if total_dist > range:
			# Passed range ✋.
			break
		
		var weight = 1.0 - (total_dist / range)
		weight = Flip.warp_ease(weight, ease_mode)
		selection.add_vertex(vertex_i, weight)
	
	# This is just so the preview line can be drawn properly.
	selection.vertex_indices.reverse()
	selection.vertex_weights.reverse()
	
	# Travel counter-clockwise of start point 👈.
	total_dist = 0.0
	for i in int(l * 0.5):
		var vertex_i = (closest_vertex_i - i - 1 + l) % l
		var vertex_i_prev = (closest_vertex_i - i + l) % l
		
		var dist = polygon[vertex_i].distance_to(polygon[vertex_i_prev])
		
		total_dist += dist
		if total_dist > range:
			# Passed range ✋.
			break
		
		var weight = 1.0 - (total_dist / range)
		weight = Flip.warp_ease(weight, ease_mode)
		selection.add_vertex(vertex_i, weight)
	
	selection.closest_point = closest_point_on_edge
	
	return selection

