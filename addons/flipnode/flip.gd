@tool
class_name Flip
extends Node

static var editor

#TODO: use this
const MaterialErase: ShaderMaterial = preload("res://addons/flipnode/shading/erase_material.tres")
const MaterialArea: ShaderMaterial = preload("res://addons/flipnode/shading/area_material.tres")

enum {DRAW_MODE_FRONT, DRAW_MODE_BEHIND, DRAW_MODE_INSIDE, DRAW_MODE_ERASE}


static func is_node_editable(node):
	return node.scene_file_path == "" or node.get_tree().edited_scene_root == node


static var default_fps := 0.0:
	get:
		if default_fps <= 0:
			default_fps = ProjectSettings.get_setting("flipnode/animation/default_fps", 12.0)
		return default_fps

enum {WARP_EASE_SMOOTH, WARP_EASE_SHARP, WARP_EASE_LINEAR, WARP_EASE_RANDOM}


static func create_polygon_line(start_position: Vector2, end_position: Vector2, width: float = 32.0, vertex_count := 32) -> PackedVector2Array:
	var angle = start_position.angle_to_point(end_position)
	var start_polygon := []
	var end_polygon := []
	var mid_left := []
	var mid_right := []
	var vertex_count_half: float = vertex_count * 0.5
	
	for i in vertex_count_half:
		start_polygon.push_back(start_position + Vector2.DOWN.rotated(angle + i / vertex_count_half * PI) * width * 0.5)
	
	var middle_points = floor(start_position.distance_to(end_position) / width)
	
	for i in vertex_count_half:
		end_polygon.push_back(end_position + Vector2.DOWN.rotated(angle + PI + i / vertex_count_half * PI) * width * 0.5)
	return PackedVector2Array(start_polygon + end_polygon)


func create_polygon_circle(center: Vector2, diameter: float = 32.0, vertex_count := 32):
	var vertices := []
	
	var radius = diameter * 0.5
	for i in vertex_count:
		vertices.push_back(center + Vector2.from_angle(i / float(vertex_count) * TAU) * radius)
	
	return PackedVector2Array(vertices)


static func catmull_rom(points, max_length := 10.0) -> PackedVector2Array:
	if points.size() < 4:
		return PackedVector2Array(points)
	
	var interpolated_points = PackedVector2Array()
	
	interpolated_points.append(points[0])
	
	for i in range(points.size() - 3):
		var p0 = points[i]
		var p1 = points[i + 1]
		var p2 = points[i + 2]
		var p3 = points[i + 3]
		
		var num_segments = min(ceil(p1.distance_to(p2) / max_length), 8)
		for j in range(num_segments):
			var t = j / float(num_segments)
			var t2 = t * t
			var t3 = t2 * t
			
			var v = 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(- p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			
			interpolated_points.append(v)
	
	return interpolated_points


static func catmull_rom_closed(points, max_length = 10.0) -> PackedVector2Array:
	if points.size() < 4:
		return PackedVector2Array(points)
	
	var interpolated_points = PackedVector2Array()
	
	#interpolated_points.append(points[0])
	var l = points.size()
	for i in range(l):
		var p0 = points[i]
		var p1 = points[(i + 1) % l]
		var p2 = points[(i + 2) % l]
		var p3 = points[(i + 3) % l]
		
		var num_segments = min(ceil(p1.distance_to(p2) / max_length), 8)
		
		for j in range(num_segments):
			var t = j / float(num_segments)
			var t2 = t * t
			var t3 = t2 * t
			
			var v = 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(- p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			
			interpolated_points.append(v)
	
	return interpolated_points


static func douglas_peucker(points: PackedVector2Array, tolerance := 1.0) -> PackedVector2Array:
	if points.size() < 3:
		return points
	
	# Find the point with the maximum distance from the line between the first and last point.
	var dmax := 0.0
	var index := 0
	for i in range(1, points.size() - 1):
		var d := 0.0
		var point = points[i]
		var point1 = points[0]
		var point2 = points[points.size() - 1]
		# Calculate the perpendicular distance between point and line segment point1-point2 .
		var dx = point2.x - point1.x
		var dy = point2.y - point1.y
		
		if dx == 0 and dy == 0:
			# Point1 and point2 are the same point.
			d = point1.distance_to(point)
		else:
			var t = ((point.x - point1.x) * dx + (point.y - point1.y) * dy) / (dx ** 2 + dy ** 2)
			if t < 0.0:
				# Point is beyond the 'left' end of the segment.
				d = point.distance_to(point1)
			elif t > 1:
				# Point is beyond the 'right' end of the segment.
				d = point.distance_to(point2)
			else:
				# Point is within the segment.
				var point_t = Vector2(
						point1.x + t * dx,
						point1.y + t * dy
					)
				d = point.distance_to(point_t)
		
		if d > dmax:
			index = i
			dmax = d
	
	# If the maximum distance is greater than the tolerance, recursively simplify.
	if dmax > tolerance:
		var results1 = douglas_peucker(points.slice(0, index+1), tolerance)
		var results2 = douglas_peucker(points.slice(index), tolerance)
		
		return results1 + results2.slice(1)
	else:
		return PackedVector2Array([points[0], points[points.size() - 1]])


static func merge_by_distance(points, min_distance := 2.0):
	var results := [points[0]]
	var last_point = points[0]
	for p in points:
		if last_point.distance_to(p) > min_distance:
			last_point = p
			results.push_back(p)
	return PackedVector2Array(results)


static func warp_ease(t, mode):
	match mode:
		WARP_EASE_SMOOTH:
			return ease(t, -1.5)
		WARP_EASE_SHARP:
			return ease(t, 3.0)
		WARP_EASE_LINEAR:
			return t
		WARP_EASE_RANDOM:
			return ease(t, -1.5) * randf()

