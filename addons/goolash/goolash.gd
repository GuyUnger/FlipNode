@tool
extends Node

static var default_fps := 12
var frame := 0.0

@onready var material = preload("res://addons/goolash/shading/brush_stroke_material.tres")

func _process(delta):
	frame += delta * default_fps
	material.set_shader_parameter("goolash_frame", fmod(floor(frame), 1000.0) )


func create_polygon_line(start_position: Vector2, end_position: Vector2, width: float = 32.0, vertex_count := 32) -> PackedVector2Array:
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
