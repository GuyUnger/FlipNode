@tool
class_name StaticBodyBrush2D
extends Brush2D

@export_flags_2d_physics var collision_layer: int = 1:
	set(value):
		collision_layer = value
		notify_property_list_changed()
@export_flags_2d_physics var collision_mask: int = 1:
	set(value):
		collision_mask = value
		notify_property_list_changed()

var body


func _ready() -> void:
	if Engine.is_editor_hint():
		super()
		return
	
	body = StaticBody2D.new()
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	add_child(body)
	for polygon in get_islands():
		var collision_polygon = CollisionPolygon2D.new()
		body.add_child(collision_polygon)
		collision_polygon.polygon = Flip.douglas_peucker(polygon, 3.0)
