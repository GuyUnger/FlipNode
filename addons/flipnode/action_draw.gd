class_name ActionDraw extends Action

var stroke: Stroke
var draw_mode: int
var stroke_inside: Stroke
var color: Color


func is_erasing() -> bool:
	return draw_mode == Flip.DRAW_MODE_ERASE

