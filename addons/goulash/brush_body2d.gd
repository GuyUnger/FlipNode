@tool
extends StaticBody2D

func _ready():
	generate()
	get_sprite().edited.connect(_on_sprite_edited)


func _on_sprite_edited():
	generate()
	

func generate():
	for child in get_children():
		child.queue_free()
	
	var polygons := []
	for stroke in get_sprite().stroke_data:
		var i := 0
		var l := polygons.size()
		var merging_polygon = stroke.polygon
		
		while i < l:
			var overlaps = Geometry2D.intersect_polygons(polygons[i], stroke.polygon).size() > 0
			if overlaps:
				merging_polygon = Geometry2D.merge_polygons(polygons[i], merging_polygon)[0]
				polygons.remove_at(i)
				l -= 1
			else:
				i += 1
		
		polygons.push_back(merging_polygon)
	
	for polygon in polygons:
		var collision_polygon = CollisionPolygon2D.new()
		add_child(collision_polygon)
		collision_polygon.polygon = _douglas_peucker(polygon, 4.0)

func get_sprite():
	if not get_parent() is BrushSprite2D:
		push_warning("BrushBody2D parent needs to be BrushSprite2D to work")
		return null
	return get_parent()


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
