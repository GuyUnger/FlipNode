@tool
class_name BrushStroke2D extends CanvasGroup

var stroke_data: BrushStrokeData

func _ready():
	show_behind_parent = true


func draw_stroke(stroke_data):
	self_modulate = stroke_data.color
	
	var polygon_count = stroke_data.holes.size() + 1
	while get_child_count() < polygon_count:
		var polygon2d = Polygon2D.new()
		add_child(polygon2d)
	while get_child_count() > polygon_count:
		var c = get_child(0)
		c.queue_free()
		remove_child(c)
	
	var node = get_child(0)
	node.modulate = Color.WHITE
	node.polygon = stroke_data.polygon
	
	for i in stroke_data.holes.size():
		node = get_child(i + 1)
		node.modulate = Color.BLACK
		node.polygon = stroke_data.holes[i]
