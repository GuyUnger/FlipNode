@tool
class_name ActionMove extends Action

var stroke: Stroke


func _init(brush: Brush2D, stroke: Stroke):
	self.brush = brush
	self.stroke = stroke


func start(position):
	brush.move_stroke_to_front(stroke)
	position_previous = position



func move_to(position: Vector2):
	stroke.translate(position - position_previous)
	stroke.draw()
	position_previous = position


func _complete():
	brush.merge_stroke(stroke)
	brush.edited.emit()
	_undo_redo_strokes_complete("Move Stroke")
