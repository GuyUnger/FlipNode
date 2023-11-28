@tool
@icon("res://addons/goolash/icons/Brush2D.svg")
class_name Brush2D
extends Node2D

const BrushStroke2D = preload("res://addons/goolash/brush_stroke2d.tscn")

signal edited

@export var stroke_data: Array
var strokes: Array

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
var _selected_highlight := 0.0

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
	show_behind_parent = true
	
	if Engine.is_editor_hint():
		draw()
	else:
		if stroke_data.size() == 0:
			return
		match physics_mode:
			PhysicsMode.NONE:
				draw()
			PhysicsMode.STATIC:
				call_deferred("_generate_static_body")
				draw()
			PhysicsMode.RIGID:
				call_deferred("_generate_rigid_body")


func add_stroke(stroke: BrushStrokeData):
	stroke_data.push_back(stroke)


func draw():
	var stroke_count = stroke_data.size()
	
	while strokes.size() > stroke_count:
		remove_child(strokes[strokes.size() - 1])
		strokes.pop_back()
	
	while strokes.size() < stroke_count:
		var stroke = BrushStroke2D.instantiate()
		add_child(stroke)
		strokes.push_back(stroke)
	
	for i in stroke_data.size():
		strokes[i].draw(stroke_data[i])

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
		
		var stroke = BrushStroke2D.instantiate()
		rigidbody.add_child(stroke)
		stroke.draw(BrushStrokeData.new(polygon, [], stroke_data[0].color))


func get_islands():
	var islands := []
	for stroke in stroke_data:
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


func _process(delta):
	queue_redraw()
	if Engine.is_editor_hint() and GoolashEditor.editor._get_editing_brush() == self:
		_selected_highlight = move_toward(_selected_highlight, 0.0, delta / 0.5)
	else:
		_selected_highlight = 0.0


func _draw():
	if _forward_draw_requested:
		GoolashEditor.editor._forward_draw_brush(self)
	
	if Engine.is_editor_hint():
		if _selected_highlight > 0.0:
			for stroke: BrushStrokeData in stroke_data:
				if stroke.polygon.size() < 3 or stroke._erasing:
					continue
				draw_stroke_outline(stroke, 2.0, ease(_selected_highlight, 0.2))
		
		#for stroke: BrushStrokeData in stroke_data:
			#if stroke._erasing:
				#draw_stroke_outline(stroke, 1.0, 0.1)


func draw_stroke_outline(stroke, thickness := 1.0, alpha := 1.0):
	thickness /= get_viewport().get_screen_transform().get_scale().x
	draw_polygon_outline(stroke.polygon, thickness, alpha)
	for hole in stroke.holes:
		draw_polygon_outline(hole, thickness, alpha)


func draw_polygon_outline(polygon, thickness := 1.0, alpha := 1.0):
	polygon = polygon.duplicate()#Geometry2D.offset_polygon(polygon, 0.0)
	polygon.push_back(polygon[0])
	draw_polyline(polygon, Color(1.0, 1.0, 1.0, alpha), thickness, true)


func get_strokes_duplicate() -> Array:
	var strokes_duplicate = []
	for stroke in stroke_data:
		strokes_duplicate.push_back(stroke.copy())
	return strokes_duplicate
