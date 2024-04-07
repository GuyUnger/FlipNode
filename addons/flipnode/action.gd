class_name Action extends RefCounted

var brush: Brush2D

var position_previous
var undo_redo

var _strokes_before

var is_complete := false


func complete():
	_complete()
	is_complete = true


func _complete():
	pass


func set_undo_redo(undo_redo):
	self.undo_redo = undo_redo
	_undo_redo_start()


func _undo_redo_start():
	undo_redo_strokes_start()


func undo_redo_strokes_start():
	_strokes_before = brush.get_strokes_duplicate()


func _undo_redo_strokes_complete(name):
	if undo_redo:
		var strokes_after = brush.get_strokes_duplicate()
		
		undo_redo.create_action(name)
		undo_redo.add_undo_property(brush, "strokes", _strokes_before)
		undo_redo.add_do_property(brush, "strokes", strokes_after)
		undo_redo.add_do_method(brush, "draw")
		undo_redo.add_undo_method(brush, "draw")
		undo_redo.add_undo_method(brush, "update_bounds")
		
		undo_redo.commit_action(false)


func request_draw_brush_overlay():
	brush.request_draw(self)


func _draw_brush():
	pass
