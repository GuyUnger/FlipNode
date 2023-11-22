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
		collision_polygon.polygon = polygon

func get_sprite():
	if not get_parent() is BrushSprite2D:
		push_warning("BrushBody2D parent needs to be BrushSprite2D to work")
		return null
	return get_parent()
