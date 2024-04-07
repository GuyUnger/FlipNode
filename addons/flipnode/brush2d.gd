@tool
@icon("res://addons/flipnode/icons/Brush2D.svg")
class_name Brush2D extends Node2D

signal edited

@export var strokes: Array
@export var bounds: Rect2

@export var frame_num: int
var animation: BrushAnimation2D
var layer: Layer2D


@export_group("LODs")
var lod_levels := 2
@export var lods := []
var lod_level := 0


func _validate_property(property):
	match property.name:
		"bounds":
			property.usage = PROPERTY_USAGE_NO_EDITOR
		"frame_num":
			if animation:
				property.usage = PROPERTY_USAGE_DEFAULT
			else:
				property.usage = PROPERTY_USAGE_NO_EDITOR


func _ready():
	if Engine.is_editor_hint():
		strokes = strokes.duplicate()
		for i in strokes.size():
			strokes[i] = strokes[i].copy()
		draw()
		generate_lods()
		update_bounds()
		
		if animation:
			set_animation_name()
		return
	
	if strokes.size() == 0:
		return
	
	draw(1)


func _enter_tree() -> void:
	if get_parent() is Layer2D:
		layer = get_parent()
		animation = layer.animation


func _exit_tree() -> void:
	layer = null
	animation = null


#TODO: need a faster way to handle LOD's
#func _process(delta):
	#if not Engine.is_editor_hint():
		#handle_lod()


func _enter():
	pass


func add_stroke(stroke: Stroke):
	#TODO: not sure if this is the best way to handle stroke data and strokes
	strokes.push_back(stroke)
	init_stroke_polygon(stroke)


func init_stroke_polygon(stroke: Stroke):
	var stroke_polygon = take_stroke_polygon()
	stroke.stroke_polygon = stroke_polygon
	add_child(stroke_polygon)
	stroke_polygon.material = get_override_material(stroke)
	stroke.draw()


func remove_stroke(stroke_data: Stroke):
	strokes.erase(stroke_data)
	var stroke_polygon = stroke_data.stroke_polygon
	remove_child(stroke_data.stroke_polygon)
	
	stroke_data.stroke_polygon = null


func move_stroke_to_back(stroke_data: Stroke):
	strokes.erase(stroke_data)
	strokes.push_front(stroke_data)


func move_stroke_to_front(stroke_data: Stroke):
	strokes.erase(stroke_data)
	strokes.push_back(stroke_data)


func draw(lod_level := -1):
	var draw_strokes = lods[lod_level] if lod_level >= 0 else strokes
	for child in get_children():
		if child is StrokePolygon2D:
			remove_child(child)
			put_stroke_polygon(child)
	
	for stroke in draw_strokes:
		if stroke is EncodedObjectAsID:
			print_stack()
			return
		init_stroke_polygon(stroke)
	queue_redraw()



func get_islands():
	var islands := []
	for stroke: Stroke in strokes:
		var i := 0
		var l := islands.size()
		var merging_polygon = stroke.polygon
		
		while i < l:
			var overlaps = Geometry2D.intersect_polygons(islands[i], stroke.polygon).size() > 0
			if overlaps:
				merging_polygon = Geometry2D.merge_polygons(islands[i], merging_polygon)[0]
				islands.remove_at(i)
				l -= 1
			else:
				i += 1
		
		islands.push_back(merging_polygon)
	
	return islands


func _draw():
	if "editor" in Flip and Flip.editor and Flip.editor.editing_brush == self:
		Flip.editor._draw_brush(self)
		var zoom = get_viewport().get_screen_transform().get_scale().x * global_scale.x
		draw_rect(bounds, Color(0.3, 0.4, 1, 0.2), false, 2.0 / zoom)


func draw_outline(thickness := 1.0, color: Color = Color.WHITE, alpha := 1.0):
	for stroke: Stroke in strokes:
		draw_stroke_outline(stroke, thickness, color, alpha)


func draw_stroke_outline(stroke, thickness := 1.0, color: Color = Color.WHITE, alpha := 1.0):
	thickness /= get_viewport().get_screen_transform().get_scale().x
	draw_polygon_outline(stroke.polygon, thickness, color, alpha)
	for hole in stroke.holes:
		draw_polygon_outline(hole, thickness, color, alpha)


func draw_polygon_outline(polygon, thickness := 1.0, color: Color = Color.WHITE, alpha := 1.0):
	if polygon.size() < 3:
		return
	polygon = polygon.duplicate()
	polygon.push_back(polygon[0])
	color.a = alpha
	draw_polyline(polygon, color, thickness, true)


func get_strokes_duplicate() -> Array:
	var strokes_duplicate = []
	for stroke in strokes:
		strokes_duplicate.push_back(stroke.copy())
	return strokes_duplicate


func get_override_material(stroke) -> Material:
	if material:
		return material
	if animation and animation.material:
		return animation.material
	return null


func merge_stroke(merging_stroke: Stroke):
	if strokes.has(merging_stroke):
		remove_stroke(merging_stroke)
	
	var merged_strokes := []
	while strokes.size() > 0:
		var stroke = strokes[0]
		remove_stroke(stroke)
		if merging_stroke.is_stroke_overlapping(stroke):
			if merging_stroke.color.to_html() == stroke.color.to_html():
				# Same color, merge
				merging_stroke.union_stroke(stroke)
			else:
				# Different color, subtract.
				merged_strokes.append_array(stroke.subtract_stroke(merging_stroke))
		else:
			# No overlap, no operations
			merged_strokes.push_back(stroke)
	
	merged_strokes.push_back(merging_stroke)
	
	for stroke in merged_strokes:
		add_stroke(stroke)
	
	_on_edit()


func subtract_stroke(subtracting_stroke: Stroke):
	if strokes.has(subtracting_stroke):
		remove_stroke(subtracting_stroke)
	
	var subtracted_strokes := []
	while strokes.size() > 0:
		var stroke: Stroke = strokes[0]
		remove_stroke(stroke)
		subtracted_strokes.append_array(stroke.subtract_stroke(subtracting_stroke))
	
	for stroke in subtracted_strokes:
		add_stroke(stroke)
	
	_on_edit()


func subtract_polygon(subtracting_polygon: PackedVector2Array):
	var subtracted_strokes := []
	
	while strokes.size() > 0:
		var stroke: Stroke = strokes[0]
		remove_stroke(stroke)
		subtracted_strokes.append_array(stroke.subtract_polygon(subtracting_polygon))
	
	for stroke in subtracted_strokes:
		add_stroke(stroke)
	
	_on_edit()


func _on_edit():
	generate_lods()
	update_bounds()
	edited.emit()


func update_bounds():
	if strokes.size() == 0:
		bounds = Rect2()
		return
	var bounding_box_min := Vector2.ONE * 999999999.0
	var bounding_box_max := Vector2.ONE * -9999999999.0
	for stroke: Stroke in strokes:
		for vertex in stroke.polygon:
			bounding_box_min.x = min(bounding_box_min.x, vertex.x)
			bounding_box_min.y = min(bounding_box_min.y, vertex.y)
			bounding_box_max.x = max(bounding_box_max.x, vertex.x)
			bounding_box_max.y = max(bounding_box_max.y, vertex.y)
	bounds = Rect2(bounding_box_min, bounding_box_max - bounding_box_min)


func generate_lods():
	lods = []
	var tolerances = [0.6, 1.0, 3.0, 10.0, 20.0]
	for level in lod_levels:
		var tolerance = tolerances[level]
		lods.push_back(generate_lod(tolerance))


func generate_lod(tolerance) -> Array:
	var lod_strokes = []
	for stroke: Stroke in strokes:
		var lod_stroke: Stroke = stroke.duplicate()
		lod_stroke.optimize(tolerance)
		lod_strokes.push_back(lod_stroke)
	return lod_strokes


func handle_lod():
	if not visible:
		return
	var _lod_level = floor(0.3 / (get_viewport_transform().get_scale().x * global_scale.x))
	_lod_level = min(_lod_level, lods.size() - 1)
	if lod_level != _lod_level:
		lod_level = _lod_level
		draw(lod_level)


func get_edge_selections_ranged(
		position, range: float, ease_mode, connected := true, max_distance := 6.0) -> Array:
	
	var edge_selections = []
	
	if connected:
		for stroke: Stroke in strokes:
			var selection = stroke.get_edge_selection_ranged(position, range, ease_mode, max_distance, connected)
			if selection:
				edge_selections.push_back(selection)
	return edge_selections


func get_stroke_at_position(position: Vector2):
	for stroke: Stroke in strokes:
		if stroke.is_point_inside(position):
			return stroke
	return null


func get_end_frame():
	if layer:
		return layer.get_brush_end_frame(self)
	return frame_num


func get_view_scale() -> Vector2:
	return get_viewport().get_screen_transform().get_scale() * global_scale


func clear():
	for stroke_data in strokes:
		var stroke_polygon = stroke_data.stroke_polygon
		remove_child(stroke_polygon)
		put_stroke_polygon(stroke_polygon)
	strokes.clear()


func is_empty() -> bool:
	return strokes.size() == 0


func duplicate(flag := 15) -> Node:
	var brush = Brush2D.new()
	brush.stroke_data = strokes.duplicate()
	return brush


func set_animation_name():
	name = "Brush2D (Frame %s)" % frame_num


func set_top(value: bool):
	var index = 4096 if value else 0
	for stroke: Stroke in strokes:
		stroke.stroke_polygon.z_index = index


static var _stroke_polygons := []


static func take_stroke_polygon():
	if _stroke_polygons.size() == 0:
		return StrokePolygon2D.new()
	else:
		return _stroke_polygons.pop_back()


static func put_stroke_polygon(stroke_polygon):
	_stroke_polygons.push_back(stroke_polygon)
