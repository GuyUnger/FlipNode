class_name ActionDraw extends Action

var stroke: Stroke
var draw_mode
var stroke_inside: Stroke
var color: Color


func is_erasing():
	return draw_mode == Flip.DRAW_MODE_ERASE

