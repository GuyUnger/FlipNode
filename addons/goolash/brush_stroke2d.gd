@tool
extends CanvasGroup

func draw(stroke):
	self_modulate = stroke.color
	
	var polygon_count = stroke.holes.size() + 1
	while get_child_count() < polygon_count:
		var polygon2d = Polygon2D.new()
		add_child(polygon2d)
	while get_child_count() > polygon_count:
		remove_child(get_child(0))
	
	var a = 1.0
	
	var node = get_child(0)
	node.modulate = Color(1.0, 1.0, 1.0, a)
	node.polygon = stroke.polygon
	
	for i in stroke.holes.size():
		node = get_child(i + 1)
		node.modulate = Color(0.0, 0.0, 0.0, a)
		node.polygon = stroke.holes[i]
