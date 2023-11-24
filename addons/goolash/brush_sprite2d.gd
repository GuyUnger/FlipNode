@tool
@icon("res://addons/goolash/icons/BrushSprite2D.svg")
class_name BrushSprite2D
extends Node2D

const BrushStroke2D = preload("res://addons/goolash/brush_stroke2d.tscn")

signal edited

@export var stroke_data: Array
var strokes: Array

enum PhysicsMode {NONE, STATIC, RIGID, SOFT}
@export var physics_mode: PhysicsMode = PhysicsMode.NONE

func _ready():
	show_behind_parent = true
	
	if not Engine.is_editor_hint():
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
	else:
		draw()


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
	add_child(body)
	for polygon in get_islands():
		var collision_polygon = CollisionPolygon2D.new()
		body.add_child(collision_polygon)
		collision_polygon.polygon = GoolashEditor.douglas_peucker(polygon, 3.0)


func _generate_rigid_body():
	for polygon in get_islands():
		var center := Vector2()
		for vertex in polygon:
			center += vertex
		center /= polygon.size()
		
		for i in polygon.size():
			polygon[i] -= center
		
		var rigidbody = RigidBody2D.new()
		rigidbody.position = position + center
		get_parent().add_child(rigidbody)
		
		var collision_polygon = CollisionPolygon2D.new()
		rigidbody.add_child(collision_polygon)
		collision_polygon.polygon = GoolashEditor.douglas_peucker(polygon, 3.0)
		
		var stroke = BrushStroke2D.instantiate()
		rigidbody.add_child(stroke)
		stroke.draw(BrushStrokeData.new(polygon))

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
