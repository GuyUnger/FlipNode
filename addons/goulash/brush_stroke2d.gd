@tool
extends CanvasGroup

func draw(shape):
	self_modulate = shape.color
	
	var polygon_count = shape.holes.size() + 1
	while get_child_count() < polygon_count:
		var polygon2d = Polygon2D.new()
		add_child(polygon2d)
	while get_child_count() > polygon_count:
		remove_child(get_child(0))
	
	var a = 1.0
	
	var node = get_child(0)
	node.modulate = Color(1.0, 1.0, 1.0, a)
	node.polygon = shape.polygon
	
	for i in shape.holes.size():
		node = get_child(i + 1)
		node.modulate = Color(0.0, 0.0, 0.0, a)
		node.polygon = shape.holes[i]
