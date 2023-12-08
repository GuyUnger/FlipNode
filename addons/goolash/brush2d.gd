@tool
@icon("res://addons/goolash/icons/Brush2D.svg")
class_name Brush2D
extends Node2D

#const BrushStroke2D = preload("res://addons/goolash/brush_stroke2d.tscn")

signal edited

@export var strokes: Array

@export_group("Collision")
enum PhysicsMode {NONE, STATIC, RIGID, SOFT}
@export var physics_mode: PhysicsMode = PhysicsMode.NONE:
	get:
		return physics_mode
	set(value):
		physics_mode = value
		notify_property_list_changed()

var bounciness := 0.0

@export_flags_2d_physics var collision_layer: int = 1:
	set(value):
		collision_layer = value
		notify_property_list_changed()
@export_flags_2d_physics var collision_mask: int = 1:
	set(value):
		collision_mask = value
		notify_property_list_changed()

var _forward_draw_requested := false

var alpha := 1.0

var static_body = StaticBody2D.new()

func _validate_property(property):
	match property.name:
		"bounciness":
			if physics_mode == PhysicsMode.RIGID:
				property.usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
			else:
				property.usage = PROPERTY_USAGE_STORAGE
		"collision_layer", "collision_mask":
			if physics_mode == PhysicsMode.NONE:
				property.usage = PROPERTY_USAGE_STORAGE
			else:
				property.usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR


func _ready():
	if Engine.is_editor_hint():
		init_strokes()
		get_tree().process_frame.connect(queue_redraw)
	else:
		if strokes.size() == 0:
			return
		match physics_mode:
			PhysicsMode.NONE:
				init_strokes()
			PhysicsMode.STATIC:
				call_deferred("generate_static_body")
				init_strokes()
			PhysicsMode.RIGID:
				call_deferred("_generate_rigid_body")


func add_stroke(stroke: BrushStroke):
	#TODO: not sure if this is the best way to handle stroke data and strokes
	strokes.push_back(stroke)
	
	var stroke_graphic = BrushStroke2D.new()
	stroke.graphic = stroke_graphic
	add_child(stroke_graphic)
	stroke.draw()
	stroke_graphic.material = get_override_material(stroke)


func remove_stroke(stroke_data: BrushStroke):
	strokes.erase(stroke_data)
	remove_child(stroke_data.graphic)
	stroke_data.graphic = null


func init_strokes():
	for stroke in strokes:
		init_stroke_graphic(stroke)


func move_stroke_to_back(stroke_data: BrushStroke):
	strokes.erase(stroke_data)
	strokes.push_front(stroke_data)


func move_stroke_to_front(stroke_data: BrushStroke):
	strokes.erase(stroke_data)
	strokes.push_back(stroke_data)


func redraw_all():
	for child in get_children():
		if child is BrushStroke2D:
			remove_child(child)
	
	for stroke in strokes:
		init_stroke_graphic(stroke)


func init_stroke_graphic(stroke: BrushStroke):
	var stroke_graphic = BrushStroke2D.new()
	stroke.graphic = stroke_graphic
	add_child(stroke_graphic)
	stroke_graphic.material = get_override_material(stroke)
	stroke.draw()


func generate_static_body():
	if not static_body:
		static_body = StaticBody2D.new()
	for c in static_body.get_children():
		c.queue_free()
	static_body.collision_layer = collision_layer
	static_body.collision_mask = collision_mask
	add_child(static_body)
	for polygon in get_islands():
		var collision_polygon = CollisionPolygon2D.new()
		static_body.add_child(collision_polygon)
		collision_polygon.polygon = GoolashEditor.douglas_peucker(polygon, 3.0)


func _generate_rigid_body():
	var physics_material: PhysicsMaterial
	if bounciness > 0.0:
		physics_material = PhysicsMaterial.new()
		physics_material.bounce = bounciness
	for polygon in get_islands():
		var center := Vector2()
		for vertex in polygon:
			center += vertex
		center /= polygon.size()
		
		for i in polygon.size():
			polygon[i] -= center
		
		var rigidbody = RigidBody2D.new()
		if physics_material:
			rigidbody.physics_material_override = physics_material
		rigidbody.collision_layer = collision_layer
		rigidbody.collision_mask = collision_mask
		rigidbody.position = position + center
		get_parent().add_child(rigidbody)
		
		var collision_polygon = CollisionPolygon2D.new()
		rigidbody.add_child(collision_polygon)
		collision_polygon.polygon = GoolashEditor.douglas_peucker(polygon, 3.0)
		
		var stroke = BrushStroke2D.new()
		rigidbody.add_child(stroke)
		stroke.init(BrushStroke.new(polygon, [], strokes[0].color))


func get_islands():
	var islands := []
	for stroke in strokes:
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
	if Engine.is_editor_hint() and _forward_draw_requested:
		_forward_draw_requested = false
		GoolashEditor.editor._forward_draw_brush(self)


func _request_forward_draw():
	_forward_draw_requested = true
	queue_redraw()


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
	if stroke._erasing:
		return GoolashEditor.StrokeEraseMaterial
	elif material:
		return material
	else:
		var material = GoolashEditor.StrokeRegularMaterial
		return material


func merge_stroke(merging_stroke: BrushStroke):
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
				# Different color, subtract
				merged_strokes.append_array(stroke.subtract_stroke(merging_stroke))
		else:
			# No overlap, no operations
			merged_strokes.push_back(stroke)
	
	merged_strokes.push_back(merging_stroke)
	
	for stroke in merged_strokes:
		add_stroke(stroke)
	
	edited.emit()


func subtract_stroke(subtracting_stroke: BrushStroke):
	if strokes.has(subtracting_stroke):
		remove_stroke(subtracting_stroke)
	
	var subtracted_strokes := []
	while strokes.size() > 0:
		var stroke: BrushStroke = strokes[0]
		remove_stroke(stroke)
		subtracted_strokes.append_array(stroke.subtract_stroke(subtracting_stroke))
	
	for stroke in subtracted_strokes:
		add_stroke(stroke)
	
	edited.emit()


func subtract_polygon(subtracting_polygon: PackedVector2Array):
	var subtracted_strokes := []
	
	while strokes.size() > 0:
		var stroke: BrushStroke = strokes[0]
		remove_stroke(stroke)
		subtracted_strokes.append_array(stroke.subtract_polygon(subtracting_polygon))
	
	for stroke in subtracted_strokes:
		add_stroke(stroke)
	
	edited.emit()
