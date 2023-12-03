@tool
@icon("res://addons/goolash/icons/Brush2D.svg")
class_name Brush2D
extends Node2D

#const BrushStroke2D = preload("res://addons/goolash/brush_stroke2d.tscn")

signal edited

@export var strokes_data: Array

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
		if strokes_data.size() == 0:
			return
		match physics_mode:
			PhysicsMode.NONE:
				init_strokes()
			PhysicsMode.STATIC:
				call_deferred("_generate_static_body")
				init_strokes()
			PhysicsMode.RIGID:
				call_deferred("_generate_rigid_body")


func add_stroke(stroke_data: BrushStrokeData):
	#TODO: not sure if this is the best way to handle stroke data and strokes
	strokes_data.push_back(stroke_data)
	
	var stroke = BrushStroke2D.new()
	stroke_data.stroke = stroke
	add_child(stroke)
	stroke_data.draw()
	stroke.material = get_override_material(stroke_data)


func remove_stroke(stroke_data: BrushStrokeData):
	strokes_data.erase(stroke_data)
	remove_child(stroke_data.stroke)


func init_strokes():
	#TODO: duplicate code from add_stroke
	for stroke_data in strokes_data:
		
		var stroke = BrushStroke2D.new()
		stroke_data.stroke = stroke
		add_child(stroke)
		stroke.material = get_override_material(stroke_data)
		stroke_data.draw()


func move_stroke_to_back(stroke_data: BrushStrokeData):
	strokes_data.erase(stroke_data)
	strokes_data.push_front(stroke_data)


func move_stroke_to_front(stroke_data: BrushStrokeData):
	strokes_data.erase(stroke_data)
	strokes_data.push_back(stroke_data)


func redraw_all():
	for child in get_children():
		if child is BrushStroke2D:
			remove_child(child)
	
	for stroke_data in strokes_data:
		var stroke = BrushStroke2D.new()
		stroke_data.stroke = stroke
		add_child(stroke)
		stroke.material = get_override_material(stroke_data)
		stroke_data.draw()


func _generate_static_body():
	var body = StaticBody2D.new()
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	add_child(body)
	for polygon in get_islands():
		var collision_polygon = CollisionPolygon2D.new()
		body.add_child(collision_polygon)
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
		stroke.init(BrushStrokeData.new(polygon, [], strokes_data[0].color))


func get_islands():
	var islands := []
	for stroke in strokes_data:
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


#func _process(delta):
	#if Engine.is_editor_hint():
		#queue_redraw()


func _draw():
	if Engine.is_editor_hint() and _forward_draw_requested:
		_forward_draw_requested = false
		GoolashEditor.editor._forward_draw_brush(self)


func draw_stroke_outline(stroke, thickness := 1.0, color: Color = Color.WHITE, alpha := 1.0):
	thickness /= get_viewport().get_screen_transform().get_scale().x
	draw_polygon_outline(stroke.polygon, thickness, color, alpha)
	for hole in stroke.holes:
		draw_polygon_outline(hole, thickness, color, alpha)


func draw_polygon_outline(polygon, thickness := 1.0, color: Color = Color.WHITE, alpha := 1.0):
	polygon = polygon.duplicate()
	polygon.push_back(polygon[0])
	color.a = alpha
	draw_polyline(polygon, color, thickness, true)


func get_strokes_duplicate() -> Array:
	var strokes_duplicate = []
	for stroke in strokes_data:
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
